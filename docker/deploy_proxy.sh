#!/bin/bash
cd /app
cp -r config/* .
set -e 

remove0x=${PARENTCHAIN_WALLET_PK:2}
echo "PRIVATE_KEY=${remove0x}" >> .env 

DEPLOY=$(npx hardhat run scripts/proxy/ProxyGatewayDeploy.js --network xdcparentnet)
PROXY=$(echo $DEPLOY | awk '{print $NF}')
echo "Proxy Gateway Deployed: $PROXY"
JSON="{\"proxyGateway\": \"$PROXY\"}"
echo $JSON > upgrade.config.json

UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet | awk '{print $NF}')
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
