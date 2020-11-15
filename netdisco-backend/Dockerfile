# vim: ft=Dockerfile
ARG TAG=latest
FROM docker.io/netdisco/netdisco:${TAG}-base

LABEL org.label-schema.name="netdisco-backend" \
      org.label-schema.description="Polling Daemon for Netdisco"

USER root
RUN apk add --no-cache \
      ca-certificates \
      curl \
      openssh-client \
      tar

WORKDIR /home/netdisco/netdisco-mibs
RUN curl -sL https://api.github.com/repos/netdisco/netdisco-mibs/releases/latest | \
  grep browser_download_url | xargs printf "curl -sL %s\n" | tail -1 | \
  sh | tar --strip-components=1 -zxf - && \
  chown -R netdisco:netdisco /home/netdisco/netdisco-mibs

USER netdisco:netdisco
WORKDIR /home/netdisco
ENTRYPOINT ["/home/netdisco/bin/netdisco-backend"]
CMD ["foreground"]
