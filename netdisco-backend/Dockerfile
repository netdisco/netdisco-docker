# vim: ft=Dockerfile
# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS netdisco-mibs

# if Netdisco MIBs VERSION has not changed, Docker's cache remains valid.
# there is a slight race, when the VERSION could have been updated in the repo before a release is made
# in which case docker will simply re-download the previous version (the current release)
ADD https://github.com/netdisco/netdisco-mibs/raw/refs/heads/master/VERSION /tmp/netdisco-mibs-version

WORKDIR /tmp/netdisco-mibs
RUN `/usr/bin/curl -sL https://api.github.com/repos/netdisco/netdisco-mibs/releases/latest | \
  grep browser_download_url | xargs printf "/usr/bin/curl -sL %s\n" | tail -1 | \
  sh | tar --strip-components=1 -zxf -`

# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS netdisco-sql

# this will probably bust the cache as it updates weekly
ADD https://github.com/netdisco/upstream-sources/raw/refs/heads/master/bootstrap/netdisco-lookup-tables.sql /tmp/

# ----------------------------------------------------------------------------
FROM localhost:5000/netdisco:netdisco-base

USER netdisco:netdisco
WORKDIR /home/netdisco

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

COPY --chown=netdisco:netdisco --chmod=755 netdisco-updatedb.sh /home/netdisco/bin/
COPY --from=netdisco-mibs --chown=netdisco:netdisco /tmp/netdisco-mibs /home/netdisco/
COPY --from=netdisco-sql --chown=root:root /tmp/netdisco-lookup-tables.sql /var/lib/postgresql/netdisco-sql/

ARG COMMITTISH=HEAD
ARG BUILD_DATE

LABEL org.label-schema.docker.schema-version="1.0" \
      org.label-schema.vendor="The Netdisco Project" \
      org.label-schema.url="http://netdisco.org" \
      org.label-schema.name="netdisco-backend" \
      org.label-schema.description="Polling Daemon for Netdisco" \
      org.label-schema.usage="https://github.com/netdisco/netdisco-docker/blob/master/README.md" \
      org.label-schema.version=${COMMITTISH} \
      org.label-schema.vcs-ref=${COMMITTISH} \
      org.label-schema.vcs-url="git://github.com/netdisco/netdisco.git" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.netdisco.maintainer="The Netdisco Project" \
      org.netdisco.version=${COMMITTISH}

ENTRYPOINT ["/home/netdisco/bin/netdisco-backend"]
CMD ["foreground"]
