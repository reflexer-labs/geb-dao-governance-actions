pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal19Test is SimulateProposalBase {
    function test_proposal_19() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        // packing data for the proposal
        address[] memory targets = new address[](7);
        bytes[] memory calldatas = new bytes[](7);

        address[6] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D,
            0x7d35123708064B7f51ef481481cdF90cf30125C3,
            0xcdED4644E025E9792352CEe1B31F410Adb7c9FC6,
            0xe67eFC40FF03395aC23D936489eaf25e6d4EB5b7
        ];

        uint[6] memory amounts = [
            uint(847 ether),
            424 ether,
            313 ether,
            593 ether,
            17 ether,
            76 ether
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
        targets[6] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[6] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41, // Merkle distributor factory
            0xeb6e78872607e7b8232c871311b7893b5a59b122b7a0b078b020691ba88a6a8d, // Merkle root
            4795500000001000000000 // Amount distributed - 0xc9a95ee2964caee600
        );

        // fetching previous balances
        uint[6] memory prevBalances;
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
        MerkleDistributorLike distributor = MerkleDistributorLike(
            merkleDistFactory.distributors(savedNonce + 1)
        );

        assertEq(
            distributor.merkleRoot(),
            0xeb6e78872607e7b8232c871311b7893b5a59b122b7a0b078b020691ba88a6a8d
        );
        assertEq(prot.balanceOf(address(distributor)), 4795500000001000000000);

        _logData(targets, calldatas);
    }
}
