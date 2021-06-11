#!/bin/bash

docker build -t lucasfs/pg-sharding-master ./master/ --no-cache
docker push lucasfs/pg-sharding-master:latest

docker build -t lucasfs/pg-sharding-shard ./shard/ --no-cache
docker push lucasfs/pg-sharding-shard:latest