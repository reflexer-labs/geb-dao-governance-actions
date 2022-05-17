# Examples

### Change the OSM price source
To build a proposal to change the OSM price source call the ```propose()``` function with the following params:
- ```targets```: [GOV_ACTIONS_CONTRACT_ADDRESS] 
- ```values```: [] (empty) 
- ```signatures```: [] (empty)
- ```calldatas```: ["0x5622b051000000000000000000000000d4a0e3ec2a937e7cca4a192756a8439a8bf4ba910000000000000000000000000000000000000000000000000000000000000abc"]
- ```description```: "Change the OSM Price Source" 

Targets should have the address of the governance actions address.

For calldata computation we are using Seth, on the unit tests of this repo we also logged the calldatas as an example. Other tools such as Ethers.js, Web3.js, Web3.py may be used to compute the calldata. For a point and click solution use [hashex](https://abi.hashex.org/).

```
seth calldata "changePriceSource(address,address)" 0xD4A0E3EC2A937E7CCa4A192756a8439A8BF4bA91 0x0000000000000000000000000000000000000abc
0x5622b051000000000000000000000000d4a0e3ec2a937e7cca4a192756a8439a8bf4ba910000000000000000000000000000000000000000000000000000000000000abc
```

Here Seth is computing the call to changePriceSource with the ETH FSM as target and with the oracle address of ```0x0000000000000000000000000000000000000abc```

### Change ```tokensToAuction``` and ```systemCoinsToRequest``` in the lender of first resort
To build a proposal to change the ``tokensToAuction``` and ```systemCoinsToRequest``` in the lender of first resort call the ```propose()``` function with the following params:
- ```targets```: [GOV_ACTIONS_CONTRACT_ADDRESS, GOV_ACTIONS_CONTRACT_ADDRESS] 
- ```values```: [] (empty) 
- ```signatures```: [] (empty)
- ```calldatas```: ["0xecf987ef000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f673797374656d436f696e73546f526571756573740000000000000000000000000000000000000000000000000000000000000000000000000000000000002710", "0xecf987ef000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f6746f6b656e73546f41756374696f6e000000000000000000000000000000000000000000000000000000000000000000000000000000000000002d79883d2000"]
- ```description```: "Change systemCoinsToRequest to 100, tokensToAuction to 5" 

Targets should have the address of the governance actions address.

For calldata computation we are using Seth, on the unit tests of this repo we also logged the calldatas as an example. Other tools such as Ethers.js, Web3.js, Web3.py may be used to compute the calldata.

```
seth calldata "modifyParameters(address,bytes32,uint256)" 0xE3c80D0e60027BbAf403fAA8A9CF6775C4D416F6 0x73797374656d436f696e73546f52657175657374000000000000000000000000 100000000000000000000000000000000000000000000000
0xecf987ef000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f673797374656d436f696e73546f52657175657374000000000000000000000000000000000000000000000000118427b3b4a05bc8a8a4de845986800000000000

seth calldata "modifyParameters(address,bytes32,uint256)" 0xE3c80D0e60027BbAf403fAA8A9CF6775C4D416F6 0x746f6b656e73546f41756374696f6e0000000000000000000000000000000000 5000000000000000000
0xecf987ef000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f6746f6b656e73546f41756374696f6e00000000000000000000000000000000000000000000000000000000000000000000000000000000004563918244f40000
```

Here Seth is computing the call to modifyParameters with the Staking overlay as target, the parameter name (converted to bytes32) as the second parameters and the value as the last one.

- 0x73797374656d436f696e73546f52657175657374000000000000000000000000: bytes32("systemCoinsToRequest")
- 0x746f6b656e73546f41756374696f6e0000000000000000000000000000000000: bytes32("tokensToAuction")

### Change the oracle in Rate Setter
To build a proposal to change the oracle in rate setter call the ```propose()``` function with the following params:
- ```targets```: [GOV_ACTIONS_CONTRACT_ADDRESS] 
- ```values```: [] (empty) 
- ```signatures```: [] (empty)
- ```calldatas```: ["0xecf987ef000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f673797374656d436f696e73546f526571756573740000000000000000000000000000000000000000000000000000000000000000000000000000000000002710"]
- ```description```: "Change rate setter oracle to 0x0000000000000000000000000000000000000abc" 

Targets should have the address of the governance actions address.

For calldata computation we are using Seth, on the unit tests of this repo we also logged the calldatas as an example. Other tools such as Ethers.js, Web3.js, Web3.py may be used to compute the calldata.

```
seth calldata "modifyParameters(address,bytes32,address)" 0xE3c80D0e60027BbAf403fAA8A9CF6775C4D416F6 0x6f72636c00000000000000000000000000000000000000000000000000000000 0x0000000000000000000000000000000000000abc
0x8eb0ee60000000000000000000000000e3c80d0e60027bbaf403faa8a9cf6775c4d416f66f72636c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000abc

```

Here Seth is computing the call to modifyParameters with the Rate Setter overlay as target, the parameter name (converted to bytes32) as the second parameters and the new oracle address as the last one.

- 0x6f72636c00000000000000000000000000000000000000000000000000000000: bytes32("orcl")


### Connect and disconnect saviours from LiquidationEngine
To build a proposal to connect and disconnect a safe savior in Liquidation Engine call ```propose()``` with the following parameters:
- ```targets```: [GOV_ACTIONS_CONTRACT_ADDRESS, GOV_ACTIONS_CONTRACT_ADDRESS] 
- ```values```: [] (empty) 
- ```signatures```: [] (empty)
- ```calldatas```: ["0xc9cf6de700000000000000000000000093336ba5b2eb5c86cabfaff0da918624107369600000000000000000000000000000000000000000000000000000000000000abc", "0x96074fd200000000000000000000000093336ba5b2eb5c86cabfaff0da918624107369600000000000000000000000000000000000000000000000000000000000000def"]
- ```description```: "Connect saviour 0x0000000000000000000000000000000000000abc, disconnect saviour 0x0000000000000000000000000000000000000def" 

Targets should have the address of the governance actions address.

For calldata computation we are using Seth, on the unit tests of this repo we also logged the calldatas as an example. Other tools such as Ethers.js, Web3.js, Web3.py may be used to compute the calldata.

```
seth calldata "connectSAFESaviour(address,address)" 0x93336ba5b2eb5C86CabFaFf0dA91862410736960 0x0000000000000000000000000000000000000abc 
0xc9cf6de700000000000000000000000093336ba5b2eb5c86cabfaff0da918624107369600000000000000000000000000000000000000000000000000000000000000abc

seth calldata "disconnectSAFESaviour(address,address)" 0x93336ba5b2eb5C86CabFaFf0dA91862410736960 0x0000000000000000000000000000000000000def 
0x96074fd200000000000000000000000093336ba5b2eb5c86cabfaff0da918624107369600000000000000000000000000000000000000000000000000000000000000def
```

Here Seth is computing the call to both connectSAFESaviour and disconnectSAFESaviour with the LiquidationEngine overlay as target, and the saviour address as the last one.
