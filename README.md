## SafeLocking.sol

### Why

-   Adds checks for locking limit and threshold when locking/unlocking.
-   Implements exit function to fully unlock tokens.

### How

-   Import _SafeLocking.sol_ and use it for Locking contract. (`using SafeLocking for ILocking;`).
-   Implement your contract as usual. Replace `Locking.Lock(validator, values)` with `Locking.safeLock(assetManagerAddress, validator, values)`, same with unlocking. Exit function also provided.
-   See [Deployed Contracts](https://github.com/GOATNetwork/goat-contracts/blob/testnet-2/contracts/locking/Locking.sol) for Goat _AssetManager.sol_ contract address.

## AssetManager.sol

Record the max effective locking balance of a token pool.
Setup and maintained by Goat.

-   #### `poolIndexCounter`

Auto-increment index starting from 1 for setting up pools. Pool with 0 index means it has not been setup yet.

-   #### `setupPool(uint256 _max, address[] calldata _tokens)`

Create a new pool consist of `_tokens` tokens, with a locking limit of `_max`.

-   #### `addTokenToPool(uint32 _poolIndex, address _token)`

Add a token `_token` to exiting pool `_poolIndex`.

-   #### `removeTokenFromPool(address _token)`

Remove a token `_token` from it's pool.

-   #### `setPoolMax(uint32 _poolIndex, uint256 _max)`

Set the locking limit of pool `_poolIndex` to `_max`.

-   #### `setGoatLocker(address _addr)`

Update the Goat Locking contract address to `_addr`.
