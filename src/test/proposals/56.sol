pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal56Test is SimulateProposalBase {
    function test_proposal_56() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        address specialModeOracle = 0x28f23bD36216a7b1b116f935Cc08cA82d5F8f163;

        // packing data for the proposal
        address[] memory targets = new address[](4);
        bytes[] memory calldatas = new bytes[](4);

        address[2] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D
        ];

        uint[2] memory amounts = [uint(5316 ether), 1952 ether];

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
        targets[2] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[2] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41, // Merkle distributor factory
            0x1ddaf6e6059f587e3835cf3f280929690b3e0f6a0c92215321a10378b6c799e6, // Merkle root
            930000000000000000000 // Amount distributed - 0x326a57b8a619480000
        );

        // fetching previous balances
        uint[2] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        uint256 savedNonce = merkleDistFactory.nonce();

        targets[3] = govActions;
        calldatas[3] = abi.encodeWithSignature(
            "ScheduleChangeTrustedOracle(address,uint8,uint256,address)",
            oracleOverlay,
            uint8(0), // "ChangeType: Add"
            uint256(2), // 0 = Chainlink, 1 = Tellor, 2 = Special Mode Oracle
            address(specialModeOracle)
        );

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
            0x1ddaf6e6059f587e3835cf3f280929690b3e0f6a0c92215321a10378b6c799e6
        );
        assertEq(prot.balanceOf(address(distributor)), 930000000000000000000);

        _logData(targets, calldatas);
    }
}
