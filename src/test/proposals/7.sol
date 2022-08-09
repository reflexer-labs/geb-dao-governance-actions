pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./6.sol";
import "../../GebDaoGovernanceActions.sol";


contract Proposal7Test is Proposal6Test {
    function test_proposal_7() public onlyFork {

        DSValueLike gasOracle = DSValueLike(0x6a8757d4eC5630EbF86A5DBBe2e65423195a47f4); // GEB_GAS_PRICE_ORACLE_FLOOR_ADJUSTER

        assertEq(gasOracle.read(), 1000 * 10**9); // 1000 gwei

        // packing data for the proposal
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("updateResult(address,uint256)")),
            address(gasOracle),
            1100 * 10**9 // 1100 gwei
        );
        _passProposal(targets, calldatas);

        assertEq(gasOracle.read(), 1100 * 10**9); // 1100 gwei

        _logData(targets, calldatas);
    }
}
