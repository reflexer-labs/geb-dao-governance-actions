pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "ds-vote-quorum/GovernorBravo.sol";

import "./GebDaoGovernanceActions.sol";

abstract contract Hevm {
    function warp(uint) virtual public;
    function roll(uint) public virtual;
}

contract Target {
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address usr) public isAuthorized { authorizedAccounts[usr] = 1; }
    function removeAuthorization(address usr) public isAuthorized { authorizedAccounts[usr] = 0; }
    modifier isAuthorized { require(authorizedAccounts[msg.sender] == 1, "target-unauthorized"); _; }

    bytes public lastReceivedCall;

    fallback() external isAuthorized {
        lastReceivedCall = msg.data;
    }
}

contract GebDaoGovernanceActionsTest is DSTest {
    Hevm hevm;

    GovernorBravo governor;
    DSDelegateToken prot;
    DSPause pause;
    Target target;
    GebDaoGovernanceActions actions;

    // gov params
    uint256 constant quorum = 15000 ether;
    uint256 constant proposalThreshold = 45000 ether;
    uint256 constant votingPeriod = 5760;
    uint256 constant votingDelay = 10000;

    // pause
    uint256 delay = 1 days;    

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.roll(10);

        DSRoles roles = new DSRoles();
        pause = new DSPause(delay, address(this), roles);

        pauseTarget = new Target();
        pauseTarget.addAuthorization(address(pause.proxy()));
        pauseTarget.removeAuthorization(address(this));

        prot = new DSDelegateToken("PROT", "PROT");
        prot.mint(1e6 ether);

        governor = new GovernorBravo(
            address(pause),
            address(prot),
            votingPeriod,
            votingDelay,
            quorum,
            proposalThreshold
        );        

        roles.setAuthority(DSAuthority(roles));
        roles.setRootUser(address(governor), true);
        roles.setOwner(address(pause.proxy()));    

        prot.delegate(address(this));

        actions = new GebDaoGovernanceActions();

        hevm.roll(1);
    }

    function _passProposal(address _target, bytes data) internal {
        hevm.roll(block.number + 1);

        address[] memory targets = new uint[](1)
        targets[0] = _target;
        bytes[] memory calldatas = new uint[](1)
        datas[0] = data;        

        uint proposalId = governor.propose(targets, new uint[](1), new string[](1), calldatas, "test-proposal");

        hevm.roll(block.number + governor.votingDelay() + votingPeriod); // very last block

        governor.castVote(proposalId, true);
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

    // function testFail_basic_sanity() public {
    //     assertTrue(false);
    // }

    // function test_basic_sanity() public {
    //     assertTrue(true);
    // }
}
