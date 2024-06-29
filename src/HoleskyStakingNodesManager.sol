// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {StakingNodesManager} from "src/StakingNodesManager.sol";
import {IStakingNode} from "src/interfaces/IStakingNode.sol";
import {IStakingNodesManager} from "src/interfaces/IStakingNodesManager.sol";

contract HoleskyStakingNodesManager is StakingNodesManager {
    // Additional functionality can be added here

    function initializeStakingNode(IStakingNode node, uint256 nodeCount) override internal {
        uint64 initializedVersion = node.getInitializedVersion();
        if (initializedVersion == 0) {
            node.initialize(
                IStakingNode.Init(IStakingNodesManager(address(this)), nodeCount)
            );

            // update to the newly upgraded version.
            initializedVersion = node.getInitializedVersion();
            emit NodeInitialized(address(node), initializedVersion);
        }

        if (initializedVersion == 1) {

            if (node.nodeId() == 2) {
                // assuming 20 unverified validators at upgrade-time
                node.initializeV2(20 * 32 ether);
            } else {
                // assuming no unverified validators at upgrade-time
                node.initializeV2(0);
            }

        }
        // NOTE: for future versions add additional if clauses that initialize the node 
        // for the next version while keeping the previous initializers
    }
}
