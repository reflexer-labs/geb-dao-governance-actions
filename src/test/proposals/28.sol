pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract Getter {
    function collateralTypes(
        bytes32
    ) external view virtual returns (uint256, uint256);
}

// abstract contract Setter {
//      function modifyParameters (bytes32, bytes32, uint256) external virtual;
// }

contract Proposal28Test is SimulateProposalBase {
    function test_proposal_28() public onlyFork {
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        uint256 currentStabilityFee = 1000000000627937192491029810;
        uint256 newStabilityFee = 500000000000000000000000000;

        address taxCollectorOverlay = 0x95f5B549E4FDdde4433Ab20Bae35F97F473f4A6F;
        address gebTaxCollector = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;

        address stakingRewardRefiller = 0xc5fEcD1080d546F9494884E834b03D7AD208cc02;
        uint256 newRefillAmount = 87500000000000000000;

        Getter taxCollector = Getter(gebTaxCollector);

        bytes32 ethA = 0x4554482d41000000000000000000000000000000000000000000000000000000;

        (uint initialStabilityFee, uint initialUpdateTime) = taxCollector.collateralTypes(ethA);

        log_uint(initialStabilityFee);
        log_uint(initialUpdateTime);

        assertEq(initialStabilityFee, currentStabilityFee);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSelector(
            bytes4(keccak256("modifyParameters(bytes32,bytes32,uint256)")),
            address(taxCollectorOverlay),
            newStabilityFee
        );

        // _passProposal(targets, calldatas);

        // assertEq(governor.votingPeriod(), newVotingPeriod);
    }
}
