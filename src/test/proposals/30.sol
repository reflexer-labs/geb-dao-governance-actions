pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract FSMLike {
    function reimburseDelay() external view virtual returns (uint256);
    function modifyParameters(bytes32, uint256) external virtual;
}

abstract contract OSMLike {
    function updateResult() external virtual;
    function getResultWithValidity() external view virtual returns (uint256, bool);
}

contract Proposal30Test is SimulateProposalBase {
    function test_proposal_30() public onlyFork {

        address gebFsm = 0x105b857583346E250FBD04a57ce0E491EB204BA3;
        FSMLike fsm = FSMLike(gebFsm);

        address gebOsm = 0xD4A0E3EC2A937E7CCa4A192756a8439A8BF4bA91;
        OSMLike osm = OSMLike(gebOsm);

        uint256 currentReimburseDelay = 3600;
        uint256 newReimburseDelay = 14400;

        uint256 initialReimburseDelay = fsm.reimburseDelay();

        assertEq(initialReimburseDelay, currentReimburseDelay);

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,uint256)")),
            address(fsm),
            bytes32("reimburseDelay"),
            newReimburseDelay
        );

        _passProposal(targets, calldatas);

        uint256 updatedReimburseDelay = fsm.reimburseDelay();

        assertEq(updatedReimburseDelay, newReimburseDelay);

        // Test we can still update the OSM hourly
        osm.updateResult();

        (uint256 firstFeedValue, bool firstFeedValueValidity) = osm.getResultWithValidity();

        assertTrue(firstFeedValueValidity);

        hevm.warp(now + 3600);
        osm.updateResult();

        (uint256 secondFeedValue, bool secondFeedValueValidity) = osm.getResultWithValidity();

        assertTrue(secondFeedValueValidity);

        hevm.warp(now + 3600);
        osm.updateResult();

        (uint256 thirdFeedValue, bool thirdFeedValueValidity) = osm.getResultWithValidity();

        assertTrue(thirdFeedValueValidity);
    }
}
