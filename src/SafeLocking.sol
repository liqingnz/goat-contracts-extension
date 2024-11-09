// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {ILocking} from "./ILocking.sol";
import {AssetManager} from "./AssetManager.sol";

contract SafeLocking {

    ILocking public goatLocker;
    AssetManager public assetManager;

    constructor(address _goatLocker, address _assetManager) {
        goatLocker = ILocking(_goatLocker);
        assetManager = AssetManager(_assetManager);
    }
   
    // revert if the locked amount is greater than the pool max
    function safeLock(
        address validator,
        ILocking.Locking[] calldata values
    )
        external
        virtual
        payable
    {
        for (uint256 i = 0; i < values.length; i++) {
            ILocking.Locking memory value = values[i];
            require(value.amount <= assetManager.getPoolSpace(value.token), "exceeded max");
        }
        goatLocker.lock(validator, values);
    }

    // revert if the locked amount is less than the threshold after unlock
    function safeUnlock(
        address validator,
        address recipient,
        ILocking.Locking[] calldata values
    )
        external
        virtual
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
        address validator,
        address recipient,
        address[] calldata tokens
    )
        external
        virtual
    {
        ILocking.Locking[] memory values = new ILocking.Locking[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            values[i].amount = goatLocker.locking(msg.sender, values[i].token);
        }
        goatLocker.unlock(validator, recipient, values);
    }

    // update the goat locking contract address
    function setGoatLocker(address _addr) external {
        require(_addr != address(0), "invalid address");
        goatLocker = ILocking(_addr);
    }

    // update the goat locking contract address
    function setAssetManager(address _addr) external {
        require(_addr != address(0), "invalid address");
        assetManager = AssetManager(_addr);
    }
}