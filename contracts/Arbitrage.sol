// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapV2Router.sol";

contract Arbitrage {
    /// @notice The token that start swap with.
    address public tokenA;

    /// @notice The token that swap with first token to.
    address public tokenB;

    /// @notice The token that swap with second token to.
    address public tokenC;

    /// @notice The address of the owner.
    address public owner;

    /// @notice The address of the router.
    address public routerAddress;

    /// @notice Flag if swap is allowed or not.
    bool public swapAllowed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(address _routerAddress) {
        require(_routerAddress != address(0), "invalid router address");

        owner = msg.sender;
        swapAllowed = false;
        routerAddress = _routerAddress;
    }

    function toogleSwapAllowed() external onlyOwner {
        swapAllowed = !swapAllowed;
    }

    function setSwapTokens(
        address _tokenA,
        address _tokenB,
        address _tokenC
    ) external onlyOwner {
        require(
            _tokenA != _tokenC && _tokenA != _tokenB && _tokenB != _tokenC,
            "invalid token pairs"
        );

        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenC = _tokenC;
    }

    function checkBenefit(uint256 _swapAmount) external view returns (bool) {
        if (!swapAllowed || _swapAmount == 0) {
            return false;
        }

        uint256 amountOut = _getAmountOut(tokenA, tokenB, _swapAmount);
        amountOut = _getAmountOut(tokenA, tokenB, amountOut);
        amountOut = _getAmountOut(tokenB, tokenC, amountOut);
        amountOut = _getAmountOut(tokenC, tokenA, amountOut);

        return amountOut > _swapAmount;
    }

    function _getAmountOut(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        uint256[] memory amounts = ISwapRouter02(routerAddress).getAmountsOut(
            _amount,
            path
        );
        return amounts[1];
    }
}
