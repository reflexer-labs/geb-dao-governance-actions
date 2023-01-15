pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal20Test is SimulateProposalBase {
    function test_proposal_20() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        // TODO: Replace with address of newly deployed Tellor Oracle
        address updatedTellorOracle = 0x1234567890123456789012345678901234567890;

        targets[0] = oracleOverlay;
        calldatas[0] = abi.encodeWithSignature(
            "scheduleChangeTrustedOracle(uint8,uint256,address)",
            uint8(0), // "ChangeType: Add"
            uint256(2), // 0 = Chainlink, 1 = Existing Tellor, 2 = Updated Tellor
            address(updatedTellorOracle)
        );
       
        // propose / execute proposal
        _passProposal(targets, calldatas);
    }
}
