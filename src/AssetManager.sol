// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAssetManager, ILocking} from "./interfaces/IAssetManager.sol";

/**
 * @dev An extension of Goat Locking contract.
 * Setups and maintain pools of tokens with max locking amount.
 * Provides a getter for pool remaining locking space.
 */
contract AssetManager is IAssetManager, OwnableUpgradeable {
    ILocking public goatLocker;

    struct PoolInfo {
        uint256 max;
        address[] tokenList;
    }

    /*
     * @dev index start from 1, 0 means not yet setup
     */
    uint32 public poolIndexCounter;
    mapping(uint32 poolIndex => PoolInfo) public poolInfos;
    mapping(address token => uint32 poolIndex) public tokenPoolIndexes;

    function initialize(
        address _goatLocker,
        address _owner
    ) public initializer {
        goatLocker = ILocking(_goatLocker);
        __Ownable_init(_owner);
        poolIndexCounter = 1;
    }

    /**
     * @dev Return locking limist of the pool `_poolIndex`
     */
    function getPoolMax(uint32 _poolIndex) external view returns (uint256) {
        return poolInfos[_poolIndex].max;
    }

    /**
     * @dev Return all token addresses of the pool `_poolIndex`
     */
    function getPoolTokens(
        uint32 _poolIndex
    ) external view returns (address[] memory) {
        return poolInfos[_poolIndex].tokenList;
    }

    /**
     * @dev Return the `_tokenIndex`th token address of the pool `_poolIndex`
     */
    function getPoolToken(
        uint32 _poolIndex,
        uint32 _tokenIndex
    ) external view returns (address) {
        return poolInfos[_poolIndex].tokenList[_tokenIndex];
    }

    /**
     * @dev Returns the remaining locking amount of a token `_token`
     */
    function getPoolSpace(address _token) public view returns (uint256) {
        uint256 total;
        address[] memory tokenList = poolInfos[tokenPoolIndexes[_token]]
            .tokenList;
        for (uint32 i; i < tokenList.length; ++i) {
            total += goatLocker.totalLocking(tokenList[i]);
        }
        return poolInfos[tokenPoolIndexes[_token]].max - total;
    }

    /**
     * @dev Return false if the locking values `values` exceed the locking limit.
     */
    function isSafe(
        ILocking.Locking[] memory values
    ) external view returns (bool) {
        uint256[] memory totals = new uint256[](values.length);
        for (uint8 i; i < values.length; ++i) {
            if (values[i].amount > 0) {
                totals[i] = values[i].amount;
                for (uint8 j = i + 1; j < values.length; ++j) {
                    if (
                        tokenPoolIndexes[values[i].token] ==
                        tokenPoolIndexes[values[j].token]
                    ) {
                        totals[i] += values[j].amount;
                        values[j].amount = 0;
                    }
                }
                if (totals[i] > getPoolSpace(values[i].token)) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @dev Setup a new token pool with `_max` locking limit and `_tokens` tokens
     * Requirement:
     * - have at least one token
     * - token has not been added to another pool
     */
    function setupPool(
        uint256 _max,
        address[] calldata _tokens
    ) external onlyOwner {
        require(_tokens.length > 0, InvalidTokenList());
        poolInfos[poolIndexCounter] = PoolInfo(_max, _tokens);
        for (uint32 i; i < _tokens.length; ++i) {
            require(
                tokenPoolIndexes[_tokens[i]] == 0,
                RegisteredToken(_tokens[i])
            );
            tokenPoolIndexes[_tokens[i]] = poolIndexCounter;
        }
        emit PoolSetup(poolIndexCounter++, _max, _tokens);
    }

    /**
     * @dev Add new token `_token` to pool `_poolIndex`
     * Requirement:
     * - token has not been added to another pool
     */
    function addTokenToPool(
        uint32 _poolIndex,
        address _token
    ) external onlyOwner {
        require(_poolIndex < poolIndexCounter, InvalidPool(_poolIndex));
        require(tokenPoolIndexes[_token] == 0, RegisteredToken(_token));
        tokenPoolIndexes[_token] = _poolIndex;
        poolInfos[_poolIndex].tokenList.push(_token);
        emit TokenAdded(_poolIndex, _token);
    }

    /**
     * @dev Remove the token `_token` from its' pool
     * Requirement:
     * - token has been registered
     */
    function removeTokenFromPool(address _token) external onlyOwner {
        require(tokenPoolIndexes[_token] != 0, UnregisteredToken(_token));
        address[] storage tokenList = poolInfos[tokenPoolIndexes[_token]]
            .tokenList;
        for (uint32 i; i < tokenList.length; ++i) {
            if (tokenList[i] == _token) {
                if (i != tokenList.length - 1) {
                    tokenList[i] = tokenList[tokenList.length - 1];
                }
                tokenList.pop();
                emit TokenRemoved(tokenPoolIndexes[_token], _token);
                tokenPoolIndexes[_token] = 0;
            }
        }
    }

    /**
     * @dev Set the locking limit of a pool `_poolIndex` to `_max`
     * Requirement:
     * - pool has been setup
     */
    function setPoolMax(uint32 _poolIndex, uint256 _max) external onlyOwner {
        require(_poolIndex < poolIndexCounter, InvalidPool(_poolIndex));
        poolInfos[_poolIndex].max = _max;
        emit MaxUpdated(_poolIndex, _max);
    }

    /**
     * @dev Update the goat locking contract address
     * Requirement:
     * - cannot set to address zero
     */
    function setGoatLocker(address _addr) external onlyOwner {
        require(_addr != address(0), InvalidAddress());
        goatLocker = ILocking(_addr);
        emit GoatLockerUpdated(_addr);
    }
}
