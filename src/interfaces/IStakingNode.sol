// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

// --------------------------------------------------------------------------------------
// $$\     $$\ $$\           $$\       $$\ $$\   $$\                       $$\     
// \$$\   $$  |\__|          $$ |      $$ |$$$\  $$ |                      $$ |    
//  \$$\ $$  / $$\  $$$$$$\  $$ | $$$$$$$ |$$$$\ $$ | $$$$$$\   $$$$$$$\ $$$$$$\   
//   \$$$$  /  $$ |$$  __$$\ $$ |$$  __$$ |$$ $$\$$ |$$  __$$\ $$  _____|\_$$  _|  
//    \$$  /   $$ |$$$$$$$$ |$$ |$$ /  $$ |$$ \$$$$ |$$$$$$$$ |\$$$$$$\    $$ |    
//     $$ |    $$ |$$   ____|$$ |$$ |  $$ |$$ |\$$$ |$$   ____| \____$$\   $$ |$$\ 
//     $$ |    $$ |\$$$$$$$\ $$ |\$$$$$$$ |$$ | \$$ |\$$$$$$$\ $$$$$$$  |  \$$$$  |
//     \__|    \__| \_______|\__| \_______|\__|  \__| \_______|\_______/    \____/ 
//--------------------------------------------------------------------------------------
//----------------------------------  IStakingNode  ------------------------------------
//--------------------------------------------------------------------------------------

import {BeaconChainProofs} from "lib/eigenlayer-contracts/src/contracts/libraries/BeaconChainProofs.sol";
import {IStakingNodesManager} from "src/interfaces/IStakingNodesManager.sol";
import {IStrategy} from "lib/eigenlayer-contracts/src/contracts/interfaces/IStrategyManager.sol";
import {IEigenPod} from "lib/eigenlayer-contracts/src/contracts/interfaces/IEigenPod.sol";
import {ISignatureUtils} from "lib/eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";

struct WithdrawalCompletionParams {
    uint256 middlewareTimesIndex;
    uint amount;
    uint32 withdrawalStartBlock;
    address delegatedAddress;
    uint96 nonce;
}

interface IStakingEvents {
    /// @notice Emitted when a user stakes ETH and receives ynETH.
    /// @param staker The address of the user staking ETH.
    /// @param ethAmount The amount of ETH staked.
    /// @param ynETHAmount The amount of ynETH received.
    event Staked(address indexed staker, uint256 ethAmount, uint256 ynETHAmount);
    event DepositETHPausedUpdated(bool isPaused);
    event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);
}

interface IStakingNode {

    /// @notice Configuration for contract initialization.
    struct Init {
        IStakingNodesManager stakingNodesManager;
        uint nodeId;
    }

    function stakingNodesManager() external view returns (IStakingNodesManager);
    function eigenPod() external view returns (IEigenPod);
    function initialize(Init memory init) external;
    function createEigenPod() external returns (IEigenPod);
    function delegate(
        address operator,
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external;
    function undelegate() external;

    function withdrawNonBeaconChainETHBalanceWei() external;
    function processDelayedWithdrawals() external;

    function implementation() external view returns (address);

    function allocateStakedETH(uint amount) external payable;   
    function getETHBalance() external view returns (uint);
    function nodeId() external view returns (uint);

    /// @notice Returns the beaconChainETHStrategy address used by the StakingNode.
    function beaconChainETHStrategy() external view returns (IStrategy);

    /**
     * @notice Verifies the withdrawal credentials and balance of validators.
     * @param oracleTimestamp An array of oracle block numbers corresponding to each validator.
     * @param stateRootProof An array of state root proofs corresponding to each validator.
     * @param validatorIndices An array of validator indices.
     * @param validatorFieldsProofs An array of ValidatorFieldsAndBalanceProofs, containing the merkle proofs for validator fields and balances.
     * @param validatorFields An array of arrays, each containing the validator fields to be verified.
     */
    function verifyWithdrawalCredentials(
        uint64 oracleTimestamp,
        BeaconChainProofs.StateRootProof calldata stateRootProof,
        uint40[] calldata validatorIndices,
        bytes[] calldata validatorFieldsProofs,
        bytes32[][] calldata validatorFields
    ) external;

    function getInitializedVersion() external view returns (uint64);
}
