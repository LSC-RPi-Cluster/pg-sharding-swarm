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
    COORDINATOR_ID=$(printf %02d $TASK_SLOT)
fi

HOST_IP=$(hostname -i)

echo "POSTGRES_USER : $PG_USER"
echo "POSTGRES_HOST_AUTH_METHOD : $AUTH_METHOD"
echo "POSTGRES_DB : $PG_DB"
echo "HOST_IP : $HOST_IP"
echo "COORDINATOR_NAME : coordinator_$COORDINATOR_ID"
echo "FDW fetch_size : $FETCH_SIZE"
echo "FDW batch_size : $BATCH_SIZE"

set -e
psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PG_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgres_fdw;

    CREATE SERVER IF NOT EXISTS coordinator_$COORDINATOR_ID 
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (dbname '$PG_DB', host '$HOST_IP', fetch_size '$FETCH_SIZE', batch_size '$BATCH_SIZE');

    CREATE USER MAPPING IF NOT EXISTS for $PG_USER 
    SERVER coordinator_$COORDINATOR_ID 
    OPTIONS (user '$PG_USER', password '$PG_PASS');
EOSQL

