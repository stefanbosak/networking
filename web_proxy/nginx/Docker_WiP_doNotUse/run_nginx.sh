#!/bin/bash
#
# This script is wrapper for starting customized NGINX container
#
./docker-run.sh "${@}" -g "daemon off;"
