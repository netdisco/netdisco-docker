# vim: ft=Dockerfile
FROM docker.io/postgres:13.4-alpine

ARG BUILD_DATE
ARG COMMITTISH=HEAD

LABEL org.label-schema.docker.schema-version="1.0" \
      org.label-schema.vendor="The Netdisco Project" \
      org.label-schema.url="http://netdisco.org" \
      org.label-schema.name="Netdisco's PostgreSQL" \
      org.label-schema.description="Database for Netdisco" \
      org.label-schema.usage="https://github.com/netdisco/netdisco-docker/blob/master/README.md" \
      org.label-schema.version=${COMMITTISH} \
      org.label-schema.vcs-ref=${COMMITTISH} \
      org.label-schema.vcs-url="git://github.com/netdisco/netdisco.git" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.netdisco.maintainer="The Netdisco Project" \
      org.netdisco.version=${COMMITTISH}

VOLUME ["/var/lib/postgresql/data"]

COPY netdisco-initdb.sh /docker-entrypoint-initdb.d/

HEALTHCHECK --interval=3s --timeout=3s --retries=10 --start-period=10s \
  CMD ["CMD", "pg_isready", "-h", "localhost"]

WORKDIR /
