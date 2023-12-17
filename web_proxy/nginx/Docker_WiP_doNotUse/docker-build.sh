#!/bin/bash
#
# This script is preparation for creating customized NGINX container
#

docker build -t nginx_proxy --network=host -f ./nginx_proxy.Dockerfile . "${@}"
