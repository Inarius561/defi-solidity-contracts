// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract ArbitrageExecutor is Ownable, ReentrancyGuard {

    error NotProfitable();
    error InvalidAddress();

    constructor() Ownable(msg.sender) {}

    function executeArbitrage(
        address routerA,
        address routerB,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minProfit
    ) external onlyOwner nonReentrant {

        if (
            routerA == address(0) ||
            routerB == address(0) ||
            tokenIn == address(0) ||
            tokenOut == address(0)
        ) revert InvalidAddress();

        IERC20(tokenIn).approve(routerA, amountIn);

        address;
        path[0] = tokenIn;
        path[1] = tokenOut;

        IUniswapV2Router(routerA).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).approve(routerB, tokenOutBalance);

        address;
        reversePath[0] = tokenOut;
        reversePath[1] = tokenIn;

        IUniswapV2Router(routerB).swapExactTokensForTokens(
            tokenOutBalance,
            0,
            reversePath,
            address(this),
            block.timestamp
        );

        uint256 finalBalance = IERC20(tokenIn).balanceOf(address(this));

        if (finalBalance < amountIn + minProfit) {
            revert NotProfitable();
        }
    }

    function withdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }
}
