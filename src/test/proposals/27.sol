pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal27Test is SimulateProposalBase {
    function test_proposal_27() public onlyFork {
        uint256 currentVotingPeriod = 19938; // 2.76 days in 12 second blocks
        uint256 newVotingPeriod = 46500; // 6.45 days in 12 second blocks (this is max period allowed)

        assertEq(governor.votingPeriod(), currentVotingPeriod);

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("_setVotingPeriod(address,uint256)")),
            address(governor),
            newVotingPeriod
        );

        _passProposal(targets, calldatas);

        assertEq(governor.votingPeriod(), newVotingPeriod);
    }
}