// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

import {TestLock} from "../src/tests/TestLock.sol";

contract DeployTestLock is Script {
    address lockingAddr;
    address amAddr;

    function setUp() public {
        lockingAddr = vm.envAddress("LOCKING_ADDRESS");
        amAddr = vm.envAddress("ASSET_MANAGER");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address testLock = address(new TestLock(lockingAddr, amAddr));
        console.log("TestLock: ", testLock);
        vm.stopBroadcast();
    }
}
