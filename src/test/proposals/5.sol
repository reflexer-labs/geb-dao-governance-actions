pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";
import "../../GebDaoGovernanceActions.sol";

abstract contract TokenLike {
    function balanceOf(address) public virtual view returns (uint256);
}

abstract contract StreamVaultLike {
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external virtual;
    function cancelStream() external virtual;
    function sablier() external virtual view returns (address);
    function streamId() external virtual view returns (uint256);
}

contract GebDaoStreamVaultRescheduler {

    // @notice Cancels current stream and creates a new stream with all tokens available in the streamVault
    function reschedule(address target, address recipient, address tokenAddress, uint256 startTime, uint256 stopTime) external {
        // cancel previous stream
        StreamVaultLike(target).cancelStream();

        // rounding the value for Sablier
        uint256 balance = TokenLike(tokenAddress).balanceOf(target);
        uint256 deposit = balance - (balance % (stopTime - startTime));

        // create new stream
        StreamVaultLike(target).createStream(recipient, deposit, tokenAddress, startTime, stopTime);
    }
}

abstract contract SablierLike {
    function getStream(uint256 streamId)
        external
        virtual
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );
}

contract Proposal5Test is SimulateProposalBase {
    function test_proposal_5() public onlyFork {
        // contracts
        StreamVaultLike streamVault = StreamVaultLike(0x0FA9c7Ad448e1a135228cA98672A0250A2636a47);

        uint256 previousStreamId = streamVault.streamId();

        GebDaoStreamVaultRescheduler rescheduler = GebDaoStreamVaultRescheduler(0xfAD2b06785f46bC17E497e10b5182623165Aa4E7);

        address recipient = 0x3E893426E65Cf198D4DF266B77CfA46559c815eE;

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(rescheduler);
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("reschedule(address,address,address,uint256,uint256)")),
            address(streamVault),
            recipient,
            address(prot),
            1659636000,
            1751047200
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);

        assertTrue(streamVault.streamId() != previousStreamId);
        assertLt(prot.balanceOf(address(streamVault)), .00001 ether); // allow for some residual flx due to rounding

        (
            address sender,
            address recipient_,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,,
        ) = SablierLike(streamVault.sablier()).getStream(streamVault.streamId());

        assertEq(sender, address(streamVault));
        assertEq(recipient_, recipient);
        assertGt(deposit, 5900 ether);
        assertEq(token, address(prot));
        assertEq(startTime, 1659636000);
        assertEq(stopTime, 1751047200);

        _logData(targets, calldatas);
    }
}