# vim: ft=Dockerfile
FROM docker.io/postgres:9.6.6-alpine

RUN apk add --no-cache \
  curl \
  jq \
  tar

COPY App-Netdisco-DB.sql docker-entrypoint-initdb.d/
RUN cd docker-entrypoint-initdb.d && \
  export TAG=$(curl -s https://api.github.com/repos/netdisco/netdisco/tags | \
  jq -r '.[]|.name|select(test("^\\d+\\.\\d+$"))' | sort -rg | head -n1) && \
  curl -sL "https://api.github.com/repos/netdisco/netdisco/tarball/$TAG" | \
  tar --wildcards -zt '*App-Netdisco-DB*' | xargs -n1 basename | sort -n -t '-' -k4 | \
  while read file; \
    do curl -sL "https://raw.githubusercontent.com/netdisco/netdisco/$TAG/share/schema_versions/$file" >> App-Netdisco-DB.sql; \
  done && \
  curl -sL "https://raw.githubusercontent.com/netdisco/upstream-sources/master/ieee/oui.sql" >> App-Netdisco-DB.sql

RUN PGDATA=/var/lib/postgresql/netdisco-data /usr/local/bin/docker-entrypoint.sh postgres --version

COPY netdisco-db-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/netdisco-db-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/netdisco-db-entrypoint.sh"]
CMD ["postgres"]
