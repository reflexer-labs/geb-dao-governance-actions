pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-token/delegate.sol";
import "ds-vote-quorum/GovernorBravo.sol";
import {DSRoles} from "ds-roles/roles.sol";
import {DSPause} from "ds-vote-quorum/test/mock/DSPauseMock.sol";
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

    constructor() public {
        authorizedAccounts[msg.sender] = 1;
    }

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
    address govActions;

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

        target = new Target();
        target.addAuthorization(address(pause.proxy()));
        target.removeAuthorization(address(this));

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

        govActions = address(new GebDaoGovernanceActions());
    }
 

    function _passProposal(address _target, bytes memory data) internal {
        hevm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = _target;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;        

        uint proposalId = governor.propose(targets, new uint[](1), new string[](1), calldatas, "test-proposal");

        hevm.roll(block.number + governor.votingDelay() + votingPeriod); // very last block

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

    function test_modify_parameters() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,uint256)")),
            address(target),
            bytes32("test-param"),
            200
        );

        emit log_named_bytes("modifyParameters(address target, bytes32 param, uint256 val):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(bytes32,uint256)")),
                    bytes32("test-param"),
                    200
                )
            )
        );
    }

    function test_modify_parameters2() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,int256)")),
            address(target),
            bytes32("test-param"),
            -200
        );

        emit log_named_bytes("modifyParameters(address target, bytes32 param, int256 val):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(bytes32,int256)")),
                    bytes32("test-param"),
                    -200
                )
            )
        );
    }    

    function test_modify_parameters3() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,address)")),
            address(target),
            bytes32("test-param"),
            address(0xfab)
        );

        emit log_named_bytes("modifyParameters(address target, bytes32 param, address val):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(bytes32,address)")),
                    bytes32("test-param"),
                    address(0xfab)
                )
            )
        );
    }        

    function test_modify_parameters4() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,bytes32,address)")),
            address(target),
            bytes32("test-collateral"),
            bytes32("test-param"),
            address(0xfab)
        );

        emit log_named_bytes("modifyParameters(address target, bytes32 collateralType, bytes32 parameter, address data):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(bytes32,bytes32,address)")),
                    bytes32("test-collateral"),
                    bytes32("test-param"),
                    address(0xfab)
                )
            )
        );
    }    

    function test_modify_parameters5() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,address,bytes32,uint256)")),
            address(target),
            address(0x123),
            bytes32("test-param"),
            123
        );

        emit log_named_bytes("modifyParameters(address target, address reimburser, bytes32 parameter, uint256 data):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(address,bytes32,uint256)")),
                    address(0x123),
                    bytes32("test-param"),
                    123
                )
            )
        );
    }      

    function test_modify_parameters6() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,address,bytes32,address)")),
            address(target),
            address(0x123),
            bytes32("test-param"),
            address(0xfab)
        );

        emit log_named_bytes("modifyParameters(address target, address reimburser, bytes32 parameter, address data):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(address,bytes32,address)")),
                    address(0x123),
                    bytes32("test-param"),
                    address(0xfab)
                )
            )
        );
    }      

    function test_modify_parameters7() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,address,bytes4,bytes32,uint256)")),
            address(target),
            address(0x123),
            this.setUp.selector,
            bytes32("test-param"),
            1234
        );

        emit log_named_bytes("modifyParameters(address target, address fundingTarget, bytes4 fundedFunction, bytes32 parameter, uint256 data):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("modifyParameters(address,bytes4,bytes32,uint256)")),
                    address(0x123),
                    this.setUp.selector,
                    bytes32("test-param"),
                    1234
                )
            )
        );
    }      

    function test_connect_safe_saviour() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("connectSAFESaviour(address,address)")),
            address(target),
            address(0xfab)
        );

        emit log_named_bytes("connectSAFESaviour(address target, address saviour):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("connectSAFESaviour(address)")),
                    address(0xfab)
                )
            )
        );
    }    

    function test_disconnect_safe_saviour() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("disconnectSAFESaviour(address,address)")),
            address(target),
            address(0xfab)
        );

        emit log_named_bytes("disconnectSAFESaviour(address target, address saviour):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("disconnectSAFESaviour(address)")),
                    address(0xfab)
                )
            )
        );
    }       

    function test_transfer_erc20() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("transferERC20(address,address,address,uint256)")),
            address(target),
            address(prot),
            address(0xfab),
            1000
        );

        emit log_named_bytes("transferERC20(address target, address token, address dst, uint256 amount):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("transferERC20(address,address,uint256)")),
                    address(prot),
                    address(0xfab),
                    1000
                )
            )
        );
    }      

    function test_restart_redemption_rate() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("restartRedemptionRate(address)")),
            address(target)
        );

        emit log_named_bytes("restartRedemptionRate(address target):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("restartRedemptionRate()"))
                )
            )
        );
    }  

    function test_change_price_source() public {
        bytes memory proposalCalldata = abi.encodeWithSelector(
            bytes4(keccak256("changePriceSource(address,address)")),
            address(target),
            address(0xfab)
        );

        emit log_named_bytes("changePriceSource(address target, address source):", proposalCalldata);
        _passProposal(
            govActions,
            proposalCalldata
        );

        assertEq(
            keccak256(target.lastReceivedCall()),
            keccak256(
                abi.encodeWithSelector(
                    bytes4(keccak256("changePriceSource(address)")),
                    address(0xfab)
                )
            )
        );
    }                    

}
