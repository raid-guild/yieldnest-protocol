// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import { IntegrationBaseTest } from "test/integration/IntegrationBaseTest.sol";
import { Invariants } from "test/scenarios/Invariants.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { TestAssetUtils } from "test/utils/TestAssetUtils.sol";

contract YnLSDScenarioTest1 is IntegrationBaseTest {

	/**
	Scenario 1: Successful LSD Deposit and Share Minting 
	Objective: Test that a user can deposit stETH and receive 
	the correct amount of shares in return.
	*/

	function test_ynLSD_Scenario_1_Fuzz(uint256 amount1, uint256 amount2, uint256 amount3) public {

		/**
		Users deposit random amounts
		- Check the total assets of ynLSD
		- Check the share balance of each user
		- Check total supply of ynLSD
		*/

		address asset = chainAddresses.lsd.STETH_ADDRESS;

		User_stETH_deposit(asset, amount1, address(0x01));
		User_stETH_deposit(asset, amount2, address(0x02));
		User_stETH_deposit(asset, amount3, address(0x03));
	}

	function User_stETH_deposit(address asset, uint256 amount, address user) public {
		
		vm.assume(amount > 1 && amount < 10_000 ether);

		uint256 previousTotalShares = ynlsd.totalSupply();
		uint256 previousTotalAssets = ynlsd.getTotalAssets()[0];

		vm.startPrank(user);
		// 1. Obtain stETH and Deposit assets to ynLSD by User
		TestAssetUtils testAssetUtils = new TestAssetUtils();
		IERC20 stETH = IERC20(asset);
		uint256 userDeposit = testAssetUtils.get_stETH(address(this), amount);

		stETH.approve(address(ynlsd), userDeposit);
		ynlsd.deposit(stETH, userDeposit, user);

		uint256 userShares = ynlsd.balanceOf(user);

		uint256 currentTotalAssets = ynlsd.getTotalAssets()[0];
		uint256 currentTotalShares = ynlsd.totalSupply();

		runInvariants(
			user, 
			previousTotalAssets, 
			previousTotalShares,
			currentTotalAssets,
			currentTotalShares,
			userDeposit, 
			userShares
		);
	}

	function runInvariants(
		address user, 
		uint256 previousTotalAssets,
		uint256 previousTotalShares,
		uint256 currentTotalAssets,
		uint256 currentTotalShares,
		uint256 userDeposit,
		uint256 userShares
	) public  view{
		Invariants.totalAssetsIntegrity(currentTotalAssets, previousTotalAssets, userDeposit);
		Invariants.shareMintIntegrity(currentTotalShares, previousTotalShares, userShares);
		Invariants.userSharesIntegrity(ynlsd.balanceOf(user), 0, userShares);
	}
}