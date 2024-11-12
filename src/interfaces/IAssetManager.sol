// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILocking} from "./ILocking.sol";

/**
 * @dev Interface of the AssetManager.
 */
interface IAssetManager {
    /**
     * @dev Emitted when a pool with index of `poolIndex`is first setup.
     * Consists a list of tokens `tokens`, `max` is the total locking limit of the pool.
     */
    event PoolSetup(
        uint32 indexed poolIndex,
        uint256 indexed max,
        address[] tokens
    );
    /**
     * @dev Emitted when a token `token` is added to a pool with index of `poolIndex`.
     */
    event TokenAdded(uint32 indexed poolIndex, address indexed token);
    /**
     * @dev Emitted when a token `token` is removed from a pool with index of `poolIndex`.
     */
    event TokenRemoveed(uint32 indexed poolIndex, address indexed token);
    /**
     * @dev Emitted when the locking limit `max` is updated to a pool with index of `poolIndex`.
     */
    event MaxUpdate(uint32 indexed poolIndex, uint256 indexed max);
    /**
     * @dev Emitted when the Goat Locking contract address is updated to `goatLocker`
     */
    event GoatLockerUpdate(address indexed goatLocker);

    /**
     * @dev Error when pass in an empty token list.
     */
    error InvalidTokenList();

    /**
     * @dev Error when add a registered token.
     */
    error RegisteredToken(address token);

    /**
     * @dev Error when remove a unregistered token.
     */
    error UnregisteredToken(address token);

    /**
     * @dev Error when access a non-existing pool
     */
    error InvalidPool(uint32 poolIndex);

    /**
     * @dev Error when pass in a zero address
     */
    error InvalidAddress();

    /**
     * @dev Return locking limist of the pool `_poolIndex`
     */
    function getPoolMax(uint32 _poolIndex) external view returns (uint256);

    /**
     * @dev Return all token addresses of the pool `_poolIndex`
     */
    function getPoolTokens(
        uint32 _poolIndex
    ) external view returns (address[] memory);

    /**
     * @dev Return the `_tokenIndex`th token address of the pool `_poolIndex`
     */
    function getPoolToken(
        uint32 _poolIndex,
        uint32 _tokenIndex
    ) external view returns (address);

    /**
     * @dev Returns the remaining locking amount of a token `_token`
     */
    function getPoolSpace(address _token) external view returns (uint256);

    /**
     * @dev Return false if the locking values `values` exceed the locking limit.
     */
    function isSafe(
        ILocking.Locking[] memory values
    ) external view returns (bool);
}
