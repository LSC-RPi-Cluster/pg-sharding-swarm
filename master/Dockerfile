FROM postgres:14beta2-buster

LABEL maintainer="github.com/lucas-fs"

COPY ./setup-master.sh /docker-entrypoint-initdb.d/setup-master.sh

RUN chmod 0666 /docker-entrypoint-initdb.d/setup-master.sh
