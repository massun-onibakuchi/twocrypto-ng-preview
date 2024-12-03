// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

// import {ERC20} from "solady/src/tokens/ERC20.sol";
// import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

// type TwoCrypto is address;
// type Token is address;

// contract PrincipalToken is ERC20, ReentrancyGuard {
//     ERC20 immutable i_yt;

//     /// @notice Deposit `shares` of YBT and mint `principal` amount of PT and YT to `receiver`
//     function supply(uint256 shares, address receiver) external nonReentrant returns (uint256) {}

//     /// @notice Burn `msg.sender`'s `principal` amount of PT and YT and send back `shares` of YBT to `receiver`.
//     function combine(uint256 principal, address receiver) external nonReentrant returns (uint256) {
//         //
//     }

//     function flashLoan(address _receiver, address _token, uint256 _amount, bytes calldata _data)
//         external
//         returns (bool)
//     {}

//     function name() public view override returns (string memory) {}

//     function symbol() public view override returns (string memory) {}
// }

// contract Router {
//     struct SwapYtParams {
//         TwoCrypto twoCrypto;
//         uint256 principal; // Amount of YT to sell
//         Token tokenOut; // YBT
//         uint256 amountOutMin;
//         address receiver;
//         uint256 deadline;
//     }

//     //// @notice Swap approx `principal` of YT to at least `minAmount` of `tokenOut` and send the `tokenOut` to `receiver`
//     function swapYtForToken(SwapYtParams calldata params, uint256 /* otherParams  */) external returns(uint256 amountOut) {
//         // Background:
//         // - We have a TwoCrypto pool PrincipalToken/Yield-bearing asset(YBT) pair per PrincipalToken instance.
//         // - 1 PT + 1 YT are always redeemable for 1 YBT.
//         // Big idea
//         // Since there's no native pool for YT, Router executes a two-step process: exchanging YBT for PT and then redeeming.
//         // To exchange YT for YBT, Router first needs to acquire PTs from the market, but it requires YBT to do so.
//         // The challenge lies in sourcing the initial YBT for buying PTs.
//         // I think there are two options to borrow YBTs:
//         // A. Flash swap
//         // B. Flash loan
//         //
//         // A) Flow
//         // 1. Router transfer YT from user
//         // 2. Flash swap YBT for PTs
//         // 2. Router redeems PTs and YTs for YBT on flashswap callback
//         // 3. Router repay debt
//         // 4. Router sends remaining of YBT to user.

//         // B) `PrincipalToken` contract CAN implement flashloan but it means reentrancy must be allowed against flashloan function.
//         // IMO it is a security concern.
//         // Spectra doesn't use nonReentrant mod but they use it for all other functions https://github.com/perspectivefi/spectra-core/blob/085198ab489842edb34a795017e603ad39c5eee7/src/tokens/PrincipalToken.sol#L470
//     }
// }
