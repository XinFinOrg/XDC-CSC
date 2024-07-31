FROM node:20-alpine

COPY . /app

WORKDIR /app
RUN yarn
RUN npx hardhat compile
WORKDIR /app/cicd
RUN yarn

ENTRYPOINT ["node"]