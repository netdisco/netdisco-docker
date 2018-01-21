# vim: ft=Dockerfile
FROM docker.io/postgres:9.6.6-alpine

ARG TAG=latest
ARG COMMITTISH=HEAD

LABEL org.netdisco.maintainer="The Netdisco Project"
LABEL org.netdisco.version=${TAG}

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
