# vim: ft=Dockerfile
ARG TAG=latest
FROM netdisco:${TAG}-base

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

RUN rm -f /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/python/netdisco/uv.lock
RUN `/home/netdisco/bin/localenv perl -MAlien::ultraviolet -e 'print Alien::ultraviolet->uv'` \
      --no-cache --no-progress --quiet --project \
      `/home/netdisco/bin/localenv perl -MFile::ShareDir -e 'print File::ShareDir::dist_dir("App-Netdisco") ."/python/netdisco"'` \
      sync --link-mode=copy

# https://github.com/astral-sh/uv/issues/9191
ENV UV_NO_MANAGED_PYTHON=true \
    UV_SYSTEM_PYTHON=true \
    UV_LOCKED=1 \
    UV_NO_SYNC=1 \
    UV_NO_CACHE=1 \
    UV_NO_DEV=1

USER netdisco:netdisco
WORKDIR /home/netdisco
ENTRYPOINT ["/home/netdisco/bin/netdisco-backend"]
CMD ["foreground"]
