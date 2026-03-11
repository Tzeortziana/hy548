#!/bin/bash

TARGET_URL=${URL:-"https://www.csd.uoc.gr"}

echo "Downloading site: $TARGET_URL"

apt-get update && apt-get install -y wget
mkdir -p /usr/share/nginx/html

wget -E -k -p -P /usr/share/nginx/html -nH --cut-dirs=100 $TARGET_URL

nginx -g 'daemon off;'