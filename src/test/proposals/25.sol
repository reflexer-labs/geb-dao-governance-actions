pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal25Test is SimulateProposalBase {
    function test_proposal_25() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSignature(
            "ScheduleChangeTrustedOracle(address,ChangeType,uint256,address)",
            uint8(0), // "ChangeType: Add"
            uint256(2), // 0 = Chainlink, 1 = Existing Tellor, 2 = Updated Tellor
            address(updatedTellorOracle)
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);
    }
}
