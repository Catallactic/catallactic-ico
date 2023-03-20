/**
 * Anji is about building an ecosystem of altruistic defi applications to enable a decentralised digital economy that leaves the earth in a better way than we found it.
 *
 * Web: https://anji.eco
 * Telegram: https://t.me/anjieco
 * Twitter: https://twitter.com/anji_eco
 *
 *                 _ _   ______                        _
 *	░██████╗░░█████╗░░██████╗░█████╗░██╗░░░░░██╗░█████╗░██╗░░██╗
 *	██╔════╝░██╔══██╗██╔════╝██╔══██╗██║░░░░░██║██╔══██╗██║░██╔╝
 *	██║░░██╗░███████║╚█████╗░██║░░╚═╝██║░░░░░██║██║░░╚═╝█████═╝░
 *	██║░░╚██╗██╔══██║░╚═══██╗██║░░██╗██║░░░░░██║██║░░██╗██╔═██╗░
 *	╚██████╔╝██║░░██║██████╔╝╚█████╔╝███████╗██║╚█████╔╝██║░╚██╗
 *	░╚═════╝░╚═╝░░╚═╝╚═════╝░░╚════╝░╚══════╝╚═╝░╚════╝░╚═╝░░╚═╝
 *
 *
 * This is a payable push token
 * 
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GasClickAntiWhale is Ownable {

	/********************************************************************************************************/
	/********************************************** WhiteLists **********************************************/
	/********************************************************************************************************/
	// whitelist Threshold
	uint256 whitelistuUSDThreshold = 10_000_000_000;
	function setWhitelistuUSDThreshold(uint256 _whitelistuUSDThreshold) external onlyOwner {
		whitelistuUSDThreshold = _whitelistuUSDThreshold;
	}
	function getWhitelistuUSDThreshold() external view returns (uint256) {
		return whitelistuUSDThreshold;
	}

	// whitelisted addresses
	address[] private whitelisted;
	function getWhitelisted() external view returns(address[] memory) {  
    return whitelisted;
  }
	function getWhitelistUserCount() external view returns(uint) {  
    return whitelisted.length;
  }

	// whitelist status
  mapping(address => bool) _isWhitelisted;
  function isWhitelisted(address _user) external view returns (bool) {
    return _isWhitelisted[_user];
  }
  function whitelistUser(address _user) external onlyOwner {
		_isWhitelisted[_user] = true;
		whitelisted.push(_user);
  }
  function unwhitelistUser(address _user) external onlyOwner {
		_isWhitelisted[_user] = false;
  }

	/********************************************************************************************************/
	/********************************************** Blacklists **********************************************/
	/********************************************************************************************************/
	// blacklist flag
	bool useBlacklist;
	function setUseBlacklist(bool _useBlacklist) external onlyOwner {
		useBlacklist = _useBlacklist;
	}
	function getUseBlacklist() external view returns (bool) {
		return useBlacklist;
	}

	// blacklisted addresses
	address[] private blacklisted;
	function getBlacklisted() external view returns(address[] memory) {  
    return blacklisted;
  }
	function getBlacklistUserCount() external view returns(uint) {  
    return blacklisted.length;
  }

	// blacklist status
  mapping(address => bool) _isBlacklisted;
  function isBlacklisted(address _user) external view returns (bool) {
    return _isBlacklisted[_user];
  }
  function blacklistUser(address _user) external onlyOwner {
		_isBlacklisted[_user] = true;
		blacklisted.push(_user);
  }
  function unblacklistUser(address _user) external onlyOwner {
		_isBlacklisted[_user] = false;
  }

	/********************************************************************************************************/
	/********************************************* Investment Limits ****************************************/
	/********************************************************************************************************/
	// Investment Limits
	mapping(address => bool) _isExcludedFromMaxInvestment;
	function setExcludedFromMaxInvestment(address account, bool exclude) external onlyOwner {
		_isExcludedFromMaxInvestment[account] = exclude;
	}
	function isExcludedFromMaxInvestment(address acc) external view returns(bool) {
		return _isExcludedFromMaxInvestment[acc];
	}
	uint256 maxuUSDInvestment = 100_000_000_000;
	function getMaxUSDInvestment() external view returns(uint256) {  
    return maxuUSDInvestment / 10**6;
  }
	function setMaxuUSDInvestment(uint256 _maxuUSDInvestment) external onlyOwner {
    maxuUSDInvestment = _maxuUSDInvestment;
  }
	
	/********************************************************************************************************/
	/********************************************* Transfer Limits ******************************************/
	/********************************************************************************************************/
	// Transfer Limits
	mapping(address => bool) _isExcludedFromMaxTransfer;
	function setExcludedFromMaxTransfer(address account, bool exclude) external onlyOwner {
		_isExcludedFromMaxTransfer[account] = exclude;
	}
	function isExcludedFromMaxTransfer(address acc) external view returns(bool) {
		return _isExcludedFromMaxTransfer[acc];
	}
	uint256 maxuUSDTransfer = 50_000_000_000;
	function getMaxUSDTransfer() external view returns(uint256) {  
    return maxuUSDTransfer / 10**6;
  }
	function setMaxuUSDTransfer(uint256 _maxuUSDTransfer) external onlyOwner {
    maxuUSDTransfer = _maxuUSDTransfer;
  }

	uint256 minuUSDTransfer = 9_999_999;
	function getMinUSDTransfer() external view returns(uint256) {  
    return minuUSDTransfer / 10**6;
  }
  function setMinuUSDTransfer(uint256 _minuUSDTransfer) external onlyOwner {
    minuUSDTransfer = _minuUSDTransfer;
  }

}