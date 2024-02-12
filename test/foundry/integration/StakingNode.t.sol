import "./IntegrationBaseTest.sol";
import "forge-std/console.sol";
import "../../../src/interfaces/IStakingNode.sol";
import "../../../src/StakingNode.sol";

contract StakingNodeTest is IntegrationBaseTest {

    function testCreateNodeAndAssertETHBalanceWithoutRegisteredValidators() public {
        // Create a staking node
        IStakingNode stakingNodeInstance = stakingNodesManager.createStakingNode();

        uint actualETHBalance = stakingNodeInstance.getETHBalance();
        assertEq(actualETHBalance, 0, "ETH balance does not match expected value");
    }

    function testCreateNodeAndAssertETHBalanceAfterDeposits() public {

        address addr1 = vm.addr(100);

        vm.deal(addr1, 100 ether);

        uint depositAmount = 32 ether;
        vm.prank(addr1);
        yneth.depositETH{value: depositAmount}(addr1);
        uint balance = yneth.balanceOf(addr1);

        IStakingNode stakingNodeInstance = stakingNodesManager.createStakingNode();

        uint nodeId = 0;

        IStakingNodesManager.DepositData[] memory depositData = new IStakingNodesManager.DepositData[](1);
        depositData[0] = IStakingNodesManager.DepositData({
            publicKey: ZERO_PUBLIC_KEY,
            signature: ZERO_SIGNATURE,
            nodeId: nodeId,
            depositDataRoot: bytes32(0)
        });


        bytes memory withdrawalCredentials = stakingNodesManager.getWithdrawalCredentials(nodeId);

        for (uint i = 0; i < depositData.length; i++) {
            uint amount = depositAmount / depositData.length;
            bytes32 depositDataRoot = stakingNodesManager.generateDepositRoot(depositData[i].publicKey, depositData[i].signature, withdrawalCredentials, amount);
            depositData[i].depositDataRoot = depositDataRoot;
        }
        
        bytes32 depositRoot = ZERO_DEPOSIT_ROOT;
        stakingNodesManager.registerValidators(depositRoot, depositData);

        uint actualETHBalance = stakingNodeInstance.getETHBalance();
        assertEq(actualETHBalance, depositAmount, "ETH balance does not match expected value");

        IEigenPod eigenPodInstance = stakingNodeInstance.eigenPod();

        uint64 restakedGwei = eigenPodInstance.restakedExecutionLayerGwei();
        IEigenPodManager eigenPodManagerInstance = eigenPodInstance.eigenPodManager();
        address podOwnerAddress = eigenPodInstance.podOwner();
        bool hasFullyRestaked = eigenPodInstance.hasRestaked();
        uint64 recentWithdrawalBlock = eigenPodInstance.mostRecentWithdrawalBlockNumber();

        // TODO: dpouble check this is the desired state for a pod.
        // we can't delegate on mainnet at this time so one should be able to farm points without delegating
        assertEq(restakedGwei, 0, "Restaked Gwei should be 0");
        assertEq(address(eigenPodManager), address(eigenPodManagerInstance), "EigenPodManager should match");
        assertEq(podOwnerAddress, address(stakingNodeInstance), "Pod owner address does not match");
        assertFalse(hasFullyRestaked, "Pod should have fully restaked");
        assertEq(recentWithdrawalBlock, 0, "Most recent withdrawal block should be greater than 0");

        stakingNodeInstance.withdrawBeforeRestaking();
    }  
}

