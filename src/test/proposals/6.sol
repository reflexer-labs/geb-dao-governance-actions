pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

abstract contract GovernorLike {
    function timelock() external virtual view returns (address);
    function _setTimelock(address) external virtual;

}

contract GovernorAdminActions {
    function _setTimelock(address target, address val) external {
        GovernorLike(target)._setTimelock(val);
    }
}

contract Proposal6Test is SimulateProposalBase {
    address constant GEB_PAUSE = 0x2cDE6A1147B0EE61726b86d83Fd548401B1162c7;
    function test_proposal_6() public onlyFork {
        address governorAdminActions = address(new GovernorAdminActions());

        assertEq(address(governor.timelock()), address(pause)); // GEB_UNGOVERNOR_PAUSE

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = governorAdminActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("_setTimelock(address,address)")),
            address(governor),
            GEB_PAUSE
        );
        _passProposal(targets, calldatas);

        assertEq(address(governor.timelock()), GEB_PAUSE); // main protocol pause

        _logData(targets, calldatas);
    }
}
