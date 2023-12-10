pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract LiquidationOverlayLike {
    function authorizedAccounts(address) external virtual returns (uint256);
}

contract Proposal39Test is SimulateProposalBase {
    function test_proposal_39() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        // packing data for the proposal
        address[] memory targets = new address[](7);
        bytes[] memory calldatas = new bytes[](7);

        address[4] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D,
            0x9C8b59443fd54567E33805fb389c3d9B9196ED2E
        ];

        uint[4] memory amounts = [
            uint(1314 ether),
            1314 ether,
            1716 ether,
            394 ether
        ];

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
        targets[4] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[4] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41, // Merkle distributor factory
            0x8e6aecebc5fa01e0368ece30c398492803bddf6da3269b92a48956095d8012bf, // Merkle root
            1240000000007000000000 // Amount distributed - 0x433874f6346d9b8600
        );

        LiquidationOverlayLike liquidationOverlay = LiquidationOverlayLike(
            0xa10C1e933C21315DfcaA8C8eDeDD032BD9b0Bccf
        );

        // Add auth to dusty liquidator
        address dustyLiquidator = 0x87dA6E890F061919738F7AF38fFE7BeE746e2FC1;

        assertEq(liquidationOverlay.authorizedAccounts(dustyLiquidator), 0); // unauthorized

        targets[5] = govActions;
        calldatas[5] = abi.encodeWithSelector(
            bytes4(keccak256("addAuthorization(address,address)")),
            address(liquidationOverlay),
            dustyLiquidator
        );

        DSValueLike gasOracle = DSValueLike(
            0x6a8757d4eC5630EbF86A5DBBe2e65423195a47f4
        ); // GEB_GAS_PRICE_ORACLE_FLOOR_ADJUSTER

        assertEq(gasOracle.read(), 1100 * 10 ** 9); // 1100 gwei

        targets[6] = govActions;
        calldatas[6] = abi.encodeWithSelector(
            bytes4(keccak256("updateResult(address,uint256)")),
            address(gasOracle),
            550 * 10 ** 9 // 550 gwei
        );

        // fetching previous balances
        uint[4] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        uint256 savedNonce = merkleDistFactory.nonce();

        // propose / execute proposal
        _passProposal(targets, calldatas);

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
            0x8e6aecebc5fa01e0368ece30c398492803bddf6da3269b92a48956095d8012bf
        );

        assertEq(prot.balanceOf(address(distributor)), 1240000000007000000000);

        // testing gas price changes
        assertEq(gasOracle.read(), 550 * 10 ** 9); // 550 gwei

        //  testing dusty liquidator auth
        assertEq(liquidationOverlay.authorizedAccounts(dustyLiquidator), 1); // authorized

        _logData(targets, calldatas);
    }
}
