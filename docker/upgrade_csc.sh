#!/bin/bash
cd /app
cp /app/config/deployment.config.json /app/deployment.config.json
cp /app/config/upgrade.config.json /app/upgrade.config.json

if [[ -n "$PARENTCHAIN_WALLET_PK" ]]; then
  PRIVATE_KEY=${PARENTCHAIN_WALLET_PK}
fi


if [[ -z "$PRIVATE_KEY" ]]; then
  source /app/config/.env
fi

if [[ -z "$PRIVATE_KEY" ]]; then
  if [[ -n "$PARENTCHAIN_WALLET_PK" ]]; then
    PRIVATE_KEY=${PARENTCHAIN_WALLET_PK}
  else
    echo "PARENTCHAIN_WALLET_PK or PRIVATE_KEY not set"
    exit 1
  fi
fi

if [[ ${PRIVATE_KEY::2} == "0x"  ]]; then
  PRIVATE_KEY=${PRIVATE_KEY:2}
fi
echo "PRIVATE_KEY=${PRIVATE_KEY}" > .env 

if [[ -z "$PARENTCHAIN_URL" ]]; then
  echo "PARENTCHAIN_URL not specified"
  exit 1
else
  cat network.config.json | sed -e "s/\"xdcparentnet\".*/\"xdcparentnet\": \"$PARENTCHAIN_URL\",/" > temp.json
  mv temp.json network.config.json
fi

if [[ -z "$SUBNET_URL" ]]; then
  echo "SUBNET_URL not specified" 
  exit 1
else
  cat network.config.json | sed -e "s/\"xdcsubnet\".*/\"xdcsubnet\": \"$SUBNET_URL\",/" > temp.json
  mv temp.json network.config.json
fi

if [[ -z "$PROXY_GATEWAY" ]]; then
  echo "PROXY_GATEWAY not specified"
  exit 1
else
  JSON="{\"proxyGateway\": \"$PROXY_GATEWAY\"}"
  echo $JSON > upgrade.config.json
fi

# UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet | awk '{print $NF}')
# FULL=$(echo $UPGRADE | cut -d' ' -f2)
# FULL="FULL=$FULL"
# LITE=$(echo $UPGRADE | cut -d' ' -f3)
# LITE="LITE=$LITE"
# echo "Upgraded Proxy Gateway with CSC"
# echo "$FULL"
# echo "$LITE"

npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet
# echo "Upgraded Proxy Gateway with CSC"