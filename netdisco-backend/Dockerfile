# vim: ft=Dockerfile
ARG TAG=latest
FROM docker.io/netdisco/netdisco:${TAG}-base

LABEL org.label-schema.name="netdisco-backend" \
      org.label-schema.description="Polling Daemon for Netdisco"

USER root
RUN apk add --no-cache \
      ca-certificates \
      curl \
      jq \
      tar

WORKDIR /home/netdisco/netdisco-mibs
RUN curl -sL https://api.github.com/repos/netdisco/netdisco-mibs/tags | \
  jq '.[]|.tarball_url|select(test("tarball/\\d+\\.\\d+$"))' | \
  sort -rg | head -n1 | xargs -n1 curl -sL | tar --strip-components=1 -zxf - && \
  chown -R netdisco:netdisco /home/netdisco/netdisco-mibs

USER netdisco:netdisco
WORKDIR /home/netdisco
ENTRYPOINT ["/home/netdisco/bin/netdisco-backend"]
CMD ["foreground"]
