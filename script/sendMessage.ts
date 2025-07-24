import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';
import { ChainsConfig, DeployedContracts, MessageSenderJson } from './interfaces';

async function main(): Promise<void> {
  // Load chain config and deployed contract addresses
  const chains: ChainsConfig = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../deploy-config/chains.json'), 'utf8')
  );

  const deployedContracts: DeployedContracts = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../deploy-config/deployedContracts.json'), 'utf8')
  );

  console.log('Sender Contract Address: ', deployedContracts.sepolia?.MessageSender);
  console.log('Receiver Contract Address: ', deployedContracts.celo?.MessageReceiver);
  console.log('...');

  // Get Sepolia testnet config
  const sepoliaChain = chains.chains.find((chain) =>
    chain.description.includes('Sepolia')
  );

  // Handle RPC URL replacement if needed
  chains.chains.forEach(chain => {
    if (chain.rpc.includes('__SEPOLIA_RPC__') && process.env.THIRDWEB_CLIENT_ID) {
      chain.rpc = `https://11155111.rpc.thirdweb.com/${process.env.THIRDWEB_CLIENT_ID}`;
    }
  });

  if (!sepoliaChain) {
    throw new Error('Sepolia configuration not found in chains.json.');
  }

  // Verify deployed contracts exist
  if (!deployedContracts.sepolia?.MessageSender) {
    throw new Error('Sepolia MessageSender address not found in deployedContracts.json');
  }

  if (!deployedContracts.celo?.MessageReceiver) {
    throw new Error('Celo MessageReceiver address not found in deployedContracts.json');
  }

  // Set up provider
  const provider = new ethers.JsonRpcProvider(sepoliaChain.rpc);

  // Load wallet from private key
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('PRIVATE_KEY not set in .env file');
  }

  const wallet = new ethers.Wallet(privateKey, provider);

  // Load ABI
  const messageSenderJson: MessageSenderJson = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../out/CrossChainMessageSender.sol/MessageSender.json'), 'utf8')
  );
  const abi = messageSenderJson.abi;

  // Instantiate MessageSender contract
  const MessageSender = new ethers.Contract(
    deployedContracts.sepolia.MessageSender,
    abi,
    wallet
  );

  // Define destination chain and receiver
  const targetChain = 14; // Wormhole chain ID for Celo Alfajores testnet
  const targetAddress = deployedContracts.celo.MessageReceiver;

  const message = 'Hello from Sepolia to Celo!';

  console.log(`Sending message: "${message}"`);
  console.log(`From Sepolia (${deployedContracts.sepolia.MessageSender})`);
  console.log(`To Celo (${targetAddress})`);
  console.log('...');

  try {
    // Quote the cost and send the message
    console.log('Getting cross-chain cost quote...');
    const txCost = await MessageSender.quoteCrossChainCost(targetChain);
    console.log(`Transaction cost: ${ethers.formatEther(txCost)} ETH`);

    console.log('Sending message...');
    const tx = await MessageSender.sendMessage(targetChain, targetAddress, message, {
      value: txCost,
    });

    console.log('Transaction sent, waiting for confirmation...');
    await tx.wait();
    console.log('...');

    console.log('Message sent successfully!');
    console.log('Transaction hash:', tx.hash);
    console.log(
      `You can track the transaction on Wormhole Explorer: https://wormholescan.io/#/tx/${tx.hash}?network=TESTNET`
    );
  } catch (error) {
    console.error('Failed to send message:', error);
    throw error;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});