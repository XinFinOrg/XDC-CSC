#!/bin/bash
cd /app
cp /app/config/deployment.config.json /app/deployment.config.json
cp /app/config/upgrade.config.json /app/upgrade.config.json

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

# UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet | awk '{print $NF}')
# FULL=$(echo $UPGRADE | cut -d' ' -f2)
# FULL="FULL=$FULL"
# LITE=$(echo $UPGRADE | cut -d' ' -f3)
# LITE="LITE=$LITE"
# echo "Upgraded Proxy Gateway with CSC"
# echo "$FULL"
# echo "$LITE"

npx hardhat run scripts/proxy/UpgradeCSC.js --network $DEPLOY_NET
# echo "Upgraded Proxy Gateway with CSC"