#!/bin/bash
#
# This script is preparation for starting customized NGINX container
#
NAME=${NAME:-"nginx_proxy_$(date +%N)"}
docker run --name "${NAME}" --rm -v "/dev/:/dev" -v "/var/log/nginx:/var/log/nginx" -v "/etc/nginx:/etc/nginx:ro" -v "/usr/local/bin/localhost.crt:/etc/ssl/certs/localhost.crt:ro" -v "/usr/local/bin/localhost.key:/etc/ssl/private/localhost.key:ro" -v "/var/www/html:/var/www/html:ro" --network=host nginx_proxy "${@}"
