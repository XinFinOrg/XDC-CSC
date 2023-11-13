#!/bin/bash
set -e 

cd /app
cp /app/config/deployment.config.json /app/deployment.config.json

#1. check PARENTCHAIN env
#2. check PRIVATE_KEY env
#3. check .env file

if [[ -n "$PARENTCHAIN_WALLET_PK" ]]; then
  PRIVATE_KEY=${PARENTCHAIN_WALLET_PK:2}
fi


if [[ -z "$PRIVATE_KEY" ]]; then
  source /app/config/.env
fi

if [[ -z "$PRIVATE_KEY" ]]; then
  if [[ -n "$PARENTCHAIN_WALLET_PK" ]]; then
    PRIVATE_KEY=${PARENTCHAIN_WALLET_PK:2}
  else
    echo "PARENTCHAIN_WALLET_PK or PRIVATE_KEY not set"
    exit 1
  fi
fi


if [[ -z "$PARENTCHAIN" ]]; then
  echo 'PARENTCHAIN is not set, default to devnet'
  DEPLOY_NET=xdcdevnet
else
  echo "PARENTCHAIN=$PARENTCHAIN"
  if [[ $PARENTCHAIN == 'devnet' || $PARENTCHAIN == 'xdcdevnet' ]]; then
      DEPLOY_NET='xdcdevnet'
  fi
  if [[ $PARENTCHAIN == 'testnet' || $PARENTCHAIN == 'xdctestnet' ]]; then
      DEPLOY_NET='xdctestnet'
  fi
  echo "Deploying to $DEPLOY_NET"
fi

DEPLOY=$(npx hardhat run scripts/proxy/ProxyGatewayDeploy.js --network $DEPLOY_NET)
PROXY=$(echo $DEPLOY | awk '{print $NF}')
echo "Proxy Gateway Deployed: $PROXY"
JSON="{\"proxyGateway\": \"$PROXY\"}"
echo $JSON > upgrade.config.json
sleep 10

UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network $DEPLOY_NET | awk '{print $NF}')
FULL=$(echo $UPGRADE | cut -d' ' -f4)
FULL="FULL=$FULL"
echo $FULL > csc.env

LITE=$(echo $UPGRADE | cut -d' ' -f5)
LITE="LITE=$LITE"
echo $LITE >> csc.env
echo "Upgraded Proxy Gateway with CSC"
echo "$FULL"
echo "$LITE"

cp upgrade.config.json config/upgrade.config.json || echo 'config not mounted'
cp csc.env config/csc.env || echo 'config not mounted'
