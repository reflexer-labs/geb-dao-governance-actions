pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

contract Proposal49Test is SimulateProposalBase {
    function test_proposal_49() public onlyFork {
        PIRawPerSecondCalculatorLike controller = PIRawPerSecondCalculatorLike(
            0x5CC4878eA3E6323FdA34b3D28551E1543DEe54C6
        ); // GEB_RRFM_CALCULATOR

        address[] memory targets = new address[](3);
        bytes[] memory calldatas = new bytes[](3);

        // RAI Controller = https://etherscan.io/address/0x5cc4878ea3e6323fda34b3d28551e1543dee54c6
        // HAI Controller = https://optimistic.etherscan.io/address/0x6f9aeC3c0DF4DF7A0Da66453a38B8C767972f609

        // Current RAI values
        // KP = sg = 222002205862
        // KI = ag = 16442
        // decay = pscl = 999999711200000000000000000

        // Current RAI values
        // KI = ag = 222002205862
        // KP = sg = 16442
        // decay = pscl = 999999711200000000000000000

        // Currrent HAI values
        // KI = 13785
        // KP = 154712579997
        // decay 999999910860706061391497541

        int256 newKiValue = 13785;
        int256 newKpValue = 154712579997;
        uint256 newDecayValue = 999999910860706061391497541;

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,int256)")),
            address(controller),
            bytes32("ag"),
            newKiValue
        );

        targets[1] = govActions;
        calldatas[1] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,int256)")),
            address(controller),
            bytes32("sg"),
            newKpValue
        );

        targets[2] = govActions;
        calldatas[2] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,uint256)")),
            address(controller),
            bytes32("pscl"),
            newDecayValue
        );

        _passProposal(targets, calldatas);

        assertEq(controller.ag(), newKiValue);
        assertEq(controller.sg(), newKpValue);
        assertEq(controller.pscl(), newDecayValue);

        _logData(targets, calldatas);
    }
}
