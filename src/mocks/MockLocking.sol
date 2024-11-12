// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLocking {
    event Lock(address validator, address token, uint256 amount);
    event Unlock(
        uint64 id,
        address validator,
        address recipient,
        address token,
        uint256 amount
    );

    struct Locking {
        address token;
        uint256 amount;
    }

    struct Token {
        bool exist; // placehold for existence check
        uint64 weight; // weight for validator power
        uint256 limit; // the max amount to lock, 0 represents no limits
        uint256 threshold; // the min amount to create a validator, 0 represents no required
    }

    uint64 internal reqId;

    mapping(address validator => mapping(address token => uint256 amount))
        public locking;

    mapping(address token => uint256 amount) public totalLocking;

    function tokens(address) public pure returns (Token memory) {
        return Token(true, 1, 10 ether, 5 ether);
    }

    function lock(
        address validator,
        Locking[] calldata values
    ) external payable {
        uint256 msgValue = msg.value;
        for (uint256 i; i < values.length; ++i) {
            Locking memory value = values[i];
            Token memory tokenConfig = tokens(value.token);

            require(value.amount > 0);

            // the threshold changed
            uint256 locked = locking[validator][value.token];
            if (locked < tokenConfig.threshold) {
                uint256 min = tokenConfig.threshold - locked;
                require(value.amount >= min);
            }

            if (value.token == address(0)) {
                require(msgValue == value.amount);
                msgValue = 0;
            } else {
                IERC20(value.token).transferFrom(
                    msg.sender,
                    address(this),
                    value.amount
                );
            }
            uint256 limit = totalLocking[value.token] + value.amount;
            require(tokenConfig.limit == 0 || tokenConfig.limit >= limit);
            totalLocking[value.token] = limit;

            locking[validator][value.token] += value.amount;
            emit Lock(validator, value.token, value.amount);
        }
        require(msgValue == 0);
    }

    function unlock(
        address validator,
        address recipient,
        Locking[] calldata values
    ) external {
        require(values.length > 0 && values.length <= 8);
        require(recipient != address(0));
        for (uint256 i = 0; i < values.length; i++) {
            Locking memory value = values[i];
            require(value.amount > 0);
            locking[validator][value.token] -= value.amount;
            totalLocking[value.token] -= value.amount;
            if (value.token != address(0) && value.amount > 0) {
                IERC20(value.token).transfer(recipient, value.amount);
            }
            emit Unlock(
                reqId++,
                validator,
                recipient,
                value.token,
                value.amount
            );
        }
    }
}
