#!/bin/bash
#
# This script is preparation for executing command within customized NGINX container
#
NAME=${NAME:-"nginx_proxy_$(date +%N)"}

if [ ! -z "$(docker container ls -q --filter name="${NAME}")" ]; then
  docker exec "${NAME}" "${@}"
fi
