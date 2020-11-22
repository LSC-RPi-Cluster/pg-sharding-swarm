#!/bin/bash

PG_USER=${POSTGRES_USER:=postgres}
PG_PASS=$POSTGRES_PASSWORD
AUTH_METHOD=${POSTGRES_HOST_AUTH_METHOD:=md5} 
PG_DB=${POSTGRES_DB:=$PG_USER}

if [ -z "$TASK_SLOT" ]
then
  echo "TASK_SLOT is not defined!"
  exit 1
else
  SHARD_ID=$(printf %02d $TASK_SLOT)
fi

MASTER_SERVICE=${MASTER_SERVICE:=master}
MASTER_TASK=`getent hosts tasks.$MASTER_SERVICE | awk '{print $1}'`
MASTER_IP=$(echo "$MASTER_TASK" | paste -d, -s -)

HOST_IP=$(hostname -i)

echo "POSTGRES_USER : $PG_USER"
echo "POSTGRES_HOST_AUTH_METHOD : $AUTH_METHOD"
echo "POSTGRES_DB : $PG_DB"
echo "MASTER_SERVICE : $MASTER_SERVICE"
echo "MASTER_IP : $MASTER_IP"
echo "HOST_IP : $HOST_IP"
echo "SHARD_NAME : shard_$SHARD_ID"

echo "host all $PG_USER all $AUTH_METHOD" >> "$PGDATA/pg_hba.conf"

until pg_isready -h $MASTER_IP -p 5432 -U $PG_USER
do
  echo "Waiting for master node..."
  sleep 2
done

set -e
PGPASSWORD=$PG_PASS psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PG_DB" -h $MASTER_IP <<-EOSQL
    CREATE SERVER IF NOT EXISTS shard_$SHARD_ID 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (dbname '$PG_DB', host '$HOST_IP');

    CREATE USER MAPPING IF NOT EXISTS for $PG_USER 
    SERVER shard_$SHARD_ID 
    OPTIONS (user '$PG_USER', password '$PG_PASS');
EOSQL
