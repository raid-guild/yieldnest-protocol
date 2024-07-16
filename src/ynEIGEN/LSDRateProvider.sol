// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IwstETH} from "src/external/lido/IwstETH.sol";


interface CoinbaseToken {
    function exchangeRate() external view returns (uint256);
}

struct StaderExchangeRate {
    uint256 block_number;
    uint256 eth_balance;
    uint256 ethx_supply;
}

interface StaderOracle {
    function getExchangeRate() external view returns (StaderExchangeRate memory);
}

interface SwellToken {
    function swETHToETHRate() external view returns (uint256);
}

interface RETHToken {
    function getExchangeRate() external view returns (uint256);
}

contract LSDRateProvider is Initializable {

    //--------------------------------------------------------------------------------------
    //----------------------------------  ERRORS  ------------------------------------------
    //--------------------------------------------------------------------------------------

    error UnsupportedAsset(address asset);

    //--------------------------------------------------------------------------------------
    //----------------------------------  CONSTANTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    uint256 constant UNIT = 1e18;
    address constant COINBASE_ASSET = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704; // cbETH
    address constant FRAX_ASSET = 0xac3E018457B222d93114458476f3E3416Abbe38F; // sfrxETH
    address constant LIDO_ASSET = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0; // wstETH
    address constant STADER_ASSET = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b; // ETHx
    address constant SWELL_ASSET = 0xf951E335afb289353dc249e82926178EaC7DEd78; // swETH
    address constant RETH_ASSET = 0xae78736Cd615f374D3085123A210448E74Fc6393; // RETH
    address constant WOETH_ASSET = 0xDcEe70654261AF21C44c093C300eD3Bb97b78192;

    address constant LIDO_UDERLYING = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // stETH
    address constant STADER_ORACLE = 0xF64bAe65f6f2a5277571143A24FaaFDFC0C2a737;

    //--------------------------------------------------------------------------------------
    //----------------------------------  INITIALIZATION  ----------------------------------
    //--------------------------------------------------------------------------------------

    constructor() {
       _disableInitializers();
    }

    function rate(address _asset) external view returns (uint256) {
        if (_asset == LIDO_ASSET) {
            return IwstETH(LIDO_UDERLYING).getPooledEthByShares(UNIT);
        }
        if (_asset == FRAX_ASSET) {
            return IERC20(FRAX_ASSET).balanceOf(address(this)) * UNIT / IERC20(FRAX_ASSET).totalSupply();
        }
        if (_asset == WOETH_ASSET) {
            return IERC4626(WOETH_ASSET).previewRedeem(UNIT);
        }
        if (_asset == RETH_ASSET) {
            return RETHToken(RETH_ASSET).getExchangeRate();
        }
        if (_asset == COINBASE_ASSET) {
            return CoinbaseToken(COINBASE_ASSET).exchangeRate();
        }
        if (_asset == STADER_ASSET) {
            StaderExchangeRate memory res = StaderOracle(STADER_ORACLE).getExchangeRate();
            return res.eth_balance * UNIT / res.ethx_supply;
        }
        if (_asset == SWELL_ASSET) {
            return SwellToken(SWELL_ASSET).swETHToETHRate();
        }
        revert UnsupportedAsset(_asset);
    }
}
