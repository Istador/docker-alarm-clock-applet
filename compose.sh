#!/bin/sh
set -e
dir=$(dirname "$0")

export UID=$(id -u)
export GID=$(id -g)
export DBUS_SESSION_BUS_ADDRESS
export DBUS=/run/user/$UID/bus

cd "$dir"
docker-compose  $@
