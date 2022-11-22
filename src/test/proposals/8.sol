pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal8Test is SimulateProposalBase {
    function test_proposal_8() public onlyFork {

        StreamVaultLike streamVault = StreamVaultLike(0x0FA9c7Ad448e1a135228cA98672A0250A2636a47); // GEB_DAO_STREAM_VAULT

        assertTrue(streamVault.streamId() != 0); // active

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("cancelStream(address)")),
            address(streamVault)
        );
        _passProposal(targets, calldatas);

        assertEq(streamVault.streamId(), 0); // cancelled

        _logData(targets, calldatas);
    }
}
