// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFriendtechSharesV1 {
    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) external view returns (uint256);
}