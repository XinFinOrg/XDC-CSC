FROM node:18.15

WORKDIR /app

COPY . /app

RUN yarn

RUN chmod +x /app/docker/deploy_proxy.sh
RUN chmod +x /app/docker/upgrade_csc.sh


# ENTRYPOINT ["sleep", "infinity"]
# ENTRYPOINT ["bash -c","sleep 100"]
# ENTRYPOINT ["bash","/app/docker/deploy_csc.sh"]