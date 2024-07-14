// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {IWithdrawalQueueManager} from "src/interfaces/IWithdrawalQueueManager.sol";
import {AccessControlUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IRedeemableAsset} from "src/interfaces/IRedeemableAsset.sol";
import {IRedemptionAssetsVault} from "src/interfaces/IRedemptionAssetsVault.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWithdrawalQueueManagerEvents {
    event WithdrawalRequested(uint256 indexed tokenId, address indexed requester, uint256 amount);
    event WithdrawalClaimed(uint256 indexed tokenId, address claimer, address receiver, IWithdrawalQueueManager.WithdrawalRequest request);
    event WithdrawalFeeUpdated(uint256 newFeePercentage);
    event FeeReceiverUpdated(address indexed oldFeeReceiver, address indexed newFeeReceiver);
    event SecondsToFinalizationUpdated(uint256 previousValue, uint256 newValue);
    event RequestsFinalized(uint256 newFinalizedIndex, uint256 previousFinalizedIndex);
}

/**
 * @title Withdrawal Queue Manager for Redeemable Assets
 * @dev Manages the queue of withdrawal requests for redeemable assets, handling fees, finalization times, and claims.
 * This contract extends ERC721 to represent each withdrawal request as a unique token.
 * 
 */

contract WithdrawalQueueManager is IWithdrawalQueueManager, ERC721Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IWithdrawalQueueManagerEvents {
    using SafeERC20 for IRedeemableAsset;

    //--------------------------------------------------------------------------------------
    //----------------------------------  ERRORS  -------------------------------------------
    //--------------------------------------------------------------------------------------

    error NotFinalized(uint256 tokenId, uint256 currentTimestamp, uint256 requestTimestamp);
    error ZeroAddress();
    error WithdrawalAlreadyProcessed(uint256 tokenId);
    error InsufficientBalance(uint256 currentBalance, uint256 requestedBalance);
    error CallerNotOwnerNorApproved(uint256 tokenId, address caller);
    error AmountExceedsSurplus(uint256 requestedAmount, uint256 availableSurplus);
    error AmountMustBeGreaterThanZero();
    error FeePercentageExceedsLimit();
    error ArrayLengthMismatch(uint256 length1, uint256 length2);
    error SecondsToFinalizationExceedsLimit(uint256 value);
    error WithdrawalRequestDoesNotExist(uint256 tokenId);
    error IndexExceedsTokenCount(uint256 index, uint256 tokenCount);
    error IndexNotAdvanced(uint256 newIndex, uint256 currentIndex);

    //--------------------------------------------------------------------------------------
    //----------------------------------  ROLES  -------------------------------------------
    //--------------------------------------------------------------------------------------

    /// @dev Role identifier for administrators who can manage the withdrawal queue settings.
    bytes32 public constant WITHDRAWAL_QUEUE_ADMIN_ROLE = keccak256("WITHDRAWAL_QUEUE_ADMIN_ROLE");

    /// @dev Role identifier for accounts authorized to withdraw surplus redemption assets.
    bytes32 public constant REDEMPTION_ASSET_WITHDRAWER_ROLE = keccak256("REDEMPTION_ASSET_WITHDRAWER_ROLE");

    /// @dev Role identifier for accounts authorized to finalize withdrawal requests.
    bytes32 public constant REQUEST_FINALIZER_ROLE = keccak256("REQUEST_FINALIZER_ROLE");

    //--------------------------------------------------------------------------------------
    //----------------------------------  CONSTANTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    uint256 constant public FEE_PRECISION = 1000000;
    uint256 constant public MAX_SECONDS_TO_FINALIZATION = 3600 * 24 * 28; // 4 weeks

    //--------------------------------------------------------------------------------------
    //----------------------------------  VARIABLES  ---------------------------------------
    //--------------------------------------------------------------------------------------

    IRedeemableAsset public redeemableAsset;
    IRedemptionAssetsVault public redemptionAssetsVault;

    uint256 public _tokenIdCounter;

    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;

    uint256 public secondsToFinalization;
    uint256 public withdrawalFee;
    address public feeReceiver;
    address public requestFinalizer;

    /// pending requested redemption amount in redemption unit of account
    uint256 public pendingRequestedRedemptionAmount;

    uint256 public lastFinalizedIndex;

    //--------------------------------------------------------------------------------------
    //----------------------------------  INITIALIZATION  ----------------------------------
    //--------------------------------------------------------------------------------------

    constructor() {
       _disableInitializers();
    }

    struct Init {
        string name;
        string symbol;
        IRedeemableAsset redeemableAsset;
        IRedemptionAssetsVault redemptionAssetsVault;
        address admin;
        address withdrawalQueueAdmin;
        address redemptionAssetWithdrawer;
        uint256 withdrawalFee;
        address feeReceiver;
        address requestFinalizer;

    }

    function initialize(Init memory init)
        public
        notZeroAddress(address(init.admin))
        notZeroAddress(address(init.redeemableAsset))
        notZeroAddress(address(init.redemptionAssetsVault))
        notZeroAddress(address(init.withdrawalQueueAdmin))
        notZeroAddress(address(init.feeReceiver))
        notZeroAddress(address(init.requestFinalizer))
    
        initializer {
        __ERC721_init(init.name, init.symbol);
        redeemableAsset = init.redeemableAsset;
        redemptionAssetsVault = init.redemptionAssetsVault;

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(WITHDRAWAL_QUEUE_ADMIN_ROLE, init.withdrawalQueueAdmin);
        _grantRole(REDEMPTION_ASSET_WITHDRAWER_ROLE, init.redemptionAssetWithdrawer);
        _grantRole(REQUEST_FINALIZER_ROLE, init.requestFinalizer);

        withdrawalFee = init.withdrawalFee;
        feeReceiver = init.feeReceiver;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  WITHDRAWAL REQUESTS  -----------------------------
    //--------------------------------------------------------------------------------------

    function requestWithdrawal(uint256 amount) external nonReentrant returns (uint256 tokenId) {
        if (amount == 0) {
            revert AmountMustBeGreaterThanZero();
        }
        
        redeemableAsset.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentRate = redemptionAssetsVault.redemptionRate();
        tokenId = _tokenIdCounter++;
        withdrawalRequests[tokenId] = WithdrawalRequest({
            amount: amount,
            feeAtRequestTime: withdrawalFee,
            redemptionRateAtRequestTime: currentRate,
            creationTimestamp: block.timestamp,
            processed: false
        });

        pendingRequestedRedemptionAmount += calculateRedemptionAmount(amount, currentRate);

        _mint(msg.sender, tokenId);

        emit WithdrawalRequested(tokenId, msg.sender, amount);
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  CLAIMS  ------------------------------------------
    //--------------------------------------------------------------------------------------

    function claimWithdrawal(uint256 tokenId, address receiver) public nonReentrant {
        if (_ownerOf(tokenId) != msg.sender && _getApproved(tokenId) != msg.sender) {
            revert CallerNotOwnerNorApproved(tokenId, msg.sender);
        }

        WithdrawalRequest memory request = withdrawalRequests[tokenId];
        if (!withdrawalRequestExists(request)) {
            revert WithdrawalRequestDoesNotExist(tokenId);
        }

        if (request.processed) {
            revert WithdrawalAlreadyProcessed(tokenId);
        }

        if (!withdrawalRequestIsFinalized(tokenId)) {
            revert NotFinalized(tokenId, block.timestamp, request.creationTimestamp);
        }

        withdrawalRequests[tokenId].processed = true;
        uint256 unitOfAccountAmount = calculateRedemptionAmount(request.amount, request.redemptionRateAtRequestTime);
        pendingRequestedRedemptionAmount -= unitOfAccountAmount;

        _burn(tokenId);
        redeemableAsset.burn(request.amount);


        uint256 feeAmount = calculateFee(unitOfAccountAmount, request.feeAtRequestTime);

        uint256 currentBalance = redemptionAssetsVault.availableRedemptionAssets();
        if (currentBalance < unitOfAccountAmount) {
            revert InsufficientBalance(currentBalance, unitOfAccountAmount);
        }

        // transfer Net Amount =  unitOfAccountAmount - feeAmount to the receiver
        redemptionAssetsVault.transferRedemptionAssets(receiver, unitOfAccountAmount - feeAmount);
        
        if (feeAmount > 0) {
            redemptionAssetsVault.transferRedemptionAssets(feeReceiver, feeAmount);
        }

        emit WithdrawalClaimed(tokenId, msg.sender, receiver, request);
    }

    /**
     * @notice Allows a batch of withdrawals to be claimed by their respective token IDs.
     * @param tokenIds An array of token IDs representing the withdrawal requests to be claimed.
     */
    function claimWithdrawals(uint256[] calldata tokenIds, address[] calldata receivers) external {

        if (tokenIds.length != receivers.length) {
            revert ArrayLengthMismatch(tokenIds.length, receivers.length);
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimWithdrawal(tokenIds[i], receivers[i]);
        }
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  ADMIN  -------------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Sets the withdrawal fee percentage.
    /// @param feePercentage The fee percentage in basis points.
    function setWithdrawalFee(uint256 feePercentage) external onlyRole(WITHDRAWAL_QUEUE_ADMIN_ROLE) {
        if (feePercentage > FEE_PRECISION) {
            revert FeePercentageExceedsLimit();
        }
        withdrawalFee = feePercentage;
        emit WithdrawalFeeUpdated(feePercentage);
    }

    /// @notice Sets the address where withdrawal fees are sent.
    /// @param _feeReceiver The address that will receive the withdrawal fees.
    function setFeeReceiver(
        address _feeReceiver
        ) external notZeroAddress(_feeReceiver) onlyRole(WITHDRAWAL_QUEUE_ADMIN_ROLE) {

        emit FeeReceiverUpdated(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  COMPUTATIONS  ------------------------------------
    //--------------------------------------------------------------------------------------

    function calculateRedemptionAmount(
        uint256 amount,
        uint256 redemptionRateAtRequestTime
    ) public view returns (uint256) {
        return amount * redemptionRateAtRequestTime / (10 ** redeemableAsset.decimals());
    }


    /// @notice Calculates the withdrawal fee based on the amount and the current fee percentage.
    /// @param amount The amount from which the fee should be calculated.
    /// @return fee The calculated fee.
    function calculateFee(uint256 amount, uint256 requestWithdrawalFee) public pure returns (uint256) {
        return (amount * requestWithdrawalFee) / FEE_PRECISION;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  REDEMPTION ASSETS  -------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Calculates the surplus of redemption assets after accounting for all pending withdrawals.
    /// @return surplus The amount of surplus redemption assets in the unit of account.
    function surplusRedemptionAssets() public view returns (uint256) {
        uint256 availableAmount = redemptionAssetsVault.availableRedemptionAssets();
        if (availableAmount > pendingRequestedRedemptionAmount) {
            return availableAmount - pendingRequestedRedemptionAmount;
        } 
        
        return 0;
    }

    /// @notice Calculates the deficit of redemption assets after accounting for all pending withdrawals.
    /// @return deficit The amount of deficit redemption assets in the unit of account.
    function deficitRedemptionAssets() public view returns (uint256) {
        uint256 availableAmount = redemptionAssetsVault.availableRedemptionAssets();
        if (pendingRequestedRedemptionAmount > availableAmount) {
            return pendingRequestedRedemptionAmount - availableAmount;
        }
        
        return 0;
    }

    /// @notice Withdraws surplus redemption assets to a specified address.
    function withdrawSurplusRedemptionAssets(uint256 amount) external onlyRole(REDEMPTION_ASSET_WITHDRAWER_ROLE) {
        uint256 surplus = surplusRedemptionAssets();
        if (amount > surplus) {
            revert AmountExceedsSurplus(amount, surplus);
        }
        redemptionAssetsVault.withdrawRedemptionAssets(amount);
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  FINALITY  ----------------------------------------
    //--------------------------------------------------------------------------------------

    /**
     * @notice Checks if a withdrawal request with a given index is finalized.
     * @param index The index of the withdrawal request.
     * @return True if the request is finalized, false otherwise.
     */
    function withdrawalRequestIsFinalized(uint256 index) public view returns (bool) {
        return index < lastFinalizedIndex;
    }

    /**
     * @notice Marks all requests whose index is less than lastFinalizedIndex as finalized.
     * @param _lastFinalizedIndex The index up to which withdrawal requests are considered finalized.
     * @dev A lastFinalizedIndex = 0 means no requests are processed. lastFinalizedIndex = 2 means
            requests 0 and 1 are processed.
     */
    function finalizeRequestsUpToIndex(uint256 _lastFinalizedIndex) external onlyRole(REQUEST_FINALIZER_ROLE) {
        if (_lastFinalizedIndex > _tokenIdCounter) {
            revert IndexExceedsTokenCount(_lastFinalizedIndex, _tokenIdCounter);
        }
        if (_lastFinalizedIndex <= lastFinalizedIndex) {
            revert IndexNotAdvanced(_lastFinalizedIndex, lastFinalizedIndex);
        }
        emit RequestsFinalized(_lastFinalizedIndex, lastFinalizedIndex);

        lastFinalizedIndex = _lastFinalizedIndex;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  VIEWS  -------------------------------------------
    //--------------------------------------------------------------------------------------

    /**
     * @notice Returns the details of a withdrawal request.
     * @param tokenId The token ID of the withdrawal request.
     * @return request The withdrawal request details.
     */
    function withdrawalRequest(uint256 tokenId) public view returns (WithdrawalRequest memory request) {
        request = withdrawalRequests[tokenId];
        if (!withdrawalRequestExists(request)) {
            revert WithdrawalRequestDoesNotExist(tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Checks if a withdrawal request exists.
     * @param request The withdrawal request to check.
     * @return True if the request exists, false otherwise.
     * @dev Reverts with WithdrawalRequestDoesNotExist if the request does not exist.
     */
    function withdrawalRequestExists(WithdrawalRequest memory request) internal view returns (bool) {
        return request.creationTimestamp > 0;
    }

    //--------------------------------------------------------------------------------------
    //----------------------------------  MODIFIERS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Ensure that the given address is not the zero address.
    /// @param _address The address to check.
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
}

