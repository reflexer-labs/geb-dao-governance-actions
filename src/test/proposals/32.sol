pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal32Test is SimulateProposalBase {
    function test_proposal_32() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        address oldTellorOracle = 0x2c88408E036B7d0B015B92862c9D93197C72775C;

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSignature(
            "ScheduleChangeTrustedOracle(address,uint8,uint256,address)",
            oracleOverlay,
            uint8(1), // "ChangeType: Remove"
            uint256(1), // 0 = Chainlink, 1 = Existing Tellor, 2 = Updated Tellor
            address(oldTellorOracle)
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);
    }
}
