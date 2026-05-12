#!/bin/bash
#
# This script is wrapper for executing of command within customized NGINX container
#
cwd=$(pushd "$(dirname $(readlink -f "${0}"))" > /dev/null 2>&1 && pwd -P && popd > /dev/null 2>&1)
${cwd}/docker-exec.sh "${@}"
