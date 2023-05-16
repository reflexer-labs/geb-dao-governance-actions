pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal32Test is SimulateProposalBase {
    function test_proposal_32() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSignature(
            "executeChange(address)",
            oracleOverlay
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);
    }
}
