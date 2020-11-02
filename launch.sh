#!/bin/sh
set -e
dir=$(dirname "$0")
"$dir/compose.sh"  up  -d
