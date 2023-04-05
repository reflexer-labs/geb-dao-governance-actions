pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract Getter {
    function collateralTypes(
        bytes32
    ) external view virtual returns (uint256, uint256);
}

contract Proposal28Test is SimulateProposalBase {
    function test_proposal_28() public onlyFork {
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        uint256 currentStabilityFee = 1000000000627937192491029810; // 2%
        uint256 newStabilityFee = 1000000000158153903837946258; // .5%

        address taxCollectorOverlay = 0x95f5B549E4FDdde4433Ab20Bae35F97F473f4A6F;
        address gebTaxCollector = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;

        Getter taxCollector = Getter(gebTaxCollector);

        bytes32 ethA = 0x4554482d41000000000000000000000000000000000000000000000000000000;
        bytes32 stabilityFeeParam = 0x73746162696c6974794665650000000000000000000000000000000000000000;

        (uint initialStabilityFee, uint initialUpdateTime) = taxCollector.collateralTypes(ethA);

        assertEq(initialStabilityFee, currentStabilityFee);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(address,bytes32,bytes32,uint256)")),
            address(taxCollectorOverlay),
            ethA,
            stabilityFeeParam,
            newStabilityFee
        );

        _passProposal(targets, calldatas);

        (uint updatedStabilityFee, uint updatedUpdateTime) = taxCollector.collateralTypes(ethA);

        assertEq(updatedStabilityFee, newStabilityFee);
    }
}
