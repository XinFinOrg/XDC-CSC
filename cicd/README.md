# XDC CSC CICD

## Deploy XDC CSC

#### Step 1: Create a `.env` File

Based on the provided `.env.example`, create your own `.env` file with the following details:

- **`PARENTNET_URL`**: RPC URL for the parentnet endpoint.
- **`SUBNET_URL`**: RPC URL for the subnet.
- **`PARENTNET_PK`**: Private key used for CSC deployment, there should be some funds.
- **`SUBNET_PK`**: Private key for subnet deployment. (only required for reverse CSC)

#### Step 2: Deploy CSC
You have a choice to deploy one of three types of CSC

Full CSC:
`docker run --env-file .env xinfinorg/xdc-csc:latest full.js`

Reverse CSC:
`docker run --env-file .env xinfinorg/xdc-csc:latest reversefull.js`

Lite CSC:
`docker run --env-file .env xinfinorg/xdc-csc:latest lite.js`


## Deploy XDC CSC at Custom Block Height
#### Step 1: Create a `.env` File to cicd/mount

Based on the provided `.env.example`, create your own `.env` file with the following details:

- **`PARENTNET_URL`**: RPC URL for the parentnet endpoint.
- **`SUBNET_URL`**: RPC URL for the subnet.
- **`PARENTNET_PK`**: Private key used for CSC deployment, there should be some funds.
- **`SUBNET_PK`**: Private key for subnet deployment. (only required for reverse CSC)

#### Step 2: Create a `deployment.config.json` File to cicd/mount

Check the main README in upper directory and deployment.config.json.example to understand the configurations

#### Step 3: Deploy CSC

You have a choice to deploy one of three types of CSC

Full CSC:
`docker run -v $(pwd)/mount:/app/cicd/mount xinfinorg/xdc-csc:latest full.js`

Reverse CSC:
`docker run -v $(pwd)/mount:/app/cicd/mount xinfinorg/xdc-csc:latest reversefull.js`

Lite CSC:
`docker run -v $(pwd)/mount:/app/cicd/mount xinfinorg/xdc-csc:latest lite.js`