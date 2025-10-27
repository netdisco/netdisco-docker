# vim: ft=Dockerfile
ARG PGVER=18
FROM docker.io/postgres:${PGVER}-alpine

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

COPY netdisco-initdb.sh /docker-entrypoint-initdb.d/
COPY netdisco-db-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/netdisco-db-entrypoint.sh

HEALTHCHECK --interval=3s --timeout=3s --retries=10 --start-period=10s \
  CMD ["pg_isready", "-h", "netdisco-postgresql", "-U", "postgres"]

WORKDIR /
ENTRYPOINT ["/usr/local/bin/netdisco-db-entrypoint.sh"]
CMD ["postgres"]
