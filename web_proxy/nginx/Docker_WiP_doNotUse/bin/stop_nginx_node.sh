#!/bin/bash
#
# This script is wrapper for starting customized NGINX container
#
cwd=$(pushd "$(dirname $(readlink -f "${0}"))" > /dev/null 2>&1 && pwd -P && popd > /dev/null 2>&1)
${cwd}/docker-exec.sh /sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx/nginx.pid
exit 0
