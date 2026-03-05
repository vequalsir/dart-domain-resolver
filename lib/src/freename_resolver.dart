import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:pointycastle/export.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'freename_abi.dart';
import 'freename_constants.dart';

class FreenameResolver {
  final Web3Client _client;
  final ContractConfig _config;
  late final DeployedContract _contract;

  FreenameResolver({
    required String rpcUrl,
    required String network,
    bool isTest = false,
  }) : _client = Web3Client(rpcUrl, http.Client()),
       _config = freenameContractConfigs.firstWhere(
         (c) => c.network == network && c.isTest == isTest && c.type == 'read',
         orElse: () => throw Exception(
           'Read contract configuration not found for network: $network',
         ),
       ) {
    _initContract();
  }

  void _initContract() {
    final abi = ContractAbi.fromJson(freenameAbiJson, 'FNSPlatform');
    final contractAddress = EthereumAddress.fromHex(_config.address);
    _contract = DeployedContract(abi, contractAddress);
  }

  /// Calculates the Keccak256 TokenID for a given domain/tld per Freename's JS logic.
  ///
  /// Logic:
  /// domainKeccak = keccak256(domain)
  /// tokenId = keccak256(tld + domainKeccak)
  /// Returns the TokenID as a BigInt string.
  BigInt generateTokenId(String fullDomain) {
    var parts = fullDomain.split('.');
    String domain = '';
    String tld = '';

    if (parts.length > 2) {
      // e.g., something.my.domain -> domain: something.my, tld: domain
      tld = parts.last;
      domain = parts.sublist(0, parts.length - 1).join('.');
    } else if (parts.length == 2) {
      domain = parts[0];
      tld = parts[1];
    } else if (parts.length == 1) {
      tld = parts[0];
    }

    if (domain.isNotEmpty) {
      final domainKeccak = _keccak256(utf8.encode(domain));

      final tldBytes = utf8.encode(tld);
      // Solidity packed: abi.encodePacked((string), (uint256))
      // Since it's a uint256 it takes up 32 bytes
      var builder = BytesBuilder();
      builder.add(tldBytes);
      builder.add(domainKeccak);

      final fullnameKeccak = _keccak256(builder.toBytes());
      return _bytesToBigInt(fullnameKeccak);
    } else {
      final tldKeccak = _keccak256(utf8.encode(tld));
      return _bytesToBigInt(tldKeccak);
    }
  }

  Future<String?> getRecord(BigInt tokenId, String key) async {
    final getRecordFunction = _contract.function('getRecord');
    try {
      final result = await _client.call(
        contract: _contract,
        function: getRecordFunction,
        params: [key, tokenId],
      );
      if (result.isNotEmpty && result[0] != null) {
        return result[0].toString();
      }
    } catch (e) {
      // Record not found or contract rejected
      return null;
    }
    return null;
  }

  Future<List<String>?> getManyRecords(
    BigInt tokenId,
    List<String> keys,
  ) async {
    final getManyRecordsFunction = _contract.function('getManyRecords');
    try {
      final result = await _client.call(
        contract: _contract,
        function: getManyRecordsFunction,
        params: [keys, tokenId],
      );
      if (result.isNotEmpty && result[0] != null) {
        return List<String>.from(result[0]);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<String>?> getAllKeys(BigInt tokenId) async {
    final getAllKeysFunction = _contract.function('getAllKeys');
    try {
      final result = await _client.call(
        contract: _contract,
        function: getAllKeysFunction,
        params: [tokenId],
      );
      if (result.isNotEmpty && result[0] != null) {
        return List<String>.from(result[0]);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, String>?> getAllRecords(BigInt tokenId) async {
    final keys = await getAllKeys(tokenId);
    if (keys == null || keys.isEmpty) return null;

    final values = await getManyRecords(tokenId, keys);
    if (values == null || keys.length != values.length) return null;

    Map<String, String> records = {};
    for (int i = 0; i < keys.length; i++) {
      records[keys[i]] = values[i];
    }
    return records;
  }

  Future<BigInt?> reverseOf(String address) async {
    final reverseOfFunction = _contract.function('reverseOf');
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      final result = await _client.call(
        contract: _contract,
        function: reverseOfFunction,
        params: [ethAddress],
      );
      if (result.isNotEmpty && result[0] != null) {
        BigInt token = result[0] as BigInt;
        if (token > BigInt.zero) return token;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> getDomainName(BigInt tokenId) async {
    final tokenURIFunction = _contract.function('tokenURI');
    try {
      final result = await _client.call(
        contract: _contract,
        function: tokenURIFunction,
        params: [tokenId],
      );
      if (result.isNotEmpty && result[0] != null) {
        final uri = result[0].toString();
        try {
          final response = await http.get(Uri.parse(uri));
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            if (json is Map && json.containsKey('name')) {
              return json['name'] as String;
            }
          }
        } catch (e) {
          // HTTP or JSON parsing error
          return null;
        }
      }
    } catch (e) {
      // Contract call error
      return null;
    }
    return null;
  }

  Future<bool> exists(BigInt tokenId) async {
    final existsFunction = _contract.function('exists');
    try {
      final result = await _client.call(
        contract: _contract,
        function: existsFunction,
        params: [tokenId],
      );
      if (result.isNotEmpty && result[0] != null) {
        return result[0] as bool;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void close() {
    _client.dispose();
  }

  Uint8List _keccak256(Uint8List data) {
    var digest = KeccakDigest(256);
    return digest.process(data);
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
