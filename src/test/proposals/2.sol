pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal2Test is SimulateProposalBase {
    function test_proposal_2() public onlyFork {
        // packing data for the proposal
        address[] memory targets = new address[](2);
        bytes[] memory calldatas = new bytes[](2);

        address[2] memory receivers = [
            address(0x3E893426E65Cf198D4DF266B77CfA46559c815eE),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e
        ];

        uint[2] memory amounts = [
            uint(1000 ether),
            500 ether
        ];

        for (uint i; i < receivers.length; ++i) {
            targets[i] = govActions;
            calldatas[i] = abi.encodeWithSelector(
                bytes4(keccak256("transferERC20(address,address,address,uint256)")),
                0x7a97E2a5639f172b543d86164BDBC61B25F8c353, // GEB_DAO_TREASURY
                address(prot),
                receivers[i],
                amounts[i]
            );
        }

        // fetching previous balances
        uint[2] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        // propose / execute proposal
        _passProposal(targets, calldatas);

        for (uint i; i < receivers.length; ++i) {
            assertEq(prot.balanceOf(receivers[i]), prevBalances[i] + amounts[i]);
        }

        _logData(targets, calldatas);
    }
}