# ERC-6551 Reference Implementation

This repository contains the reference implementation of [ERC-6551](https://eips.ethereum.org/EIPS/eip-6551).

**This project is under active development and may undergo changes until ERC-6551 is finalized.**

The current ERC6551Registry address is `0x8deDFee9BEEe2D64817Dd8dB8cff138C468Bd3Ef`.

For the most recently deployed version of these contracts, see the [v0.3.0](https://github.com/erc6551/reference/releases/tag/v0.3.0) release. We recommend this version for any production usage.

## Using as a Dependency

If you want to use `erc6551/reference` as a dependency in another project, you can add it using `forge install`:

```sh
forge install erc6551=erc6551/reference
```

This will add `erc6551/reference` as a git submodule in your project. For more information on managing dependencies, refer to the [Foundry dependencies guide](https://github.com/foundry-rs/book/blob/master/src/projects/dependencies.md).

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

**0.2.1**

- Making examples' functions `virtual` and `public` so that the examples can be used as a base for more advanced contracts
