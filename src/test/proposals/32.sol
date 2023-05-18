pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";



abstract contract OSMLike {
    function currentOracle() external view virtual returns (address);
    function read() virtual external view returns (uint256);
    function trustedOracles(uint256) external view virtual returns (uint256);
}

enum ChangeType {Add, Remove, Replace}

contract Proposal32Test is SimulateProposalBase {
    function test_proposal_32() public onlyFork {

        address[] memory targets = new address[](1);
        bytes[] memory calldatas = new bytes[](1);

        address oracleOverlay = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

        address updatedTellorOracle = 0x58881e5bbecA2F1186921Ae86149edaCc717429A;
        address oldTellorOracle = 0x2c88408E036B7d0B015B92862c9D93197C72775C;

        OSMLike osm = OSMLike(oracleOverlay);

        uint readValue = osm.read();
        address currentItem = osm.currentOracle();

        // uint oracleCount = osm.trustedOracles().length;
        // address[] memory trustedOracles = osm.trustedOracles();
        // address[] memory trustedOracles;
        uint currentOracle = osm.trustedOracles(1);


        

        // trustedOracles = osm.trustedOracles();

        log_named_uint("readValue", readValue);
        log_named_uint("currentOracle", currentOracle);
        
        
        log_named_address("currentItem", currentItem);
        // log_named_uint("oracleCount", oracleCount);

        // address[] memory trustedOracles = oracleOverlay.trustedOracles;
        // log_string("initialOracleCount");

        targets[0] = govActions;
        calldatas[0] = abi.encodeWithSignature(
            "ScheduleChangeTrustedOracle(address,uint8,uint256,address)",
            oracleOverlay,
            uint8(1), // "ChangeType: Add"
            uint256(1), // 0 = Chainlink, 1 = Existing Tellor, 2 = Updated Tellor
            address(oldTellorOracle)
        );

        // propose / execute proposal
        _passProposal(targets, calldatas);
    }
}
