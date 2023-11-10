FROM node:18.15

WORKDIR /app

COPY . /app

RUN rm .env deployment.config.json upgrade.config.json || echo ok
RUN rm yarn.lock || echo ok 
RUN rm -r node_modules || echo ok

RUN yarn

RUN chmod +x /app/docker/deploy_csc.sh
RUN chmod +x /app/docker/deploy_proxy.sh
RUN chmod +x /app/docker/upgrade_csc.sh


# ENTRYPOINT ["sleep", "infinity"]
# ENTRYPOINT ["bash -c","sleep 100"]
# ENTRYPOINT ["bash","/app/docker/deploy_csc.sh"]