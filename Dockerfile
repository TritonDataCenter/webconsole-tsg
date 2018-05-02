FROM joyent/webconsole-node:0.0.2

# Setup the Node.js app
COPY app /opt/app
WORKDIR /opt/app/
RUN yarn --production

# Setup the prestart script
COPY ./bin/prestart.sh /bin/prestart.sh
RUN chmod 700 /bin/prestart.sh

CMD ["node", "server.js"]
