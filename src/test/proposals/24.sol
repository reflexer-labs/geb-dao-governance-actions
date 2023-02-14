pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal24Test is SimulateProposalBase {
    function test_proposal_24() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        address updatedTellorOracle = 0x58881e5bbecA2F1186921Ae86149edaCc717429A;

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
