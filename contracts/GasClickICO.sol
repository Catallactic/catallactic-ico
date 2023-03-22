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
 // SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./GasClickAntiWhale.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "hardhat/console.sol";

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
	function setCrowdsaleStage(uint _stage) external onlyOwner {
		if(uint(CrowdsaleStage.NotStarted) == _stage) {							// 0
			stage = CrowdsaleStage.NotStarted;
		} else if (uint(CrowdsaleStage.Ongoing) == _stage) {				// 1
			stage = CrowdsaleStage.Ongoing;
		} else if (uint(CrowdsaleStage.OnHold) == _stage) {					// 2
			stage = CrowdsaleStage.OnHold;
		} else if (uint(CrowdsaleStage.Finished) == _stage) {				// 3
			stage = CrowdsaleStage.Finished;
		}
	}

	/********************************************************************************************************/
	/*********************************************** Supplies ***********************************************/
	/********************************************************************************************************/
	// Supplies
	uint256 private HARD_CAP_uUSD = 300_000_000_000;
	function getHardCap() external view returns (uint256) {
		return HARD_CAP_uUSD / 10**6;
	}
	function setHardCapuUSD(uint256 _hardCap) external onlyOwner {
		HARD_CAP_uUSD = _hardCap;
	}

	uint256 private SOFT_CAP_uUSD = 50_000_000_000;
	function getSoftCap() external view returns (uint256) {
		return SOFT_CAP_uUSD / 10**6;
	}
	function setSoftCapuUSD(uint256 _softCap) external onlyOwner {
		SOFT_CAP_uUSD = _softCap;
	}

	uint256 private totaluUSDTInvested = 0;
	function getTotaluUSDInvested() external view returns (uint256) {
		return totaluUSDTInvested;
	}	

	// ICO Price
	uint256 private uUSDT_PER_TOKEN = 0.03*10**6;
	function getPriceuUSD() external view returns (uint256) {
		return uUSDT_PER_TOKEN;
	}
	function setPriceuUSD(uint256 _uusd_per_token) external onlyOwner {
		uUSDT_PER_TOKEN = _uusd_per_token;
	}
	
	bool dynamicPrice = false;
	function gettDynamicPrice() external view returns(bool) {
		return dynamicPrice;
	}
	function setDynamicPrice(bool _dynamicPrice) external onlyOwner {
		dynamicPrice = _dynamicPrice;
	}

	/********************************************************************************************************/
	/******************************************* Payment Tokens *********************************************/
	/********************************************************************************************************/
	// bytes5 https://github.com/ethereum-optimism/smock/issues/35
	// https://web3.hashnode.com/solidity-tutorial-data-types-and-data-structures-in-solidity
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
	function getPaymentToken(string calldata _symbol) external view returns(PaymentToken memory) {
		return paymentTokens[_symbol];
	}
	function setPaymentToken(string calldata _symbol, address _tokenAddress, address _priceFeed, uint256 _uUSDPerTokens, uint8 _decimals) external onlyOwner {
		if (paymentTokens[_symbol].ptDecimals == 0) {
			paymentSymbols.push(_symbol);
		}

		paymentTokens[_symbol] = PaymentToken({
      ptTokenAddress: _tokenAddress,
      ptPriceFeed: _priceFeed,
			ptUUSD_PER_TOKEN: _uUSDPerTokens,
			ptDecimals: _decimals,
			ptuUSDInvested: 0,
			ptAmountInvested: 0
    });

	}
	function deletePaymentToken(string calldata _symbol, uint8 index) external onlyOwner {
		require(keccak256(bytes(_symbol)) == keccak256(bytes(paymentSymbols[index])), "ERRP_INDX_PAY");

		delete paymentTokens[_symbol];

		paymentSymbols[index] = paymentSymbols[paymentSymbols.length - 1];
		paymentSymbols.pop();
	}

	// price update
	function getUUSD_PER_TOKEN(string calldata _symbol) external view returns (uint256) {
		AggregatorV3Interface currencyToUsdPriceFeed = AggregatorV3Interface(paymentTokens[_symbol].ptPriceFeed);
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

	function getContribution(address investor, string calldata _symbol) external view returns(uint256){
		return contributions[investor].conts[_symbol].cAmountInvested;
	}

	function getuUSDContribution(address investor, string calldata _symbol) external view returns(uint256){
		return contributions[investor].conts[_symbol].cuUSDInvested;
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
	function depositTokens(string calldata _symbol, uint256 _rawAmountWitDecimals) external nonReentrant {
		depositWithuUSD(_symbol, _rawAmountWitDecimals);
	}

	function depositWithuUSD(string memory _symbol, uint256 _rawAmountWitDecimals) internal {
		if(!dynamicPrice || paymentTokens[_symbol].ptPriceFeed == address(0)) {
			deposit(_symbol, _rawAmountWitDecimals, _rawAmountWitDecimals * paymentTokens[_symbol].ptUUSD_PER_TOKEN / 10**paymentTokens[_symbol].ptDecimals);
		} else {
			AggregatorV3Interface currencyToUsdPriceFeed = AggregatorV3Interface(paymentTokens[_symbol].ptPriceFeed);
			(,int256 answer,,,) = currencyToUsdPriceFeed.latestRoundData();
			uint256 priceuUsd = (uint256(answer) * 10**6 / 10**currencyToUsdPriceFeed.decimals());
			paymentTokens[_symbol].ptUUSD_PER_TOKEN = priceuUsd;
			//console.log("ICO - calculated price in uusd: %s ", priceuUsd);
			deposit(_symbol, _rawAmountWitDecimals, _rawAmountWitDecimals * priceuUsd / 10**paymentTokens[_symbol].ptDecimals);
		}
	}

	// receive contribution
	function deposit(string memory _symbol, uint256 _rawAmountWitDecimals, uint _uUSDAmount) internal {
		//console.log("ICO - transferring : %s %s %s", _symbol, _rawAmountWitDecimals, _uUSDAmount);
		require(stage == CrowdsaleStage.Ongoing, "ERRD_MUST_ONG");																																										// ICO must be ongoing
		require(!useBlacklist || !_isBlacklisted[msg.sender], 'ERRD_MUSN_BLK');																																				// must not be blacklisted
		require(_uUSDAmount >= minuUSDTransfer, "ERRD_TRAS_LOW");																																											// transfer amount too low
		require(_uUSDAmount <= maxuUSDTransfer, "ERRD_TRAS_HIG");																																											// transfer amount too high
		require((contributions[msg.sender].uUSDToPay +_uUSDAmount < whitelistuUSDThreshold) || _isWhitelisted[msg.sender], 'ERRD_MUST_WHI');					// must be whitelisted
		require(contributions[msg.sender].uUSDToPay +_uUSDAmount <= maxuUSDInvestment, "ERRD_INVT_HIG");																							// total invested amount too high
		require(_uUSDAmount + totaluUSDTInvested < HARD_CAP_uUSD, "ERRD_HARD_CAP");																																		// amount higher than available

		// add investor
		if(!contributions[msg.sender].known) {
			investors.push(msg.sender);
			contributions[msg.sender].known = true;
		}

		// add contribution to investor
		contributions[msg.sender].conts[_symbol].cAmountInvested += _rawAmountWitDecimals;	// only for refund
		contributions[msg.sender].conts[_symbol].cuUSDInvested += _uUSDAmount;								// only for audit

		// add total to investor
		contributions[msg.sender].uUSDToPay += _uUSDAmount;																	// only for claim

		// add total to payment method
		paymentTokens[_symbol].ptuUSDInvested += _uUSDAmount;																// only for audit
		paymentTokens[_symbol].ptAmountInvested += _rawAmountWitDecimals;										// only for audit

		// add total
		totaluUSDTInvested += _uUSDAmount;										// lifecycle

		emit FundsReceived(msg.sender, _symbol, _rawAmountWitDecimals);

		// move tokens if tokens investment
		if (keccak256(bytes(_symbol)) != keccak256(bytes("COIN"))) {
			//console.log("ICO - getting from COIN: ", _symbol, _rawAmountWitDecimals);
			//console.log("ICO - investor allowance: ", IERC20(paymentTokens[_symbol].ptTokenAddress).allowance(msg.sender, address(this)));
			require(IERC20(paymentTokens[_symbol].ptTokenAddress).allowance(msg.sender, address(this)) >= _rawAmountWitDecimals, "ERRD_ALLO_LOW");				// insuffient allowance
			IERC20(paymentTokens[_symbol].ptTokenAddress).safeTransferFrom(msg.sender, address(this), _rawAmountWitDecimals);
		}

	}
	event FundsReceived (address _backer, string symbol, uint _amount);

	/********************************************************************************************************/
	/**************************************************** Refund ********************************************/
	/********************************************************************************************************/
	function refund(string calldata _symbol) external nonReentrant {
		refundInvestor(_symbol, msg.sender);
	}
	function refundAll(string calldata _symbol) external onlyOwner {
		uint investorsLength = investors.length;
		for (uint i = 0; i < investorsLength; i++) {
			refundInvestor(_symbol, investors[i]);
		}
	}
	function refundInvestor(string calldata _symbol, address investor) internal {
		//console.log("ICO - refunding tokens for : ", investor);
		require(stage == CrowdsaleStage.Finished, "ERRR_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested < SOFT_CAP_uUSD, "ERRR_PASS_SOF");																																									// Passed SoftCap. No refund
		uint256 rawAmount = contributions[investor].conts[_symbol].cAmountInvested;
		require(rawAmount > 0, "ERRR_ZERO_REF");																																																			// Nothing to refund

		// clear variables
		contributions[investor].conts[_symbol].cAmountInvested = 0;
		contributions[investor].conts[_symbol].cuUSDInvested = 0;
		contributions[investor].uUSDToPay = 0;

		emit FundsRefunded(investor, _symbol, rawAmount);

		// do refund
		if (rawAmount > 0) {
			if (keccak256(bytes(_symbol)) == keccak256(bytes("COIN"))) {
				(bool success, ) = payable(investor).call{ value: rawAmount }("");
				require(success, "ERRR_WITH_REF");																																																			// Unable to refund

			} else {
				IERC20(paymentTokens[_symbol].ptTokenAddress).safeTransfer(investor, rawAmount);
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
		//console.log("ICO - claiming tokens for : ", investor);
		require(stage == CrowdsaleStage.Finished, "ERRC_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested > SOFT_CAP_uUSD, "ERRC_NPAS_SOF");																																									// Not passed SoftCap
		require(tokenAddress != address(0x0), "ERRC_MISS_TOK");																																												// Provide Token

		uint claimed = contributions[investor].uUSDToPay * 10**18 / uUSDT_PER_TOKEN;

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
	event FundsClaimed(address _backer, uint _amount);

	// tokenWalletAddress
	address payable tokenAddress;
	function setTokenAddress(address payable _address) external onlyOwner {
		tokenAddress = _address;
	}
	function getTokenAddress() external view returns (address) {
		return tokenAddress;
	}

	/********************************************************************************************************/
	/*************************************************** Withdraw *******************************************/
	/********************************************************************************************************/
	function withdraw(string calldata _symbol, uint8 percentage) external nonReentrant onlyOwner {
		require(stage == CrowdsaleStage.Finished, "ERRW_MUST_FIN");																																										// ICO must be finished
		require(totaluUSDTInvested > SOFT_CAP_uUSD, "ERRW_NPAS_SOF");																																									// Not passed SoftCap
		require(targetWalletAddress != address(0x0), "ERRW_MISS_WAL");																																								// Provide Wallet

		paymentTokens[_symbol].ptuUSDInvested -= paymentTokens[_symbol].ptuUSDInvested * percentage / 100;
		paymentTokens[_symbol].ptAmountInvested -= paymentTokens[_symbol].ptAmountInvested * percentage / 100;

		if (keccak256(bytes(_symbol)) == keccak256(bytes("COIN"))) {
			uint amount = address(this).balance;
			require(amount > 0, "ERRR_ZERO_WIT");																																																				// Nothing to withdraw

			(bool success, ) = targetWalletAddress.call{ value: amount * percentage / 100 }("");
			require(success, "ERRR_WITH_BAD");																																																					// Unable to withdraw
			emit FundsWithdrawn(_symbol, amount);

		} else {
			address paymentTokenAddress = paymentTokens[_symbol].ptTokenAddress;
			uint amount = IERC20(paymentTokenAddress).balanceOf(address(this));
			require(amount > 0, "ERRR_ZERO_WIT");																																																				// Nothing to withdraw

			IERC20(paymentTokenAddress).safeTransfer(targetWalletAddress, amount * percentage / 100 );
			emit FundsWithdrawn(_symbol, amount);
		}
	}
	event FundsWithdrawn(string _symbol, uint _amount);

	// targetWalletAddress
	address payable targetWalletAddress;
	function setTargetWalletAddress(address payable _address) external onlyOwner {
		targetWalletAddress = _address;
	}
	function getTargetWalletAddress() external view returns (address) {
		return targetWalletAddress;
	}

}