/**
 *                _ _   ______                        _
 *	░██████╗░░█████╗░░██████╗░█████╗░██╗░░░░░██╗░█████╗░██╗░░██╗
 *	██╔════╝░██╔══██╗██╔════╝██╔══██╗██║░░░░░██║██╔══██╗██║░██╔╝
 *	██║░░██╗░███████║╚█████╗░██║░░╚═╝██║░░░░░██║██║░░╚═╝█████═╝░
 *	██║░░╚██╗██╔══██║░╚═══██╗██║░░██╗██║░░░░░██║██║░░██╗██╔═██╗░
 *	╚██████╔╝██║░░██║██████╔╝╚█████╔╝███████╗██║╚█████╔╝██║░╚██╗
 *	░╚═════╝░╚═╝░░╚═╝╚═════╝░░╚════╝░╚══════╝╚═╝░╚════╝░╚═╝░░╚═╝
 *
 *
 * Web: https://gasclick.net
 *
 *
 * Merging the new cryptoeconomy and the traditional economy.
 * By leveraging the value already existing on LPG consumption, we tokenize, capture and offer it to worldwide investors. 
 * A match made in heaven.
 * 
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import "./GasClickAntiWhale.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GasClickICO is GasClickAntiWhale, ReentrancyGuard {
	using SafeERC20 for IERC20;

	/********************************************************************************************************/
	/************************************************* Lifecycle ********************************************/
	/********************************************************************************************************/
	// Crowdsale Stage
	function getCrowdsaleStage() external view returns (CrowdsaleStage) {
		return stage;
	}
	enum CrowdsaleStage {
		NotStarted,
		Ongoing,
		OnHold,
		Finished
	}
	CrowdsaleStage private stage = CrowdsaleStage.NotStarted;
	function setCrowdsaleStage(uint stage_) external onlyOwner {
		if(uint(CrowdsaleStage.NotStarted) == stage_) {							// 0
			stage = CrowdsaleStage.NotStarted;
		} else if (uint(CrowdsaleStage.Ongoing) == stage_) {				// 1
			stage = CrowdsaleStage.Ongoing;
		} else if (uint(CrowdsaleStage.OnHold) == stage_) {					// 2
			stage = CrowdsaleStage.OnHold;
		} else if (uint(CrowdsaleStage.Finished) == stage_) {				// 3
			stage = CrowdsaleStage.Finished;
		}
	}

	/********************************************************************************************************/
	/*********************************************** Invested ***********************************************/
	/********************************************************************************************************/
	uint256 private totaluUSDTInvested = 0;
	function getTotaluUSDInvested() external view returns (uint256) {
		return totaluUSDTInvested;
	}	

	uint256 private hardCapuUSD = 300_000_000_000;
	function getHardCap() external view returns (uint256) {
		return hardCapuUSD / 10**6;
	}
	function setHardCapuUSD(uint256 hardCap) external onlyOwner {
		hardCapuUSD = hardCap;
		emit UpdatedHardCap(hardCap);
	}
	event UpdatedHardCap(uint256 hardCap);

	uint256 private softCapuUSD = 50_000_000_000;
	function getSoftCap() external view returns (uint256) {
		return softCapuUSD / 10**6;
	}
	function setSoftCapuUSD(uint256 softCap) external onlyOwner {
		softCapuUSD = softCap;
		emit UpdatedSoftCap(softCap);
	}
	event UpdatedSoftCap(uint256 hardCap);

	// ICO Price
	uint256 private constant UUSDT_PER_TOKEN = 0.03*10**6;
	function getPriceuUSD() external pure returns (uint256) {
		return UUSDT_PER_TOKEN;
	}
	
	bool dynamicPrice = false;
	function gettDynamicPrice() external view returns(bool) {
		return dynamicPrice;
	}
	function setDynamicPrice(bool dynPrice) external onlyOwner {
		dynamicPrice = dynPrice;
	}

	/********************************************************************************************************/
	/******************************************* Payment Tokens *********************************************/
	/********************************************************************************************************/
	// Payment Tokens
	string[] private paymentSymbols;
	function getPaymentSymbols() external view returns (string[] memory) {
		return paymentSymbols;
	}
	mapping (string => PaymentToken) paymentTokens;
	struct PaymentToken {
		address ptTokenAddress;
		address ptPriceFeed;
		uint256 ptUUSD_PER_TOKEN;
		uint8 ptDecimals;
		uint256 ptuUSDInvested;
		uint256 ptAmountInvested;
	}
	function getPaymentToken(string calldata symbol) external view returns(PaymentToken memory) {
		return paymentTokens[symbol];
	}
	function setPaymentToken(string calldata symbol, address tokenAdd, address priceFeed, uint256 uUSDPerTokens, uint8 decimals) external onlyOwner {
		if (paymentTokens[symbol].ptDecimals == 0) {
			paymentSymbols.push(symbol);
		}

		paymentTokens[symbol] = PaymentToken({
      ptTokenAddress: tokenAdd,
      ptPriceFeed: priceFeed,
			ptUUSD_PER_TOKEN: uUSDPerTokens,
			ptDecimals: decimals,
			ptuUSDInvested: 0,
			ptAmountInvested: 0
    });

	}
	function deletePaymentToken(string calldata symbol, uint8 index) external onlyOwner {
		require(keccak256(bytes(symbol)) == keccak256(bytes(paymentSymbols[index])), "ERRP_INDX_PAY");

		delete paymentTokens[symbol];

		paymentSymbols[index] = paymentSymbols[paymentSymbols.length - 1];
		paymentSymbols.pop();
	}

	// price update
	function getUusdPerToken(string calldata symbol) external view returns (uint256) {
		AggregatorV3Interface currencyToUsdPriceFeed = AggregatorV3Interface(paymentTokens[symbol].ptPriceFeed);
		(,int256 answer,,,) = currencyToUsdPriceFeed.latestRoundData();
		return(uint256(answer) * 10**6 / 10**currencyToUsdPriceFeed.decimals());
	}

	/********************************************************************************************************/
	/********************************************* Investors ************************************************/
	/********************************************************************************************************/
	// Investors
	address[] private investors;
	function getInvestors() external view returns (address[] memory) {
		return investors;
	}
	function getInvestorsCount() external view returns(uint) {  
		return investors.length;
	}

	// contributions
	struct Contribution { 				// only for refund
		uint256 cAmountInvested;		// only for refund
		uint256 cuUSDInvested;			// only for audit
	}
	struct Contributions {
		bool known;
		uint256 uUSDToPay;					// for claim and deposits
		mapping (string => Contribution) conts;
	}
	mapping (address => Contributions) private contributions;

	function getContribution(address investor, string calldata symbol) external view returns(uint256){
		return contributions[investor].conts[symbol].cAmountInvested;
	}

	function getuUSDContribution(address investor, string calldata symbol) external view returns(uint256){
		return contributions[investor].conts[symbol].cuUSDInvested;
	}

	function getuUSDToClaim(address investor) external view returns(uint256){
		return contributions[investor].uUSDToPay;
	}

	/********************************************************************************************************/
	/*********************************************** Deposit ************************************************/
	/********************************************************************************************************/
	receive() external payable {
		if(msg.value > 0) depositWithuUSD("COIN", msg.value);																			// exclude unwanted wallet calls
	}
	fallback() external payable {
		if(msg.value > 0) depositWithuUSD("COIN", msg.value);																			// exclude unwanted wallet calls
	}
	function depositTokens(string calldata symbol, uint256 rawAmountWitDecimals) external nonReentrant {
		depositWithuUSD(symbol, rawAmountWitDecimals);
	}

	function depositWithuUSD(string memory symbol, uint256 rawAmountWitDecimals) internal {
		if(!dynamicPrice || paymentTokens[symbol].ptPriceFeed == address(0)) {
			deposit(symbol, rawAmountWitDecimals, rawAmountWitDecimals * paymentTokens[symbol].ptUUSD_PER_TOKEN / 10**paymentTokens[symbol].ptDecimals);
		} else {
			AggregatorV3Interface currencyToUsdPriceFeed = AggregatorV3Interface(paymentTokens[symbol].ptPriceFeed);
			(,int256 rawUsdPrice,,,) = currencyToUsdPriceFeed.latestRoundData();
			paymentTokens[symbol].ptUUSD_PER_TOKEN = uint256(rawUsdPrice) * 10**6 / 10**currencyToUsdPriceFeed.decimals();
			deposit(symbol, rawAmountWitDecimals, rawAmountWitDecimals * paymentTokens[symbol].ptUUSD_PER_TOKEN / 10**paymentTokens[symbol].ptDecimals);
		}
	}

	// receive contribution
	function deposit(string memory symbol, uint256 rawAmountWitDecimals, uint uUSDAmount) internal {
		require(stage == CrowdsaleStage.Ongoing, "ERRD_MUST_ONG");																																										// ICO must be ongoing
		require(!useBlacklist || !blacklisted[msg.sender], 'ERRD_MUSN_BLK');																																				// must not be blacklisted
		require(uUSDAmount >= minuUSDTransfer, "ERRD_TRAS_LOW");																																											// transfer amount too low
		require(uUSDAmount <= maxuUSDTransfer, "ERRD_TRAS_HIG");																																											// transfer amount too high
		require((contributions[msg.sender].uUSDToPay +uUSDAmount < whitelistuUSDThreshold) || whitelisted[msg.sender], 'ERRD_MUST_WHI');					// must be whitelisted
		require(contributions[msg.sender].uUSDToPay +uUSDAmount <= maxuUSDInvestment, "ERRD_INVT_HIG");																							// total invested amount too high
		require(uUSDAmount + totaluUSDTInvested < hardCapuUSD, "ERRD_HARD_CAP");																																		// amount higher than available

		// add investor
		if(!contributions[msg.sender].known) {
			investors.push(msg.sender);
			contributions[msg.sender].known = true;
		}

		// add contribution to investor
		contributions[msg.sender].conts[symbol].cAmountInvested += rawAmountWitDecimals;	// only for refund
		contributions[msg.sender].conts[symbol].cuUSDInvested += uUSDAmount;							// only for audit

		// add total to investor
		contributions[msg.sender].uUSDToPay += uUSDAmount;																// only for claim

		// add total to payment method
		paymentTokens[symbol].ptuUSDInvested += uUSDAmount;																// only for audit
		paymentTokens[symbol].ptAmountInvested += rawAmountWitDecimals;										// only for audit

		// add total
		totaluUSDTInvested += uUSDAmount;																									// lifecycle

		emit FundsReceived(msg.sender, symbol, rawAmountWitDecimals);

		// move tokens if tokens investment
		if (keccak256(bytes(symbol)) != keccak256(bytes("COIN"))) {
			require(IERC20(paymentTokens[symbol].ptTokenAddress).allowance(msg.sender, address(this)) >= rawAmountWitDecimals, "ERRD_ALLO_LOW");				// insuffient allowance
			IERC20(paymentTokens[symbol].ptTokenAddress).safeTransferFrom(msg.sender, address(this), rawAmountWitDecimals);
		}

	}
	event FundsReceived (address backer, string symbol, uint amount);

	/********************************************************************************************************/
	/**************************************************** Refund ********************************************/
	/********************************************************************************************************/
	function refund(string calldata symbol) external nonReentrant {
		refundInvestor(symbol, msg.sender);
	}
	function refundAll(string calldata symbol) external onlyOwner {
		uint investorsLength = investors.length;
		for (uint i = 0; i < investorsLength; i++) {
			refundInvestor(symbol, investors[i]);
		}
	}
	function refundInvestor(string calldata symbol, address investor) internal {
		require(stage == CrowdsaleStage.Finished, "ERRR_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested < softCapuUSD, "ERRR_PASS_SOF");																																									// Passed SoftCap. No refund
		uint256 rawAmount = contributions[investor].conts[symbol].cAmountInvested;
		require(rawAmount > 0, "ERRR_ZERO_REF");																																																			// Nothing to refund

		// clear variables
		contributions[investor].conts[symbol].cAmountInvested = 0;
		contributions[investor].conts[symbol].cuUSDInvested = 0;
		contributions[investor].uUSDToPay = 0;

		emit FundsRefunded(investor, symbol, rawAmount);

		// do refund
		if (rawAmount > 0) {
			if (keccak256(bytes(symbol)) == keccak256(bytes("COIN"))) {
				(bool success, ) = payable(investor).call{ value: rawAmount }("");
				require(success, "ERRR_WITH_REF");																																																			// Unable to refund

			} else {
				IERC20(paymentTokens[symbol].ptTokenAddress).safeTransfer(investor, rawAmount);
			}
		}

	}
	event FundsRefunded(address _backer, string symbol, uint _amount);

	/********************************************************************************************************/
	/**************************************************** Claim *********************************************/
	/********************************************************************************************************/
	function claim() external nonReentrant {
		claimInvestor(msg.sender);
	}
	function claimAll() external onlyOwner {
		uint investorsLength = investors.length;
		for (uint i = 0; i < investorsLength; i++) {
			claimInvestor(investors[i]);
		}
	}
	function claimInvestor(address investor) internal {
		require(stage == CrowdsaleStage.Finished, "ERRC_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested > softCapuUSD, "ERRC_NPAS_SOF");																																										// Not passed SoftCap
		require(tokenAddress != address(0x0), "ERRC_MISS_TOK");																																												// Provide Token

		uint claimed = contributions[investor].uUSDToPay * 10**18 / UUSDT_PER_TOKEN;

		// clear variables
		uint paymentSymbolsLength = paymentSymbols.length;
		for (uint i = 0; i < paymentSymbolsLength; i++) {
			contributions[investor].conts[paymentSymbols[i]].cAmountInvested = 0;
			contributions[investor].conts[paymentSymbols[i]].cuUSDInvested = 0;
			contributions[investor].uUSDToPay = 0;
		}

		// do claim
		if(claimed > 0) {
			emit FundsClaimed(investor, claimed);

			IERC20(tokenAddress).safeTransferFrom(owner(), investor, claimed);
		}
	}
	event FundsClaimed(address backer, uint amount);

	// tokenWalletAddress
	address payable tokenAddress;
	function setTokenAddress(address payable add) external onlyOwner {
		require(add !=  address(0), "ERRW_INVA_ADD");

		tokenAddress = add;
	}
	function getTokenAddress() external view returns (address) {
		return tokenAddress;
	}

	/********************************************************************************************************/
	/*************************************************** Withdraw *******************************************/
	/********************************************************************************************************/
	function withdraw(string calldata symbol, uint8 percentage) external nonReentrant onlyOwner {
		require(stage == CrowdsaleStage.Finished, "ERRW_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested > softCapuUSD, "ERRW_NPAS_SOF");																																									// Not passed SoftCap
		require(targetWalletAddress != address(0x0), "ERRW_MISS_WAL");																																								// Provide Wallet

		paymentTokens[symbol].ptuUSDInvested -= paymentTokens[symbol].ptuUSDInvested * percentage / 100;
		paymentTokens[symbol].ptAmountInvested -= paymentTokens[symbol].ptAmountInvested * percentage / 100;

		if (keccak256(bytes(symbol)) == keccak256(bytes("COIN"))) {
			uint amount = address(this).balance;
			require(amount > 0, "ERRR_ZERO_WIT");																																																				// Nothing to withdraw

			(bool success, ) = targetWalletAddress.call{ value: amount * percentage / 100 }("");
			require(success, "ERRR_WITH_BAD");																																																					// Unable to withdraw
			emit FundsWithdrawn(symbol, amount);

		} else {
			address paymentTokenAddress = paymentTokens[symbol].ptTokenAddress;
			uint amount = IERC20(paymentTokenAddress).balanceOf(address(this));
			require(amount > 0, "ERRR_ZERO_WIT");																																																				// Nothing to withdraw

			IERC20(paymentTokenAddress).safeTransfer(targetWalletAddress, amount * percentage / 100 );
			emit FundsWithdrawn(symbol, amount);
		}
	}
	event FundsWithdrawn(string symbol, uint amount);

	// targetWalletAddress
	address payable targetWalletAddress;
	function setTargetWalletAddress(address payable add) external onlyOwner {
		require(add !=  address(0), "ERRW_INVA_ADD");

		targetWalletAddress = add;
	}
	function getTargetWalletAddress() external view returns (address) {
		return targetWalletAddress;
	}

}