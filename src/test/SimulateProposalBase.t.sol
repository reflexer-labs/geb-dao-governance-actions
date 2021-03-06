pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-token/delegate.sol";
import "ds-vote-quorum/GovernorBravo.sol";
import {DSRoles} from "ds-roles/roles.sol";
import {DSPause} from "ds-vote-quorum/test/mock/DSPauseMock.sol";
import "../GebDaoGovernanceActions.sol";

abstract contract Hevm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external virtual;
    // Set block.height (newHeight)
    function roll(uint256) external virtual;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external virtual returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external virtual;
}

contract SimulateProposalBase is DSTest {
    Hevm hevm;

    GovernorBravo governor = GovernorBravo(0x7a6BBe7fDd793CC9ab7e0fc33605FCd2D19371E8);
    DSDelegateToken prot = DSDelegateToken(0x6243d8CEA23066d098a15582d81a598b4e8391F4);
    DSPause pause = DSPause(0x7ae91003722F29be9e53B09F469543dEFF8Af17d);
    address govActions = 0x1975B38656d65A5a57c7a41d66B054F429487e94;

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

    function _logData(address[] memory targets, bytes[] memory calldatas) internal {
        for (uint i; i < targets.length; ++i) {
            emit log_named_address("target", targets[i]);
            emit log_named_bytes("calldata", calldatas[i]);
        }
    }


}
