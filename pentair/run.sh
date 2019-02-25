#!/bin/bash
#set -e

CONFIG_PATH=/data/options.json
SL_CONN="$(jq --raw-output '.sl_conn' $CONFIG_PATH)"
MQTT_BROKER="$(jq --raw-output '.mqtt_broker' $CONFIG_PATH)"
MQTT_INSECURE="$(jq --raw-output '.mqtt_insecure' $CONFIG_PATH)"
MQTT_PASS="$(jq --raw-output '.mqtt_pass' $CONFIG_PATH)"
MQTT_PORT="$(jq --raw-output '.mqtt_port' $CONFIG_PATH)"
MQTT_USER="$(jq --raw-output '.mqtt_user' $CONFIG_PATH)"
PENTAIR_CONN="$(jq --raw-output '.pentair_conn' $CONFIG_PATH)"
PENTAIR_IP="$(jq --raw-output '.pentair_ip' $CONFIG_PATH)"
PENTAIR_SYSTEM="$(jq --raw-output '.pentair_system' $CONFIG_PATH)"
PENTAIR_PASS="$(jq --raw-output '.pentair_pass' $CONFIG_PATH)"

MQTT_SUBSCRIBE="mosquitto_sub -v -t /pentair/# -W 10 -C 1"
MQTT_PUBLISH="mosquitto_pub"

if [ -n "$MQTT_BROKER" ]; then
MQTT_ARGS="$MQTT_ARGS -h ${MQTT_BROKER}"
fi

if [ "$MQTT_INSECURE" == "true" ]; then
MQTT_ARGS="$MQTT_args --insecure"
fi

if [ -n "$MQTT_USER" ]; then
MQTT_ARGS_="$MQTT_ARGS -u $MQTT_USER"
fi

if [ -n "$MQTT_PASS" ]; then
MQTT_ARGS="$MQTT_ARGS -P $MQTT_PASS"
fi

if [ -n "$MQTT_PORT" ]; then
MQTT_ARGS_="$MQTT_ARGS -p $MQTT_PORT"
fi

if [ -f /ca.crt ]; then
MQTT_ARGS="$MQTT_ARGS --cafile /ca.crt"
fi

MQTT_SUBSCRIBE="mosquitto_sub $MQTT_ARGS -v -t /pentair/# -W 10 -C 1 "
MQTT_PUBLISH="mosquitto_pub $MQTT_ARGS"

echo MQTTPUBLISH = $MQTT_PUBLISH
echo MQTTSUBSCRIBE = $MQTT_SUBSCRIBE


cd /node_modules/node-screenlogic

while [ 1 ]; do
PAYLOAD=`$MQTT_SUBSCRIBE`
if [ $? -gt 0 ]; then
  echo "WARN: MQTT Client exited with status $?, backing off for a minute"
  sleep 60
else
  TOPIC=`echo $PAYLOAD | awk '{print $1}'`
  MESSAGE=`echo $PAYLOAD | awk '{print $2}'`

  case $TOPIC in
    "/pentair/circuit_5??/command")
       CIRCUIT=`echo $TOPIC| awk -F/ '{print $2}' | awk -F_ '{print $2}'`
       if [ "${MESSAGE}" == "ON" ]; then
          ./circuit $CIRCUIT ON
       elif [ "${MESSAGE}" == "OFF" ]; then
          ./circuit $CIRCUIT OFF
       fi
    ;;
    *)
       echo "WARN: GOT A MQTT MESSAGE I DONT UNDERSTAND: TOPIC = $TOPIC, PAYLOAD = $PAYLOAD"
  esac
fi

node hassio.js | awk -F= -vPUBLISH="$MQTTPUBLISH" '{print PUBLISH -t " $1 " -m " $2}'

done


