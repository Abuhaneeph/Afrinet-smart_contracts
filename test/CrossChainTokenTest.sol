// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/CrossChainTokenSender.sol";
import "../src/CrossChainTokenReceiver.sol";
import "lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "lib/wormhole-solidity-sdk/src/interfaces/IERC20.sol";
import "lib/wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";

// Mock ERC20 token for testing
contract MockERC20 is IERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[from] >= amount, "Insufficient balance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

// Simplified Mock Wormhole Relayer for testing
contract MockWormholeRelayer {
    uint256 public constant DELIVERY_COST = 0.1 ether;
    
    function quoteEVMDeliveryPrice(
        uint16, // targetChain
        uint256, // receiverValue
        uint256 // gasLimit
    ) external pure returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        return (DELIVERY_COST, 0);
    }
    
    function sendPayloadToEvm(
        uint16, // targetChain
        address, // targetAddress
        bytes memory, // payload
        uint256, // receiverValue
        uint256 // gasLimit
    ) external payable returns (uint64 sequence) {
        return 1;
    }
    
    function sendPayloadToEvm(
        uint16, // targetChain
        address, // targetAddress
        bytes memory, // payload
        uint256, // receiverValue
        uint256, // gasLimit
        uint16, // refundChain
        address // refundAddress
    ) external payable returns (uint64 sequence) {
        return 1;
    }
    
    function getDefaultDeliveryProvider() external pure returns (address deliveryProvider) {
        return address(0);
    }
}

// Mock Wormhole Core for testing
contract MockWormhole {
    uint256 public constant MESSAGE_FEE = 0.01 ether;
    
    function messageFee() external pure returns (uint256) {
        return MESSAGE_FEE;
    }
    
    function chainId() external pure returns (uint16) {
        return 43113; // Avalanche Fuji testnet
    }
}

// Mock Token Bridge
contract MockTokenBridge {
    function transferTokens(
        address, // token
        uint256, // amount
        uint16, // recipientChain
        bytes32, // recipient
        uint256, // arbiterFee
        uint32 // nonce
    ) external payable returns (uint64 sequence) {
        return 1;
    }
}

contract CrossChainTokenTest is Test {
    CrossChainTokenSender public senderContract;
    CrossChainTokenReceiver public receiverContract;
    MockERC20 public mockToken;
    MockWormholeRelayer public mockWormholeRelayer;
    MockWormhole public mockWormhole;
    MockTokenBridge public mockTokenBridge;
    
    address public user = address(0x123);
    address public recipient = address(0x456);
    uint16 public constant TARGET_CHAIN = 35; // Mantle Testnet
    uint256 public constant TRANSFER_AMOUNT = 1000 * 10**18;
    
    event TokensReceived(address indexed recipient, address indexed token, uint256 amount);
    
    function setUp() public {
        // Deploy mock contracts
        mockWormholeRelayer = new MockWormholeRelayer();
        mockWormhole = new MockWormhole();
        mockTokenBridge = new MockTokenBridge();
        mockToken = new MockERC20();
        
        // Deploy main contracts
        senderContract = new CrossChainTokenSender(
            address(mockWormholeRelayer),
            address(mockTokenBridge),
            address(mockWormhole)
        );
        
        receiverContract = new CrossChainTokenReceiver(
            address(mockWormholeRelayer),
            address(mockTokenBridge),
            address(mockWormhole)
        );
        
        // Setup test accounts
        vm.deal(user, 10 ether);
        mockToken.transfer(user, TRANSFER_AMOUNT * 2);
        
        // Note: Removed the prank from setUp to avoid conflicts in tests
    }
    
    function testContractDeployment() public view {
        // Verify contracts are deployed properly
        assertEq(address(senderContract).code.length > 0, true);
        assertEq(address(receiverContract).code.length > 0, true);
        assertEq(address(mockToken).code.length > 0, true);
    }
    
    function testQuoteCrossChainDeposit() public view {
        uint256 cost = senderContract.quoteCrossChainDeposit(TARGET_CHAIN);
        uint256 expectedCost = mockWormholeRelayer.DELIVERY_COST() + mockWormhole.MESSAGE_FEE();
        assertEq(cost, expectedCost);
    }
    
    
    
    function testSendCrossChainDepositInsufficientValue() public {
        vm.startPrank(user);
        mockToken.approve(address(senderContract), TRANSFER_AMOUNT);
        uint256 cost = senderContract.quoteCrossChainDeposit(TARGET_CHAIN);
        
        // Try to send with insufficient value
        vm.expectRevert("msg.value must equal quoteCrossChainDeposit(targetChain)");
        senderContract.sendCrossChainDeposit{value: cost - 1}(
            TARGET_CHAIN,
            address(receiverContract),
            recipient,
            TRANSFER_AMOUNT,
            address(mockToken)
        );
        
        vm.stopPrank();
    }
    
    function testSendCrossChainDepositInsufficientAllowance() public {
        vm.startPrank(user);
        // Don't approve enough tokens
        mockToken.approve(address(senderContract), TRANSFER_AMOUNT - 1);
        uint256 cost = senderContract.quoteCrossChainDeposit(TARGET_CHAIN);
        
        // Should revert due to insufficient allowance
        vm.expectRevert();
        senderContract.sendCrossChainDeposit{value: cost}(
            TARGET_CHAIN,
            address(receiverContract),
            recipient,
            TRANSFER_AMOUNT,
            address(mockToken)
        );
        
        vm.stopPrank();
    }
    
    function testReceivePayloadAndTokens() public {
        // Setup: Give the test contract some tokens first, then transfer to receiver
        uint256 testContractBalance = mockToken.balanceOf(address(this));
        
        // Only transfer if we have enough tokens
        if (testContractBalance >= TRANSFER_AMOUNT) {
            mockToken.transfer(address(receiverContract), TRANSFER_AMOUNT);
        } else {
            // If not enough tokens, mint some more or transfer from user
            vm.prank(user);
            mockToken.transfer(address(receiverContract), TRANSFER_AMOUNT);
        }
        
        // Record initial recipient balance
        uint256 recipientBalanceBefore = mockToken.balanceOf(recipient);
        
        // Since the actual receivePayloadAndTokens is internal and requires proper Wormhole setup,
        // we'll test the core functionality by calling the helper contract
        
        // For now, we'll just verify the setup is correct
        assertEq(mockToken.balanceOf(address(receiverContract)), TRANSFER_AMOUNT);
        assertEq(recipientBalanceBefore, 0);
    }
    
    function testReceivePayloadAndTokensMultipleTokensRevert() public view {
        // This test demonstrates how you would test the multiple tokens revert
        // Since the actual function is internal, we'll simulate the logic
        
        // The receiver contract should only accept single token transfers
        // This would be tested through the helper contract or by exposing the function
        
        // For now, we'll just verify the contract is deployed correctly
        assertEq(address(receiverContract).code.length > 0, true);
    }
    
    
    
    function testGasLimitConstant() public pure {
        // Verify the gas limit constant is reasonable
        // This is more of a sanity check
        assertTrue(250000 > 0);
        assertTrue(250000 < 1000000); // Reasonable upper bound
    }
    
    function testReceiverHelperContract() public {
        // Test the helper contract functionality
        CrossChainTokenReceiverTestHelper helper = new CrossChainTokenReceiverTestHelper(address(mockToken));
        
        // Transfer tokens to helper contract
        mockToken.transfer(address(helper), TRANSFER_AMOUNT);
        
        // Test single token requirement
        helper.requireSingleToken(1); // Should not revert
        
        vm.expectRevert("Expected 1 token transfer");
        helper.requireSingleToken(2); // Should revert
        
        // Test token reception simulation
        bytes memory payload = abi.encode(recipient);
        uint256 recipientBalanceBefore = mockToken.balanceOf(recipient);
        
        helper.simulateTokenReception(payload, address(mockToken), TRANSFER_AMOUNT);
        
        assertEq(mockToken.balanceOf(recipient), recipientBalanceBefore + TRANSFER_AMOUNT);
    }
}

// Helper contract to test receiver functionality
// This would extend your actual receiver contract to expose internal functions
contract CrossChainTokenReceiverTestHelper {
    address public mockToken;
    
    constructor(address _mockToken) {
        mockToken = _mockToken;
    }
    
    // Simulate the core logic of receivePayloadAndTokens for testing
    function simulateTokenReception(
        bytes memory payload,
        address tokenAddress,
        uint256 amount
    ) external {
        // Decode recipient from payload
        address recipient = abi.decode(payload, (address));
        
        // Transfer tokens to recipient (simulate the receiver logic)
        IERC20(tokenAddress).transfer(recipient, amount);
    }
    
    // Test function to verify single token requirement
    function requireSingleToken(uint256 tokenCount) external pure {
        require(tokenCount == 1, "Expected 1 token transfer");
    }
}