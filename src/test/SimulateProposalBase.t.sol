pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-token/delegate.sol";
import {GovernorBravo} from "ds-vote-quorum/GovernorBravo.sol";
import {DSRoles} from "ds-roles/roles.sol";
import {DSPause} from "ds-vote-quorum/test/mock/DSPauseMock.sol";
import "../GebDaoGovernanceActions.sol";
import "./Interfaces.sol";

contract SimulateProposalBase is DSTest {
    Hevm hevm;

    GovernorBravo governor = GovernorBravo(0x7a6BBe7fDd793CC9ab7e0fc33605FCd2D19371E8);
    DSDelegateToken prot = DSDelegateToken(0x6243d8CEA23066d098a15582d81a598b4e8391F4);
    DSPause pause = DSPause(0x7ae91003722F29be9e53B09F469543dEFF8Af17d);
    address govActions = 0xC4E0060A723a927cDfbface7616CC3B0cb4eF938;

    modifier onlyFork() {
        if (now < 1654052400) return; // abort for non fork execution
        _;
    }

    function setUp() public onlyFork {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        // cheat, minting FLX to this contract in order to propose/vote
        _giveTokens(address(prot), address(this), 1.2e5 ether);
        prot.delegate(address(this));
    }

    function _giveTokens(
        address token_,
        address to,
        uint256 amount
    ) internal {
        DSDelegateToken token = DSDelegateToken(token_);
        // Edge case - balance is already set for some reason
        if (token.balanceOf(to) == amount) return;

        for (int256 i = 0; i < 200; i++) {
        // Scan the storage for the balance storage slot
        bytes32 prevValue = hevm.load(address(token), keccak256(abi.encode(to, uint256(i))));
        hevm.store(address(token), keccak256(abi.encode(to, uint256(i))), bytes32(amount));
        if (token.balanceOf(to) == amount) {
            // Found it
            return;
        } else {
            // Keep going after restoring the original value
            hevm.store(address(token), keccak256(abi.encode(to, uint256(i))), prevValue);
        }
        }

        // We have failed if we reach here
        assertTrue(false);
    }


    function _passProposal(address[] memory targets, bytes[] memory calldatas) internal {
        hevm.roll(block.number + 1);

        uint proposalId = governor.propose(targets, new uint[](1), new string[](1), calldatas, "test-proposal");

        hevm.roll(block.number + governor.votingDelay() + governor.votingPeriod()); // very last block

        governor.castVote(proposalId, 1);
        hevm.roll(block.number + 1);
        governor.queue(proposalId);
        hevm.warp(now + pause.delay());
        governor.execute(proposalId);

        {
            (
                ,,,,,,,,
                bool canceled,
                bool executed
            ) = governor.proposals(proposalId);
            assertTrue(!canceled);
            assertTrue(executed);
        }
    }

    function _passProposal(address target, bytes memory data) internal {
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = target;
        calldatas[0] = data;
        _passProposal(targets, calldatas);
    }

    function _logData(address[] memory targets, bytes[] memory calldatas) internal {
        for (uint i; i < targets.length; ++i) {
            emit log_named_address("target", targets[i]);
            emit log_named_bytes("calldata", calldatas[i]);
        }
    }

    function _logData(address target, bytes memory data) internal {
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = target;
        calldatas[0] = data;
        _logData(targets, calldatas);
    }
}
