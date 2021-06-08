FROM lucasfs/postgres-armv7:14-beta

LABEL maintainer="github.com/lucas-fs"

COPY ./setup-shard.sh /docker-entrypoint-initdb.d/setup-shard.sh

RUN chmod 0666 /docker-entrypoint-initdb.d/setup-shard.sh
