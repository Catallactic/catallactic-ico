/**
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GasClickAntiWhale.sol";
import "hardhat/console.sol";

// possibly ERC20Capped
contract DemoToken is GasClickAntiWhale, ReentrancyGuard, IERC20 {
  using SafeMath for uint256;

	uint constant TRANSACTION_VALUE = 90;
	uint constant TRANSACTION_PROJECT_FEE = 10;
	uint constant TOKEN_DISTRIBUTION_SALES_AND_OPERATIONS = 90;
	uint constant TOKEN_DISTRIBUTION_PROJECT = 10;

	/********************************************************************************************************/
	/************************************************ Initial Values ****************************************/
	/********************************************************************************************************/
	constructor() {

		_isExcludedFromMaxInvestment[address(this)] = true;
		_isExcludedFromMaxInvestment[_projectWalletAddress] = true;
		_isExcludedFromMaxInvestment[_liquidityWalletAddress] = true;
		_isExcludedFromMaxInvestment[msg.sender] = true;

		_isExcludedFromMaxTransfer[address(this)] = true;
		_isExcludedFromMaxTransfer[_projectWalletAddress] = true;
		_isExcludedFromMaxTransfer[_liquidityWalletAddress] = true;
		_isExcludedFromMaxTransfer[msg.sender] = true;

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[_projectWalletAddress] = true;
		_isExcludedFromFees[_liquidityWalletAddress] = true;
		_isExcludedFromFees[address(this)] = true;

		// maybe use a ERC20Capped a 1_000_000_000
		// plus 3pc fees
		// plus wallets
		// plus DAO and proxy?
		// plus using SafeERC20 for ERC20;
		// pre-minted tokens
		//_totalSupply = 200_000_000;
		_mint(msg.sender, 200_000_000 * 10**18);
		console.log("Token Owner address: ", msg.sender);
		console.log("Balance of Sender: ", _balances[msg.sender]);

		//_mint(address(this), 200_000_000);
		//console.log("Token address: ", address(this));
		//console.log("Balance of Token: ", _balances[address(this)]);
	}

	/********************************************************************************************************/
	/************************************************** Owner ***********************************************/
	/********************************************************************************************************/

	/********************************************************************************************************/
	/************************************************ Token Info ********************************************/
	/********************************************************************************************************/
	string private _name = 'CryptoGas';
	function name() external view returns (string memory) {
		return _name;
	}
	string private _symbol = 'CYGAS';
	function symbol() external view returns (string memory) {
		return _symbol;
	}
	uint8 private _decimals = 18;
	function decimals() external view returns (uint8) {
		return _decimals;
	}

	/********************************************************************************************************/
	/********************************************** lifecycle ***********************************************/
	/********************************************************************************************************/


	/********************************************************************************************************/
	/********************************************** Supplies ************************************************/
	/********************************************************************************************************/
	uint256 private _totalSupply;
	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	/**************************************************** Mint **********************************************/
	function mint(uint256 amount) external {
		_mint(address(this), amount);
	}
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	/**************************************************** Burn **********************************************/


	/********************************************************************************************************/
	/********************************************* investors ************************************************/
	/********************************************************************************************************/
	// balances
  mapping(address => uint256) private _balances;
	function balanceOf(address account) external view virtual override returns (uint256) {
		return _balances[account];
	}

	// allowances
	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }
	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}
		return true;
  }
	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
		uint256 currentAllowance = _allowances[owner][spender];
		console.log("existing allowance: ", owner, spender, currentAllowance);
		console.log("required allowance: ", owner, spender, amount);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	// allowances
	mapping(address => mapping(address => uint256)) private _allowances;
	function allowance(address owner, address spender) external view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	// approval
	function approve(address spender, uint256 amount) external virtual override returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}
	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		console.log("_approved Allowance for: ", owner, spender, _allowances[owner][spender]);

		emit Approval(owner, spender, amount);
	}

	/********************************************************************************************************/
	/************************************************* Input Money ???????????????????????? ******************************************/
	/********************************************************************************************************/
	// * receive function
	receive() external payable {}

	// * fallback function
	fallback() external payable {}

	/********************************************************************************************************/
	/************************************************* Transfer *********************************************/
	/********************************************************************************************************/
  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
	function transfer(address to, uint256 amount) external virtual override returns (bool) {
		address owner = _msgSender();

		console.log("Token address: ", address(this));
		console.log("Balance of Token address: ",  _balances[address(this)]);
		console.log("Token Sender address: ", msg.sender);
		console.log("Balance of Sender Address: ", _balances[msg.sender]);

		_transferWithFees(owner, to, amount);
		return true;
	}
	/**
		* @dev See {IERC20-transferFrom}.
		*
		* Emits an {Approval} event indicating the updated allowance. This is not
		* required by the EIP. See the note at the beginning of {ERC20}.
		*
		* NOTE: Does not update the allowance if the current allowance
		* is the maximum `uint256`.
		*
		* Requirements:
		*
		* - `from` and `to` cannot be the zero address.
		* - `from` must have a balance of at least `amount`.
		* - the caller must have allowance for ``from``'s tokens of at least `amount`.
		*/
	function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
			address spender = _msgSender();
			_spendAllowance(from, spender, amount);
			_transferWithFees(from, to, amount);
			return true;
	}
	function _transferWithFees(address from, address to, uint256 amount) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		if(amount == 0) {
			return;
		}

		// if any account belongs to _isExcludedFromFee account then remove the fee
		/*bool takeFee = !_isExcludedFromFees[from] && !_isExcludedFromFees[to];
		if(takeFee) {
			uint256 fees = amount.mul(TRANSACTION_PROJECT_FEE).div(100);
			amount = amount.sub(fees);
			_transfer(from, address(this), fees);
		}*/

		_transfer(from, to, amount);
	}
	/**
		* @dev Moves `amount` of tokens from `from` to `to`.
		*
		* This internal function is equivalent to {transfer}, and can be used to
		* e.g. implement automatic token fees, slashing mechanisms, etc.
		*
		* Emits a {Transfer} event.
		*
		* Requirements:
		*
		* - `from` cannot be the zero address.
		* - `to` cannot be the zero address.
		* - `from` must have a balance of at least `amount`.
		*/
	function _transfer(address from, address to, uint256 amount) internal virtual {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		console.log("Token - Transferring: ", from, to, amount);
		if(amount == 0) {
			return;
		}

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
				_balances[from] = fromBalance - amount;
		}
		_balances[to] += amount;

		emit Transfer(from, to, amount);
	}

	/********************************************************************************************************/
	/************************************************* Liquidity ********************************************/
	/********************************************************************************************************/

	/********************************************** Swap and Liquify ****************************************/

	/************************************************** Swapback ********************************************/

	/************************************************** Buyback *********************************************/

	/************************************************** Rebase **********************************************/



	/********************************************************************************************************/
	/************************************************* Rewards **********************************************/
	/********************************************************************************************************/


	/************************************************* Fees *************************************************/
	// exclude from fees
	mapping (address => bool) private _isExcludedFromFees;
	
	function excludeFromFees(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromFees[account] != excluded, " : Account is already the value of 'excluded'");
		_isExcludedFromFees[account] = excluded;

		emit ExcludeFromFees(account, excluded);
	}
	event ExcludeFromFees(address indexed account, bool isExcluded);

	function isExcludedFromFees(address account) external view returns(bool) {
		return _isExcludedFromFees[account];
	}

	/************************************************* Wallets **********************************************/
	address private _projectWalletAddress;
	function setProjectWallet(address payable wallet) external onlyOwner{
			_projectWalletAddress = wallet;
	}
	address private _liquidityWalletAddress;
	function setLiquidityWallet(address payable wallet) external onlyOwner{
			_liquidityWalletAddress = wallet;
	}

	/************************************************* Withdraw *********************************************/









	/*********************************************** Reflections ********************************************/

	/************************************************ Dividends *********************************************/

	/********************************************************************************************************/
	/************************************************ Governance ********************************************/
	/********************************************************************************************************/


}