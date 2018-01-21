# vim: ft=Dockerfile
ARG TAG=latest
FROM docker.io/netdisco/netdisco:${TAG}-base

LABEL org.label-schema.name="netdisco-web" \
      org.label-schema.description="Web Frontend for Netdisco"

EXPOSE 5000
ENTRYPOINT ["/home/netdisco/bin/netdisco-web"]
CMD ["foreground"]
