ARG BUILD_FROM=hassio-addons/base:2.3.2
FROM ${BUILD_FROM}

ENV LANG C.UTF-8

RUN apk add npm jq mosquitto-clients && npm install node-screenlogic smart-buffer

COPY ca.crt    /
COPY circuit   /node_modules/node-screenlogic/
COPY hassio.js /node_modules/node-screenlogic/
COPY run.sh /

RUN chmod a+x /node_modules/node-screenlogic/*
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

