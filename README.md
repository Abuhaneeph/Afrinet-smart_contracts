# Afrinet 🌍

> **The First Global Cross-Chain DEX for African Stablecoins** - Built on Mantle Sepolia Network with Wormhole Protocol Integration

Afrinet is a comprehensive decentralized finance (DeFi) ecosystem that bridges African and international financial markets through innovative blockchain solutions. Our platform enables seamless cross-border transactions, cross-chain asset swaps, traditional savings groups, and real-world utility payments using African and international stablecoins across multiple blockchain networks.

## 🌟 Platform Overview

Afrinet is the **first decentralized exchange (DEX) built on the Mantle Sepolia Network** that enables **global cross-chain access** to African and international stablecoins. We're revolutionizing how people interact with African currencies by providing:

- 🔄 **Cross-Border Stablecoin Swapping** - Direct swaps between African stablecoins (cNGN, cZAR, cKES, AFX) and international tokens (USDT, WETH, MNT, DAI)
- 🌐 **Cross-Chain Interoperability** - Seamlessly swap and provide liquidity across different EVM-compatible blockchains using Wormhole Protocol
- 💰 **AFX Stablecoin** - Our native Naira-pegged stablecoin for swaps, savings, and payments
- 🏦 **Digital Savings Groups** - On-chain rotational savings (Ajo/Esusu/Stokvel) with smart contract automation
- 📱 **Utility Payments** - Pay bills, airtime, and utilities using stablecoins
- 🔁 **On-Ramp/Off-Ramp** - Bank and mobile money integrations for NGN/cNGN, KES/cKES, and NGN/AFX

---

## 🎯 Problem Statement

Despite the rise of stablecoins in Africa and globally, critical gaps persist:

- ❌ **Isolated Local Stablecoins** - Low liquidity and limited global exchange support
- 🌍 **Expensive Cross-Border Remittances** - High fees, long wait times, centralized systems, and lack of direct cross-chain asset transfer
- 🔗 **No Global African Stablecoin DEX** - Users can't trade cNGN or cZAR with global tokens across different blockchain networks
- 🧱 **Informal Savings Groups** - Lack transparency, automation, and security
- 💳 **Limited Crypto Utility Payments** - Especially for local bills and services
- ⛓️ **Blockchain Fragmentation** - African stablecoins trapped on specific chains without interoperability

---

## ✨ Our Solution & Uniqueness

### 🔄 **AfriSwap - Enhanced Token Exchange Engine with Cross-Chain Capabilities**
**The core DEX functionality enabling both same-chain and cross-chain stablecoin access**

AfriSwap has been enhanced with comprehensive cross-chain functionality, offering users both traditional same-chain swaps and revolutionary cross-chain asset transfers powered by Wormhole Protocol.

#### 🏆 **Regular Swapping (Same-Chain) - Currently Live & Frontend Ready** ✅
Our core swapping functionality is fully operational with complete frontend integration:

**Live Features:**
- **Multi-Token Support**: Native ↔ ERC20 and ERC20 ↔ ERC20 swaps ✅ *Live & Frontend Ready*
- **African Stablecoin Focus**: cNGN, cZAR, cKES, cGHS integrated with USDT, WETH, MNT, DAI ✅ *Live & Frontend Ready*
- **Competitive Fees**: 0.20% swap fee (20 basis points) for same-chain operations ✅ *Live & Frontend Ready*
- **Liquidity Incentives**: 80% of fees distributed to liquidity providers ✅ *Live & Frontend Ready*
- **Real-time Price Discovery**: Integrated price feeds for accurate swap rates ✅ *Live & Frontend Ready*
- **Mantle-Optimized**: Built specifically for Mantle Sepolia Network infrastructure ✅ *Live & Frontend Ready*

**Currently Live Same-Chain Operations:**
```solidity
// ✅ Frontend Ready - Users can access these via web interface
function swap(address tokenIn, address tokenOut, uint256 amountIn) // Direct token swaps ✅
function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) // Add liquidity ✅
function removeLiquidity(address tokenA, address tokenB, uint256 liquidity) // Remove liquidity ✅
function claimRewards() // Withdraw earned rewards from liquidity provision ✅
```

#### 🌐 **Cross-Chain Swapping - Smart Contract Ready, Frontend Integration Pending** ⚠️
Revolutionary cross-chain swap functionality has been implemented at the smart contract level with Wormhole Protocol integration:

**Smart Contract Complete Features:**
- **Cross-Chain Token Swaps**: Swap tokens from one blockchain to receive different tokens on another chain ⚠️ *Smart Contract Ready*
- **Wormhole Integration**: Secure cross-chain messaging and token transfers ⚠️ *Smart Contract Ready*
- **Multi-Chain Asset Support**: Token mapping and routing across supported networks ⚠️ *Smart Contract Ready*
- **Enhanced Fee Structure**: 0.05% additional fee for cross-chain operations ⚠️ *Smart Contract Ready*
- **Cross-Chain Cost Estimation**: Built-in functions to calculate cross-chain operation costs ⚠️ *Smart Contract Ready*
- **Slippage Protection**: Minimum output amount validation for cross-chain swaps ⚠️ *Smart Contract Ready*

**Cross-Chain Swap Functions (Smart Contract Level - Complete):**
```solidity
// ⚠️ Smart Contract Ready - Frontend integration in development
function crossChainSwap(CrossChainSwapParams memory params) payable // Execute cross-chain swaps ⚠️
function quoteCrossChainSwap(uint16 targetChain) view returns (uint256) // Get cross-chain costs ⚠️
function estimateCrossChainSwap(CrossChainSwapParams memory params) view returns (uint256) // Estimate outputs ⚠️
function addSupportedChain(uint16 chainId, bytes32 targetAddress) // Add chain support ⚠️
function setWrappedToken(address sourceToken, uint16 targetChain, address targetToken) // Map tokens ⚠️
```

**Cross-Chain Swap Parameters:**
```solidity
struct CrossChainSwapParams {
    uint16 targetChain;        // Destination blockchain ID
    address tokenIn;           // Source token to swap
    address tokenOut;          // Desired output token (on source chain for bridging)
    uint256 amountIn;          // Amount to swap
    address recipient;         // Recipient address on target chain
    uint256 minAmountOut;      // Minimum acceptable output (slippage protection)
}
```

#### Current Fee Structure:

**Live Same-Chain Operations (Frontend Ready):**
- **Swap Fee**: 0.20% per transaction ✅ *Live & Frontend Ready*
- **Provider Rewards**: 80% of collected fees ✅ *Live & Frontend Ready*
- **Platform Revenue**: 17% of collected fees ✅ *Live & Frontend Ready*
- **Burn Mechanism**: 3% of collected fees (deflationary) ✅ *Live & Frontend Ready*

**Cross-Chain Operations (Smart Contract Ready, Frontend Pending):**
- **Base Swap Fee**: 0.20% (same as regular swaps) ⚠️ *Smart Contract Ready*
- **Cross-Chain Fee**: Additional 0.05% for cross-chain complexity ⚠️ *Smart Contract Ready*
- **Wormhole Network Fee**: Variable based on destination chain and message size ⚠️ *Smart Contract Ready*
- **Fee Distribution**: Same model as regular swaps (80% to LPs, 17% platform, 3% burn) ⚠️ *Smart Contract Ready*

### 🌐 **Cross-Chain Interoperability with Wormhole Protocol** ⚠️ *Smart Contract Ready, Frontend Integration Pending*
**Next-generation cross-chain functionality for true global stablecoin access**

Afrinet has implemented comprehensive Wormhole Protocol integration to enable secure and reliable cross-chain token transfers and messaging. The core smart contract functionality has been developed and is ready for integration, but frontend implementation is planned for the next development phase.

#### Core Cross-Chain Features (Smart Contract Level - Complete):

**🔄 Cross-Chain Token Transfers** - *Contract Complete, Frontend Pending*
- Smart contract ready for token transfers from one supported chain to another
- Wormhole relayer integration implemented for secure cross-chain operations
- Backend infrastructure complete for cross-border asset exchange
- Frontend integration planned for next development phase

**📨 Cross-Chain Messaging** - *Contract Complete, Frontend Pending*
- Smart contract framework for sending arbitrary messages along with token transfers
- Backend logic implemented for cross-chain communication
- Message verification and processing infrastructure ready
- User interface development in progress

**📡 Secure Message Handling** - *Fully Implemented*
- Contract successfully receives and processes cross-chain messages via Wormhole
- Security validation for all cross-chain operations implemented
- Automatic handling of failed transactions with retry mechanisms
- Production-ready backend infrastructure

**🗺️ Multi-Chain Asset Support** - *Backend Complete*
- Token mapping between different chains functional
- Asset recognition and routing logic complete
- Multi-chain deployment scripts ready
- Administrative dashboard pending frontend development

**💎 Configurable Cross-Chain Economics** - *Smart Contract Ready*
- Backend logic implemented for cross-chain transfer fees
- Sustainable cross-chain functionality with transparent fee structure
- Fee optimization algorithms based on network conditions
- Revenue sharing model for cross-chain operations implemented
- Frontend fee display and user controls in development

### 💰 **AFX Stablecoin - Naira-Pegged Stability**
**Our native hybrid-collateralized stablecoin maintaining 1:1 peg with Nigerian Naira (Currently Live)**

#### Core Features:
- **Dual Collateral System**: Backed by both fiat reserves (NGN) and approved crypto assets ✅ *Live*
- **Dynamic Collateral Ratios**: Automatic adjustment based on market conditions ✅ *Live*
- **Integrated Price Oracle**: Real-time price feeds for accurate valuation ✅ *Live*
- **Over-Collateralization**: Crypto-backed positions require over-collateralization ✅ *Live*
- **Emergency Liquidation**: Automated liquidation for unsafe positions ✅ *Live*
- **Automated Rebalancing**: Protocol maintains optimal fiat/crypto backing ratios ✅ *Live*

#### Minting Options:
```solidity
// Currently Live Functions
function mintWithFiat() // Mint AFX using NGN reserves ✅
function depositFiatAndMint() // Add fiat and mint in one transaction ✅
function depositAndMint() // Deposit crypto collateral and mint AFX ✅
function burnAndWithdraw() // Burn AFX and withdraw collateral ✅
```

#### Security Features:
- **Role-Based Access**: Minters, burners, oracles, liquidators, fiat depositors
- **Blacklisting Capability**: Compliance and security controls across all chains
- **Emergency Controls**: Pausable contract with emergency withdrawal
- **Liquidation Protection**: Automated liquidation of unsafe positions

### 🏦 **AjoEsusu Savings - Digital Rotating Savings Groups**
**Traditional African savings systems powered by smart contracts (Currently Live)**

#### Revolutionary Features:
- **Agent-Based System**: Trusted community members manage savings groups ✅ *Live*
- **Multi-Token Support**: Compatible with cNGN, cZAR, cGHS, cKES, USDT, WETH, AFX ✅ *Live*
- **Automated Payouts**: Smart contract handles calculations and distributions ✅ *Live*
- **Reputation System**: Performance-based scoring for agents and members ✅ *Live*
- **Invite Code Security**: Secure group joining through agent-generated codes ✅ *Live*
- **Flexible Schedules**: Customizable contribution frequencies ✅ *Live*
- **Default Protection**: Automatic detection and handling of member defaults ✅ *Live*
- **Frontend Ready**: Comprehensive view functions for easy integration with web interfaces ✅ *Live*

#### Core Functionality:
```solidity
// Currently Live Functions
function registerUser(string memory _name) ✅
function registerAsAjoAgent(string memory _name, string memory _contactInfo) ✅
function createGroup(...) // Agents create savings groups ✅
function createCrossChainGroup(...) // Framework ready for groups accepting multi-chain contributions ⚠️
function joinGroupWithCode(uint256 _groupId, string memory _inviteCode) ✅
function generateInviteCode(uint256 _groupId, uint256 _maxUses, uint256 _validityDays) ✅
```

#### Advanced Group Features:
- **Flexible Group Sizes**: 2-20 members (configurable) ✅ *Live*
- **Customizable Schedules**: Minutes to months (demo-friendly) ✅ *Live*
- **Multiple Currencies**: Support for 8+ African and international tokens ✅ *Live*
- **Automated Management**: Smart contract handles rotation and payments ✅ *Live*
- **Reputation Tracking**: Built-in scoring system for members and agents ✅ *Live*
- **Emergency Controls**: Pause functionality and emergency withdrawals ✅ *Live*

---

## 🚀 Technical Architecture

### Deployment Networks
- **Primary Network**: Mantle Sepolia (Testnet) ✅ *Currently Live*
- **Cross-Chain Support**: Smart contracts ready for Ethereum Sepolia, Binance Smart Chain Testnet, Polygon Mumbai ⚠️ *Smart Contract Ready*
- **Production Ready**: Mantle Mainnet with multi-chain expansion planned 📅 *Roadmap*
- **Oracle Strategy**: Manual price management with oracle-ready architecture ✅ *Live*
- **Wormhole Integration**: Smart contracts with full Wormhole Protocol implementation ⚠️ *Backend Complete*

### Project Structure
```
├── src/                  # Solidity contracts
│   ├── CrossChainMessageReceiver.sol
│   ├── CrossChainMessageSender.sol
│   ├── CrossChainTokenReceiver.sol
│   ├── CrossChainTokenSender.sol
│   └── main/             # Core DeFi and utility modules
│       ├── core/         # Core swap and savings logic
│       │   ├── Swap.sol  # Enhanced with cross-chain capabilities
│       │   └── Savings.sol
│       ├── feeds/        # Price feed mocks and test feeds
│       │   ├── MockV3Aggregator.sol
│       │   └── TestPriceFeed.sol
│       ├── interfaces/   # Core interfaces
│       │   ├── AggregatorV3Interface.sol
│       │   ├── IPriceFeed.sol
│       │   └── xIERC20.sol
│       ├── libraries/    # Shared libraries
│       │   └── Events.sol
│       ├── stablecoin/   # Stablecoin implementation
│       │   └── AfriStable.sol
│       └── tokens/       # Example/test tokens
│           └── TestToken.sol
├── script/               # TypeScript deployment and interaction scripts
│   ├── cross-chain-transfer.ts
│   ├── deployCrossChainContracts.ts
│   ├── deployReceiver.ts
│   ├── deploySender.ts
│   └── sendMessage.ts
├── test/                 # Solidity tests (Forge)
│   ├── CrossChainMessagingTest.sol
│   └── CrossChainTokenTest.sol
├── lib/                  # External libraries (forge-std, openzeppelin, wormhole-solidity-sdk)
├── deploy-config/        # Deployment configuration files
├── package.json          # Node.js dependencies and scripts
├── tsconfig.json         # TypeScript configuration
└── README.md             # Project documentation
```

### Enhanced Smart Contract Stack
```solidity
// Core Contracts (core/)
- Savings.sol                    // Rotating savings groups with cross-chain support
- Swap.sol                      // Enhanced DEX contract with Wormhole cross-chain integration

// Cross-Chain Contracts
- CrossChainTokenSender.sol     // Handles sending tokens and messages to another chain
- CrossChainTokenReceiver.sol   // Handles receiving tokens and messages from another chain
- CrossChainMessageSender.sol   // For message-only cross-chain communication
- CrossChainMessageReceiver.sol // For receiving cross-chain messages

// Stablecoin Module (stablecoin/)
- AfriStable.sol                // AFX stablecoin protocol with cross-chain features

// Token Contracts (tokens/)
- TestToken.sol                 // Supported ERC20 tokens

// Supporting Infrastructure (feeds/)
- MockV3Aggregator.sol          // Chainlink Aggregator
- TestPriceFeed.sol            // Price oracle system

// Wormhole Integration (external imports)
- IWormholeRelayer.sol         // Wormhole relayer interface
- ITokenBridge.sol             // Token bridge interface
- IWormhole.sol                // Core Wormhole interface
```

### Cross-Chain Architecture Components

**🌐 Chain Registry System**
```solidity
struct SupportedChain {
    uint16 chainId;
    address wormholeRelayer;
    address tokenBridge;
    bytes32 targetAddress;
    bool isActive;
    uint256 minConfirmations;
}
```

**📡 Message Protocol**
```solidity
struct CrossChainMessage {
    MessageType msgType; // TOKEN_TRANSFER, MESSAGE_ONLY, TOKEN_WITH_MESSAGE
    address sender;
    address token;
    uint256 amount;
    address recipient;
    bytes payload;
    uint32 nonce;
}
```

**🔒 Security Framework**
- **Wormhole Validation**: All cross-chain messages validated through Wormhole protocol
- **Slippage Protection**: Automatic handling of cross-chain slippage protection  
- **Failed Transaction Recovery**: Robust handling of failed cross-chain operations
- **Emergency Circuit Breakers**: Cross-chain operation pausing in emergency situations

### Oracle Infrastructure
**Multi-Chain Price Management**

Enhanced oracle system supporting cross-chain price coordination:
- **Current**: Manual price management by authorized oracles across all chains
- **Cross-Chain Sync**: Price synchronization across supported networks
- **Future-Ready**: Seamless integration when Chainlink becomes available on all networks
- **No Redeployment**: Toggle between manual and oracle pricing per chain
- **Hybrid Support**: Multiple price source options with cross-chain validation

```solidity
// Enhanced Oracle Management
function togglePriceSource(uint16 chainId, address _tokenAddress, bool _useOracle)
function setCrossChainAggregator(uint16 chainId, address _tokenAddress, address _aggregatorAddress) 
function updateCrossChainPrice(uint16 chainId, address _tokenAddress, int256 _newPrice)
function syncPricesAcrossChains(address _tokenAddress) // Synchronize prices across all supported chains
```

### 🛠️ **For Developers: Direct Smart Contract Interaction**

While frontend integration for cross-chain features is in development, developers can interact directly with the enhanced swap contract:

```javascript
// Example: Cross-chain swap using ethers.js
const swapContract = new ethers.Contract(swapAddress, abi, signer);

// Cross-Chain Swap Parameters
const crossChainParams = {
    targetChain: 2,           // Ethereum chain ID
    tokenIn: mantleNativeToken,
    tokenOut: mantleUSDC,
    amountIn: ethers.utils.parseEther("1"), // 1 MNT
    recipient: userAddress,
    minAmountOut: ethers.utils.parseUnits("950", 6) // Minimum 950 USDC
};

// Get cross-chain cost estimate
const crossChainCost = await swapContract.quoteCrossChainSwap(2);

// Execute cross-chain swap
await swapContract.crossChainSwap(crossChainParams, {
    value: ethers.utils.parseEther("1").add(crossChainCost)
});

// Estimate cross-chain swap output
const estimatedOutput = await swapContract.estimateCrossChainSwap(crossChainParams);

// Regular same-chain swap (Frontend Ready)
await swapContract.swap(tokenIn, tokenOut, amountIn);
```

**Available Cross-Chain Swap Functions:**
- `crossChainSwap()` - Execute cross-chain token swaps ⚠️ *Smart Contract Ready*
- `quoteCrossChainSwap()` - Get cost estimates for cross-chain operations ⚠️ *Smart Contract Ready*
- `estimateCrossChainSwap()` - Estimate output amounts for cross-chain swaps ⚠️ *Smart Contract Ready*
- `addSupportedChain()` - Add support for new blockchain networks ⚠️ *Smart Contract Ready*
- `setWrappedToken()` - Map tokens across different chains ⚠️ *Smart Contract Ready*

**Available Same-Chain Swap Functions (Frontend Ready):**
- `swap()` - Execute same-chain token swaps ✅ *Live & Frontend Ready*
- `addLiquidity()` - Add liquidity to trading pairs ✅ *Live & Frontend Ready*
- `removeLiquidity()` - Remove liquidity from trading pairs ✅ *Live & Frontend Ready*
- `claimRewards()` - Claim liquidity provider rewards ✅ *Live & Frontend Ready*

---

## 🔗 Cross-Chain Development Status & Roadmap

### ✅ **Phase 1: Core Platform (COMPLETED)**
- AfriSwap DEX with same-chain swapping ✅ *Live & Frontend Ready*
- AFX Stablecoin with dual collateral system ✅ *Live & Frontend Ready*
- AjoEsusu Digital Savings Groups ✅ *Live & Frontend Ready*
- Multi-token support (8 tokens) ✅ *Live & Frontend Ready*
- Liquidity provision and rewards ✅ *Live & Frontend Ready*
- Frontend web application ✅ *Live & Frontend Ready*

### ⚠️ **Phase 2: Cross-Chain Infrastructure (IN PROGRESS)**
**Smart Contract Development: ✅ COMPLETED**
- Enhanced Swap contract with cross-chain capabilities implemented
- Wormhole Protocol integration implemented
- Cross-chain token swap functionality ready
- Cross-chain messaging system complete
- Multi-chain asset mapping system
- Security validation and error handling
- Administrative functions for chain management

**Frontend Integration: 🚧 IN DEVELOPMENT**
- Cross-chain swap UI (pending)
- Cross-chain transfer interface (pending)
- Multi-chain wallet connection
- Cross-chain transaction tracking
- Chain selection and token mapping
- Fee estimation and display
- Transaction status monitoring

### 📅 **Phase 3: Multi-Chain Expansion (PLANNED)**
- Deploy enhanced swap contract on Mantle Mainnet 
- Deploy on Ethereum Mainnet
- Binance Smart Chain integration
- Polygon network support
- Additional African stablecoin support
- Cross-chain arbitrage opportunities
- Advanced cross-chain analytics

### 🎯 **Current Status Summary**
**✅ Ready for Users:**
- Same-chain token swapping with full frontend support
- Liquidity provision and rewards
- AFX stablecoin minting and management
- Digital savings groups (AjoEsusu)

**⚠️ Ready for Developers (Smart Contract Level):**
- Cross-chain token swaps via direct contract interaction
- Cross-chain messaging and token transfers
- Multi-chain asset support and token mapping
- Cross-chain fee estimation and cost calculation

**🚧 In Development:**
- Frontend UI for cross-chain operations
- User-friendly cross-chain swap interface
- Cross-chain transaction monitoring and status tracking

### 🎯 **Current Limitations**
- Cross-chain swap features available via smart contract interaction only
- No frontend UI for cross-chain operations yet
- Limited to Mantle Sepolia testnet for now
- Manual testing required for cross-chain functions
- Documentation for direct contract interaction available

---

## Prerequisites
- [Node.js](https://nodejs.org/) (for scripts)
- [Foundry](https://book.getfoundry.sh/) (for Solidity development and testing)
- [TypeScript](https://www.typescriptlang.org/)

## Installation
1. Clone the repository:
   ```sh
   git clone <repo-url>
   cd afrinet-wormhole-messaging
   ```
2. Install Node.js dependencies:
   ```sh
   npm install
   ```
3. Install Foundry (if not already installed):
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

## Usage
### Running Tests
Run all Solidity tests using Foundry:
```sh
forge test
```

### Deploying Contracts
Use the provided TypeScript scripts in the `script/` directory to deploy contracts or the npm scripts:

#### Using npm scripts:
```sh
# Deploy all cross-chain contracts
npm run deploy:cross-chain-contracts

# Deploy sender contract only
npm run deploy:sender

# Deploy receiver contract only
npm run deploy:receiver

# Send cross-chain message
npm run send:message
```

#### Direct script execution:
```sh
npx ts-node script/deployCrossChainContracts.ts
```

### Cross-Chain Token Transfer
1. Deploy sender and receiver contracts on source and target chains.
2. Use the `cross-chain-transfer.ts` script to initiate a token transfer.

### Configuration
- Update `deploy-config/chains.json` and `deploy-config/contracts.json` with your chain and contract addresses as needed.

## Contracts Overview
- **CrossChainTokenSender.sol**: Handles sending tokens and messages to another chain.
- **CrossChainTokenReceiver.sol**: Handles receiving tokens and messages from another chain.
- **CrossChainMessageSender/Receiver.sol**: For message-only cross-chain communication.

### Core DeFi and Utility Modules (in `src/main/`)
- **core/Swap.sol**: Enhanced core swap logic with cross-chain capabilities for token exchanges.
- **core/Savings.sol**: Digital savings groups contract for DeFi operations.
- **feeds/MockV3Aggregator.sol, TestPriceFeed.sol**: Mock and test price feeds for development/testing.
- **interfaces/AggregatorV3Interface.sol, IPriceFeed.sol, xIERC20.sol**: Interfaces for price feeds and ERC20 extensions.
- **libraries/Events.sol**: Shared event definitions and utilities.
- **stablecoin/AfriStable.sol**: AFX stablecoin implementation.
- **tokens/TestToken.sol**: Example/test ERC20 token.

## Testing
- Mock contracts are provided for ERC20, Wormhole relayer, and token bridge to enable local testing without real cross-chain infrastructure.
- See `test/CrossChainTokenTest.sol` for example test cases.

## License
This project is licensed under the MIT License.