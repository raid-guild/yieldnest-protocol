// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {StakingNodesManager} from "src/StakingNodesManager.sol";
import {StakingNode} from "src/StakingNode.sol";
import {RewardsReceiver} from "src/RewardsReceiver.sol";
import {stdJson} from "lib/forge-std/src/StdJson.sol";
import {RewardsDistributor} from "src/RewardsDistributor.sol";
import {ynETH} from "src/ynETH.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {Utils} from "script/Utils.sol";
import {ActorAddresses} from "script/Actors.sol";
import {BaseScript} from "script/BaseScript.s.sol";
import {console} from "lib/forge-std/src/console.sol";

abstract contract BaseYnETHScript is BaseScript {
    using stdJson for string;

    struct Deployment {
        ynETH ynETH;
        StakingNodesManager stakingNodesManager;
        RewardsReceiver executionLayerReceiver;
        RewardsReceiver consensusLayerReceiver;
        RewardsDistributor rewardsDistributor;
        StakingNode stakingNodeImplementation;
    }

    function getDeploymentFile() internal virtual view returns (string memory) {
        string memory root = vm.projectRoot();
        return string.concat(root, "/deployments/ynETH-", vm.toString(block.chainid), ".json");
    }

    function saveDeployment(Deployment memory deployment) public virtual {
        string memory json = "deployment";

        // contract addresses
        serializeProxyElements(json, "ynETH", address(deployment.ynETH)); 
        serializeProxyElements(json, "stakingNodesManager", address(deployment.stakingNodesManager));
        serializeProxyElements(json, "executionLayerReceiver", address(deployment.executionLayerReceiver));
        serializeProxyElements(json, "consensusLayerReceiver", address(deployment.consensusLayerReceiver));
        serializeProxyElements(json, "rewardsDistributor", address(deployment.rewardsDistributor));
        vm.serializeAddress(json, "stakingNodeImplementation", address(deployment.stakingNodeImplementation));

        ActorAddresses.Actors memory actors = getActors();
        // actors
        vm.serializeAddress(json, "PROXY_ADMIN_OWNER", address(actors.admin.PROXY_ADMIN_OWNER));
        vm.serializeAddress(json, "ADMIN", address(actors.admin.ADMIN));
        vm.serializeAddress(json, "STAKING_ADMIN", address(actors.admin.STAKING_ADMIN));
        vm.serializeAddress(json, "STAKING_NODES_OPERATOR", address(actors.ops.STAKING_NODES_OPERATOR));
        vm.serializeAddress(json, "VALIDATOR_MANAGER", address(actors.ops.VALIDATOR_MANAGER));
        vm.serializeAddress(json, "FEE_RECEIVER", address(actors.admin.FEE_RECEIVER));
        vm.serializeAddress(json, "PAUSE_ADMIN", address(actors.ops.PAUSE_ADMIN));
        vm.serializeAddress(json, "UNPAUSE_ADMIN", address(actors.admin.UNPAUSE_ADMIN));
        vm.serializeAddress(json, "LSD_RESTAKING_MANAGER", address(actors.ops.LSD_RESTAKING_MANAGER));
        vm.serializeAddress(json, "STAKING_NODE_CREATOR", address(actors.ops.STAKING_NODE_CREATOR));
        vm.serializeAddress(json, "ORACLE_ADMIN", address(actors.admin.ORACLE_ADMIN));
        vm.serializeAddress(json, "DEPOSIT_BOOTSTRAPPER", address(actors.eoa.DEPOSIT_BOOTSTRAPPER));

        string memory finalJson = vm.serializeAddress(json, "DEFAULT_SIGNER", address((actors.eoa.DEFAULT_SIGNER)));
        vm.writeJson(finalJson, getDeploymentFile());

        console.log("Deployment JSON file written successfully:", getDeploymentFile());
    }

    function loadDeployment() public view returns (Deployment memory) {
        string memory deploymentFile = getDeploymentFile();
        string memory jsonContent = vm.readFile(deploymentFile);
        Deployment memory deployment;
        deployment.ynETH = ynETH(payable(jsonContent.readAddress(".proxy-ynETH")));
        deployment.stakingNodesManager = StakingNodesManager(payable(jsonContent.readAddress(".proxy-stakingNodesManager")));
        deployment.executionLayerReceiver = RewardsReceiver(payable(jsonContent.readAddress(".proxy-executionLayerReceiver")));
        deployment.consensusLayerReceiver = RewardsReceiver(payable(jsonContent.readAddress(".proxy-consensusLayerReceiver")));
        deployment.rewardsDistributor = RewardsDistributor(payable(jsonContent.readAddress(".proxy-rewardsDistributor")));
        deployment.stakingNodeImplementation = StakingNode(payable(jsonContent.readAddress(".stakingNodeImplementation")));

        return deployment;
    }
}