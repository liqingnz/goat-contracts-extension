// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeLocking} from "../SafeLocking.sol";
import {ILocking} from "../interfaces/ILocking.sol";

contract TestLock {
    using SafeLocking for ILocking;

    ILocking locking;
    address assetManager;

    constructor(address _locking, address _assetManager) {
        locking = ILocking(_locking);
        assetManager = _assetManager;
    }

    function depositAndApprove(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).approve(address(locking), _amount);
    }

    function lock(
        address _validator,
        ILocking.Locking[] calldata _values
    ) external {
        locking.lock(_validator, _values);
    }

    function safeLock(
        address _validator,
        ILocking.Locking[] calldata _values
    ) external {
        locking.safeLock(assetManager, _validator, _values);
    }

    function unlock(
        address _validator,
        address _recipient,
        ILocking.Locking[] calldata _values
    ) external {
        locking.unlock(_validator, _recipient, _values);
    }

    function safeUnlock(
        address _validator,
        address _recipient,
        ILocking.Locking[] calldata _values
    ) external {
        locking.safeUnlock(_validator, _recipient, _values);
    }

    function exit(
        address _validator,
        address _recipient,
        address[] calldata tokens
    ) external {
        locking.exit(_validator, _recipient, tokens);
    }
}
