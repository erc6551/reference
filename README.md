# ERC-6551 Reference Implementation

This repository contains the reference implementation of [ERC-6551](https://eips.ethereum.org/EIPS/eip-6551).

**This project is under active development and may undergo changes until ERC-6551 is finalized.**

The current ERC6551Registry address is `0x284be69BaC8C983a749956D7320729EB24bc75f9`.

For the most recently deployed version of these contracts, see the [v0.3.0](https://github.com/erc6551/reference/releases/tag/v0.3.0) release. We recommend this version for any production usage.

## Using as a Dependency

### If you use Forge

If you want to use `erc6551/reference` as a dependency in another project, you can add it using `forge install`:

```sh
forge install erc6551=erc6551/reference
```

This will add `erc6551/reference` as a git submodule in your project. For more information on managing dependencies, refer to the [Foundry dependencies guide](https://github.com/foundry-rs/book/blob/master/src/projects/dependencies.md).

### If you use Hardhat

```sh
npm install erc6551 @openzeppelin/contracts
```

and use, for example, as
```
import "erc6551/interfaces/IERC6551Account.sol";
```

## Development Setup

You will need to have Foundry installed on your system. Please refer to the [Foundry installation guide](https://github.com/foundry-rs/book/blob/master/src/getting-started/installation.md) for detailed instructions.

To use this repository, first clone it:

```sh
git clone https://github.com/erc6551/reference.git
cd contracts
```

Then, install the dependencies:

```sh
forge install
```

## Running Tests

To run the tests, use the `forge test` command:

```sh
forge test
```

For more information on writing and running tests, refer to the [Foundry testing guide](https://github.com/foundry-rs/book/blob/master/src/forge/writing-tests.md).

## History

**0.3.3**
- prepare the repo to be published to NPM as `erc6551`, replacing the version published by Cruna (https://github.com/cruna-cc/erc6551)

**0.3.2**
- fix typos in comments

**0.3.1**
- pragma has been changed to ^0.8.4; is the minimum for custom errors.
- Create2.computeAddress -> ERC6551BytecodeLib.computeAddress so that it is actually a single file. This makes it easier to verify in case OZ updates their code, such as bumping their solidity pragma. I'd recommend including the bytecode hash in the compilation config as per default to prevent comment vandalism.

**0.3.0** (breaking changes)
- Remove the initData parameter - this has been a major source of confusion for folks building with 6551, as it is not clear what the value of initData should be. Additionally, this has been brought up as a potential security footgun in both audits we've done, as users may not be aware that the data passed to a 6551 implementation via initData is unauthenticated. For these reasons this parameter is being removed in favor of encouraging folks to use multicall for creation of accounts that require initialization.
- Change the type of salt from uint256 to bytes32 - this small change means that salt does not need to be type casted inside the account and createAccount functions, and prevents confusion between the tokenId and chainId uint256 parameters
- Make salt the second argument of the createAccount and account functions instead of the fifth - this more closely aligns the order of the arguments in calldata to the order of values stored as constants in the bytecode. The order is also changed in the AccountCreated event
- Modify the operation argument of the execute function to use uint8 instead of uint256 - this allows implementations to use an enum to represent the value of operation without changing the function signature or execution interface id
- Rename AccountCreated event to ERC6551AccountCreated - this change helps distinguish 6551-specific events from other account contracts that make use of AccountCreated events (some folks have been confused by this)
- Flatten the ERC6551Registry file - this makes permissionless deployment of the registry easier as the exact source code can be included in the EIP rather than having it split across multiple files and relying on a developer's local environment to compile it properly

**0.2.2**
- Adds several helper functions to the ERC6551AccountLib library
- Removes prettier in favor of forge fmt for formatting.

**0.2.1**

- Making examples' functions `virtual` and `public` so that the examples can be used as a base for more advanced contracts
