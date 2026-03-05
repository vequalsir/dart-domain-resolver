import 'dart:io';
import 'package:dart_domain_resolver/src/freename_resolver.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  if (arguments.isEmpty) {
    print('Usage: dart run bin/dart_domain_resolver.dart <domain_or_address>');
    exit(1);
  }

  final input = arguments[0];
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

  final apiKey = env['ALCHEMY_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: Missing ALCHEMY_API_KEY in .env file.');
    exit(1);
  }

  bool foundRecord = false;
  print('Resolving $input...\n');

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
        print('Checking reverse lookup on $network...');
        final tokenId = await resolver.reverseOf(input);
        if (tokenId != null) {
          print('Found TokenID on $network: $tokenId');

          final domainName = await resolver.getDomainName(tokenId);
          if (domainName != null) {
            print('Resolved Domain: $domainName');
          } else {
            print('Resolved Domain: [Name not found in metadata]');
          }

          final records = await resolver.getAllRecords(tokenId);
          if (records != null) {
            print('Records:');
            records.forEach((key, value) {
              print('  $key: $value');
            });
          }
          foundRecord = true;
          break;
        }
      } else {
        print('Checking domain on $network...');
        final tokenId = resolver.generateTokenId(input);

        final exists = await resolver.exists(tokenId);
        if (exists) {
          print('Domain exists on $network!');
          print('Generated TokenID: $tokenId');
          final records = await resolver.getAllRecords(tokenId);
          if (records != null) {
            print('Records:');
            records.forEach((key, value) {
              print('  $key: $value');
            });
          } else {
            print('No records found for domain.');
          }
          foundRecord = true;
          break;
        }
      }
    } catch (e) {
      print('Error on $network: $e');
    } finally {
      resolver.close();
    }
  }

  if (!foundRecord) {
    if (isReverse) {
      print(
        '\nNo reverse lookup record found for $input across checked networks.',
      );
    } else {
      print('\nDomain does not exist across checked networks.');
    }
  }
}
