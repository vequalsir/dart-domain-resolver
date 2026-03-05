class ContractConfig {
  final String network;
  final String address;
  final String type;
  final bool isTest;

  const ContractConfig({
    required this.network,
    required this.address,
    required this.type,
    required this.isTest,
  });
}

const List<ContractConfig> freenameContractConfigs = [
  ContractConfig(
    network: 'polygon_mumbai',
    address: '0x6034C0d80e6d023FFd62Ba48e6B5c13afe72D143',
    type: 'read',
    isTest: true,
  ),
  ContractConfig(
    network: 'polygon_mumbai',
    address: '0x6034C0d80e6d023FFd62Ba48e6B5c13afe72D143',
    type: 'write',
    isTest: true,
  ),
  ContractConfig(
    network: 'polygon',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'polygon',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'write',
    isTest: false,
  ),
  ContractConfig(
    network: 'cronos',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'cronos',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'write',
    isTest: false,
  ),
  ContractConfig(
    network: 'bsc',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'bsc',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'write',
    isTest: false,
  ),
  ContractConfig(
    network: 'aurora',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'aurora',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'write',
    isTest: false,
  ),
  ContractConfig(
    network: 'ethereum',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'sepolia',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: true,
  ),
  ContractConfig(
    network: 'base',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: false,
  ),
  ContractConfig(
    network: 'base_sepolia',
    address: '0x465ea4967479A96D4490d575b5a6cC2B4A4BEE65',
    type: 'read',
    isTest: true,
  ),
];
