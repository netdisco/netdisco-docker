# vim: ft=Dockerfile
ARG TAG=latest
FROM netdisco:${TAG}-backend

LABEL org.label-schema.name="netdisco-do" \
      org.label-schema.description="CLI App for Netdisco"

USER root
RUN apk add --no-cache bash
USER netdisco:netdisco

COPY --chown=netdisco:netdisco netdisco-updatedb.sh /home/netdisco/bin/
RUN chmod +x /home/netdisco/bin/netdisco-updatedb.sh

WORKDIR /var/lib/postgresql/netdisco-sql
RUN curl -sLO "https://raw.githubusercontent.com/netdisco/upstream-sources/refs/heads/master/bootstrap/netdisco-lookup-tables.sql"

ENTRYPOINT ["/home/netdisco/bin/netdisco-do"]
CMD [""]
