#!/bin/bash
#
# This script is wrapper for starting customized NGINX container
#
cwd=$(pushd "$(dirname $(readlink -f "${0}"))" > /dev/null 2>&1 && pwd -P && popd > /dev/null 2>&1)
${cwd}/docker-run.sh "${@}" -g "daemon off; master_process on;"
