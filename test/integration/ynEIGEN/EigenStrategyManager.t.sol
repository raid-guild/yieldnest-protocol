// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity 0.8.24;

import "./ynEigenIntegrationBaseTest.sol";
import {ProxyAdmin} from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {UpgradeableBeacon} from "lib/openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {ITransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPausable} from "lib/eigenlayer-contracts/src/contracts/interfaces//IPausable.sol";
import {ITokenStakingNode} from "src/interfaces/ITokenStakingNode.sol";
import {ynBase} from "src/ynBase.sol";
import "forge-std/console.sol";


contract EigenStrategyManagerTest is ynEigenIntegrationBaseTest {

    TestAssetUtils testAssetUtils;
    address[10] public depositors;

    constructor() {
        testAssetUtils = new TestAssetUtils();
        for (uint i = 0; i < 10; i++) {
            depositors[i] = address(uint160(uint256(keccak256(abi.encodePacked("depositor", i)))));
        }
    }

    function testStakeAssetsToNodeSuccessFuzz(
        uint256 wstethAmount,
        uint256 woethAmount,
        uint256 rethAmount,
        uint256 sfrxethAmount
    ) public {

        // cannot call stakeAssetsToNode with any amount == 0. all must be non-zero.
        vm.assume(
            wstethAmount < 100 ether && wstethAmount >= 2 wei &&
            woethAmount < 100 ether && woethAmount >= 2 wei &&
            rethAmount < 100 ether && rethAmount >= 2 wei &&
            sfrxethAmount < 100 ether && sfrxethAmount >= 2 wei
        );

        // Setup: Create a token staking node and prepare assetsToDeposit
        vm.prank(actors.ops.STAKING_NODE_CREATOR);
        tokenStakingNodesManager.createTokenStakingNode();
        ITokenStakingNode tokenStakingNode = tokenStakingNodesManager.nodes(0);

        // uint256 wstethAmount = 2;
        // uint256 woethAmount = 2;
        // uint256 rethAmount = 2;
        // uint256 sfrxethAmount = 5642858642974091827; // 5.642e18

        uint256 assetCount = 4;

        // Call with arrays and from controller
        IERC20[] memory assetsToDeposit = new IERC20[](assetCount);
        assetsToDeposit[0] = IERC20(chainAddresses.lsd.WSTETH_ADDRESS);
        assetsToDeposit[1] = IERC20(chainAddresses.lsd.WOETH_ADDRESS);
        assetsToDeposit[2] = IERC20(chainAddresses.lsd.RETH_ADDRESS);
        assetsToDeposit[3] = IERC20(chainAddresses.lsd.SFRXETH_ADDRESS);

        uint256[] memory amounts = new uint256[](assetCount);
        amounts[0] = wstethAmount;
        amounts[1] = woethAmount;
        amounts[2] = rethAmount;
        amounts[3] = sfrxethAmount;

        for (uint256 i = 0; i < assetCount; i++) {
            address prankedUser = depositors[i];
            if (amounts[i] == 0) {
                // no deposits
                continue;
            }
            testAssetUtils.depositAsset(ynEigenToken, address(assetsToDeposit[i]), amounts[i], prankedUser);
        }

        uint256[] memory initialBalances = new uint256[](assetsToDeposit.length);
        for (uint256 i = 0; i < assetsToDeposit.length; i++) {
            initialBalances[i] = assetsToDeposit[i].balanceOf(address(ynEigenToken));
        }

        vm.startPrank(actors.ops.STRATEGY_CONTROLLER);
        eigenStrategyManager.stakeAssetsToNode(tokenStakingNode.nodeId(), assetsToDeposit, amounts);
        vm.stopPrank();

        for (uint256 i = 0; i < assetsToDeposit.length; i++) {
            uint256 initialBalance = initialBalances[i];
            uint256 finalBalance = assetsToDeposit[i].balanceOf(address(ynEigenToken));
            assertEq(initialBalance - finalBalance, amounts[i], "Balance of ynEigen did not decrease by the staked amount for asset");
            assertEq(compareWithThreshold(eigenStrategyManager.getStakedAssetBalance(assetsToDeposit[i]), initialBalance, 3), true, "Staked asset balance does not match initial balance within threshold");
            uint256 userUnderlyingView = eigenStrategyManager.strategies(assetsToDeposit[i]).userUnderlyingView(address(tokenStakingNode));

            if (address(assetsToDeposit[i]) == chainAddresses.lsd.WSTETH_ADDRESS || address(assetsToDeposit[i]) == chainAddresses.lsd.WOETH_ADDRESS) {
                uint256 wrappedAssetRate = rateProvider.rate(address(assetsToDeposit[i]));
                userUnderlyingView = userUnderlyingView * 1e18 / wrappedAssetRate;
            }

            // console.log("Asset Index: ", i);
            // console.log("Initial Balance: ", initialBalance);
            // console.log("User Underlying View: ", userUnderlyingView);

            uint256 comparisonTreshold = 4;
            if (address(assetsToDeposit[i]) == chainAddresses.lsd.WOETH_ADDRESS) {
                comparisonTreshold = 1 ether;
            }
            assertEq(compareWithThreshold(initialBalance, userUnderlyingView, comparisonTreshold), true, "Initial balance does not match user underlying view within threshold");
        }
    }
}