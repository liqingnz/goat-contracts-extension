-include .env

deployTest :
	forge script --chain 48816 script/DeployTestLock.s.sol:DeployTestLock --broadcast -vvvv --rpc-url goatTest --verify --verifier blockscout --verifier-url https://explorer.testnet3.goat.network/api/

deployLocal:
	forge script --chain 1337 --rpc-url localhost --broadcast -vvvv --account default