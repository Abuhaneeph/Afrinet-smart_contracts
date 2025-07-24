// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Events} from "../libraries/Events.sol";
import {xIERC20} from "../interfaces/xIERC20.sol";
import {TestPriceFeed} from "../feeds/TestPriceFeed.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "lib/wormhole-solidity-sdk/src/interfaces/IERC20.sol";

/**
 * @title AfriCoin Cross-Chain Swap Contract
 * @dev Decentralized exchange contract with cross-chain swapping capabilities using Wormhole
 * @notice This contract allows users to swap tokens locally and across different chains
 * @author AfriCoin Team
 */
contract CrossChainSwap is Ownable, TokenSender, TokenReceiver {
    
    // ============ CROSS-CHAIN CONSTANTS ============
    uint256 constant GAS_LIMIT = 250_000;
    
    // ============ EVENTS ============
    
    /**
     * @dev Emitted when the contract receives native MNT tokens
     * @param sender Address that sent the MNT
     * @param amount Amount of MNT received in wei
     */
    event Received(address sender, uint amount);
    
    /**
     * @dev Emitted when a cross-chain swap is initiated
     */
    event CrossChainSwapInitiated(
        address indexed user,
        uint16 targetChain,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 expectedAmountOut
    );
    
    /**
     * @dev Emitted when a cross-chain swap is completed
     */
    event CrossChainSwapCompleted(
        address indexed recipient,
        address tokenReceived,
        uint256 amountReceived
    );

    // ============ RECEIVE FUNCTION ============
    
    /**
     * @dev Allows contract to receive native MNT tokens
     * @notice Automatically called when MNT is sent to the contract
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    // ============ STATE VARIABLES ============
    
    /// @dev Price feed oracle contract for token price calculations
    TestPriceFeed private priceAPI;
    
    /// @dev Platform accumulated profits in AfriCoin tokens
    uint256 private _platformProfit;
    
    /// @dev Accumulated fees designated for burning
    uint256 private _burnableFees;

    /// @dev Swap fee percentage (0.02% = 20 basis points)
    uint private swapFee = 20;
    
    /// @dev Cross-chain swap fee (additional fee for cross-chain operations)
    uint private crossChainFee = 50; // 0.05%

    /// @dev Unique identifier counter for pools
    uint256 private POOL_ID;
    
    /// @dev Unique identifier counter for liquidity positions
    uint256 private LIQUID_ID;
    
    /// @dev Unique identifier counter for providers
    uint256 private PROVIDER_ID;

    /// @dev Address of the AfriCoin token contract
    address public AFRI_COIN;
    
    // ============ CROSS-CHAIN MAPPINGS ============
    
    /// @dev Maps chain ID to supported status
    mapping(uint16 => bool) public supportedChains;
    
    /// @dev Maps chain ID to target receiver contract address
    mapping(uint16 => address) public targetReceivers;
    
    /// @dev Maps token address to chain ID to wrapped token address
    mapping(address => mapping(uint16 => address)) public wrappedTokens;
 
    // ============ EXISTING MAPPINGS ============
    
    /// @dev Maps pool ID to Pool struct
    mapping(uint => Pool) public pools;
    
    /// @dev Maps provider address to Provider struct
    mapping(address => Provider) public providers;
    
    /// @dev Maps liquid ID to Liquid struct
    mapping(uint => Liquid) public liquids;

    // ============ STRUCTS ============

    /**
     * @dev Represents a liquidity pool containing two tokens
     */
    struct Pool {
        uint id;
        address token0;
        address token1;
        uint[] liquids;
    }

    /**
     * @dev Represents a liquidity position provided by a user
     */
    struct Liquid {
        uint id;
        uint poolId;
        uint256 amount0;
        uint256 amount1;
        address provider;
    }

    /**
     * @dev Represents a liquidity provider's profile
     */
    struct Provider {
        uint id;
        uint256 totalEarned;
        uint256 balance;
        bool autoStake;
        uint[] liquids;
    }
    
    /**
     * @dev Represents a cross-chain swap request
     */
    struct CrossChainSwapParams {
        uint16 targetChain;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 minAmountOut;
    }

    // ============ CONSTRUCTOR ============

    /**
     * @dev Initializes the cross-chain swap contract
     * @param _priceAPI Address of the price feed oracle contract
     * @param _AFRI_COIN Address of the AfriCoin token contract
     * @param _wormholeRelayer Address of the Wormhole relayer
     * @param _tokenBridge Address of the Wormhole token bridge
     * @param _wormhole Address of the Wormhole core contract
     */
    constructor(
        address _priceAPI,
        address _AFRI_COIN,
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) 
        Ownable(msg.sender) 
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) 
    {
        // Initialize the price feed oracle
        priceAPI = TestPriceFeed(_priceAPI);

        // Set the AfriCoin token address
        AFRI_COIN = _AFRI_COIN;

        // Create initial pool for MNT/AfriCoin pair
        _createPool(priceAPI.getNativeToken(), _AFRI_COIN);
    }

    // ============ CROSS-CHAIN ADMIN FUNCTIONS ============

    /**
     * @dev Adds support for a new chain (owner only)
     * @param chainId Wormhole chain ID
     * @param targetReceiver Address of the receiver contract on target chain
     */
    function addSupportedChain(uint16 chainId, address targetReceiver) external onlyOwner {
        supportedChains[chainId] = true;
        targetReceivers[chainId] = targetReceiver;
        setRegisteredSender(chainId, toWormholeFormat(targetReceiver));
    }

    /**
     * @dev Removes support for a chain (owner only)
     * @param chainId Wormhole chain ID to remove
     */
    function removeSupportedChain(uint16 chainId) external onlyOwner {
        supportedChains[chainId] = false;
        delete targetReceivers[chainId];
    }

    /**
     * @dev Maps a token to its wrapped version on another chain
     * @param localToken Address of token on current chain
     * @param targetChain ID of target chain
     * @param wrappedToken Address of wrapped token on target chain
     */
    function setWrappedToken(
        address localToken,
        uint16 targetChain,
        address wrappedToken
    ) external onlyOwner {
        wrappedTokens[localToken][targetChain] = wrappedToken;
    }

    /**
     * @dev Updates the cross-chain swap fee (owner only)
     * @param fee New cross-chain fee in basis points
     */
    function updateCrossChainFee(uint fee) external onlyOwner {
        require(fee < 1000, "Cross-chain fee cannot exceed 10%");
        crossChainFee = fee;
    }

    // ============ CROSS-CHAIN VIEW FUNCTIONS ============

    /**
     * @dev Gets the estimated cost for a cross-chain swap
     * @param targetChain ID of the target chain
     * @return cost Total cost in native tokens
     */
    function quoteCrossChainSwap(uint16 targetChain) public view returns (uint256 cost) {
        require(supportedChains[targetChain], "Chain not supported");
        
        uint256 deliveryCost;
        (deliveryCost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
        cost = deliveryCost + wormhole.messageFee();
    }

    /**
     * @dev Estimates output for cross-chain swap
     * @param params Cross-chain swap parameters
     * @return estimatedOutput Estimated amount of output tokens
     */
    function estimateCrossChainSwap(
        CrossChainSwapParams memory params
    ) public view returns (uint256 estimatedOutput) {
        require(supportedChains[params.targetChain], "Chain not supported");
        
        // Get wrapped token address on target chain
        address wrappedTokenOut = wrappedTokens[params.tokenOut][params.targetChain];
        require(wrappedTokenOut != address(0), "Token not supported on target chain");
        
        // Estimate local swap first, then account for cross-chain fees
        uint256 localEstimate = estimate(params.tokenIn, params.tokenOut, params.amountIn);
        uint256 crossChainFeeAmount = (localEstimate * crossChainFee) / 10000;
        
        estimatedOutput = localEstimate - crossChainFeeAmount;
    }

    // ============ CROSS-CHAIN SWAP FUNCTIONS ============

    /**
     * @dev Initiates a cross-chain token swap
     * @param params Cross-chain swap parameters
     */
    function crossChainSwap(CrossChainSwapParams memory params) external payable {
        require(supportedChains[params.targetChain], "Chain not supported");
        require(params.amountIn >= 100, "Amount too small");
        
        // Calculate cross-chain costs
        uint256 crossChainCost = quoteCrossChainSwap(params.targetChain);
        
        // Verify sufficient payment for cross-chain operation
        if (params.tokenIn == priceAPI.getNativeToken()) {
            require(msg.value >= params.amountIn + crossChainCost, "Insufficient payment");
        } else {
            require(msg.value >= crossChainCost, "Insufficient payment for cross-chain");
            // Transfer input tokens from user
            xIERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        }
        
        // Perform local swap first
        uint256 swappedAmount;
        if (params.tokenIn == priceAPI.getNativeToken()) {
            // For native token swaps, subtract cross-chain cost from swap amount
            swappedAmount = doSwap(
                params.tokenIn,
                params.tokenOut,
                params.amountIn,
                address(this)
            );
        } else {
            swappedAmount = doSwap(
                params.tokenIn,
                params.tokenOut,
                params.amountIn,
                address(this)
            );
        }
        
        // Apply cross-chain fee
        uint256 crossChainFeeAmount = (swappedAmount * crossChainFee) / 10000;
        uint256 finalAmount = swappedAmount - crossChainFeeAmount;
        
        // Add cross-chain fee to platform profit
        _platformProfit += estimate(params.tokenOut, AFRI_COIN, crossChainFeeAmount);
        
        // Verify minimum output
        require(finalAmount >= params.minAmountOut, "Insufficient output amount");
        
        // Get wrapped token address on target chain
        address wrappedTokenOut = wrappedTokens[params.tokenOut][params.targetChain];
        require(wrappedTokenOut != address(0), "Token not supported on target chain");
        
        // Prepare payload for cross-chain transfer
        bytes memory payload = abi.encode(params.recipient, wrappedTokenOut);
        
        // Send tokens across chains
        sendTokenWithPayloadToEvm(
            params.targetChain,
            targetReceivers[params.targetChain],
            payload,
            0,
            GAS_LIMIT,
            params.tokenOut,
            finalAmount
        );
        
        emit CrossChainSwapInitiated(
            msg.sender,
            params.targetChain,
            params.tokenIn,
            params.tokenOut,
            params.amountIn,
            finalAmount
        );
    }

    /**
     * @dev Receives cross-chain tokens and completes the swap
     * @param payload Encoded recipient and token information
     * @param receivedTokens Array of received tokens
     * @param sourceAddress Address of the sender on source chain
     * @param sourceChain ID of the source chain
     */
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // deliveryHash
    )
        internal
        override
        onlyWormholeRelayer
        isRegisteredSender(sourceChain, sourceAddress)
    {
        require(receivedTokens.length == 1, "Expected 1 token transfer");
        
        // Decode the recipient and target token from payload
        (address recipient, address targetToken) = abi.decode(payload, (address, address));
        
        // Transfer the received tokens to the intended recipient
        IERC20(receivedTokens[0].tokenAddress).transfer(
            recipient,
            receivedTokens[0].amount
        );
        
        emit CrossChainSwapCompleted(
            recipient,
            receivedTokens[0].tokenAddress,
            receivedTokens[0].amount
        );
    }

    // ============ EXISTING FUNCTIONS (keeping all original functionality) ============
    
    /**
     * @dev Returns the total liquidity size for a token pair
     */
    function getPoolSize(
        address token0,
        address token1
    ) public view returns (uint256, uint256) {
        uint poolId = _findPool(token0, token1);
        return _poolSize(poolId);
    }

    /**
     * @dev Estimates the output amount for a token swap
     */
    function estimate(
        address token0,
        address token1,
        uint256 amount0
    ) public view returns (uint256) {
        uint256 _rate = priceAPI.estimate(token0, token1, amount0);
        return _rate;
    }

    /**
     * @dev Returns the address of this contract
     */
    function getContractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @dev Finds a pool ID for a given token pair
     */
    function findPool(address token0, address token1) public view returns (uint256) {
        return _findPool(token0, token1);
    }

    /**
     * @dev Gets the liquid ID for a provider in a specific pool
     */
    function liquidIndex(uint256 pool_id) public view returns (uint256) {
        return _liquidIndex(pool_id, msg.sender);
    } 

    /**
     * @dev Gets Current Pool ID created
     */
    function getPoolId () public view returns (uint256) {
        return POOL_ID;
    }

    /**
     * @dev Returns the current burnable fees balance (owner only)
     */
    function getBurnableFeesBal() public view onlyOwner returns (uint256) {
        return _burnableFees;
    }

    // ============ PROVIDER FUNCTIONS ============

    /**
     * @dev Registers a new liquidity provider account
     */
    function unlockedProviderAccount() public onlyGuest {
        PROVIDER_ID++;

        providers[msg.sender] = Provider(
            PROVIDER_ID,
            providers[msg.sender].totalEarned,
            providers[msg.sender].balance,
            false,
            providers[msg.sender].liquids
        );
    }

    /**
     * @dev Updates provider's auto-staking preference
     */
    function updateProviderProfile(bool _autoStake) public onlyProvider {
        providers[msg.sender].autoStake = _autoStake;
    }

    /**
     * @dev Allows provider to withdraw their earned rewards
     */
    function withDrawEarnings(uint256 amount) public onlyProvider {
        require(
            providers[msg.sender].balance >= amount,
            "Insufficient Balance"
        );

        xIERC20(AFRI_COIN).transfer(msg.sender, amount);
        providers[msg.sender].balance -= amount;
    }

    // ============ SWAPPING FUNCTIONS ============

    /**
     * @dev Swaps tokens for the caller
     */
    function swap(
        address token0,
        address token1,
        uint256 amount0
    ) public payable returns (uint256) {
        return doSwap(token0, token1, amount0, msg.sender);
    }

    /**
     * @dev Performs token swap with detailed validation and fee handling
     */
    function doSwap(
        address token0,
        address token1,
        uint256 amount0,
        address user
    ) public payable returns (uint256) {
        require(amount0 >= 100, "Amount to swap cannot be lesser than 100 WEI");

        uint256 amount1;
        uint256 _safeAmount0 = amount0;

        uint poolId = _findPool(token0, token1);
        require(pools[poolId].id > 0, "Pool does not exists");

        // [Keep all existing swap logic exactly as it was]
        // Handle MNT => ERC20 swaps
        if (token0 == priceAPI.getNativeToken()) {
            require(msg.value >= 100, "Native Currency cannot be lesser than 100 WEI");
            
            _safeAmount0 = msg.value;
            amount1 = estimate(token0, token1, _safeAmount0);

            (, uint256 poolSizeToken1) = _poolSize(poolId);
            require(poolSizeToken1 >= amount1, "Insufficient Pool Size");

            uint256 fee = _transferSwappedTokens0(
                pools[poolId].token1,
                amount1,
                user
            );

            uint256 providersReward = ((fee * 80) / 100);
            uint256 burnFee = ((fee * 3) / 100);
            _burnableFees += burnFee;
            uint256 contractProfit = fee - providersReward - burnFee;
            _platformProfit += contractProfit;

            _aggregateLiquids(
                _safeAmount0,
                amount1,
                poolSizeToken1,
                pools[poolId],
                providersReward
            );
        }
        // Handle ERC20 => MNT swaps
        else if (token1 == priceAPI.getNativeToken()) {
            amount1 = estimate(token0, token1, _safeAmount0);

            (uint256 poolSizeToken1, ) = _poolSize(poolId);
            require(poolSizeToken1 >= amount1, "Insufficient Pool Size");

            uint256 fee = _transferSwappedTokens1(
                pools[poolId].token0,
                _safeAmount0,
                amount1,
                user
            );

            uint256 providersReward = ((fee * 80) / 100);
            uint256 burnFee = ((fee * 3) / 100);
            _burnableFees += burnFee;
            uint256 contractProfit = fee - providersReward - burnFee;
            _platformProfit += contractProfit;

            _aggregateLiquids(
                _safeAmount0,
                amount1,
                poolSizeToken1,
                pools[poolId],
                providersReward
            );
        }
        // Handle ERC20 => ERC20 swaps
        else {
            amount1 = estimate(token0, token1, _safeAmount0);
            
            uint256 poolSizeToken1;
            if (pools[poolId].token0 == token1) {
                (uint256 _poolSizeToken1, ) = _poolSize(poolId);
                poolSizeToken1 = _poolSizeToken1;
            } else if (pools[poolId].token1 == token1) {
                (, uint256 _poolSizeToken1) = _poolSize(poolId);
                poolSizeToken1 = _poolSizeToken1;
            }

            require(poolSizeToken1 >= amount1, "Insufficient Pool Size");

            uint256 fee = _transferSwappedTokens2(
                token0,
                token1,
                _safeAmount0,
                amount1,
                user
            );

            uint256 providersReward = ((fee * 80) / 100);
            uint256 burnFee = ((fee * 3) / 100);
            _burnableFees += burnFee;
            uint256 contractProfit = fee - providersReward - burnFee;
            _platformProfit += contractProfit;

            _aggregateLiquids(
                _safeAmount0,
                amount1,
                poolSizeToken1,
                pools[poolId],
                providersReward
            );
        }

        emit Events.FleepSwaped(
            amount0,
            amount1,
            token0,
            token1,
            block.timestamp
        );

        return amount1;
    }

    // ============ LIQUIDITY PROVIDER FUNCTIONS ============

    /**
     * @dev Provides liquidity to a specified pool
     */
    function provideLiquidity(
        uint poolId,
        uint256 amount0
    ) public payable {
        require(amount0 >= 100, "Amount cannot be lesser than 100 WEI");

        uint256 amount1;
        uint256 _safeAmount0 = amount0;

        if (providers[msg.sender].id == 0) {
            unlockedProviderAccount();
        }

        if (pools[poolId].token0 == priceAPI.getNativeToken()) {
            require(msg.value > 100, "MNT cannot be lesser than 100 WEI");
            
            _safeAmount0 = msg.value;
            amount1 = estimate(
                pools[poolId].token0,
                pools[poolId].token1,
                _safeAmount0
            );

            xIERC20(pools[poolId].token1).transferFrom(
                msg.sender,
                address(this),
                amount1
            );
        } else {
            amount1 = estimate(
                pools[poolId].token0,
                pools[poolId].token1,
                _safeAmount0
            );
            
            xIERC20(pools[poolId].token0).transferFrom(
                msg.sender,
                address(this),
                _safeAmount0
            );
            xIERC20(pools[poolId].token1).transferFrom(
                msg.sender,
                address(this),
                amount1
            );
        }

        uint liquidId = _liquidIndex(poolId, msg.sender);

        if (liquidId > 0) {
            liquids[liquidId].amount0 += _safeAmount0;
            liquids[liquidId].amount1 += amount1;
        } else {
            _createLiquid(poolId, _safeAmount0, amount1, msg.sender);
        }

        emit Events.LiquidProvided(
            pools[poolId].token0,
            pools[poolId].token1,
            _safeAmount0,
            amount1,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Removes liquidity from a pool and returns tokens to provider
     */
    function removeLiquidity(uint id) public onlyProvider {
        require(liquids[id].provider == msg.sender, "Unauthorized");
    
        uint poolId = liquids[id].poolId;
        Pool memory pool = pools[poolId];

        if (pools[poolId].token0 == priceAPI.getNativeToken()) {
            payable(msg.sender).transfer(liquids[id].amount0);
            xIERC20(pool.token1).transfer(msg.sender, liquids[id].amount1);
        } else {
            xIERC20(pool.token0).transfer(msg.sender, liquids[id].amount0);
            xIERC20(pool.token1).transfer(msg.sender, liquids[id].amount1);
        }

        for (uint index = 0; index < pools[poolId].liquids.length; index++) {
            if (liquids[pools[poolId].liquids[index]].provider == msg.sender) {
                delete pools[poolId].liquids[index];
            }
        }

        for (uint index = 0; index < providers[msg.sender].liquids.length; index++) {
            if (liquids[providers[msg.sender].liquids[index]].poolId == pool.id) {
                delete providers[msg.sender].liquids[index];
            }
        }

        delete liquids[id];
    }

    /**
     * @dev Returns all liquidity positions for a given wallet
     */
    function myLiquidities(
        address wallet
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory providerLiquids = providers[wallet].liquids;

        uint256[] memory _pools = new uint256[](providerLiquids.length);
        uint256[] memory _amounts0 = new uint256[](providerLiquids.length);
        uint256[] memory _amounts1 = new uint256[](providerLiquids.length);

        for (uint index; index < providerLiquids.length; index++) {
            _pools[index] = liquids[providerLiquids[index]].poolId;
            _amounts0[index] = liquids[providerLiquids[index]].amount0;
            _amounts1[index] = liquids[providerLiquids[index]].amount1;
        }

        return (_pools, _amounts0, _amounts1, providerLiquids);
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Creates a new trading pool for a token pair (owner only)
     */
    function createPool(
        address token0,
        address token1
    ) public onlyOwner returns (uint) {
        return _createPool(token0, token1);
    }

    /**
     * @dev Updates the swap fee percentage (owner only)
     */
    function updateSwapFee(uint fee) public onlyOwner {
        require(fee > 0, "Platform fee cannot be zero");
        require(fee < 1000, "Platform fee cannot be a hundred");
        swapFee = fee;
    }

    /**
     * @dev Withdraws platform earnings to specified address (owner only)
     */
    function withDrawPlaformEarnings(
        uint256 amount,
        address receiver
    ) public onlyOwner {
        require(_platformProfit >= amount, "Insufficient Balance");

        xIERC20(AFRI_COIN).transfer(receiver, amount);
        _platformProfit -= amount;
    }

    /**
     * @dev Burns accumulated fees by destroying AfriCoin tokens (owner only)
     */
    function burnFees() public onlyOwner {
        require(getBurnableFeesBal() > 0, "Insufficient Balance");
        
        xIERC20(AFRI_COIN).burn(_burnableFees);
        _burnableFees -= getBurnableFeesBal();
    }

    // ============ INTERNAL FUNCTIONS ============

    /**
     * @dev Finds the liquid ID for a provider in a specific pool
     */
    function _liquidIndex(
        uint poolId,
        address provider
    ) private view returns (uint) {
        uint256[] memory providerLiquids = providers[provider].liquids;

        for (uint index = 0; index < providerLiquids.length; index++) {
            if (liquids[providerLiquids[index]].poolId == poolId) {
                return providerLiquids[index];
            }
        }

        return 0;
    }

    /**
     * @dev Distributes swap impact and rewards across all liquidity providers
     */
    function _aggregateLiquids(
        uint256 amount0,
        uint256 amount1,
        uint256 poolSizeToken1,
        Pool memory pool,
        uint256 fee
    ) private {
        for (uint index = 0; index < pool.liquids.length; index++) {
            uint liquidId = pool.liquids[index];

            uint256 reward = ((liquids[liquidId].amount1 * fee) / poolSizeToken1);

            address provider = liquids[liquidId].provider;

            uint256 additionAmount = ((liquids[liquidId].amount1 * amount0) / poolSizeToken1);
            liquids[liquidId].amount0 += additionAmount;

            uint256 deductionAmount = ((liquids[liquidId].amount1 * amount1) / poolSizeToken1);
            liquids[liquidId].amount1 -= deductionAmount;

            providers[provider].totalEarned += reward;
            providers[provider].balance += reward;
        }
    }

    /**
     * @dev Handles MNT => ERC20 token transfers and fee calculation
     */
    function _transferSwappedTokens0(
        address token1,
        uint256 amount1,
        address owner
    ) private returns (uint256) {
        xIERC20 quoteToken = xIERC20(token1);

        uint256 _fee = ((amount1 / 1000) * swapFee);

        quoteToken.transfer(owner, (amount1 - _fee));

        return estimate(token1, AFRI_COIN, _fee);
    }

    /**
     * @dev Handles ERC20 => MNT token transfers and fee calculation
     */
    function _transferSwappedTokens1(
        address token0,
        uint256 amount0,
        uint256 amount1,
        address owner
    ) public payable returns (uint256) {
        xIERC20 baseToken = xIERC20(token0);

        uint256 _fee = ((amount1 / 1000) * swapFee);

        baseToken.transferFrom(owner, address(this), amount0);

        require(
            address(this).balance >= amount1,
            "Contract: Insufficient Balance"
        );

        (bool sent, ) = owner.call{value: amount1 - _fee}("");
        require(sent, "Failed to send MNT to the User");

        return estimate(priceAPI.getNativeToken(), AFRI_COIN, _fee);
    }

    /**
     * @dev Handles ERC20 => ERC20 token transfers and fee calculation
     */
    function _transferSwappedTokens2(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address owner
    ) private returns (uint256) {
        xIERC20 baseToken = xIERC20(token0);
        xIERC20 quoteToken = xIERC20(token1);

        uint256 _fee = ((amount1 / 1000) * swapFee);

        baseToken.transferFrom(owner, address(this), amount0);

        quoteToken.transfer(owner, (amount1 - _fee));

        return estimate(token1, AFRI_COIN, _fee);
    }

    /**
     * @dev Converts amount to wei (internal utility function)
     */
    function _inWei(uint256 amount) private pure returns (uint256) {
        return amount * 10 ** 18;
    }

    /**
     * @dev Finds a pool ID for a given token pair
     */
    function _findPool(
        address token0,
        address token1
    ) private view returns (uint) {
        require(
            token0 != address(0) && token1 != address(0),
            "Invalid Pool Tokens"
        );
        
        for (uint index = 0; index <= POOL_ID; index++) {
            if (
                (pools[index].token0 == token0 && pools[index].token1 == token1) ||
                (pools[index].token0 == token1 && pools[index].token1 == token0)
            ) {
                return index;
            }
        }
        return 0;
    }

    /**
     * @dev Creates a new liquidity position
     */
    function _createLiquid(
        uint poolId,
        uint256 amount0,
        uint256 amount1,
        address provider
    ) private {
        LIQUID_ID++;
        
        liquids[LIQUID_ID] = Liquid(
            LIQUID_ID,
            poolId,
            amount0,
            amount1,
            provider
        );
        
        pools[poolId].liquids.push(LIQUID_ID);
        providers[provider].liquids.push(LIQUID_ID);
    }

    /**
     * @dev Calculates the total size of a liquidity pool
     */
    function _poolSize(uint id) private view returns (uint256, uint256) {
        uint256 amount0;
        uint256 amount1;
        
        for (uint index = 0; index < pools[id].liquids.length; index++) {
            uint liquidId = pools[id].liquids[index];
            amount0 += liquids[liquidId].amount0;
            amount1 += liquids[liquidId].amount1;
        }
        
        return (amount0, amount1);
    }

    /**
     * @dev Creates a new liquidity pool for a token pair
     */
    function _createPool(
        address token0,
        address token1
    ) private returns (uint) {
        require(
            token0 != address(0),
            "Pair does not exists, Contact admin"
        );
        require(
            token1 != address(0),
            "Pair does not exists, Contact admin"
        );

        bool exists = _findPool(token0, token1) != 0;
        if (exists) return 0;

        POOL_ID++;
        Pool memory pool = pools[POOL_ID];

        pools[POOL_ID] = Pool(POOL_ID, token0, token1, pool.liquids);

        return POOL_ID;
    }

    // ============ MODIFIERS ============

    /**
     * @dev Restricts access to addresses that are not registered as providers
     */
    modifier onlyGuest() {
        require(providers[msg.sender].id == 0, "Only Guest");
        _;
    }

    /**
     * @dev Restricts access to registered liquidity providers only
     */
    modifier onlyProvider() {
        require(providers[msg.sender].id != 0, "Only Provider");
        _;
    }
}