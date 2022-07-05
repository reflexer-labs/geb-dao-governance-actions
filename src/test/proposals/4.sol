pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

abstract contract MinterLike{
    function mint() external virtual view;
}

contract Proposal4Test is SimulateProposalBase {
    function test_proposal_4() public onlyFork {
        // contracts
        MinterLike minter = MinterLike(0xB5B59Ed1C679B5A955BF7eFfC6628d5f4b7CA7f3);

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("mint(address)")),
            address(minter)
        );
        // _passProposal(targets, calldatas); // reverting unauthed

        _logData(targets, calldatas);
    }
}