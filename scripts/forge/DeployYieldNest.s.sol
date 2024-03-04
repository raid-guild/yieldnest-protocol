// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;


import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/StakingNodesManager.sol";
import "../../src/RewardsReceiver.sol";
import "../../src/RewardsDistributor.sol";
import "../../src/ynETH.sol";
import "../../src/interfaces/IStakingNode.sol";
import "../../src/external/ethereum/IDepositContract.sol";
import "../../src/interfaces/IRewardsDistributor.sol";
import "../../src/external/tokens/IWETH.sol";
import "../../test/foundry/ContractAddresses.sol";
import "./BaseScript.s.sol";
import "../../src/YieldNestOracle.sol";
import "../../src/ynLSD.sol";


contract DeployYieldNest is BaseScript {

    TransparentUpgradeableProxy public ynethProxy;
    TransparentUpgradeableProxy public stakingNodesManagerProxy;
    TransparentUpgradeableProxy public rewardsDistributorProxy;
    TransparentUpgradeableProxy public yieldNestOracleProxy;
    TransparentUpgradeableProxy public ynLSDProxy;
    
    ynETH public yneth;
    StakingNodesManager public stakingNodesManager;
    RewardsReceiver public executionLayerReceiver;
    RewardsReceiver public consensusLayerReceiver; // Added consensusLayerReceiver
    RewardsDistributor public rewardsDistributor;
    StakingNode public stakingNodeImplementation;
    YieldNestOracle public yieldNestOracle;
    ynLSD public ynlsd;
    address payable feeReceiver;

    IEigenPodManager public eigenPodManager;
    IDelegationManager public delegationManager;
    IDelayedWithdrawalRouter public delayedWithdrawalRouter;
    IStrategyManager public strategyManager;
    IDepositContract public depositContract;
    IWETH public weth;

    uint startingExchangeAdjustmentRate;

    bytes ZERO_PUBLIC_KEY = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"; 
    bytes ONE_PUBLIC_KEY = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
    bytes TWO_PUBLIC_KEY = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002";

    bytes ZERO_SIGNATURE = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    bytes32 ZERO_DEPOSIT_ROOT = bytes32(0);

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // ynETH.sol ROLES
        address ynethAdminAddress = vm.envAddress("YNETH_ADMIN_ADDRESS");
        address pauserAddress = vm.envAddress("PAUSER_ADDRESS");
        address proxyOwnerAddress = vm.envAddress("PROXY_OWNER");

        address rewardsDistributorAdminAddress = vm.envAddress("REWARDS_DISTRIBUTOR_ADMIN_ADDRESS");

        // StakingNodesManager.sol ROLES
        address stakingNodesManagerAdminAddress = vm.envAddress("STAKING_NODES_MANAGER_ADMIN_ADDRESS");
        address stakingAdminAddress = vm.envAddress("STAKING_ADMIN_ADDRESS");
        address stakingNodesAdminAddress = vm.envAddress("STAKING_NODES_ADMIN_ADDRESS");
        address validatorManagerAddress = vm.envAddress("VALIDATOR_MANAGER_ADDRESS");

        address _broadcaster = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);


        console.log("Default Signer Address:", _broadcaster);
        console.log("Current Block Number:", block.number);
        console.log("Current Chain ID:", block.chainid);


        feeReceiver = payable(_broadcaster); // Casting the default signer address to payable


        startingExchangeAdjustmentRate = 4;

        ContractAddresses contractAddresses = new ContractAddresses();
        ContractAddresses.ChainAddresses memory chainAddresses = contractAddresses.getChainAddresses(block.chainid);
        eigenPodManager = IEigenPodManager(chainAddresses.EIGENLAYER_EIGENPOD_MANAGER_ADDRESS);
        delegationManager = IDelegationManager(chainAddresses.EIGENLAYER_DELEGATION_MANAGER_ADDRESS);
        delayedWithdrawalRouter = IDelayedWithdrawalRouter(chainAddresses.EIGENLAYER_DELAYED_WITHDRAWAL_ROUTER_ADDRESS); // Assuming DEPOSIT_2_ADDRESS is used for DelayedWithdrawalRouter
        strategyManager = IStrategyManager(chainAddresses.EIGENLAYER_STRATEGY_MANAGER_ADDRESS);
        depositContract = IDepositContract(chainAddresses.DEPOSIT_2_ADDRESS);
        weth = IWETH(chainAddresses.WETH_ADDRESS);

        // Deploy implementations
        yneth = new ynETH();
        stakingNodesManager = new StakingNodesManager();
        executionLayerReceiver = new RewardsReceiver();
        consensusLayerReceiver = new RewardsReceiver(); // Instantiating consensusLayerReceiver
        stakingNodeImplementation = new StakingNode();
        yieldNestOracle = new YieldNestOracle();
        ynlsd = new ynLSD();

        RewardsDistributor rewardsDistributorImplementation = new RewardsDistributor();
        rewardsDistributorProxy = new TransparentUpgradeableProxy(address(rewardsDistributorImplementation), proxyOwnerAddress, "");
        rewardsDistributor = RewardsDistributor(payable(rewardsDistributorProxy));

        YieldNestOracle yieldNestOracleImplementation  = new YieldNestOracle();
        yieldNestOracleProxy = new TransparentUpgradeableProxy(address(yieldNestOracleImplementation), proxyOwnerAddress, "");
        yieldNestOracle = YieldNestOracle(address(yieldNestOracleProxy));

        ynLSD ynLSDImplementation = new ynLSD();
        ynLSDProxy = new TransparentUpgradeableProxy(address(ynLSDImplementation), proxyOwnerAddress, "");
        ynlsd = ynLSD(address(ynLSDProxy));

        // Deploy proxies
        ynethProxy = new TransparentUpgradeableProxy(address(yneth), proxyOwnerAddress, "");
        stakingNodesManagerProxy = new TransparentUpgradeableProxy(address(stakingNodesManager), proxyOwnerAddress, "");

        yneth = ynETH(payable(ynethProxy));
        stakingNodesManager = StakingNodesManager(payable(stakingNodesManagerProxy));
    
        // Initialize ynETH with example parameters
        address[] memory pauseWhitelist = new address[](1);
        pauseWhitelist[0] = pauserAddress;

        ynETH.Init memory ynethInit = ynETH.Init({
            admin: ynethAdminAddress,
            pauser: pauserAddress,
            stakingNodesManager: IStakingNodesManager(address(stakingNodesManager)),
            rewardsDistributor: IRewardsDistributor(address(rewardsDistributor)),
            exchangeAdjustmentRate: startingExchangeAdjustmentRate,
            pauseWhitelist: pauseWhitelist
        });
        yneth.initialize(ynethInit);


        // Initialize StakingNodesManager with example parameters
        StakingNodesManager.Init memory stakingNodesManagerInit = StakingNodesManager.Init({
            admin: stakingNodesManagerAdminAddress,
            stakingAdmin: stakingAdminAddress,
            stakingNodesAdmin: stakingNodesAdminAddress,
            validatorManager: validatorManagerAddress,
            maxNodeCount: 10,
            depositContract: depositContract,
            ynETH: IynETH(address(yneth)),
            eigenPodManager: eigenPodManager,
            delegationManager: delegationManager,
            delayedWithdrawalRouter: delayedWithdrawalRouter,
            strategyManager: strategyManager,
            rewardsDistributor: IRewardsDistributor(address(rewardsDistributor))
        });
        stakingNodesManager.initialize(stakingNodesManagerInit);

        stakingNodesManager.registerStakingNodeImplementationContract(address(stakingNodeImplementation));

        RewardsDistributor.Init memory rewardsDistributorInit = RewardsDistributor.Init({
            admin: rewardsDistributorAdminAddress,
            executionLayerReceiver: executionLayerReceiver,
            consensusLayerReceiver: consensusLayerReceiver, // Adding consensusLayerReceiver to the initialization
            feesReceiver: feeReceiver, // Assuming the contract itself will receive the fees
            ynETH: IynETH(address(yneth))
        });
        rewardsDistributor.initialize(rewardsDistributorInit);

        // Initialize RewardsReceiver with example parameters
        RewardsReceiver.Init memory rewardsReceiverInit = RewardsReceiver.Init({
            admin: rewardsDistributorAdminAddress,
            withdrawer: address(rewardsDistributor)
        });
        executionLayerReceiver.initialize(rewardsReceiverInit);
        consensusLayerReceiver.initialize(rewardsReceiverInit); // Initializing consensusLayerReceiver

        

        vm.stopBroadcast();

        Deployment memory deployment = Deployment({
            ynETH: yneth,
            stakingNodesManager: stakingNodesManager,
            executionLayerReceiver: executionLayerReceiver,
            consensusLayerReceiver: consensusLayerReceiver, // Adding consensusLayerReceiver to the deployment
            rewardsDistributor: rewardsDistributor,
            stakingNodeImplementation: stakingNodeImplementation
        });
        
        saveDeployment(deployment);
    }
}



