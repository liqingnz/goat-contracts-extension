// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILocking} from "./interfaces/ILocking.sol";
import {IAssetManager} from "./interfaces/IAssetManager.sol";

/**
 * @dev Wrappers around Goat Locking contract that revert when:
 * 1, locking amount exceeded pool max;
 * 2, locked amount after unlock is below the required threshold.
 * And provides an exit API for fully unlock chosen tokens.
 *
 * To use this library you can add a `using SafeLocking for ILocking;` statement to your contract,
 * which allows you to call the safe operations as `ILocking.safeLock(...)`, etc.
 */
library SafeLocking {
    /**
     * @dev An operation with lock failed.
     */
    error SafeLockFailed();

    /**
     * @dev An operation with unlock failed.
     */
    error SafeUnlockFailed(address token, uint256 amount);

    /**
     * @dev Lock `values` tokens to `goatLocker` with validator of `validator`.
     * Need to pass in the address of AssetManager to get the correct locking limit.
     * Revert if the locked amount exceeds the pool max
     */
    function safeLock(
        ILocking goatLocker,
        address assetManager,
        address validator,
        ILocking.Locking[] calldata values
    ) external {
        require(IAssetManager(assetManager).isSafe(values), SafeLockFailed());
        goatLocker.lock{value: msg.value}(validator, values);
    }

    /**
     * @dev Unlock `values` tokens from `goatLocker` with validator of `validator`,
     * recipient of `recipient`.
     * Revert if the locked amount is below the threshold after unlock
     */
    function safeUnlock(
        ILocking goatLocker,
        address validator,
        address recipient,
        ILocking.Locking[] calldata values
    ) external {
        for (uint256 i; i < values.length; ++i) {
            ILocking.Locking memory value = values[i];
            ILocking.Token memory tokenConfig = goatLocker.tokens(value.token);
            require(
                goatLocker.locking(msg.sender, value.token) - value.amount >=
                    tokenConfig.threshold,
                SafeUnlockFailed(value.token, value.amount)
            );
        }
        goatLocker.unlock(validator, recipient, values);
    }

    /**
     * @dev Unlock all `tokens` tokens from `goatLocker` with validator of `validator`,
     * recipient of `recipient`.
     */
    function exit(
        ILocking goatLocker,
        address validator,
        address recipient,
        address[] calldata tokens
    ) external {
        ILocking.Locking[] memory values = new ILocking.Locking[](
            tokens.length
        );
        for (uint256 i; i < tokens.length; ++i) {
            values[i].token = tokens[i];
            values[i].amount = goatLocker.locking(msg.sender, tokens[i]);
        }
        goatLocker.unlock(validator, recipient, values);
    }
}
