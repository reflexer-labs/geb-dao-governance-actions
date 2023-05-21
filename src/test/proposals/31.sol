pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal31Test is SimulateProposalBase {
    function test_proposal_31() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(
                0xb5Ed650eF207e051453B68A2138D7cb67CC85E41
            );

        address streamVault = 0x3d3d2Bd7e8fdbadb26b83a4D9Ee7e3F202F819c0;

        // packing data for the proposal
        address[] memory targets = new address[](7);
        bytes[] memory calldatas = new bytes[](7);

        address[4] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D,
            0x98364Cd83C09d898DAc8638658f03EB72FC2EF8F
            
        ];

        uint[4] memory amounts = [
            uint(736 ether),
            751 ether,
            787 ether,
            501 ether
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
            0x8d61a0f52074682453e299ca22c52d68e83f1cea6dbe3d3da4861d4dc1dd143a, // Merkle root
            929999999993000000000 // Amount distributed - 0x326a57b8a5ddad3600
        );

        uint duration = 3 * 52 weeks;

        // Treasury transfer to stream
        targets[5] = govActions;
        calldatas[5] = abi.encodeWithSelector(
            bytes4(
                keccak256("transferERC20(address,address,address,uint256)")
            ),
            0x7a97E2a5639f172b543d86164BDBC61B25F8c353, // GEB_DAO_TREASURY
            address(prot),
            streamVault, // Stream vault
            3000 ether // Amount distributed
        );

        targets[6] = streamVault;
        calldatas[6] = abi.encodeWithSelector(
            bytes4(keccak256("createStream(address,uint256,address,uint256,uint256)")),
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D,
            3000 ether - (3000 ether % duration),
            address(prot),
            now,
            now + duration
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
            0x8d61a0f52074682453e299ca22c52d68e83f1cea6dbe3d3da4861d4dc1dd143a
        );
        assertEq(prot.balanceOf(address(distributor)), 929999999993000000000);

        testStreamVault(
            streamVault,
            2999 ether,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D
        );

        _logData(targets, calldatas);
    }

    function testStreamVault(address streamVaultAddress, uint256 deposit, address recipient) internal {
        StreamVaultLike streamVault = StreamVaultLike(streamVaultAddress);
        assertTrue(streamVault.streamId() != 0);
        assertLt(prot.balanceOf(address(streamVault)), .00001 ether); // allow for some residual flx due to rounding

        (
            address sender,
            address recipient_,
            uint256 deposit_,
            address token,
            uint256 startTime,
            uint256 stopTime,,
        ) = SablierLike(streamVault.sablier()).getStream(streamVault.streamId());

        assertEq(sender, address(streamVault));
        assertEq(recipient_, recipient);
        assertGt(deposit_, deposit);
        assertEq(token, address(prot));
        assertEq(startTime, now);
        assertEq(stopTime, now + 3 * 52 weeks);
    }
}
