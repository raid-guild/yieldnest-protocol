// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;


contract ContractAddresses {

    struct YieldNestAddresses {
        address YNETH_ADDRESS;
        address STAKING_NODES_MANAGER_ADDRESS;
        address REWARDS_DISTRIBUTOR_ADDRESS;
        address EXECUTION_LAYER_RECEIVER_ADDRESS;
        address CONSENSUS_LAYER_RECEIVER_ADDRESS;  
    }

    struct EigenlayerAddresses {
        address EIGENPOD_MANAGER_ADDRESS;
        address DELEGATION_MANAGER_ADDRESS;
        address DELEGATION_PAUSER_ADDRESS;
        address STRATEGY_MANAGER_ADDRESS;
        address STRATEGY_MANAGER_PAUSER_ADDRESS;
        address DELAYED_WITHDRAWAL_ROUTER_ADDRESS;
    }

    struct LSDAddresses {
        address SFRXETH_ADDRESS;
        address RETH_ADDRESS;
        address STETH_ADDRESS;
        address RETH_FEED_ADDRESS;
        address STETH_FEED_ADDRESS;
        address RETH_STRATEGY_ADDRESS;
        address STETH_STRATEGY_ADDRESS;
    }

    struct EthereumAddresses {
        address WETH_ADDRESS;
        address DEPOSIT_2_ADDRESS;
    }

    struct ChainAddresses {
        EthereumAddresses ethereum;
        EigenlayerAddresses eigenlayer;
        LSDAddresses lsd;
        YieldNestAddresses yn;
    }

    struct ChainIds {
        uint256 mainnet;
        uint256 holeksy;
    }

    mapping(uint256 => ChainAddresses) public addresses;
    ChainIds public chainIds = ChainIds({
        mainnet: 1,
        holeksy: 17000
    });

    constructor() {
        addresses[chainIds.mainnet] = ChainAddresses({
            ethereum: EthereumAddresses({
                WETH_ADDRESS: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                DEPOSIT_2_ADDRESS: 0x00000000219ab540356cBB839Cbe05303d7705Fa
            }),
            eigenlayer: EigenlayerAddresses({
                EIGENPOD_MANAGER_ADDRESS: 0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338,
                DELEGATION_MANAGER_ADDRESS: 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A,
                DELEGATION_PAUSER_ADDRESS: 0x369e6F597e22EaB55fFb173C6d9cD234BD699111,
                STRATEGY_MANAGER_ADDRESS: 0x858646372CC42E1A627fcE94aa7A7033e7CF075A,
                STRATEGY_MANAGER_PAUSER_ADDRESS: 0xBE1685C81aA44FF9FB319dD389addd9374383e90,
                DELAYED_WITHDRAWAL_ROUTER_ADDRESS: 0x7Fe7E9CC0F274d2435AD5d56D5fa73E47F6A23D8
            }),
            lsd: LSDAddresses({
                SFRXETH_ADDRESS: 0xac3E018457B222d93114458476f3E3416Abbe38F,
                RETH_ADDRESS: 0xae78736Cd615f374D3085123A210448E74Fc6393,
                STETH_ADDRESS: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
                RETH_FEED_ADDRESS: 0x536218f9E9Eb48863970252233c8F271f554C2d0,
                STETH_FEED_ADDRESS: 0x86392dC19c0b719886221c78AB11eb8Cf5c52812,
                RETH_STRATEGY_ADDRESS: 0x1BeE69b7dFFfA4E2d53C2a2Df135C388AD25dCD2,
                STETH_STRATEGY_ADDRESS: 0x93c4b944D05dfe6df7645A86cd2206016c51564D
            }),
            yn: YieldNestAddresses({
                YNETH_ADDRESS: 0x09db87A538BD693E9d08544577d5cCfAA6373A48,
                STAKING_NODES_MANAGER_ADDRESS: 0x8C33A1d6d062dB7b51f79702355771d44359cD7d,
                REWARDS_DISTRIBUTOR_ADDRESS: 0x40d5FF3E218f54f4982661a0464a298Cf6652351,
                EXECUTION_LAYER_RECEIVER_ADDRESS: 0x1D6b2a11FFEa5F9a8Ed85A02581910b3d695C12b,
                CONSENSUS_LAYER_RECEIVER_ADDRESS: 0xE439fe4563F7666FCd7405BEC24aE7B0d226536e
            })
        });

        // In absence of Eigenlayer a placeholder address is used for all Eigenlayer addresses
        address placeholderAddress = address(1);

        addresses[chainIds.holeksy] = ChainAddresses({
            ethereum: EthereumAddresses({
                WETH_ADDRESS: placeholderAddress, // Placeholder address, replaced with address(1) for holesky
                DEPOSIT_2_ADDRESS: 0x4242424242424242424242424242424242424242
            }),
            eigenlayer: EigenlayerAddresses({
                EIGENPOD_MANAGER_ADDRESS: 0xB8d8952f572e67B11e43bC21250967772fa883Ff, // Placeholder address, replaced with address(1) for holesky
                DELEGATION_MANAGER_ADDRESS: 0x75dfE5B44C2E530568001400D3f704bC8AE350CC, // Placeholder address, replaced with address(1) for holesky
                DELEGATION_PAUSER_ADDRESS: 0x28Ade60640fdBDb2609D8d8734D1b5cBeFc0C348, // Placeholder address, replaced with address(1) for holesky
                STRATEGY_MANAGER_ADDRESS: 0xF9fbF2e35D8803273E214c99BF15174139f4E67a, // Placeholder address, replaced with address(1) for holesky
                STRATEGY_MANAGER_PAUSER_ADDRESS: 0x28Ade60640fdBDb2609D8d8734D1b5cBeFc0C348,
                DELAYED_WITHDRAWAL_ROUTER_ADDRESS: 0x642c646053eaf2254f088e9019ACD73d9AE0FA32 // Placeholder address, replaced with address(1) for holesky
            }),
            lsd: LSDAddresses({
                SFRXETH_ADDRESS: placeholderAddress, // Placeholder address, replaced with address(1) for holesky
                RETH_ADDRESS: 0x7322c24752f79c05FFD1E2a6FCB97020C1C264F1, // source: https://docs.rocketpool.net/guides/staking/via-rp
                STETH_ADDRESS: 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034, // source: https://docs.lido.fi/deployed-contracts/holesky/
                RETH_FEED_ADDRESS: 0xC028a945D4Ac8593F84F8dE3784F83143a165F1A, // Self-created aggregator TODO: Update
                STETH_FEED_ADDRESS: 0xC028a945D4Ac8593F84F8dE3784F83143a165F1A, // Self-created aggregator TODO: Update
                RETH_STRATEGY_ADDRESS: 0x3A8fBdf9e77DFc25d09741f51d3E181b25d0c4E0, // Placeholder address, replaced with address(1) for holesky
                STETH_STRATEGY_ADDRESS: 0x7D704507b76571a51d9caE8AdDAbBFd0ba0e63d3 // Placeholder address, replaced with address(1) for holesky
            }),
            yn: YieldNestAddresses({
                YNETH_ADDRESS: 0xd9029669BC74878BCB5BE58c259ed0A277C5c16E,
                STAKING_NODES_MANAGER_ADDRESS: 0xc2387EBb4Ea66627E3543a771e260Bd84218d6a1,
                REWARDS_DISTRIBUTOR_ADDRESS: 0x82915efF62af9FCC0d0735b8681959e069E3f2D8,
                EXECUTION_LAYER_RECEIVER_ADDRESS: 0xA5E9E1ceb4cC1854d0e186a9B3E67158b84AD072,
                CONSENSUS_LAYER_RECEIVER_ADDRESS: 0x706EED02702fFE9CBefD6A65E63f3C2b59B7eF2d
            })
        });
    }

    function getChainAddresses(uint256 chainId) external view returns (ChainAddresses memory) {
        return addresses[chainId];
    }
}
