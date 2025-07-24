import { BytesLike, ethers } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';
import readlineSync from 'readline-sync';

dotenv.config();

interface ChainConfig {
  description: string;
  chainId: number;
  rpc: string;
  tokenBridge: string;
  wormholeRelayer: string;
  wormhole: string;
}

interface DeployedContracts {
  [chainId: number]: {
    networkName: string;
    CrossChainSender?: string;
    CrossChainReceiver?: string;
    deployedAt: string;
  };
}

function loadConfig(): ChainConfig[] {
  const configPath = path.resolve(__dirname, '../deploy-config/chains.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const chains: ChainConfig[] = config.chains;
  
  // Replace RPC URLs based on environment variables
  chains.forEach(chain => {
    // Replace Sepolia RPC
    if (chain.rpc.includes('__SEPOLIA_RPC__') && process.env.THIRDWEB_CLIENT_ID) {
      chain.rpc = `https://11155111.rpc.thirdweb.com/${process.env.THIRDWEB_CLIENT_ID}`;
    }
    
    // Replace Mantle Sepolia RPC
    if (chain.rpc.includes('_MANTLE_SEPOLIA_RPC_') && process.env.MANTLE_SEPOLIA_RPC) {
      chain.rpc = process.env.MANTLE_SEPOLIA_RPC;
    }
    
    // Replace Celo RPC
    if (chain.rpc.includes('__CELO_RPC__') && process.env.CELO_RPC) {
      chain.rpc = process.env.CELO_RPC;
    }
    
    // Add more RPC replacements as needed
    // You can also use a more generic approach:
    const rpcMatches = chain.rpc.match(/__([A-Z_]+)__/g);
    if (rpcMatches) {
      rpcMatches.forEach(match => {
        const envVarName = match.replace(/__/g, '');
        const envValue = process.env[envVarName];
        if (envValue) {
          chain.rpc = chain.rpc.replace(match, envValue);
        }
      });
    }
    
    // Handle single underscore patterns like _MANTLE_SEPOLIA_RPC_
    const singleUnderscoreMatches = chain.rpc.match(/_([A-Z_]+)_/g);
    if (singleUnderscoreMatches) {
      singleUnderscoreMatches.forEach(match => {
        const envVarName = match.replace(/_/g, '');
        const envValue = process.env[envVarName];
        if (envValue) {
          chain.rpc = chain.rpc.replace(match, envValue);
        }
      });
    }
  });
  
  return chains;
}

function selectChain(
  chains: ChainConfig[],
  role: 'source' | 'target'
): ChainConfig {
  console.log(`\nSelect the ${role.toUpperCase()} chain:`);
  chains.forEach((chain, index) => {
    console.log(`${index + 1}: ${chain.description}`);
  });

  const chainIndex =
    readlineSync.questionInt(
      `\nEnter the number for the ${role.toUpperCase()} chain: `
    ) - 1;
  
  if (chainIndex < 0 || chainIndex >= chains.length) {
    console.error('Invalid chain selection');
    process.exit(1);
  }
  
  const selectedChain = chains[chainIndex];
  
  // Validate that RPC URL was properly resolved
  if (selectedChain.rpc.includes('__') || selectedChain.rpc.includes('_RPC_')) {
    console.error(`\nError: RPC URL for ${selectedChain.description} was not resolved.`);
    console.error(`Current RPC: ${selectedChain.rpc}`);
    console.error('Please check your environment variables.');
    process.exit(1);
  }
  
  return selectedChain;
}

async function main() {
  const chains = loadConfig();

  const sourceChain = selectChain(chains, 'source');
  const targetChain = selectChain(chains, 'target');

  console.log(`\nSource Chain: ${sourceChain.description} (${sourceChain.rpc})`);
  console.log(`Target Chain: ${targetChain.description} (${targetChain.rpc})`);

  const sourceProvider = new ethers.JsonRpcProvider(sourceChain.rpc);
  const targetProvider = new ethers.JsonRpcProvider(targetChain.rpc);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, sourceProvider);

  const senderJson = JSON.parse(
    fs.readFileSync(
      path.resolve(
        __dirname,
        '../out/CrossChainTokenSender.sol/CrossChainTokenSender.json'
      ),
      'utf8'
    )
  );

  const abi = senderJson.abi;
  const bytecode = senderJson.bytecode;

  const CrossChainSenderFactory = new ethers.ContractFactory(
    abi,
    bytecode,
    wallet
  );

  try {
    console.log('\nDeploying CrossChainSender...');
    const senderContract = await CrossChainSenderFactory.deploy(
      sourceChain.wormholeRelayer,
      sourceChain.tokenBridge,
      sourceChain.wormhole
    );
    await senderContract.waitForDeployment();

    // Safely access the deployed contract's address
    const senderAddress = (senderContract as ethers.Contract).target;
    console.log(
      `CrossChainSender on ${sourceChain.description}: ${senderAddress}`
    );

    const targetWallet = new ethers.Wallet(
      process.env.PRIVATE_KEY!,
      targetProvider
    );
    const receiverJson = JSON.parse(
      fs.readFileSync(
        path.resolve(
          __dirname,
          '../out/CrossChainTokenReceiver.sol/CrossChainTokenReceiver.json'
        ),
        'utf8'
      )
    );
    const CrossChainReceiverFactory = new ethers.ContractFactory(
      receiverJson.abi,
      receiverJson.bytecode,
      targetWallet
    );

    console.log('Deploying CrossChainReceiver...');
    const receiverContract = await CrossChainReceiverFactory.deploy(
      targetChain.wormholeRelayer,
      targetChain.tokenBridge,
      targetChain.wormhole
    );
    await receiverContract.waitForDeployment();

    // Safely access the deployed contract's address
    const receiverAddress = (receiverContract as ethers.Contract).target;
    console.log(
      `CrossChainReceiver on ${targetChain.description}: ${receiverAddress}`
    );

    // Register the sender contract in the receiver contract
    console.log(
      `\nRegistering CrossChainSender (${senderAddress}) as a valid sender in CrossChainReceiver (${receiverAddress})...`
    );

    const CrossChainReceiverContract = new ethers.Contract(
      receiverAddress,
      receiverJson.abi,
      targetWallet
    );

    const tx = await CrossChainReceiverContract.setRegisteredSender(
      sourceChain.chainId,
      ethers.zeroPadValue(senderAddress as BytesLike, 32)
    );

    await tx.wait();
    console.log(
      `CrossChainSender registered as a valid sender on ${targetChain.description}`
    );

    // Load existing deployed contract addresses from contracts.json
    const deployedContractsPath = path.resolve(
      __dirname,
      '../deploy-config/contracts.json'
    );
    let deployedContracts: DeployedContracts = {};

    if (fs.existsSync(deployedContractsPath)) {
      deployedContracts = JSON.parse(
        fs.readFileSync(deployedContractsPath, 'utf8')
      );
    }

    // Update the contracts.json file:
    // If a contract already exists on a chain, update its address; otherwise, add a new entry.
    if (!deployedContracts[sourceChain.chainId]) {
      deployedContracts[sourceChain.chainId] = {
        networkName: sourceChain.description,
        deployedAt: new Date().toISOString(),
      };
    }
    deployedContracts[sourceChain.chainId].CrossChainSender =
      senderAddress.toString();
    deployedContracts[sourceChain.chainId].deployedAt =
      new Date().toISOString();

    if (!deployedContracts[targetChain.chainId]) {
      deployedContracts[targetChain.chainId] = {
        networkName: targetChain.description,
        deployedAt: new Date().toISOString(),
      };
    }
    deployedContracts[targetChain.chainId].CrossChainReceiver =
      receiverAddress.toString();
    deployedContracts[targetChain.chainId].deployedAt =
      new Date().toISOString();

    // Save the updated contracts.json file
    fs.writeFileSync(
      deployedContractsPath,
      JSON.stringify(deployedContracts, null, 2)
    );
    
    console.log('\nDeployment completed successfully!');
    console.log(`Contracts saved to: ${deployedContractsPath}`);
  } catch (error: any) {
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error(
        'Error: Insufficient funds for deployment. Please make sure your wallet has enough funds to cover the gas fees.'
      );
    } else if (error.code === 'NETWORK_ERROR') {
      console.error(
        'Error: Network connection failed. Please check your RPC URLs and internet connection.'
      );
    } else {
      console.error('An unexpected error occurred:', error.message);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});