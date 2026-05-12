#!/bin/bash
#
# This script is preparation for starting customized NGINX container
#
docker run --name "nginx_proxy_$(date +%N)" --rm -v "/dev/:/dev" -v "/etc/nginx:/etc/nginx:ro" -v "$(pwd)/localhost.crt:/etc/ssl/certs/localhost.crt:ro" -v "$(pwd)/localhost.key:/etc/ssl/private/localhost.key:ro" -v "/var/www/html:/var/www/html:ro" --network=host nginx_proxy "${@}"
