// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {TransparentUpgradeableProxy} from "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {BaseScript} from "script/BaseScript.s.sol";
import {PooledDepositsVault} from "src/PooledDepositsVault.sol"; // Renamed from PooledDeposits to PooledDepositsVault
import {ActorAddresses} from "script/Actors.sol";
import {console} from "lib/forge-std/src/console.sol";

contract Upgrade is BaseScript {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // ynETH.sol ROLES
        ActorAddresses.Actors memory actors = getActors();

        PooledDepositsVault[] memory pooledDepositsVaults = new PooledDepositsVault[](5); // Renamed from PooledDeposits to PooledDepositsVault
        vm.startBroadcast(deployerPrivateKey);

        PooledDepositsVault pooledDepositsVaultImplementation = new PooledDepositsVault(); // Renamed from PooledDeposits to PooledDepositsVault
        for (uint i = 0; i < 5; i++) {
            bytes memory initData = abi.encodeWithSelector(PooledDepositsVault.initialize.selector, actors.ops.POOLED_DEPOSITS_OWNER); // Renamed from PooledDeposits to PooledDepositsVault
            TransparentUpgradeableProxy pooledDepositsVaultProxy = new TransparentUpgradeableProxy(address(pooledDepositsVaultImplementation), actors.PROXY_ADMIN_OWNER, initData);
            PooledDepositsVault pooledDepositsVault = PooledDepositsVault(payable(address(pooledDepositsVaultProxy))); // Renamed from PooledDeposits to PooledDepositsVault
            pooledDepositsVaults[i] = pooledDepositsVault;
        }
        savePooledDepositsDeployment(pooledDepositsVaults);
        vm.stopBroadcast();
    }

    function savePooledDepositsDeployment(PooledDepositsVault[] memory pooledDepositsVaults) internal { // Renamed from PooledDeposits to PooledDepositsVault
        string memory json = "pooledDepositsVaultsDeployment";
        for (uint i = 0; i < pooledDepositsVaults.length; i++) {
            vm.serializeAddress(json, vm.toString(i), address(pooledDepositsVaults[i]));
        }
        vm.writeJson(json, getDeploymentFile());
    }
}
