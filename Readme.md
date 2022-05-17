# GEB DAO Governance Actions

This repository contains a governance actions contract for all RAI parameters that are still governed after ungovernance.

The contract is deployed at: TBD (Mainnet)

## Differences present in the RAI Governor

The Reflexer governor contract differs from the original Compound implementation. Slight changes were made to it so it integrates with DSPause (the original timelock inherited from DSS).

The main difference in it is the fact that the DSPause executes transactions by delegatecalling another contract instead of direct calls as made by the Compound timelock. This contract contains the logic for all possible calls.

## Steps to create a proposal

The interface of the ```propose()``` function in the governor was kept the same for compatibility reasons, but the usage is slightly different, the arrays ```values``` and ```signatures``` are ignored, only ```targets``` (the gov actions address), ```calldatas``` (the calldata of the calls) and description should be filled. Up to ten actions can be included in a proposal.

Check examples in the file examples.md