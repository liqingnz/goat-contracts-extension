pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {AssetManager} from "../src/AssetManager.sol";
import {IAssetManager} from "../src/interfaces/IAssetManager.sol";

import {MockLocking} from "../src/mocks/MockLocking.sol";
import {MockToken} from "../src/mocks/MockToken.sol";

contract TokenPool is Test {
    AssetManager public assetManager;
    MockLocking public locking;
    address[] public mockTokens;

    address public msgSender;

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
    }

    function test_SetupPool() public {
        uint32 initialPoolIndex = assetManager.poolIndexCounter();
        assertEq(assetManager.getPoolMax(initialPoolIndex), 0);
        assertEq(assetManager.getPoolTokens(initialPoolIndex).length, 0);

        // fail: pass in an empty address array
        address[] memory emptyAddresses;
        vm.expectRevert(IAssetManager.InvalidTokenList.selector);
        assetManager.setupPool(TEST_POOL_MAX, emptyAddresses);

        // fail: pass in repeating token addresses
        address[] memory invalidAddresses = new address[](2);
        invalidAddresses[0] = mockTokens[0];
        invalidAddresses[1] = mockTokens[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetManager.RegisteredToken.selector,
                invalidAddresses[1]
            )
        );
        assetManager.setupPool(TEST_POOL_MAX, invalidAddresses);

        // success
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.PoolSetup(
            initialPoolIndex,
            TEST_POOL_MAX,
            mockTokens
        );
        assetManager.setupPool(TEST_POOL_MAX, mockTokens);
        assertEq(assetManager.poolIndexCounter(), initialPoolIndex + 1);
        assertEq(assetManager.getPoolMax(initialPoolIndex), TEST_POOL_MAX);
        assertEq(assetManager.getPoolTokens(initialPoolIndex), mockTokens);
        for (uint8 i; i < 3; ++i) {
            assertEq(
                assetManager.getPoolToken(initialPoolIndex, i),
                mockTokens[i]
            );
        }

        // setup the second pool
        uint256 newPoolMax = 30 ether;
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(new MockToken());
        tokenAddresses[1] = address(new MockToken());

        assetManager.setupPool(newPoolMax, tokenAddresses);
        assertEq(assetManager.poolIndexCounter(), initialPoolIndex + 2);
        assertEq(assetManager.getPoolMax(initialPoolIndex + 1), newPoolMax);
        assertEq(
            assetManager.getPoolTokens(initialPoolIndex + 1),
            tokenAddresses
        );
    }

    function test_AddToken() public {
        uint32 poolIndex = assetManager.poolIndexCounter();
        uint256 tokenSize = 3;
        address newToken = address(new MockToken());
        assetManager.setupPool(TEST_POOL_MAX, mockTokens);
        assertEq(assetManager.getPoolTokens(poolIndex).length, tokenSize);

        // fail: pass in an invalid pool index
        uint32 invalidPoolindex = poolIndex + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetManager.InvalidPool.selector,
                invalidPoolindex
            )
        );
        assetManager.addTokenToPool(invalidPoolindex, newToken);

        // fail: pass in a registered token address
        address invalidToken = mockTokens[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetManager.RegisteredToken.selector,
                invalidToken
            )
        );
        assetManager.addTokenToPool(poolIndex, invalidToken);

        // success
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.TokenAdded(poolIndex, newToken);
        assetManager.addTokenToPool(poolIndex, newToken);
        assertEq(assetManager.getPoolTokens(poolIndex).length, tokenSize + 1);

        // add a second token
        newToken = address(new MockToken());
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.TokenAdded(poolIndex, newToken);
        assetManager.addTokenToPool(poolIndex, newToken);
        assertEq(assetManager.getPoolTokens(poolIndex).length, tokenSize + 2);

        // add native token
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.TokenAdded(poolIndex, address(0));
        assetManager.addTokenToPool(poolIndex, address(0));
        assertEq(assetManager.getPoolTokens(poolIndex).length, tokenSize + 3);
    }

    function test_RemoveToken() public {
        uint32 poolIndex = assetManager.poolIndexCounter();
        uint256 tokenSize = 3;
        assetManager.setupPool(TEST_POOL_MAX, mockTokens);
        address removingToken = mockTokens[0];
        assertEq(assetManager.tokenPoolIndexes(removingToken), poolIndex);
        assertEq(
            assetManager
                .getPoolTokens(assetManager.tokenPoolIndexes(removingToken))
                .length,
            tokenSize
        );

        // fail: remove a non-existing token
        address invalidToken = address(new MockToken());
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetManager.UnregisteredToken.selector,
                invalidToken
            )
        );
        assetManager.removeTokenFromPool(invalidToken);

        // success
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.TokenRemoved(poolIndex, removingToken);
        assetManager.removeTokenFromPool(removingToken);
        assertEq(assetManager.tokenPoolIndexes(removingToken), 0);
        assertEq(assetManager.getPoolTokens(poolIndex).length, tokenSize - 1);
    }

    function test_SetPoolMax() public {
        uint32 poolIndex = assetManager.poolIndexCounter();
        assetManager.setupPool(TEST_POOL_MAX, mockTokens);
        uint256 newPoolMax = 25 ether;

        // fail: pass in an invalid pool index
        uint32 invalidPoolindex = poolIndex + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetManager.InvalidPool.selector,
                invalidPoolindex
            )
        );
        assetManager.setPoolMax(invalidPoolindex, newPoolMax);

        // success
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.MaxUpdated(poolIndex, newPoolMax);
        assetManager.setPoolMax(poolIndex, newPoolMax);
        assertEq(assetManager.getPoolMax(poolIndex), newPoolMax);
    }

    function test_SetLocking() public {
        // fail: pass in zero address
        vm.expectRevert(IAssetManager.InvalidAddress.selector);
        assetManager.setGoatLocker(address(0));

        // success
        address newLocking = address(new MockLocking());
        vm.expectEmit(true, true, true, true);
        emit IAssetManager.GoatLockerUpdated(newLocking);
        assetManager.setGoatLocker(newLocking);
    }

    function _deployProxy(
        address _logic,
        address _admin
    ) internal returns (address) {
        return address(new TransparentUpgradeableProxy(_logic, _admin, ""));
    }
}
