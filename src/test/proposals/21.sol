pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal21Test is SimulateProposalBase {
    function test_proposal_21() public onlyFork {
        uint256 currentVotingDelay = 1;
        uint256 newVotingDelay = 6600; // 22 hours in 12 second blocks (this is max delay allowed)

        assertEq(governor.votingDelay(), currentVotingDelay);

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("_setVotingDelay(address,uint256)")),
            address(governor),
            newVotingDelay
        );

        _passProposal(targets, calldatas);

        assertEq(governor.votingDelay(), newVotingDelay);
    }
}