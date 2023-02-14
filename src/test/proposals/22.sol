pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

abstract contract StakingLike {
    function modifyParameters(bytes32, uint256) external virtual;
    function toggleForcedExit() external virtual;
    function toggleBypassAuctions() external virtual;
}

abstract contract StakingRefillLike {
    function transferTokenOut(address, uint256) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
}

abstract contract ERC20Like {
    function balanceOf(address) external virtual view returns (uint256);
}

contract Proposal22 {
    StakingLike constant stakingOverlay = StakingLike(0xcC8169c51D544726FB03bEfD87962cB681148aeA);
    StakingRefillLike constant stakingRefill = StakingRefillLike(0xc5fEcD1080d546F9494884E834b03D7AD208cc02);
    StakingRefillLike constant stakingDripper = StakingRefillLike(0x03da3D5E0b13b6f0917FA9BC3d65B46229d7Ef47);
    ERC20Like constant protocolToken = ERC20Like(0x6243d8CEA23066d098a15582d81a598b4e8391F4);


    function execute() public {
        // toggleBypassAuctions - prevent auctions from starting
        stakingOverlay.toggleBypassAuctions();

        // set minStakedTokensToKeep to max (250k) // will prevent auctions from starting (current amount is 10k, cannot increase)
        stakingOverlay.modifyParameters("minStakedTokensToKeep", 250000 ether);

        // toggleForcedExit - allows exiting even if system becomes underwater
        stakingOverlay.toggleForcedExit();

        // optional: prevent locking of rewards. (modifyParams escrowPaused to 1)
        stakingOverlay.modifyParameters("escrowPaused", 1);

        // transfer all rewards to the dao treasury
        stakingRefill.transferTokenOut(0x7a97E2a5639f172b543d86164BDBC61B25F8c353, protocolToken.balanceOf(address(stakingRefill))); // GEB_DAO_TREASURY

        // transfer all rewards to the dao treasury
        stakingDripper.transferTokenOut(0x7a97E2a5639f172b543d86164BDBC61B25F8c353, protocolToken.balanceOf(address(stakingDripper))); // GEB_DAO_TREASURY

        // updating emission to 10FLX/day
        stakingDripper.modifyParameters("rewardPerBlock", uint(10 ether) / 7200); // 7200 blocks per day, considering post merge 12s block time
        stakingDripper.modifyParameters("rewardCalculationDelay", uint(-1));      // This is to prevent the emission rate from being upgraded by anyone

        // notes: What is not being done because params are ungoverned:
        // - exit delay cannot be changed, 3 week lock will be forced still
        // - cannot prevent other users from joining
        // - rewards will keep on being paid at the current rate until the balance of the staking contract is depleted. It has no risk now, so it can be seen as a liquidity incenive for ETH/FLX.
    }
}

contract Guy {
    DebtAuctionHouseLike debtAuctionHouse;
    constructor(DebtAuctionHouseLike debtAuctionHouse_) public {
        debtAuctionHouse = debtAuctionHouse_;
        SAFEEngineLike(address(debtAuctionHouse.safeEngine())).approveSAFEModification(address(debtAuctionHouse));
        TokenLike(address(debtAuctionHouse.protocolToken())).approve(address(debtAuctionHouse), uint(-1));
    }
    function decreaseSoldAmount(uint id, uint amountToBuy, uint bid) public {
        debtAuctionHouse.decreaseSoldAmount(id, amountToBuy, bid);
    }
    function settleAuction(uint id) public {
        debtAuctionHouse.settleAuction(id);
    }
    function try_decreaseSoldAmount(uint id, uint amountToBuy, uint bid)
        public returns (bool ok)
    {
        string memory sig = "decreaseSoldAmount(uint256,uint256,uint256)";
        (ok,) = address(debtAuctionHouse).call(abi.encodeWithSignature(sig, id, amountToBuy, bid));
    }
    function try_settleAuction(uint id)
        public returns (bool ok)
    {
        string memory sig = "settleAuction(uint256)";
        (ok,) = address(debtAuctionHouse).call(abi.encodeWithSignature(sig, id));
    }
    function try_restart_auction(uint id)
        public returns (bool ok)
    {
        string memory sig = "restartAuction(uint256)";
        (ok,) = address(debtAuctionHouse).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {
    uint256 public totalOnAuctionDebt;

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function startAuction(DebtAuctionHouseLike debtAuctionHouse, uint amountToSell, uint initialBid) external returns (uint) {
        totalOnAuctionDebt += initialBid;
        uint id = debtAuctionHouse.startAuction(address(this), amountToSell, initialBid);
        return id;
    }
    function cancelAuctionedDebtWithSurplus(uint rad) external {
        totalOnAuctionDebt = sub(totalOnAuctionDebt, rad);
    }
    function disableContract(DebtAuctionHouseLike debtAuctionHouse) external {
        debtAuctionHouse.disableContract();
    }
}

contract Proposal22Test is SimulateProposalBase {
    GebLenderFirstResortRewardsVested staking = GebLenderFirstResortRewardsVested(0x69c6C08B91010c88c95775B6FD768E5b04EFc106);
    AccountingEngineLike accountingEngine = AccountingEngineLike(0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE);
    DebtAuctionHouseLike debtAuctionHouse = DebtAuctionHouseLike(0x1896adBE708bF91158748B3F33738Ba497A69e8f);
    DSTokenLike protocolToken = DSTokenLike(0x6243d8CEA23066d098a15582d81a598b4e8391F4);
    DSTokenLike stakedToken = DSTokenLike(0xd6F3768E62Ef92a9798E5A8cEdD2b78907cEceF9);
    StakeRefillerLike constant stakingRefill = StakeRefillerLike(0xc5fEcD1080d546F9494884E834b03D7AD208cc02);
    StakeRefillerLike constant stakingDripper = StakeRefillerLike(0x03da3D5E0b13b6f0917FA9BC3d65B46229d7Ef47);

    function setUp() override public onlyFork {
        super.setUp();

        // packing data for the proposal
        address target = address(new Proposal22());
        bytes memory data = abi.encodeWithSelector(Proposal22.execute.selector);

        // propose / execute proposal
        _passProposal(target, data);

        _logData(target, data);
    }

    function test_proposal_22_execution() public onlyFork {
        assertEq(staking.bypassAuctions(), 1);
        assertEq(staking.minStakedTokensToKeep(), 250000 ether);
        assertEq(staking.forcedExit(), 1);
        assertEq(staking.escrowPaused(), 1);
        assertEq(protocolToken.balanceOf(address(stakingRefill)), 0);
        assertEq(protocolToken.balanceOf(address(stakingDripper)), 0);
        assertEq(stakingDripper.rewardPerBlock(), uint(10 ether) / 7200);
        assertEq(stakingDripper.rewardCalculationDelay(), uint(-1));
    }

    function test_proposal_22_debt_auction() public onlyFork {
        address ali = address(new Guy(debtAuctionHouse));
        address bob = address(new Guy(debtAuctionHouse));

        uint initialBalance = 10**52;

        // giving coin to bidders
        _setCoinBalance(ali, initialBalance);
        _setCoinBalance(bob, initialBalance);

        // adding just enough debt to allow for an auction
        _giveAuth(address(safeEngine), address(this));
        safeEngine.createUnbackedDebt(
            address(accountingEngine),
            address(0),
                accountingEngine.debtAuctionBidSize() +
                accountingEngine.totalQueuedDebt() +
                accountingEngine.totalOnAuctionDebt()
        );
        _setCoinBalance(address(accountingEngine), 0);

        // kick off debt auction
        uint previousDebt = safeEngine.debtBalance(address(accountingEngine));
        uint id = accountingEngine.auctionDebt();
        (uint bidAmount,,,,) = debtAuctionHouse.bids(id);

        Guy(ali).decreaseSoldAmount(id, 100 ether, bidAmount);
        // bid taken from bidder
        assertEq(safeEngine.coinBalance(ali), initialBalance - bidAmount);
        // accountingEngine receives payment, settles debt
        assertEq(safeEngine.coinBalance(address(accountingEngine)),  0);
        assertEq(safeEngine.debtBalance(address(accountingEngine)), previousDebt - bidAmount);
        assertEq(Gal(address(accountingEngine)).totalOnAuctionDebt(), 0);

        Guy(bob).decreaseSoldAmount(id, 80 ether, bidAmount);
        // bid taken from bidder
        assertEq(safeEngine.coinBalance(bob), initialBalance - bidAmount);
        // prev bidder refunded
        assertEq(safeEngine.coinBalance(ali), initialBalance);
        // accountingEngine receives no more
        assertEq(safeEngine.coinBalance(address(accountingEngine)), 0);

        hevm.warp(now + 5 weeks);
        uint previousProtSupply = protocolToken.totalSupply();

        Guy(bob).settleAuction(id);
        // marked auction in the accounting engine
        assertEq(debtAuctionHouse.activeDebtAuctions(), 0);
        // tokens minted on demand
        assertEq(protocolToken.totalSupply(), previousProtSupply + 80 ether);
        // bob gets the winnings
        assertEq(protocolToken.balanceOf(bob), 80 ether);
    }

    function test_proposal_22_withdraw_no_staking_rewards_balance() public onlyFork {
        // Get some LP tokens to stake
        uint stakedAmount = 500 ether;
        _giveTokens(address(stakedToken), address(this), stakedAmount);

        // Stake them
        uint price = staking.joinPrice(stakedAmount);
        stakedToken.approve(address(staking), stakedAmount);
        staking.join(stakedAmount);

        assertEq(staking.descendantBalanceOf(address(this)),price);

        // empty balance of staking contract / refill
        _giveTokens(address(stakedToken), address(staking), 0);
        _giveTokens(address(stakedToken), address(0xc5fEcD1080d546F9494884E834b03D7AD208cc02), 0);

        // fast forward 1 year (allow rewards to accrue)
        hevm.warp(now + 52 weeks);

        // withdraw
        price = staking.exitPrice(stakedAmount);
        staking.requestExit(stakedAmount);
        hevm.warp(now + staking.exitDelay());

        uint previousBalance = stakedToken.balanceOf(address(this));
        staking.exit();

        assertEq(stakedToken.balanceOf(address(this)), previousBalance + price);
        assertEq(stakedToken.balanceOf(address(this)), stakedAmount); // no slashing happened
        assertEq(staking.descendantBalanceOf(address(this)), 0);
    }
}