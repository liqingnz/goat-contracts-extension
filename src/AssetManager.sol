// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ILocking} from "./ILocking.sol";

contract AssetManager is OwnableUpgradeable {

    event PoolSetup(uint32 indexed poolIndex, uint256 indexed max, address[] tokens);
    event TokenAdded(uint32 indexed poolIndex, address indexed token);
    event TokenRemoveed(uint32 indexed poolIndex, address indexed token);
    event MaxUpdate(uint32 indexed poolIndex, uint256 indexed max);
    event GoatLockerUpdate(address indexed goatLocker);

    ILocking public goatLocker;

    struct PoolInfo {
        uint256 maxLimit;
        address[] tokenList;
    }

    uint32 public poolIndexCounter = 1; // index start from 1, 0 means not yet setup
    mapping(uint32 poolIndex => PoolInfo) public poolInfos;
    mapping(address token => uint32 poolIndex) public tokenPoolIndexes;

    function initialize(address _goatLocker, address _owner) public initializer {
        goatLocker = ILocking(_goatLocker);
        __Ownable_init(_owner);
    }

    // get all token addresses of the pool
    function getPoolTokens(uint32 _poolIndex) external view returns(address[] memory) {
        return poolInfos[_poolIndex].tokenList;
    }

    // get the specific index token address of the pool
    function getPoolToken(uint32 _poolIndex, uint32 _tokenIndex) external view returns(address) {
        return poolInfos[_poolIndex].tokenList[_tokenIndex];
    }

    // check for remaining locking amount of a token pool
    function getPoolSpace(address _token) external view returns (uint256) {
        uint256 total;
        address[] memory tokenList = poolInfos[tokenPoolIndexes[_token]].tokenList;
        for(uint32 i; i < tokenList.length; ++i) {
            total += goatLocker.totalLocking(tokenList[i]);
        }
        return poolInfos[tokenPoolIndexes[_token]].maxLimit - total;
    }

    // setup a new token pool
    function setupPool(uint256 _max, address[] calldata _tokens) external onlyOwner {
        require(_tokens.length > 0, "invalid token");
        poolInfos[poolIndexCounter] = PoolInfo(_max, _tokens);
        for(uint32 i; i < _tokens.length; ++i) {
            require(tokenPoolIndexes[_tokens[i]] == 0, "already registered");
            tokenPoolIndexes[_tokens[i]] = poolIndexCounter;
        }
        emit PoolSetup(++poolIndexCounter, _max, _tokens);
    }

    // add new token to a pool
    function addTokenToPool(uint32 _poolIndex, address _token) external onlyOwner {
        require(tokenPoolIndexes[_token] == 0, "already registered");
        tokenPoolIndexes[_token] = _poolIndex;
        poolInfos[_poolIndex].tokenList.push(_token);
        emit TokenAdded(tokenPoolIndexes[_token], _token);
    }

    // remove a token from the pool
    function removeTokenFromPool(address _token) external onlyOwner {
        address[] storage tokenList = poolInfos[tokenPoolIndexes[_token]].tokenList;
        for(uint32 i; i <tokenList.length; ++i) {
            if (tokenList[i] == _token) {
                if (i != tokenList.length - 1) {
                    tokenList[i] = tokenList[tokenList.length - 1];
                }
                tokenList.pop();
                emit TokenAdded(tokenPoolIndexes[_token], _token);
            }
        }
    }

    // set the max limit of a pool
    function setPoolMax(uint32 _poolIndex, uint256 _max) external onlyOwner {
        require(poolInfos[_poolIndex].tokenList.length > 0, "pool does not exit");
        poolInfos[_poolIndex].maxLimit = _max;
        emit MaxUpdate(_poolIndex, _max);
    }

    // update the goat locking contract address
    function setGoatLocker(address _addr) external onlyOwner {
        require(_addr != address(0), "invalid address");
        goatLocker = ILocking(_addr);
        emit GoatLockerUpdate(_addr);
    }
}