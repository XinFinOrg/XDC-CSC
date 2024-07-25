FROM node:20-alpine

COPY . /app

WORKDIR /app
RUN yarn
WORKDIR /app/cicd
RUN yarn

ENTRYPOINT ["node"]