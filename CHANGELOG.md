# Changelog

## v0.3.1

- Prepare the repo to be published to NPM as `erc6551`, replacing the version published by Cruna (https://github.com/cruna-cc/erc6551)
- Fix typos in comments
- Changed pragma to ^0.8.4 as that is the minimum for custom errors
- Create2.computeAddress -> ERC6551BytecodeLib.computeAddress to remove registry dependency on OpenZeppelin
- Inluded bytecode_hash in the compilation config as per default to prevent comment vandalism

## v.3.0 (breaking changes)

- Removed the initData parameter to reduce developer confusion and avoid security issues relating to unauthenticated initialization calls
- Change the type of salt from uint256 to bytes32 to avoid type casting and prevent confusion between the tokenId and chainId uint256 parameters
- Make salt the second argument of the createAccount and account functions instead of the fifth to more closely align the order of the arguments in calldata to the order of values stored as constants in the bytecode. The order is also changed in the AccountCreated event
- Modify the operation argument of the execute function to use uint8 instead of uint256 to allow implementations to represent the value of operation as an emum without changing the function signature or execution interface id
- Rename AccountCreated event to ERC6551AccountCreated to help distinguish 6551-specific events from other account contracts that make use of AccountCreated events
- Flatten the ERC6551Registry file to make permissionless deployment of the registry easier

## v0.2.2

- Added several helper functions to the ERC6551AccountLib library
- Removed prettier in favor of forge fmt for formatting

## v0.2.1

- Made examples' functions `virtual` and `public` so that the examples can be used as a base for more advanced contracts
