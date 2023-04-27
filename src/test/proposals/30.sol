pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract FSMLike {
    function reimburseDelay() external view virtual returns (uint256);
    function modifyParameters(bytes32, uint256) external virtual;
}

abstract contract OSMLike {
    function updateResult() external virtual;
    function lastUpdateTime() external view virtual returns (uint64);
}

contract Proposal30Test is SimulateProposalBase {

    function test_proposal_30() public onlyFork {

        address medianizerEth = 0xE2e1Cf7C3A3959157A9b64cAF9675114396d451c;
        FSMLike fsm = FSMLike(0x105b857583346E250FBD04a57ce0E491EB204BA3);
        OSMLike osm = OSMLike(0xD4A0E3EC2A937E7CCa4A192756a8439A8BF4bA91);

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
        
        hevm.store(medianizerEth, bytes32(uint256(2)), bytes32(now));
        osm.updateResult();
        uint firstUpdateTime = osm.lastUpdateTime();

        hevm.warp(now + 5000);
        hevm.store(medianizerEth, bytes32(uint256(2)), bytes32(now));
        osm.updateResult();

        uint secondUpdateTime = osm.lastUpdateTime();
        assertGt(secondUpdateTime, firstUpdateTime);

        hevm.warp(now + 5000);
        hevm.store(medianizerEth, bytes32(uint256(2)), bytes32(now));
        osm.updateResult();

        uint thirdUpdateTime = osm.lastUpdateTime();
        assertGt(thirdUpdateTime, secondUpdateTime);
    }
}
