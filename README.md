# PROJECT

This project is meant to be a stablecoin where users can deposit WETH and WBTC in exchange for a token that will be pegged to the USD.

It would be:
- An anchored/pegged stablecoin -> $1
- Use the algorithmic stability mechanism (minting)
- Collateral: Exogenous -> wETH, wBTC

## Quickstart
```shell
git clone https://github.com/ifaycodes/decentralized-stablecoin
cd foundry-defi-stablecoin-f23
forge build
```

### Updates
Install:

openzeppelin contract
```forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
```
Chainlink contracts
```
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
```


### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
### Test coverage

```shell
$ forge coverage
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ make anvil
```

### Deploy

```shell
$ make deploy
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
