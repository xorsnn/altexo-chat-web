#!/bin/bash

cd "${0%/*}"

export SCRIPT_DIR=`pwd`

cd ..

export VERSION=`cat package.json | python -c "import sys, json; print json.load(sys.stdin)['version']"`

npm run build

docker build -t xors/altexo-chat-web .
docker tag xors/altexo-chat-web xors/altexo-chat-web:v${VERSION}
