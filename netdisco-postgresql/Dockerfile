# vim: ft=Dockerfile
FROM docker.io/postgres:9.6.6-alpine

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

RUN apk add --no-cache \
  curl \
  tar

COPY netdisco-initdb.sh /docker-entrypoint-initdb.d/
COPY netdisco-db-entrypoint.sh netdisco-updatedb.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/netdisco-*

WORKDIR /var/lib/postgresql/netdisco-sql
RUN curl -sL "https://api.github.com/repos/netdisco/netdisco/tarball/${COMMITTISH}" | \
  tar --wildcards --strip-components=3 -zx '*App-Netdisco-DB-*' && \
  curl -sLO "https://raw.githubusercontent.com/netdisco/upstream-sources/master/ieee/oui.sql" && \
  curl -sLO "https://raw.githubusercontent.com/netdisco/netdisco/master/lib/App/Netdisco/DB.pm"

VOLUME ["/var/lib/postgresql/data"]

WORKDIR /
ENTRYPOINT ["/usr/local/bin/netdisco-db-entrypoint.sh"]
CMD ["postgres"]
