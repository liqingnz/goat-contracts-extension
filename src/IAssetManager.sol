// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAssetManager {
    function getPoolSpace(address _token) external view returns (uint256);
}