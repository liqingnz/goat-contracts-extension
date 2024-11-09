// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILocking} from "./ILocking.sol";
import {IAssetManager} from "./IAssetManager.sol";

library SafeLocking {
   
    // revert if the locked amount is greater than the pool max
    function safeLock(
        ILocking goatLocker,
        address assetManager,
        address validator,
        ILocking.Locking[] calldata values
    )
        external
    {
        for (uint256 i = 0; i < values.length; i++) {
            ILocking.Locking memory value = values[i];
            require(value.amount <= IAssetManager(assetManager).getPoolSpace(value.token), "exceeded max");
        }
        goatLocker.lock(validator, values);
    }

    // revert if the locked amount is less than the threshold after unlock
    function safeUnlock(
        ILocking goatLocker,
        address validator,
        address recipient,
        ILocking.Locking[] calldata values
    )
        external
    {
        for (uint256 i = 0; i < values.length; i++) {
            ILocking.Locking memory value = values[i];
            ILocking.Token memory tokenConfig = goatLocker.tokens(value.token);
            require(goatLocker.locking(msg.sender, value.token) - value.amount > tokenConfig.threshold, "below threshold");
        }
        goatLocker.unlock(validator, recipient, values);
    }

    // withdraw all token from lock
    function exit(
        ILocking goatLocker,
        address validator,
        address recipient,
        address[] calldata tokens
    )
        external
    {
        ILocking.Locking[] memory values = new ILocking.Locking[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            values[i].amount = goatLocker.locking(msg.sender, values[i].token);
        }
        goatLocker.unlock(validator, recipient, values);
    }
}