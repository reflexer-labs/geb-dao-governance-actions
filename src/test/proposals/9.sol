pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal9Test is SimulateProposalBase {
    function test_proposal_9() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(0xb5Ed650eF207e051453B68A2138D7cb67CC85E41);

        // packing data for the proposal
        address[] memory targets = new address[](3);
        bytes[] memory calldatas = new bytes[](3);

        address[2] memory receivers = [
            address(0x3E893426E65Cf198D4DF266B77CfA46559c815eE),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e
        ];

        uint[2] memory amounts = [
            uint(290 ether),
            146 ether
        ];


        // dao payroll
        for (uint i; i < receivers.length; ++i) {
            targets[i] = govActions;
            calldatas[i] = abi.encodeWithSelector(
                bytes4(keccak256("transferERC20(address,address,address,uint256)")),
                0x7a97E2a5639f172b543d86164BDBC61B25F8c353, // GEB_DAO_TREASURY
                address(prot),
                receivers[i],
                amounts[i]
            );
        }

        // monthly distro
        targets[2] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[2] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41,                            // Merkle distributor factory
            0x0f016a39f4c56e2b791e157688987514db77cf4c4a8b0933b65f117693a95cfd,    // Merkle root
            0xc9a95ee2964caee600                                                   // Amount distributed - 0xc9a95ee2964caee600
        );

        // fetching previous balances
        uint[2] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        uint256 savedNonce = merkleDistFactory.nonce();

        // propose / execute proposal
        _passProposal(targets, calldatas);

        // testing balances
        for (uint i; i < receivers.length; ++i) {
            assertEq(prot.balanceOf(receivers[i]), prevBalances[i] + amounts[i]);
        }

        // testing distro
        assertEq(savedNonce + 1, merkleDistFactory.nonce());
        MerkleDistributorLike distributor = MerkleDistributorLike(merkleDistFactory.distributors(savedNonce + 1));

        assertEq(distributor.merkleRoot(), 0x0f016a39f4c56e2b791e157688987514db77cf4c4a8b0933b65f117693a95cfd);
        assertEq(prot.balanceOf(address(distributor)), 3719999999991000000000);

        _logData(targets, calldatas);
    }
}