# vim: ft=Dockerfile
FROM docker.io/postgres:9.6.6-alpine

ARG SOURCE_BRANCH
ENV SOURCE_BRANCH ${SOURCE_BRANCH:-master}

RUN apk add --no-cache \
  curl \
  jq \
  tar

RUN mkdir /var/lib/postgresql/netdisco-sql && \
  cd /var/lib/postgresql/netdisco-sql && \
  curl -sL "https://api.github.com/repos/netdisco/netdisco/tarball/${SOURCE_BRANCH}" | \
  tar --wildcards -zt '*App-Netdisco-DB-*' | xargs -n1 basename | sort -n -t '-' -k4 | \
  while read file; \
    do curl -sLO "https://raw.githubusercontent.com/netdisco/netdisco/${SOURCE_BRANCH}/share/schema_versions/$file"; \
  done && \
  curl -sLO "https://raw.githubusercontent.com/netdisco/upstream-sources/master/ieee/oui.sql" && \
  curl -sLO "https://raw.githubusercontent.com/netdisco/netdisco/master/lib/App/Netdisco/DB.pm"

RUN PGDATA=/var/lib/postgresql/netdisco-pgdata /usr/local/bin/docker-entrypoint.sh postgres --version

COPY netdisco-db-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/netdisco-db-entrypoint.sh

WORKDIR /
ENTRYPOINT ["/usr/local/bin/netdisco-db-entrypoint.sh"]
CMD ["postgres"]
