pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract IncreasingRewardRelayerLikeLike {
    function refundRequestor() external virtual returns (address);
}

abstract contract MinimalRateSetterLike {
    function orcl() external virtual returns (address);
}

abstract contract CollateralAuctionHouseLike {
    function systemCoinOracle() external virtual returns (address);
}

abstract contract PoolSaviourLike {
    function systemCoinOrcl() external virtual returns (address);
}

abstract contract DebtAuctionInitialParameterSetterLike {
    function systemCoinOrcl() external virtual returns (address);
}

contract Proposal40Test is SimulateProposalBase {
    function test_proposal_40() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        // packing data for the proposal
        address[] memory targets = new address[](8);
        bytes[] memory calldatas = new bytes[](8);

        address[3] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D
        ];

        uint[3] memory amounts = [uint(1313 ether), 1313 ether, 1898 ether];

        // dao payroll
        for (uint i; i < receivers.length; ++i) {
            targets[i] = govActions;
            calldatas[i] = abi.encodeWithSelector(
                bytes4(
                    keccak256("transferERC20(address,address,address,uint256)")
                ),
                0x7a97E2a5639f172b543d86164BDBC61B25F8c353, // GEB_DAO_TREASURY
                address(prot),
                receivers[i],
                amounts[i]
            );
        }

        // monthly distro
        targets[3] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[3] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41, // Merkle distributor factory
            0x6d86c66aa18d606c9e7640f2955e0618ffbeae7bcf5cc13f575cfcb8b0f7e156, // Merkle root
            1157808333339000000000 // Amount distributed - 0x3ec3d180d722274e00
        );

        // fetching previous balances
        uint[3] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        uint256 savedNonce = merkleDistFactory.nonce();

        // ----------------------------------
        //
        // Oracle Migration to Uni v3 Steps - see: https://community.reflexer.finance/t/oracle-migration-to-uniswap-v3-incentive-adjustments/510/22
        //
        // ----------------------------------

        address oldOracle = 0x92dC9b16be52De059279916c1eF810877f85F960; // RAI ChainlinkTWAP
        address newOracle = 0xcbE170458B8e69147100504D26FFc8f02c1B862F; // ConverterFeed for UNI v3 RAI/ETH TWAP x Chainlink ETH/USD TWAP

        // **********
        //
        // 1. Remove rewards relayer from old contract (chainlink rai feed)
        //    - not needed since refundRequester on the relayer is updated
        //
        // **********

        // **********
        //
        // 2. Add rewards relayer to new oracle (ETH ChainlinkTWAP for RAI Oracle ConverterFeed)
        //    - already done, see: https://etherscan.io/address/0x345000502A9b6c0536C4b1930F1ed75412984AEA#readContract
        //
        // **********

        // **********
        //
        // 3. Update refundRequester on RAI rewards relayer
        //
        // **********
        IncreasingRewardRelayerLikeLike medianizerRaiRewardsRelayer = IncreasingRewardRelayerLikeLike(
                0xE8063b122Bef35d6723E33DBb3446092877C6855
            );
        assertEq(medianizerRaiRewardsRelayer.refundRequestor(), oldOracle);
        // Set new refundRequestor on IncreasingRewardsRelayer
        targets[4] = govActions;
        calldatas[4] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,address)")),
            address(medianizerRaiRewardsRelayer), // IncreasingRewardsRelayer
            0x726566756e64526571756573746f720000000000000000000000000000000000, // "refundRequestor" param
            0x345000502A9b6c0536C4b1930F1ed75412984AEA // Chainlink ETH/USD TWAP for RAI Oracle ConverterFeed
        );

        // **********
        //
        // 4. Update RAI orcl on rate setter
        //
        // **********
        MinimalRateSetterLike piRateSetter = MinimalRateSetterLike(
            0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48
        );
        assertEq(piRateSetter.orcl(), oldOracle);
        // Set new oracle on GEB_RRFM_SETTER
        targets[5] = govActions;
        calldatas[5] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,address)")),
            0x67E38536d8b1eFad846a030B797C00e43364372E, // rate setter overlay
            0x6f72636c00000000000000000000000000000000000000000000000000000000, // "orcl" param
            newOracle
        );

        // **********
        //
        // 5. Update RAI orcl on eth uni v2 pool saviour
        //
        // **********
        PoolSaviourLike poolSaviour = PoolSaviourLike(
            0xA9402De5ce3F1E03Be28871b914F77A4dd5e4364
        );
        assertEq(poolSaviour.systemCoinOrcl(), oldOracle);
        targets[6] = govActions;
        calldatas[6] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,address)")),
            address(poolSaviour), // eth uni v2 pool saviour
            0x73797374656d436f696e4f72636c000000000000000000000000000000000000, // "systemCoinOracle" param
            newOracle
        );

        // **********
        //
        // 6. Update RAI orcle on debt auction intitial param setter
        //
        // **********
        DebtAuctionInitialParameterSetterLike debtAuctionParamSetter = DebtAuctionInitialParameterSetterLike(
                0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E
            );
        assertEq(debtAuctionParamSetter.systemCoinOrcl(), oldOracle);
        targets[7] = govActions;
        calldatas[7] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,address)")),
            0xd3aE3208b6Fc3ec3091923bD8570151a6a4a96a0, // debt auction intitial param setter overlay
            0x73797374656d436f696e4f72636c000000000000000000000000000000000000, // "systemCoinOracle" param
            newOracle
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);

        // 1. Testing update refundRequester on RAI rewards relayer
        assertEq(
            medianizerRaiRewardsRelayer.refundRequestor(),
            0x345000502A9b6c0536C4b1930F1ed75412984AEA // Chainlink ETH/USD TWAP for RAI Oracle ConverterFeed
        );
        // 2. Testing update RAI orcle on rate setter
        assertEq(piRateSetter.orcl(), newOracle);
        // 3. Testing update RAI oracle on eth uni v2 pool saviour
        assertEq(poolSaviour.systemCoinOrcl(), newOracle);
        // 4. Testing update RAI oracle on debt auction intitial param setter
        assertEq(debtAuctionParamSetter.systemCoinOrcl(), newOracle);

        // testing balances
        for (uint i; i < receivers.length; ++i) {
            assertEq(
                prot.balanceOf(receivers[i]),
                prevBalances[i] + amounts[i]
            );
        }

        // testing distro
        assertEq(savedNonce + 1, merkleDistFactory.nonce());
        MerkleDistributorLike distributor = MerkleDistributorLike(
            merkleDistFactory.distributors(savedNonce + 1)
        );

        assertEq(
            distributor.merkleRoot(),
            0x6d86c66aa18d606c9e7640f2955e0618ffbeae7bcf5cc13f575cfcb8b0f7e156
        );
        assertEq(prot.balanceOf(address(distributor)), 1157808333339000000000);

        _logData(targets, calldatas);
    }
}
