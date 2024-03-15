#!/bin/bash

mkdir config
mkdir customAutoLoad
mkdir database
mkdir videos
mkdir plugins

chmod -R 777 config
chmod -R 777 customAutoLoad
chmod -R 777 database
chmod -R 777 videos
chmod -R 777 plugins

docker compose up -d --force-recreate --build --always-recreate-deps