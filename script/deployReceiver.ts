import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';
import { ChainsConfig, DeployedContracts, MessageReceiverJson } from './interfaces';

async function main(): Promise<void> {
  // Load chain configuration
  const chains: ChainsConfig = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../deploy-config/chains.json'), 'utf8')
  );

  // Find Celo network config
  const celoChain = chains.chains.find((chain) =>
    chain.description.includes('Celo')
  );

  // Handle RPC URL replacement if needed
  chains.chains.forEach(chain => {
    if (chain.rpc.includes('_CELO_RPC__') && process.env.THIRDWEB_CLIENT_ID) {
      chain.rpc = `https://alfajores-forno.celo-testnet.org/`; // Adjusted placeholder
    }
  });

  if (!celoChain) {
    throw new Error('Celo configuration not found in chains.json.');
  }

  // Set up provider
  const provider = new ethers.JsonRpcProvider(celoChain.rpc);

  // Load wallet from private key
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in .env file');
  }

  const wallet = new ethers.Wallet(privateKey, provider);

  // Load ABI and bytecode for MessageReceiver
  const messageReceiverJson: MessageReceiverJson = JSON.parse(
    fs.readFileSync(
      path.resolve(__dirname, '../out/CrossChainMessageReceiver.sol/MessageReceiver.json'),
      'utf8'
    )
  );
  const { abi, bytecode } = messageReceiverJson;

  // Create contract factory and deploy
  const MessageReceiver = new ethers.ContractFactory(abi, bytecode, wallet);
  const receiverContract = await MessageReceiver.deploy(celoChain.wormholeRelayer);
  await receiverContract.waitForDeployment();

  console.log('MessageReceiver deployed to:', receiverContract.target);

  // Load deployed contracts
  const deployedContractsPath = path.resolve(__dirname, '../deploy-config/deployedContracts.json');
  const deployedContracts: DeployedContracts = JSON.parse(
    fs.readFileSync(deployedContractsPath, 'utf8')
  );

  // Register sender from Sepolia
  const sepoliaSenderAddress = deployedContracts.sepolia?.MessageSender;
  if (!sepoliaSenderAddress) {
    throw new Error('Sepolia MessageSender address not found.');
  }

  const sourceChainId = 10002; // Wormhole chain ID for Sepolia testnet

  const tx = await (receiverContract as any).setRegisteredSender(
    sourceChainId,
    ethers.zeroPadValue(sepoliaSenderAddress, 32)
  );
  await tx.wait();

  console.log(`Registered MessageSender (${sepoliaSenderAddress}) for Sepolia chain (${sourceChainId})`);

  // Update deployedContracts.json
  deployedContracts.celo = {
    MessageReceiver: receiverContract.target as any,
    deployedAt: new Date().toISOString(),
  };

  fs.writeFileSync(deployedContractsPath, JSON.stringify(deployedContracts, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
