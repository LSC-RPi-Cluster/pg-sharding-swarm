#!/bin/bash

PG_USER=${POSTGRES_USER:=postgres}
PG_PASS=$POSTGRES_PASSWORD
AUTH_METHOD=${POSTGRES_HOST_AUTH_METHOD:=md5} 
PG_DB=${POSTGRES_DB:=$PG_USER}

FETCH_SIZE=${FDW_FETCH_SIZE:=100}
BATCH_SIZE=${FDW_BATCH_SIZE:=1}

if [ -z "$TASK_SLOT" ]
then
    echo "TASK_SLOT is not defined!"
    exit 1
else
    SHARD_ID=$(printf %02d $TASK_SLOT)
fi

COORDINATOR_SERVICE=${COORDINATOR_SERVICE:=coordinator}
COORDINATOR_TASK=`getent hosts tasks.$COORDINATOR_SERVICE | awk '{print $1}'`
COORDINATOR_IP=$(echo "$COORDINATOR_TASK" | paste -d, -s -)

HOST_IP=$(hostname -i)

echo "POSTGRES_USER : $PG_USER"
echo "POSTGRES_HOST_AUTH_METHOD : $AUTH_METHOD"
echo "POSTGRES_DB : $PG_DB"
echo "COORDINATOR_SERVICE : $COORDINATOR_SERVICE"
echo "COORDINATOR_IP : $COORDINATOR_IP"
echo "HOST_IP : $HOST_IP"
echo "SHARD_NAME : shard_$SHARD_ID"
echo "FDW fetch_size : $FETCH_SIZE"
echo "FDW batch_size : $BATCH_SIZE"


echo "host all $PG_USER all $AUTH_METHOD" >> "$PGDATA/pg_hba.conf"

until pg_isready -h $COORDINATOR_IP -p 5432 -U $PG_USER
do
    echo "Waiting for coordinator node..."
    sleep 2
done

set -e
PGPASSWORD=$PG_PASS psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PG_DB" -h $COORDINATOR_IP <<-EOSQL
    CREATE SERVER IF NOT EXISTS shard_$SHARD_ID 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (dbname '$PG_DB', host '$HOST_IP', fetch_size '$FETCH_SIZE', batch_size '$BATCH_SIZE');

    CREATE USER MAPPING IF NOT EXISTS for $PG_USER 
    SERVER shard_$SHARD_ID 
    OPTIONS (user '$PG_USER', password '$PG_PASS');
EOSQL
