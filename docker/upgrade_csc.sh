#!/bin/bash
cd /app
cp -r config/* .

remove0x=${PARENTCHAIN_WALLET_PK:2}
echo "PRIVATE_KEY=${remove0x}" >> .env 

# UPGRADE=$(npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet | awk '{print $NF}')
# FULL=$(echo $UPGRADE | cut -d' ' -f2)
# FULL="FULL=$FULL"
# LITE=$(echo $UPGRADE | cut -d' ' -f3)
# LITE="LITE=$LITE"
# echo "Upgraded Proxy Gateway with CSC"
# echo "$FULL"
# echo "$LITE"

npx hardhat run scripts/proxy/UpgradeCSC.js --network xdcparentnet
echo "Upgraded Proxy Gateway with CSC"