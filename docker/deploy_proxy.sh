#!/bin/bash
set -e 

cd /app
cp /app/config/deployment.config.json /app/deployment.config.json

#1. check PARENTNET env
#2. check PRIVATE_KEY env
#3. check .env file

if [[ -n "$PARENTNET_WALLET_PK" ]]; then
  PRIVATE_KEY=${PARENTNET_WALLET_PK}
fi


if [[ -z "$PRIVATE_KEY" ]]; then
  source /app/config/.env || echo ''
fi

if [[ -z "$PRIVATE_KEY" ]]; then
  if [[ -n "$PARENTNET_WALLET_PK" ]]; then
    PRIVATE_KEY=${PARENTNET_WALLET_PK}
  else
    echo "PARENTNET_WALLET_PK or PRIVATE_KEY not set"
    exit 1
  fi
fi

if [[ ${PRIVATE_KEY::2} == "0x"  ]]; then
  PRIVATE_KEY=${PRIVATE_KEY:2}
fi
echo "PRIVATE_KEY=${PRIVATE_KEY}" > .env 

if [[ -z "$PARENTNET_URL" ]]; then
  echo "PARENTNET_URL not specified"
  exit 1
else
  cat network.config.json | sed -e "s@\"xdcparentnet\".*@\"xdcparentnet\": \"$PARENTNET_URL\",@" > temp.json
  mv temp.json network.config.json
fi

if [[ -z "$SUBNET_URL" ]]; then
  echo "SUBNET_URL not specified" 
  exit 1
else
  cat network.config.json | sed -e "s@\"xdcsubnet\".*@\"xdcsubnet\": \"$SUBNET_URL\",@" > temp.json
  mv temp.json network.config.json
fi

DEPLOY=$(npx hardhat run scripts/proxy/ProxyGatewayDeploy.js --network xdcparentnet)
PROXY=$(echo $DEPLOY | awk '{print $NF}')
echo "Proxy Gateway Deployed: $PROXY"
JSON="{\"proxyGateway\": \"$PROXY\"}"
echo $JSON > upgrade.config.json
echo "" >> config/common.env || echo 'config not mounted'
echo "#Checkpoint Smart Contract (CSC) addresses" >> config/common.env || echo 'config not mounted'
echo "PROXY_GATEWAY=$PROXY" >> config/common.env || echo 'config not mounted'


UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet | awk '{print $NF}')
FULL_CSC=$(echo $UPGRADE | cut -d' ' -f4)
FULL_CSC_LINE="FULL_CSC=$FULL_CSC"
echo $FULL_CSC_LINE >> config/common.env || echo 'config not mounted'


LITE_CSC=$(echo $UPGRADE | cut -d' ' -f5)
LITE_CSC_LINE="LITE_CSC=$LITE_CSC"
echo $LITE_CSC_LINE >> config/common.env || echo 'config not mounted'
echo "Upgraded Proxy Gateway with CSC"
echo "$FULL_CSC_LINE"
echo "$LITE_CSC_LINE"

if [[ $RELAYER_MODE == 'full' ]]; then
  echo 'Relayer mode full, updating CHECKPOINT_CONTRACT'
  cat config/common.env | sed -e "s/CHECKPOINT_CONTRACT.*/CHECKPOINT_CONTRACT=$FULL_CSC/" > temp.env
  mv temp.env config/common.env
fi
if [[ $RELAYER_MODE == 'lite' ]]; then
  echo 'Relayer mode lite, updating CHECKPOINT_CONTRACT'
  cat config/common.env | sed -e "s/CHECKPOINT_CONTRACT.*/CHECKPOINT_CONTRACT=$LITE_CSC/" > temp.env
  mv temp.env config/common.env
fi