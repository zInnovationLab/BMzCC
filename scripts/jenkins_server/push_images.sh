#!/bin/bash

read -r -a IMGS <<< $(echo $(docker images | awk '{print $1}' | grep jenkins))
#docker tag ${IMGS[1]} "lal/${IMGS[1]}"
for img in "${IMGS[@]}"
do
	echo "$img"
	docker tag $img "${REGISTRY}:${REGISTRY_PORT}/${USR_NAME}/bluemix_$img"
	docker push "${REGISTRY}:${REGISTRY_PORT}/${USR_NAME}/bluemix_$img"
	docker rmi "${REGISTRY}:${REGISTRY_PORT}/${USR_NAME}/bluemix_$img"
done
