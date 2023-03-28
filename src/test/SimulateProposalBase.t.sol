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
    SAFEEngineLike safeEngine = SAFEEngineLike(0xCC88a9d330da1133Df3A7bD823B95e52511A6962);
    address govActions = 0x1A82755a497b59B9aB70B6874905305CaCfDaeBA;

    modifier onlyFork() {
        if (now < 1654052400) return; // abort for non fork execution
        _;
    }

    function setUp() public virtual onlyFork {
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
            _logData(targets[i], calldatas[i]);
        }
    }

    function _logData(address target, bytes memory data) internal {
        emit log_named_address("target", target);
        emit log_named_bytes("calldata", data);
    }

    function _setCoinBalance(address to, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (safeEngine.coinBalance(to) == amount) return;

        for (int256 i = 0; i < 200; i++) {
        // Scan the storage for the balance storage slot
        bytes32 prevValue = hevm.load(address(safeEngine), keccak256(abi.encode(to, uint256(i))));
        hevm.store(address(safeEngine), keccak256(abi.encode(to, uint256(i))), bytes32(amount));
        if (safeEngine.coinBalance(to) == amount) {
            // Found it
            return;
        } else {
            // Keep going after restoring the original value
            hevm.store(address(safeEngine), keccak256(abi.encode(to, uint256(i))), prevValue);
        }
        }
        // We have failed if we reach here
        assertTrue(false);
    }

    function _giveAuth(address _base, address target) internal {
        AuthLike base = AuthLike(_base);

        // Edge case - ward is already set
        if (base.authorizedAccounts(target) == 1) return;

        for (int256 i = 0; i < 100; i++) {
        // Scan the storage for the authed account storage slot
        bytes32 prevValue = hevm.load(address(base), keccak256(abi.encode(target, uint256(i))));
        hevm.store(address(base), keccak256(abi.encode(target, uint256(i))), bytes32(uint256(1)));
        if (base.authorizedAccounts(target) == 1) {
            // Found it
            return;
        } else {
            // Keep going after restoring the original value
            hevm.store(address(base), keccak256(abi.encode(target, uint256(i))), prevValue);
        }
        }

        // We have failed if we reach here
        assertTrue(false);
    }
}
