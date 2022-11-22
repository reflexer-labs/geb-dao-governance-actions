pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

contract Proposal3Test is SimulateProposalBase {
    function test_proposal_3() public onlyFork {
        // contracts
        StreamVaultLike streamVault = StreamVaultLike(0x0FA9c7Ad448e1a135228cA98672A0250A2636a47);

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        uint256 deposit = 6000 ether;
        deposit = deposit - (deposit % (1751043600 - 1657904400)); // rounding down the value for sablier

        // cheat, minting prot to stramVault
        _giveTokens(address(prot), address(streamVault), deposit);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("createStream(address,address,uint256,address,uint256,uint256)")),
            address(streamVault),
            0x6fa8ea8cB7655895844d6d705B4F9ef825b3FC0F, // recipient
            deposit,
            address(prot),
            1657904400,
            1751043600
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);

        assertTrue(streamVault.streamId() != 0);
        assertEq(prot.balanceOf(address(streamVault)), 0);

        // calldatas[0] = abi.encodeWithSelector(
        //     bytes4(keccak256("cancelStream(address)")),
        //     address(streamVault)
        // );
        // _passProposal(targets, calldatas);

        // assertTrue(streamVault.streamId() == 0);
        // assertEq(prot.balanceOf(address(streamVault)), deposit);

        _logData(targets, calldatas);
    }
}