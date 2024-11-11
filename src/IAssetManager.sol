// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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
     * @dev Returns the remaining locking amount of a token `_token`
     */
    function getPoolSpace(address _token) external view returns (uint256);
}
