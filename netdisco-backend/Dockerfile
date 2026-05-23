# vim: ft=Dockerfile
ARG TAG=latest
FROM localhost:5000/netdisco:${TAG}-base

USER root

RUN --mount=type=cache,target=/var/cache/apk \
    apk add \
      ca-certificates \
      curl \
      openssh-client \
      bash \
      tar

WORKDIR /var/lib/postgresql/netdisco-sql
RUN curl -sLO "https://github.com/netdisco/upstream-sources/raw/refs/heads/master/bootstrap/netdisco-lookup-tables.sql"

USER netdisco:netdisco
WORKDIR /home/netdisco

# if Netdisco MIBs VERSION has not changed, Docker's cache remains valid.
# there is a slight race, when the VERSION could have been updated in the repo before a release is made
# in which case docker will simply re-download the previous version (the current release)
ADD https://github.com/netdisco/netdisco-mibs/raw/refs/heads/master/VERSION /tmp/netdisco-mibs-version

RUN curl -sL https://api.github.com/repos/netdisco/netdisco-mibs/releases/latest | \
  grep browser_download_url | xargs printf "curl -sL %s\n" | tail -1 | \
  sh | tar -zxf -

ARG COMMITTISH=HEAD
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

COPY --chown=netdisco:netdisco netdisco-updatedb.sh /home/netdisco/bin/
RUN chmod +x /home/netdisco/bin/netdisco-updatedb.sh

LABEL org.label-schema.name="netdisco-backend" \
      org.label-schema.description="Polling Daemon for Netdisco"

ENTRYPOINT ["/home/netdisco/bin/netdisco-backend"]
CMD ["foreground"]
