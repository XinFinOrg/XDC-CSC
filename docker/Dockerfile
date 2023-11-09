FROM node:18.15

WORKDIR /app

COPY . /app

#this step here for caching
RUN yarn
# RUN npm install

RUN chmod +x /app/docker/deploy_csc.sh

# RUN cd script && npm install

ENTRYPOINT ["bash","/app/docker/deploy_csc.sh"]