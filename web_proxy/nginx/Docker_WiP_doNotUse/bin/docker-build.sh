#!/bin/bash
#
# This script is preparation for creating customized NGINX container
#

#set -e
#set -x

#PROD=false

#if [ "$1" == "--prod" ]; then
#  PROD="prod"
#fi

#source $MNT_CLOUD_LIB/bash/cloud/docker.sh

#docker-build "nginx_proxy"
#docker-tag-push "nginx_proxy" "$PROD"

docker build -t nginx_proxy --network=host -f ./nginx_proxy.Dockerfile . "${@}"
