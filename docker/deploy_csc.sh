#!/bin/bash
cd /app
cp /app/config/deployment.config.json /app/deployment.config.json

#1. check PARENTCHAIN env
#2. check PRIVATE_KEY env
#3. check .env file

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
  cat network.config.json | sed -e "s@\"xdcparentnet\".*@\"xdcparentnet\": \"$PARENTCHAIN_URL\",@" > temp.json
  mv temp.json network.config.json
fi

if [[ -z "$SUBNET_URL" ]]; then
  echo "SUBNET_URL not specified" 
  exit 1
else
  cat network.config.json | sed -e "s@\"xdcsubnet\".*@\"xdcsubnet\": \"$SUBNET_URL\",@" > temp.json
  mv temp.json network.config.json
fi

if [[ $RELAYER_MODE == 'full' ]]
then
  echo "Deploying full CSC"
  npx hardhat run scripts/FullCheckpointDeploy.js --network xdcparentnet 2>&1 | tee csc.log
elif [[ $RELAYER_MODE == 'lite' ]]
then
  echo "Deploying lite CSC"
  npx hardhat run scripts/LiteCheckpointDeploy.js --network xdcparentnet 2>&1 | tee csc.log
else
  echo "Unknown RELAYER_MODE"
  exit 1
fi


# found=$(cat csc.log | grep -m 1 "deployed to")
# echo $found

# if [[ $found == '' ]]
# then
#   echo 'CSC deployment failed'
#   exit 1
# else
#   echo 'Replacing CSC address in common.env file'
#   contract=${found: -42}
#   echo $contract
#   cat /app/generated/common.env | sed -e "s/CHECKPOINT_CONTRACT.*/CHECKPOINT_CONTRACT=$contract/" > temp.env
#   mv temp.env /app/generated/common.env
# fi