# XDC Checkpoint Smart Contract

This folder has provided scripts for:

- Contract Building and Testing
- Contract Deployment

## Contract Building and Testing:

Environmental preparation

###### Nodejs 16 or higher version

Install dependencies

```shell
yarn
```

Test

```shell
npx hardhat compile
npx hardhat test
```

## Contract Setup:

This step is recommended to complete in python virtual environment because it is going to use the web3 library adapted for XDC. And before running the process, it is required to performed two operations:

1. Fill in the fields in `deployment.config.json`

   - `validators`: List of initial validator addresses
   - `gap`: GAP block number on public chain
   - `epoch`: EPOCH block number on public chain

   Check your network in `network.config.js`

   - `xdcparentnet`: xdcparentnet rpc url
   - `xdcsubnet`: xdcparentnet rpc url

2. Create a `.env` file which contain a valid account privatekey, check `.env.sample` for example

## Contract Deployment:

And get the deployed contract address

FullCheckpoint

```shell
npx hardhat run scripts/FullCheckpointDeploy.js --network xdcparentnet
```

Lite checkpoint

```shell
npx hardhat run scripts/LiteCheckpointDeploy.js --network xdcparentnet
```

## Other command

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx prettier '**/*.{js,json,sol,md}' --check
npx prettier '**/*.{js,json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

## Gas report

![Alt text](image.png)

## Upgrade module

1. Fill in the fields in `upgrade.config.json`
   - `proxyGateway`: Admin contract that manages all proxy contracts

If you have no proxyGateway contract , deploy your ProxyGateway

```shell
npx hardhat run scripts/proxy/ProxyGatewayDeploy.js --network xdcparentnet
```

2. Upgrade

```shell
npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet
```
