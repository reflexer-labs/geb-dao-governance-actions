pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal48Test is SimulateProposalBase {
    function test_proposal_50() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        // packing data for the proposal
        address[] memory targets = new address[](4);
        bytes[] memory calldatas = new bytes[](4);

        address[3] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D
        ];

        uint[3] memory amounts = [uint(2236 ether), 2236 ether, 2236 ether];

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
            0x804b19fcb16b3f117054d4e1d74f2db05ca509e810b6c742abddf5e13a34e6fa, // Merkle root
            930000000000000000000 // Amount distributed - 0x326a57b8a619480000
        );

        // fetching previous balances
        uint[3] memory prevBalances;
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
            0x804b19fcb16b3f117054d4e1d74f2db05ca509e810b6c742abddf5e13a34e6fa
        );
        assertEq(prot.balanceOf(address(distributor)), 930000000000000000000);

        _logData(targets, calldatas);
    }
}
