pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {AssetManager} from "../src/AssetManager.sol";
import {IAssetManager} from "../src/interfaces/IAssetManager.sol";
import {SafeLocking} from "../src/SafeLocking.sol";
import {TestLock} from "../src/tests/TestLock.sol";
import {ILocking} from "../src/interfaces/ILocking.sol";

import {MockLocking} from "../src/mocks/MockLocking.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract LockingProcess is Test {
    AssetManager public assetManager;
    TestLock public testLock;

    MockLocking public locking;
    address[] public mockTokens;
    address public msgSender;

    uint256 public constant DEFAULT_LOCK_AMOUNT = 10 ether;
    uint256 public constant TEST_POOL_MAX = 20 ether;

    function setUp() public virtual {
        msgSender = address(this);

        // deploy mock Goat Locking contract
        locking = new MockLocking();

        // deploy mock tokens
        for (uint8 i; i < 3; ++i) {
            mockTokens.push(address(new MockToken()));
        }

        // deploy AssetManager
        address logic = address(new AssetManager());
        address proxy = address(
            new TransparentUpgradeableProxy(logic, msgSender, "")
        );
        assetManager = AssetManager(proxy);
        assetManager.initialize(address(locking), msgSender);
        assertEq(assetManager.owner(), msgSender);

        // deploy a test contract for testing SafeLocking library
        testLock = new TestLock(address(locking), address(assetManager));
        // deposit token into the test contract
        for (uint8 i; i < 3; ++i) {
            MockToken(mockTokens[i]).approve(
                address(testLock),
                DEFAULT_LOCK_AMOUNT
            );
            testLock.depositAndApprove(mockTokens[i], DEFAULT_LOCK_AMOUNT);
        }

        // setup a pool: 3 tokens with a total locking limit of 20 ether
        assetManager.setupPool(TEST_POOL_MAX, mockTokens);
    }

    function test_Lock() public {
        // fail: total locking amount exceeded 20 (10 + 10 + 10 > 20)
        ILocking.Locking[] memory values = new ILocking.Locking[](3);
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], DEFAULT_LOCK_AMOUNT);
        }
        vm.expectRevert(SafeLocking.SafeLockFailed.selector);
        testLock.safeLock(msgSender, values);

        // success
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], 5 ether);
        }
        vm.expectEmit(true, true, true, true);
        emit ILocking.Lock(msgSender, values[0].token, values[0].amount);
        testLock.safeLock(msgSender, values);
        for (uint8 i; i < 3; ++i) {
            assertEq(
                locking.locking(msgSender, values[i].token),
                values[i].amount
            );
        }

        // would still pass for non-safe locks
        vm.expectEmit(true, true, true, true);
        emit ILocking.Lock(msgSender, values[0].token, values[0].amount);
        testLock.lock(msgSender, values);
    }

    function test_Lock2() public {
        // new user A
        address userA = makeAddr("user A");
        vm.startPrank(userA);
        // token setup for user A
        for (uint8 i; i < 3; ++i) {
            MockToken(mockTokens[i]).mint(userA, DEFAULT_LOCK_AMOUNT);
            MockToken(mockTokens[i]).approve(
                address(testLock),
                DEFAULT_LOCK_AMOUNT
            );
            testLock.depositAndApprove(mockTokens[i], DEFAULT_LOCK_AMOUNT);
        }
        // user A lock first
        ILocking.Locking[] memory values = new ILocking.Locking[](3);
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], 5 ether);
        }
        testLock.safeLock(msgSender, values);
        vm.stopPrank();

        // fail: exceeds the limit (20, Current total = 5 + 5 + 5).
        assertEq(
            assetManager.getPoolSpace(mockTokens[0]),
            TEST_POOL_MAX - (3 * 5 ether)
        );
        vm.expectRevert(SafeLocking.SafeLockFailed.selector);
        testLock.safeLock(msgSender, values);

        // it is safe to lock one token
        values = new ILocking.Locking[](1);
        values[0] = ILocking.Locking(mockTokens[0], 5 ether);
        vm.expectEmit(true, true, true, true);
        emit ILocking.Lock(msgSender, values[0].token, values[0].amount);
        testLock.safeLock(msgSender, values);
    }

    function test_Unlock() public {
        uint256 THRESHOLD = 5 ether;
        uint64 reqId;
        ILocking.Locking[] memory values = new ILocking.Locking[](3);
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], DEFAULT_LOCK_AMOUNT);
        }
        testLock.lock(msgSender, values);

        // fail: below threshold after unlock
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(
                mockTokens[i],
                DEFAULT_LOCK_AMOUNT - THRESHOLD + 1 // 1 wei below threshold
            );
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                SafeLocking.SafeUnlockFailed.selector,
                values[0].token,
                values[0].amount
            )
        );
        testLock.safeUnlock(msgSender, msgSender, values);

        // success
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(
                mockTokens[i],
                DEFAULT_LOCK_AMOUNT - THRESHOLD // equal threshold
            );
        }
        vm.expectEmit(true, true, true, true);
        emit ILocking.Unlock(
            reqId,
            msgSender,
            msgSender,
            values[0].token,
            values[0].amount
        );
        testLock.safeUnlock(msgSender, msgSender, values);
        reqId += 3;

        // fail: will not be able to safely unlock any token
        // when threshold has been reached
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], 1);
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                SafeLocking.SafeUnlockFailed.selector,
                values[0].token,
                1
            )
        );
        testLock.safeUnlock(msgSender, msgSender, values);

        // successfully unlock using normal unlock function
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(
                mockTokens[i],
                THRESHOLD // equal threshold
            );
        }
        vm.expectEmit(true, true, true, true);
        emit ILocking.Unlock(
            reqId,
            msgSender,
            msgSender,
            values[0].token,
            values[0].amount
        );
        testLock.unlock(msgSender, msgSender, values);
        reqId += 3;
    }

    function test_Exit() public {
        uint64 reqId;
        ILocking.Locking[] memory values = new ILocking.Locking[](3);
        for (uint8 i; i < 3; ++i) {
            values[i] = ILocking.Locking(mockTokens[i], DEFAULT_LOCK_AMOUNT);
        }
        testLock.lock(msgSender, values);

        for (uint8 i; i < 3; ++i) {
            assertEq(
                locking.locking(msgSender, mockTokens[0]),
                DEFAULT_LOCK_AMOUNT
            );
        }
        vm.expectEmit(true, true, true, true);
        emit ILocking.Unlock(
            reqId,
            msgSender,
            msgSender,
            values[0].token,
            values[0].amount
        );
        testLock.exit(msgSender, msgSender, mockTokens);
        for (uint8 i; i < 3; ++i) {
            assertEq(locking.locking(msgSender, mockTokens[0]), 0);
        }
    }
}
