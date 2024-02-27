// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

contract ContractAddresses {
    struct ChainAddresses {
        address WETH_ADDRESS;
        address DEPOSIT_2_ADDRESS;
        address EIGENLAYER_EIGENPOD_MANAGER_ADDRESS;
        address EIGENLAYER_DELEGATION_MANAGER_ADDRESS;
        address EIGENLAYER_STRATEGY_MANAGER_ADDRESS;
        address EIGENLAYER_DELAYED_WITHDRAWAL_ROUTER_ADDRESS;
        address SFRXETH_ADDRESS;
        address RETH_ADDRESS;
        address STETH_ADDRESS;
        // address SFRXETH_FEED_ADDRESS;
        address RETH_FEED_ADDRESS;
        address STETH_FEED_ADDRESS;
        // address SFRXETH_STRATEGY_ADDRESS;
        address RETH_STRATEGY_ADDRESS;
        address STETH_STRATEGY_ADDRESS;
    }

    mapping(uint256 => ChainAddresses) public addresses;

    constructor() {
        addresses[1] = ChainAddresses({
            WETH_ADDRESS: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            DEPOSIT_2_ADDRESS: 0x00000000219ab540356cBB839Cbe05303d7705Fa,
            EIGENLAYER_EIGENPOD_MANAGER_ADDRESS: 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338,
            EIGENLAYER_DELEGATION_MANAGER_ADDRESS: 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A,
            EIGENLAYER_STRATEGY_MANAGER_ADDRESS: 0x858646372CC42E1A627fcE94aa7A7033e7CF075A,
            EIGENLAYER_DELAYED_WITHDRAWAL_ROUTER_ADDRESS: 0x7Fe7E9CC0F274d2435AD5d56D5fa73E47F6A23D8,
            SFRXETH_ADDRESS: 0xac3E018457B222d93114458476f3E3416Abbe38F,
            RETH_ADDRESS: 0xae78736Cd615f374D3085123A210448E74Fc6393,
            STETH_ADDRESS: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            // SFRXETH_FEED_ADDRESS: 0x0000000000000000000000000000000000000000,
            RETH_FEED_ADDRESS: 0x536218f9E9Eb48863970252233c8F271f554C2d0,
            STETH_FEED_ADDRESS: 0x86392dC19c0b719886221c78AB11eb8Cf5c52812,
            // SFRXETH_STRATEGY_ADDRESS: 0x0000000000000000000000000000000000000000,
            RETH_STRATEGY_ADDRESS: 0x1BeE69b7dFFfA4E2d53C2a2Df135C388AD25dCD2,
            STETH_STRATEGY_ADDRESS: 0x93c4b944D05dfe6df7645A86cd2206016c51564D
        });

        addresses[5] = ChainAddresses({
            WETH_ADDRESS: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            DEPOSIT_2_ADDRESS: 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b,
            EIGENLAYER_EIGENPOD_MANAGER_ADDRESS: 0xa286b84C96aF280a49Fe1F40B9627C2A2827df41,
            EIGENLAYER_DELEGATION_MANAGER_ADDRESS: 0x1b7b8F6b258f95Cf9596EabB9aa18B62940Eb0a8,
            EIGENLAYER_STRATEGY_MANAGER_ADDRESS: 0x779d1b5315df083e3F9E94cB495983500bA8E907,
            EIGENLAYER_DELAYED_WITHDRAWAL_ROUTER_ADDRESS: 0x89581561f1F98584F88b0d57c2180fb89225388f,
            SFRXETH_ADDRESS: 0x0000000000000000000000000000000000000000,
            RETH_ADDRESS: 0x0000000000000000000000000000000000000000,
            STETH_ADDRESS: 0x0000000000000000000000000000000000000000,
            // SFRXETH_FEED_ADDRESS: 0x0000000000000000000000000000000000000000,
            RETH_FEED_ADDRESS: 0x0000000000000000000000000000000000000000,
            STETH_FEED_ADDRESS: 0x0000000000000000000000000000000000000000,
            // SFRXETH_STRATEGY_ADDRESS: 0x0000000000000000000000000000000000000000,
            RETH_STRATEGY_ADDRESS: 0x0000000000000000000000000000000000000000,
            STETH_STRATEGY_ADDRESS: 0x0000000000000000000000000000000000000000
        });
    }

    function getChainAddresses(uint256 chainId) external view returns (ChainAddresses memory) {
        return addresses[chainId];
    }

}
