// File: contracts/PLSBV6.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "gitlab.com/"

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WPLS() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


////////CONTRACT//IMPLEMENTATION/////////

contract PLSBV7 is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    using Address for address;
    address private _owner;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;

    string private constant _name = "PLSBV7";
    string private constant _symbol = "PLSBV7";
    uint8 private constant _decimals = 4;

    uint256 constant _totalSupply = 55555555 * (10**_decimals);
    uint256 private constant _tTotal = _totalSupply;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    struct Fees {
        uint16 reflect;
        uint16 burn;
        uint16 liquidity;
        uint16 treasury;
        uint16 team;
        uint16 charity;
        uint16 totalSwap;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 total;
    }

    Fees public _buyTaxes =
        Fees({
            reflect: 200,
            burn: 200,
            liquidity: 400,
            treasury: 200,
            charity: 200,
            team: 200,
            totalSwap: 200
        });

    Fees public _sellTaxes =
        Fees({
            reflect: 0,
            burn: 200,
            liquidity: 0,
            treasury: 0,
            charity: 0,
            team: 0,
            totalSwap: 20
        });

    Ratios public _ratios = Ratios({liquidity: 200, total: 200});

    uint256 constant masterTaxDivisor = 10000;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant charityWallet =
        0x29751598271D344f4C387dAE50990eB10217A08D;
    address public constant teamWallet =
        0x4a6fbC4Ef1815CdB254dAB6ff34f1e4837E54042;
    address public constant treasuryWallet =
        0xCD56B9788ED5919714CB2c45724Cf4cCfA6EfB33;

    bool inSwap;
    uint256 public contractSwapTimer = 0 seconds;
    uint256 private lastSwap;
    uint256 public constant swapThreshold = (_tTotal * 5) / 10000;
    uint256 public constant swapAmount = (_tTotal * 10) / 10000;

    uint256 private _maxTxAmount = (_tTotal * 200) / 10000;

    event BalanceUpdate(address indexed addr, uint256 value);


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }

    constructor() payable {
        _rOwned[msg.sender] = _rTotal;

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 941) {
            dexRouter = IUniswapV2Router02(
                0xb4A7633D8932de086c9264D5eb39a8399d7C0E3A
            );
            contractSwapTimer = 10 seconds;
        } else {
            revert();
        }

        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(
            dexRouter.WPLS(),
            address(this)
        );
        lpPairs[lpPair] = true;

        _approve(msg.sender, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromLimits[owner()] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;


        emit Transfer(address(0), _msgSender(), _tTotal);
        
    }

    

    receive() external payable {}

    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }


    function _isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

// Add liquidity pools to PLSB
    function _checkIfAddressIfUniswapV2PLSBPool(address addr) public view returns (bool) {
        if(!_isContract(addr))
            return false;

        address plsbAddress = address(this); 
        try IUniswapV2Pair(addr).token0() returns (address token0) {
            if(token0 == plsbAddress)
                return true;
        }
        catch {
            return false;
        }
        try IUniswapV2Pair(addr).token1() returns (address token1) {
            if(token1 == plsbAddress)
                return true;
        }
        catch {
        }
        return false;
    }

    function deletePlsbPoolKey() external virtual onlyOwner {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function totalSupply() external pure override returns (uint256) {
        if (_tTotal == 0) {
            revert();
        }
        return _tTotal;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Sender is not zero Address");
        require(spender != address(0), "ERC20: Spender is not zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function getCirculatingSupply() external view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled)
        private
    {
        _isExcludedFromFees[account] = enabled;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (lpPairs[from] || lpPairs[to]) {
            if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
            }
        }
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if (lpPairs[to]) {
            if (!inSwap) {
                if (lastSwap + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if (contractTokenBalance >= swapAmount) {
                            contractTokenBalance = swapAmount;
                        }
                        contractSwap(contractTokenBalance);
                        lastSwap = block.timestamp;
                    }
                }
            }
        }
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        if (
            _allowances[address(this)][address(dexRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) /
            ratios.total) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WPLS();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 tBurn;
        uint256 tCharity;
        uint256 tTeam;
        uint256 tTreasury;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
        uint256 currentRate;
    }

    function _finalizeTransfer(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee
    ) private returns (bool) {
        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }

        emit Transfer(from, to, values.tTransferAmount);
        emit BalanceUpdate(from, balanceOf(from));
        emit BalanceUpdate(to, balanceOf(to));

        return true;
    }

    function _getValues(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee
    ) private returns (ExtraValues memory) {
        ExtraValues memory values;
        values.currentRate = _getRate();

        values.rAmount = tAmount * values.currentRate;

        if (takeFee) {
            uint256 currentReflect;
            uint256 currentSwap;
            uint256 currentBurn;
            uint256 currentCharity;
            uint256 currentTeam;
            uint256 currentTreasury;
            uint256 divisor = masterTaxDivisor;

          if (_checkIfAddressIfUniswapV2PLSBPool(to)) {
                currentReflect = _sellTaxes.reflect;
                currentBurn = _sellTaxes.burn;
                currentCharity = _sellTaxes.charity;
                currentTeam = _sellTaxes.team;
                currentTreasury = _sellTaxes.treasury;
                currentSwap = _sellTaxes.totalSwap;
            } else if (_checkIfAddressIfUniswapV2PLSBPool(from)) {
                currentReflect = _buyTaxes.reflect;
                currentBurn = _buyTaxes.burn;
                currentCharity = _buyTaxes.charity;
                currentTeam = _buyTaxes.team;
                currentTreasury = _buyTaxes.treasury;
                currentSwap = _buyTaxes.totalSwap;
            }

            values.tFee = (tAmount * currentReflect) / divisor;
            values.tSwap = (tAmount * currentSwap) / divisor;
            values.tBurn = (tAmount * currentBurn) / divisor;
            values.tCharity = (tAmount * currentCharity) / divisor;
            values.tTeam = (tAmount * currentTeam) / divisor;
            values.tTreasury = (tAmount * currentTreasury) / divisor;
            values.tTransferAmount =
                tAmount -
                (values.tFee +
                    values.tSwap +
                    values.tBurn +
                    values.tCharity +
                    values.tTeam +
                    values.tTreasury);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tBurn = 0;
            values.tCharity = 0;
            values.tTeam = 0;
            values.tTreasury = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            
            emit Transfer(from, address(this), values.tSwap);
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] += values.tBurn * values.currentRate;
            
            emit Transfer(from, DEAD, values.tBurn);
        }

        if (values.tCharity > 0) {
            _rOwned[charityWallet] += values.tCharity * values.currentRate;
           
            emit Transfer(from, charityWallet, values.tCharity);
        }

        if (values.tTeam > 0) {
            _rOwned[teamWallet] += values.tTeam * values.currentRate;
          
            emit Transfer(from, teamWallet, values.tTeam);
        }
        if (values.tTreasury > 0) {
            _rOwned[treasuryWallet] += values.tTreasury * values.currentRate;
            
            emit Transfer(from, treasuryWallet, values.tTreasury);
        }

        values.rTransferAmount =
            values.rAmount -
            (values.rFee +
                (values.tSwap * values.currentRate) +
                (values.tBurn * values.currentRate) +
                (values.tCharity * values.currentRate) +
                (values.tTeam * values.currentRate) +
                (values.tTreasury * values.currentRate));
        return values;
    }

    function _getRate() internal view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }
}