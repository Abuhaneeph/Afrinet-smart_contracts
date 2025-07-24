import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';
import { ChainsConfig, DeployedContracts, MessageSenderJson } from './interfaces';

async function main(): Promise<void> {
  // Load chain configuration
  const chains: ChainsConfig = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../deploy-config/chains.json'), 'utf8')
  );

  // Find Sepolia testnet config
  const sepoliaChain = chains.chains.find((chain) =>
    chain.description.includes('Sepolia')
  );


  chains.chains.forEach(chain => {
  if (chain.rpc.includes('__SEPOLIA_RPC__') && process.env.THIRDWEB_CLIENT_ID) {
    chain.rpc = `https://11155111.rpc.thirdweb.com/${process.env.THIRDWEB_CLIENT_ID}`;
  }
});

  if (!sepoliaChain) {
    throw new Error('Sepolia configuration not found in chains.json.');
  }

  // Set up provider
  const provider = new ethers.JsonRpcProvider(sepoliaChain.rpc);

  // Load wallet from private key
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in .env file');
  }

  const wallet = new ethers.Wallet(privateKey, provider);

  // Load ABI and bytecode
  const messageSenderJson: MessageSenderJson = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../out/CrossChainMessageSender.sol/MessageSender.json'), 'utf8')
  );
  const { abi, bytecode } = messageSenderJson;

  // Create contract factory and deploy
  const MessageSender = new ethers.ContractFactory(abi, bytecode, wallet);
  const senderContract = await MessageSender.deploy(sepoliaChain.wormholeRelayer);
  await senderContract.waitForDeployment();

  console.log('MessageSender deployed to:', senderContract.target);

  // Update deployedContracts.json
  const deployedContractsPath = path.resolve(__dirname, '../deploy-config/deployedContracts.json');
  const deployedContracts: DeployedContracts = JSON.parse(
    fs.readFileSync(deployedContractsPath, 'utf8')
  );

  deployedContracts.sepolia = {
    MessageSender: senderContract.target as any,
    deployedAt: new Date().toISOString(),
  };

  fs.writeFileSync(deployedContractsPath, JSON.stringify(deployedContracts, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
