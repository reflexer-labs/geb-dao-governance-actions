pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal21Test is SimulateProposalBase {
    function test_proposal_21() public onlyFork {
        uint256 currentVotingDelay = 1;
        uint256 newVotingDelay = 5760; // 24 hours in 15 second blocks

        assertEq(governor.votingDelay(), currentVotingDelay);

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(governor);
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("_setVotingDelay(uint256)")),
            newVotingDelay
        );

        _passProposal(targets, calldatas);

        assertEq(governor.votingDelay(), newVotingDelay);
    }
}
