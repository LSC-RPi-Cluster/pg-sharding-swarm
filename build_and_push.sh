#!/bin/bash

docker build -t lucasfs/pg-sharding-coordinator ./coordinator/ --no-cache
docker push lucasfs/pg-sharding-coordinator:latest

docker build -t lucasfs/pg-sharding-shard ./shard/ --no-cache
docker push lucasfs/pg-sharding-shard:latest