// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {console} from "lib/forge-std/src/console.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IwstETH} from "src/external/lido/IwstETH.sol";
import {IynEigen} from "src/interfaces/IynEigen.sol";

import {BaseYnEigenScript} from "script/BaseYnEigenScript.s.sol";

contract DepositStETHToYnLSDe is BaseYnEigenScript {
    IERC20 public stETH;

    Deployment deployment;

    function getWstETH(address _broadcaster, uint256 amount) internal returns (uint256) {
        stETH = IERC20(chainAddresses.ynEigen.STETH_ADDRESS);
        console.log("stETH contract loaded:", address(stETH));

        console.log("Allocating ether to contract:", amount);
        vm.deal(address(this), amount);
        console.log("Depositing ether to stETH contract");
        (bool sent,) = address(stETH).call{value: amount}("");
        require(sent, "Failed to send Ether");
        IwstETH wstETH = IwstETH(chainAddresses.ynEigen.WSTETH_ADDRESS);
        console.log("Approving wstETH contract to spend stETH");
        stETH.approve(address(wstETH), amount);
        console.log("Wrapping stETH to wstETH");
        wstETH.wrap(amount);
        uint256 wstETHBalance = wstETH.balanceOf(_broadcaster);
        console.log("Balance of wstETH:", wstETHBalance);
        return wstETHBalance;
    }

    function run() external {
        deployment = loadDeployment();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address _broadcaster = vm.addr(deployerPrivateKey);

        // solhint-disable-next-line no-console
        console.log("Default Signer Address:", _broadcaster);
        // solhint-disable-next-line no-console
        console.log("Current Block Number:", block.number);
        // solhint-disable-next-line no-console
        console.log("Current Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        uint256 amount = 0.01 ether;

        IwstETH wstETH = IwstETH(chainAddresses.ynEigen.WSTETH_ADDRESS);

        uint256 wstETHBalance = getWstETH(_broadcaster, amount);

        console.log("Depositing wstETH into ynEigen");
        IynEigen ynEigen = IynEigen(deployment.ynEigen);
        wstETH.approve(address(deployment.ynEigen), wstETHBalance);

        // deposit half of it.
        ynEigen.deposit(IERC20(address(wstETH)), wstETHBalance / 2, _broadcaster);

        // //Send wstETH to the specified address

        // address recipient = _broadcaster;
        // uint256 amountToSend = wstETHBalance / 2;

        // console.log("Sending wstETH to:", recipient);
        // console.log("Amount to send:", amountToSend);

        // bool success = wstETH.transfer(recipient, amountToSend);
        // require(success, "Failed to transfer wstETH");

        // console.log("wstETH transfer successful");

        vm.stopBroadcast();

        console.log("Deposit successful");
    }
}
