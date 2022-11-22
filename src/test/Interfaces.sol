pragma solidity ^0.6.7;

// === HEVM ===

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
      address,
      bytes32,
      bytes32
    ) external;

    function store(
      address,
      bytes32,
      address
    ) external;

    function load(address, bytes32) external view returns (bytes32);
}

// === Helpers ===

abstract contract AuthLike {
    function authorizedAccounts(address) external view virtual returns (uint256);
}

abstract contract TokenLike {
    function approve(address, uint256) public virtual returns (bool);

    function decimals() public view virtual returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address) public view virtual returns (uint256);

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function owner() public view virtual returns (address);
}

abstract contract DSProxyLike {
    function execute(address, bytes memory) public payable virtual returns (bytes memory response);
}

abstract contract SaviourLike {
    function deposit(uint256, uint256) external virtual;
    function debtBelowFloor(bytes32, uint256) external virtual returns (bool);
    function lpToken() external virtual returns (address);
    function canSave(bytes32, address) public virtual returns (bool);
    function getTargetCRatio(address) public virtual returns (uint256);
    function lpTokenCover(address) public virtual returns (uint256);
    function getLPUnderlying(address) public virtual returns (uint256, uint256);
    function getTokensForSaving(address, uint256) public virtual returns (uint256, uint256);
    function getKeeperPayoutTokens(address, uint256, uint256, uint256) public virtual returns (uint256, uint256);
    function getSystemCoinMarketPrice() public virtual returns (uint256);
    function getCollateralPrice() public virtual returns (uint256);
    function minKeeperPayoutValue() public virtual returns (uint256);
    function underlyingReserves(address) public virtual returns (uint256, uint256);
}

abstract contract CRatioSetterLike {
    function setDesiredCollateralizationRatio(bytes32, uint256, uint256) external virtual;
     function defaultDesiredCollateralizationRatios(bytes32) external virtual returns (uint);
     function minDesiredCollateralizationRatios(bytes32) external virtual returns (uint);
}

// === GEB ===

abstract contract DSPauseLike {
    function proxy() external view virtual returns (address);

    function delay() external view virtual returns (uint256);

    function scheduleTransaction(
      address,
      bytes32,
      bytes calldata,
      uint256
    ) external virtual;

    function abandonTransaction(
      address,
      bytes32,
      bytes calldata,
      uint256
    ) external virtual;

    function executeTransaction(
      address,
      bytes32,
      bytes calldata,
      uint256
    ) external virtual returns (bytes memory);

    function authority() external view virtual returns (address);

    function owner() external view virtual returns (address);
    function currentlyScheduledTransactions() external view virtual returns (uint256);
    function maxScheduledTransactions() external view virtual returns (uint256);
}

abstract contract LiquidationEngineLike is AuthLike {
    function collateralTypes(bytes32) virtual public view returns (
        address collateralAuctionHouse,
        uint256 liquidationPenalty,     // [wad]
        uint256 liquidationQuantity     // [rad]
    );
    function disableContract() virtual external;
    function liquidateSAFE(bytes32, address) external virtual returns (uint);
    function chosenSAFESaviour(bytes32, address) external virtual returns (address);
    function safeSaviours(address) external virtual view returns (uint);
    function onAuctionSystemCoinLimit() external virtual view returns (uint);
}

abstract contract AccountingEngineLike {
    function debtAuctionBidSize() public view virtual returns (uint256);

    function surplusAuctionAmountToSell() public view virtual returns (uint256);

    function initialDebtAuctionMintedTokens() public view virtual returns (uint256);

    function surplusBuffer() public view virtual returns (uint256);

    function canPrintProtocolTokens() public view virtual returns (bool);

    function totalQueuedDebt() public view virtual returns (uint256);

    function totalOnAuctionDebt() public view virtual returns (uint256);

    function auctionDebt() external virtual returns (uint256);

    function popDebtDelay() public view virtual returns (uint256);

    function unqueuedUnauctionedDebt() public view virtual returns (uint256);

    function settleDebt(uint256 rad) public virtual;

    function transferPostSettlementSurplus() external virtual;

    function disableCooldown() external virtual returns (uint256);

    function systemStakingPool() external virtual returns (address);

    function auctionSurplus() external virtual returns (uint256);
    function extraSurplusIsTransferred() external virtual returns (uint256);
    function pushDebtToQueue(uint256) external virtual;
    function popDebtFromQueue(uint256) external virtual;

}

abstract contract SAFEEngineLike {
    function coinBalance(address) public view virtual returns (uint256);

    function debtBalance(address) public view virtual returns (uint256);
    function globalDebtCeiling() public view virtual returns (uint256);

    function settleDebt(uint256) external virtual;

    function approveSAFEModification(address) external virtual;

    function denySAFEModification(address) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function modifyCollateralBalance(
      bytes32,
      address,
      int256
    ) external virtual;

    function transferInternalCoins(
      address,
      address,
      uint256
    ) external virtual;

    function createUnbackedDebt(
      address,
      address,
      uint256
    ) external virtual;

    function collateralTypes(bytes32)
      public
      view
      virtual
      returns (
        uint256 debtAmount, // [wad]
        uint256 accumulatedRate, // [ray]
        uint256 safetyPrice, // [ray]
        uint256 debtCeiling, // [rad]
        uint256 debtFloor, // [rad]
        uint256 liquidationPrice // [ray]
      );

    function safes(bytes32, address)
      public
      view
      virtual
      returns (
        uint256 lockedCollateral, // [wad]
        uint256 generatedDebt // [wad]
      );

    function globalDebt() public virtual returns (uint256);

    function transferCollateral(
      bytes32 collateralType,
      address src,
      address dst,
      uint256 wad
    ) external virtual;

    function confiscateSAFECollateralAndDebt(
      bytes32 collateralType,
      address safe,
      address collateralSource,
      address debtDestination,
      int256 deltaCollateral,
      int256 deltaDebt
    ) external virtual;

    function disableContract() external virtual;

    function tokenCollateral(bytes32, address) public view virtual returns (uint256);
}


abstract contract ProxyRegistryLike {
    function proxies(address) public view virtual returns (address);
    function build() public virtual returns (address);
}

abstract contract GlobalSettlementLike {
    function collateralCashPrice(bytes32) public view virtual returns (uint256);

    function redeemCollateral(bytes32, uint256) public virtual;

    function freeCollateral(bytes32) public virtual;

    function prepareCoinsForRedeeming(uint256) public virtual;

    function processSAFE(bytes32, address) public virtual;

    function shutdownTime() public view virtual returns (uint256);

    function finalCoinPerCollateralPrice(bytes32) public view virtual returns (uint256);

    function freezeCollateralType(bytes32) external virtual;

    function setOutstandingCoinSupply() external virtual;

    function outstandingCoinSupply() external virtual returns (uint256);

    function calculateCashPrice(bytes32) external virtual;

    function shutdownCooldown() external virtual;
}

abstract contract SystemCoinLike {
    function balanceOf(address) public view virtual returns (uint256);

    function approve(address, uint256) public virtual returns (uint256);

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
      address,
      address,
      uint256
    ) public virtual returns (bool);
}

abstract contract GebSafeManagerLike {
    function safei() public view virtual returns (uint256);

    function safes(uint256) public view virtual returns (address);

    function ownsSAFE(uint256) public view virtual returns (address);

    function lastSAFEID(address) public virtual returns (uint);

    function protectSAFE(uint256, address, address) public virtual;

    function safeCan(
      address,
      uint256,
      address
    ) public view virtual returns (uint256);
}

abstract contract TaxCollectorLike {
    function collateralTypes(bytes32) public virtual returns (uint256, uint256);

    function taxSingle(bytes32) public virtual returns (uint256);

    function modifyParameters(bytes32, uint256) external virtual;

    function taxAll() external virtual;

    function globalStabilityFee() external view virtual returns (uint256);

    function isSecondaryReceiver(uint256) external virtual view returns (bool);

    function latestSecondaryReceiver() external virtual view returns (uint256);

    function secondaryReceiverAccounts(uint256) external virtual view returns (address);
    function secondaryTaxReceivers(bytes32, uint256) external virtual view returns (uint256, uint256);
}

abstract contract DSTokenLike {
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address) public view virtual returns (uint256);
    function approve(address, uint256) public virtual;
    function transfer(address, uint256) public virtual returns (bool);
    function transferFrom(
      address,
      address,
      uint256
    ) public virtual returns (bool);
}

abstract contract CoinJoinLike {
    function safeEngine() public virtual returns (SAFEEngineLike);
    function systemCoin() public virtual returns (DSTokenLike);
    function join(address, uint256) public payable virtual;
    function exit(address, uint256) public virtual;
}

abstract contract CollateralJoinLike {
    function decimals() public virtual returns (uint256);
    function collateral() public virtual returns (TokenLike);
    function join(address, uint256) public payable virtual;
    function exit(address, uint256) public virtual;
}

abstract contract ESMLike {
    function triggerThreshold() public view virtual returns (uint256);
    function thresholdSetter() public view virtual returns (address);
    function shutdown() public virtual;
}

abstract contract DebtAuctionHouseLike {
    function bids(uint256) public virtual view returns (uint256, uint256, address, uint48, uint48);
    function safeEngine() public virtual view returns (address);
    function protocolToken() public virtual view returns (address);
    function bidDecrease() public virtual view returns (uint256);
    function amountSoldIncrease() public virtual view returns (uint256);
    function bidDuration() public virtual view returns (uint48);
    function totalAuctionLength() public virtual view returns (uint48);
    function auctionsStarted() public virtual view returns (uint256);
    function activeDebtAuctions() public virtual view returns (uint256);
    function contractEnabled() public virtual view returns (uint256);
    function modifyParameters(bytes32, uint256) public virtual;
    function startAuction(address, uint256, uint256) public virtual returns (uint256);
    function restartAuction(uint256) public virtual;
    function decreaseSoldAmount(uint256, uint256, uint256) public virtual;
    function settleAuction(uint256) public virtual;
    function disableContract() public virtual;
    function terminateAuctionPrematurely(uint256 id) public virtual;
}

abstract contract MerkleDistributorFactoryLike {
    function nonce() virtual public view returns (uint256);
    function deployDistributor(bytes32, uint256) virtual external;
    function sendTokensToDistributor(uint256) virtual external;
    function sendTokensToCustom(address, uint256) virtual external;
    function dropDistributorAuth(uint256) virtual external;
    function getBackTokensFromDistributor(uint256, uint256) virtual external;
    function distributors(uint256) public view virtual returns(address);
    function tokensToDistribute(uint256) public view virtual returns(uint256);
    function authorizedAccounts(address) public view virtual returns(uint256);
}

abstract contract MerkleDistributorLike {
    function token() virtual external view returns (address);
    function merkleRoot() virtual external view returns (bytes32);
    function deploymentTime() virtual external view returns (uint256);
    function owner() virtual external view returns (address);
    function isClaimed(uint256 index) virtual external view returns (bool);
    function sendTokens(address dst, uint256 tokenAmount) virtual external;
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) virtual external;
}

abstract contract StabilityFeeTreasuryLike is AuthLike {
    function getAllowance(address) virtual external view returns (uint256, uint256);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint256) virtual external;
    function giveFunds(address, uint256) external virtual;
    function takeFunds(address, uint256) external virtual;
    function extraSurplusReceiver() external virtual returns (address);
    function transferSurplusFunds() external virtual;
    function surplusTransferDelay() external virtual returns (uint256);
    function settleDebt() external virtual;
    function minimumFundsRequired() external virtual returns (uint256);
    function treasuryCapacity() external virtual returns (uint256);
    function setPerBlockAllowance(address, uint256) virtual external;
    function setTotalAllowance(address, uint256) virtual external;
    function pulledPerBlock(address, uint256) virtual external returns (uint);
    function expensesAccumulator() external virtual returns (uint256);
    function pullFundsMinThreshold() external virtual returns (uint256);
}

abstract contract DSValueLike {
    function read() virtual external view returns (uint256);
}

abstract contract OracleLike is DSValueLike {
    function getResultWithValidity() virtual external view returns (uint256, bool);
    function updateResult(address) virtual external;
    function maxWindowSize() virtual external view returns (uint256);
}

abstract contract DebtFloorSetterLike {
    function updateDelay() virtual external view returns (uint256);
    function recomputeCollateralDebtFloor(address) virtual external;
    function lastUpdateTime() external virtual returns (uint256);
    function ethPriceOracle() external virtual returns (address);
}

abstract contract DebtPopperRewardsLike {
    function rewardTimeline() virtual external view returns (uint256);
    function interPeriodDelay() virtual external view returns (uint256);
    function fixedReward() virtual external view returns (uint256);
    function rewardedPop(uint256) virtual external view returns (bool);
    function rewardsPerPeriod(uint256) virtual external view returns (uint256);
    function getRewardForPop(uint256, address) virtual external;
    function rewardPeriodStart() virtual external view returns (uint256);

}

abstract contract PRawPerSecondCalculatorLike {
    function allReaderToggle() virtual external view returns (uint256);
    function lut() external view virtual returns (uint256);
    function sg() virtual external view returns (int256);
    function tlv() virtual external view returns (uint256);
    function getLastProportionalTerm() virtual external view returns (int256);
    function folb() virtual external view returns (int256);
    function foub() virtual external view returns (uint256);
    function computeRate(uint, uint, uint) external virtual returns (uint256);
}

abstract contract PIRawPerSecondCalculatorLike {
    function allReaderToggle() virtual external view returns (uint256);
    function lut() external view virtual returns (uint256);
    function oll() virtual external view returns (uint256);
    function sg() virtual external view returns (int256);
    function ag() virtual external view returns (int256);
    function pscl() virtual external view returns (uint256);
    function pdc() virtual external view returns (uint256);
    function tlv() virtual external view returns (uint256);
    function getLastIntegralTerm() virtual external view returns (int256);
    function getLastProportionalTerm() virtual external view returns (int256);
    function folb() virtual external view returns (int256);
    function foub() virtual external view returns (uint256);
    function computeRate(uint, uint, uint) external virtual returns (uint256);
    function integralPeriodSize() virtual external view returns (uint256);
}

abstract contract IncreasingDiscountCollateralAuctionHouseLike {
    function safeEngine() external virtual view returns (address);
    function maxDiscount() external virtual view returns (uint256);
    function minimumBid() external virtual view returns (uint256);
    function perSecondDiscountUpdateRate() external virtual returns (uint256);
    function buyCollateral(uint256, uint256) external virtual;
    function bids(uint256) external virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint48, address, address);
    function systemCoinOracle() external virtual view returns (address);
}

abstract contract OracleRelayerLike {
    function collateralTypes(bytes32) external virtual view returns (address, uint256, uint256);
    function redemptionPrice() external virtual returns (uint256);
    function redemptionRate() external virtual returns (uint256);
    function redemptionRateUpperBound() external virtual view returns (uint256);
    function redemptionRateLowerBound() external virtual view returns (uint256);
    function modifyParameters(bytes32, uint256) external virtual;
    function updateCollateralPrice(bytes32) external virtual;
    function orcl(bytes32) external virtual returns (address);
}

abstract contract GebLenderFirstResortRewardsVested {
    function protocolUnderwater() public virtual view returns (bool);
    function canAuctionTokens() public virtual view returns (bool);
    function ancestorPool() public virtual view returns (address);
    function auctionAncestorTokens() external virtual;
    function tokensToAuction() public virtual returns(uint256);
    function maxConcurrentAuctions() public virtual returns(uint256);
    function exitDelay() public virtual returns(uint256);
    function systemCoinsToRequest() public virtual returns(uint256);
    function join(uint256) public virtual;
    function descendantBalanceOf(address) public virtual returns (uint256);
    function joinPrice(uint256) public virtual returns (uint256);
    function exitPrice(uint256) public virtual returns (uint256);
    function requestExit(uint256) public virtual;
    function exit() public virtual;
    function escrowPaused() public virtual returns (uint256);
    function minStakedTokensToKeep() public virtual returns (uint256);
    function bypassAuctions() public virtual returns (uint256);
}

abstract contract StakedTokenAuctionHouse {
    function bids(uint256) public virtual returns (uint256,uint256,address,uint48,uint48);
    function auctionsStarted() public virtual returns(uint256);
    function activeStakedTokenAuctions() public virtual returns (uint256);
    function restartAuction(uint256 id) external virtual;
    function increaseBidSize(uint256 id, uint256 amountToBuy, uint256 bid) external virtual;
    function settleAuction(uint256 id) external virtual;
    function bidDuration() public virtual returns(uint256);
    function totalAuctionLength() public virtual returns(uint256);
    function stakedToken() public virtual returns(TokenLike);
    function redemptionPrice() external virtual returns (uint256);
}

abstract contract SurplusAuctionHouseLike is AuthLike {
    function bids(uint256) public virtual view returns (uint256, uint256, address, uint48, uint48);
    function safeEngine() public virtual view returns (address);
    function protocolToken() public virtual view returns (address);
    function protocolTokenBidReceiver() public virtual view returns (address);
    function bidIncrease() public virtual view returns (uint256);
    function bidDuration() public virtual view returns (uint48);
    function totalAuctionLength() public virtual view returns (uint48);
    function auctionsStarted() public virtual view returns (uint256);
    function contractEnabled() public virtual view returns (uint256);
    function modifyParameters(bytes32, uint256) public virtual;
    function startAuction(uint256, uint256) public virtual returns (uint256);
    function restartAuction(uint256) public virtual;
    function increaseBidSize(uint256, uint256, uint256) public virtual;
    function settleAuction(uint256) public virtual;
    function disableContract() public virtual;
    function terminateAuctionPrematurely(uint256 id) public virtual;
}

abstract contract DebtAuctionParamSetterLike {
    function systemCoinOrcl() public virtual view returns (address);
    function setDebtAuctionInitialParameters(address) public virtual;
    function lastUpdateTime() public virtual view returns (uint);
    function protocolTokenOrcl() public virtual view returns (address);
}

abstract contract StakeRefillerLike {
  function refillAmount() public virtual view returns (uint);
  function refill() public virtual;
  function lastRefillTime() public virtual view returns (uint);
  function refillDelay() public virtual view returns (uint);
  function refillDestination() public virtual view returns (address);
}

abstract contract RateSetterRelayerLike {
  function relayDelay() external view virtual returns (uint);
  function lastUpdateTime() external view virtual returns (uint);
  function baseUpdateCallerReward() external view virtual returns (uint);
  function maxUpdateCallerReward() external view virtual returns (uint);
  function maxRewardIncreaseDelay() external view virtual returns (uint);
  function perSecondCallerRewardIncrease() external view virtual returns (uint);
  function getCallerReward(uint, uint) external view virtual returns (uint);
  function relayRate(uint256, address) external virtual;
}

abstract contract AutoSurplusBufferLike is AuthLike {
    function stopAdjustments() public virtual view returns (uint);
    function minimumGlobalDebtChange() public virtual view returns (uint);
    function maximumBufferSize() public virtual view returns (uint);
    function updateDelay() public virtual view returns (uint);
    function lastRecordedGlobalDebt() public virtual view returns (uint);
    function percentageDebtChange(uint) public virtual view returns (uint);
    function adjustSurplusBuffer(address) public virtual;
    function minimumBufferSize() external virtual view returns (uint256);
    function bufferInflationDelay() external virtual view returns (uint256);
    function bufferTargetInflation() external virtual view returns (uint256);
    function maxRewardIncreaseDelay() external virtual view returns (uint256);
}

abstract contract TreasuryParamAdjusterLike is AuthLike {
    function addRewardAdjuster(address) external virtual;
    function addFundedFunction(address, bytes4, uint256) external virtual;
    function rewardAdjusters(address) external virtual view returns (uint256);
    function whitelistedFundedFunctions(address, bytes4) external virtual view returns (uint256, uint256);
}

abstract contract FixedRewardsAdjusterLike is AuthLike {
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256) external virtual;
    function fundingReceivers(address, bytes4) external virtual view returns (uint256, uint256, uint256, uint256);
    function gasPriceOracle() public virtual view returns (address);
    function ethPriceOracle() public virtual view returns (address);

}

abstract contract MinMaxRewardsAdjusterLike is AuthLike {
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256, uint256) external virtual;
    function fundingReceivers(address, bytes4) external virtual view returns (uint256, uint256, uint256, uint256, uint256);
    function recomputeRewards(address, bytes4) external virtual;
    function gasPriceOracle() public virtual view returns (address);
    function ethPriceOracle() public virtual view returns (address);
}

abstract contract IncreasingReimbursementOverlayLike {
    function reimbursers(address) public virtual returns (uint);
}

abstract contract RewardAdjusterPingerBundlerLike {
    function recomputeAllRewards() public virtual;
    function minMaxRewardAdjuster() public virtual returns (address);
    function fixedRewardAdjuster() public virtual returns (address);
    function addedFunction(address, bytes4) public virtual view returns (uint);
}

abstract contract DebtAuctionInitialParamSetterLike {
    function protocolTokenOrcl() public virtual view returns (address);
    function systemCoinOrcl() public virtual view returns (address);
    function setDebtAuctionInitialParameters(address) public virtual;
}

abstract contract DebtCeilingSetterLike {
    function blockIncreaseWhenRevalue() public virtual view returns (uint256);
    function blockDecreaseWhenDevalue() public virtual view returns (uint256);
    function getNextCollateralCeiling() public virtual view returns (uint256);
    function lastUpdateTime() public virtual view returns (uint256);
    function autoUpdateCeiling(address) public virtual;
}

abstract contract RateSetterLike {
    function pidCalculator() public virtual view returns (address);
    function defaultLeak() public virtual view returns (uint256);
    function orcl() public virtual view returns (address);
    function updateRateDelay() public virtual view returns (uint256);
    function lastUpdateTime() public virtual view returns (uint256);
    function updateRate(address) public virtual;
}

abstract contract StreamVaultLike {
    function createStream(address, uint256, address, uint256, uint256) external virtual;
    function cancelStream() external virtual;
    function sablier() external virtual view returns (address);
    function streamId() external virtual view returns (uint256);
}

abstract contract SablierLike {
    function getStream(uint256)
        external
        virtual
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );
}