pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

contract Proposal23Test is SimulateProposalBase {
    function test_proposal_23() public onlyFork {
        PIRawPerSecondCalculatorLike controller = PIRawPerSecondCalculatorLike(0x5CC4878eA3E6323FdA34b3D28551E1543DEe54C6); // GEB_RRFM_CALCULATOR

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        int256 newKiValue = (5555 * int256(2.96 ether)) / 10**18; // 16442

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,int256)")),
            address(controller),
            bytes32("ag"),
            newKiValue
        );
        _passProposal(targets, calldatas);

        assertEq(controller.ag(), newKiValue);

        _logData(targets, calldatas);
    }
}
