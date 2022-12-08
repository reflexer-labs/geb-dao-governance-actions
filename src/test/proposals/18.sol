pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract Getter {
    function refillAmount() external view virtual returns (uint256);
}

contract Proposal18 is SimulateProposalBase {
    // Proposed Incentive Adjustments
    // https://community.reflexer.finance/t/october-2022-proposed-incentive-adjustments/374
    //
    // Current Staking Rewards -> 100 FLX / day
    // Proposed First Reduction -> 87.5

    function test_proposal_18() public onlyFork {
        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address stakingRewardRefiller = 0xc5fEcD1080d546F9494884E834b03D7AD208cc02;
        uint256 newRefillAmount = 87500000000000000000;

        Getter stakingRewards = Getter(stakingRewardRefiller);

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSignature(
            "modifyParameters(address,bytes32,uint256)",
            stakingRewardRefiller, // GEB_STAKING_REWARD_REFILLER
            bytes32("refillAmount"),
            newRefillAmount
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);

        // Test updated refillAmount
        uint256 updatedRefillAmount = stakingRewards.refillAmount();

        assertEq(updatedRefillAmount, newRefillAmount);
    }
}
