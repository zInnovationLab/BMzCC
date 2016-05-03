#!/bin/bash

read -r -a IMGS <<< $(echo $(curl http://${REGISTRY}:${REGISTRY_PORT}/v2/_catalog |python -m json.tool | grep -o '"'${USR_NAME}'/bluemix.*"' | sed 's/"//g'))

for img in "${IMGS[@]}"
do
#	echo "$img"
	docker pull "${REGISTRY}:${REGISTRY_PORT}/$img"
done
