import 'dart:io';
import 'dart:convert';
import 'package:dart_domain_resolver/src/freename_resolver.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
  // Initialize DotEnv (don't load yet)
  var env = DotEnv(includePlatformEnvironment: true);

  // Load .env only if it exists (local development)
  if (File('.env').existsSync()) {
    env.load();
  }

  // Prefer Platform environment (for Docker/Coolify runtime), fallback to .env
  final apiKey =
      Platform.environment['ALCHEMY_API_KEY'] ?? env['ALCHEMY_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: Missing ALCHEMY_API_KEY in environment or .env file.');
    exit(1);
  }

  final portStr = Platform.environment['PORT'] ?? env['PORT'];
  final port = (portStr != null && portStr.isNotEmpty)
      ? int.tryParse(portStr) ?? 8080
      : 8080;

  // Bind to any IPv6 (which implicitly bindings to IPv4 on Linux) to ensure Docker port mapping works
  final server = await HttpServer.bind(InternetAddress.anyIPv6, port);
  print('Server listening on port $port');

  await for (HttpRequest request in server) {
    if (request.method == 'GET' && request.uri.path.startsWith('/resolve/')) {
      final input = request.uri.pathSegments.last;

      if (input.isEmpty) {
        _sendResponse(request, 400, {
          'error': 'Missing domain or address to resolve',
        });
        continue;
      }

      await _handleResolveRequest(request, input, apiKey);
    } else {
      _sendResponse(request, 404, {'error': 'Not Found'});
    }
  }
}

Future<void> _handleResolveRequest(
  HttpRequest request,
  String input,
  String apiKey,
) async {
  final isReverse = input.startsWith('0x') && input.length == 42;

  final networks = <Map<String, dynamic>>[
    {
      'name': 'ethereum',
      'baseUrl': 'https://eth-mainnet.g.alchemy.com/v2',
      'isTest': false,
    },
    {
      'name': 'sepolia',
      'baseUrl': 'https://eth-sepolia.g.alchemy.com/v2',
      'isTest': true,
    },
    {
      'name': 'polygon',
      'baseUrl': 'https://polygon-mainnet.g.alchemy.com/v2',
      'isTest': false,
    },
    {
      'name': 'polygon_mumbai',
      'baseUrl': 'https://polygon-amoy.g.alchemy.com/v2',
      'isTest': true,
    },
    {
      'name': 'base',
      'baseUrl': 'https://base-mainnet.g.alchemy.com/v2',
      'isTest': false,
    },
    {
      'name': 'base_sepolia',
      'baseUrl': 'https://base-sepolia.g.alchemy.com/v2',
      'isTest': true,
    },
  ];

  Map<String, dynamic>? resultData;
  String? resolvedNetwork;

  for (final config in networks) {
    final network = config['name'] as String;
    final rpcUrl = '${config['baseUrl']}/$apiKey';
    final isTest = config['isTest'] as bool;

    final resolver = FreenameResolver(
      rpcUrl: rpcUrl,
      network: network,
      isTest: isTest,
    );

    try {
      if (isReverse) {
        final tokenId = await resolver.reverseOf(input);
        if (tokenId != null) {
          final domainName = await resolver.getDomainName(tokenId);
          final records = await resolver.getAllRecords(tokenId);

          resultData = {
            'type': 'reverse',
            'input': input,
            'tokenId': tokenId.toString(),
            'domain': domainName ?? '[Name not found in metadata]',
            'records': records ?? {},
          };
          resolvedNetwork = network;
          break;
        }
      } else {
        final tokenId = resolver.generateTokenId(input);
        final exists = await resolver.exists(tokenId);

        if (exists) {
          final records = await resolver.getAllRecords(tokenId);

          resultData = {
            'type': 'forward',
            'input': input,
            'tokenId': tokenId.toString(),
            'records': records ?? {},
          };
          resolvedNetwork = network;
          break;
        }
      }
    } catch (e) {
      print('Error on $network: $e');
    } finally {
      resolver.close();
    }
  }

  if (resultData != null) {
    _sendResponse(request, 200, {
      'network': resolvedNetwork,
      'data': resultData,
    });
  } else {
    _sendResponse(request, 404, {
      'error': isReverse
          ? 'No reverse lookup record found across checked networks.'
          : 'Domain does not exist across checked networks.',
    });
  }
}

void _sendResponse(
  HttpRequest request,
  int statusCode,
  Map<String, dynamic> jsonData,
) {
  request.response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(jsonData))
    ..close();
}
