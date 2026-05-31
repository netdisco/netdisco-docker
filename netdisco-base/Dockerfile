# vim: ft=Dockerfile
# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS netdisco-static-image

# temporary bloated image used for building Netdisco.
# netdisco-base will copy the built Netdisco files from this image

ARG CACHE_BUST_OS=1
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add \
      linux-headers \
      ca-certificates \
      curl \
      findutils \
      g++ \
      gcc \
      git \
      jq \
      libc6-compat \
      musl-dev \
      musl-obstack-dev \
      make \
      net-snmp-perl \
      openssl-dev \
      perl-crypt-rijndael \
      perl-dbd-pg \
      perl-dev \
      perl-io-socket-ssl \
      perl-ldap \
      perl-netaddr-ip \
      postgresql18-client \
      postgresql18-dev \
      python3 \
      tzdata \
      openssh-client \
      wget && \
    apk fix --no-cache perl perl-dev

WORKDIR /tmp
RUN curl -sL -o /tmp/cpanm https://cpanmin.us/ && \
  chmod +x /tmp/cpanm

ARG WORK_DIR=/home/netdisco
WORKDIR ${WORK_DIR}

# CFLAGS for Authen::TacacsPlus
RUN --mount=type=cache,target=${WORK_DIR}/.cpanm,sharing=locked \
    export PERL5LIB="${WORK_DIR}" \
           PERL_CPANM_HOME="${WORK_DIR}/.cpanm" && \
           CFLAGS="-Wno-error=old-style-definition -std=gnu17" \
    /tmp/cpanm --verbose --notest --local-lib "${WORK_DIR}/perl5" \
      IO::Tty Authen::TacacsPlus

RUN --mount=type=cache,target=${WORK_DIR}/.cpanm,sharing=locked \
    export PERL5LIB="${WORK_DIR}" \
           PERL_CPANM_HOME="${WORK_DIR}/.cpanm" && \
    /tmp/cpanm --quiet --notest --local-lib "${WORK_DIR}/perl5" \
      Dancer::Debug \
      URL::Encode \
      REST::Client

# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS fetcher

# retrieve Build.PL to use as a cache invalidation test (whether to rebuild
# netdisco dependencies which is a very slow task)

RUN --mount=type=cache,target=/var/cache/apk \
    apk add git

# NETDISCO_GIT_URL lets CI / local builds point at a fork (e.g. to test a PR)
# without editing the Dockerfile. Defaults to upstream.

ARG NETDISCO_GIT_URL=https://github.com/netdisco/netdisco.git
ARG COMMITTISH=HEAD

WORKDIR /fetch

RUN git init \
  && git remote add origin "${NETDISCO_GIT_URL}" \
  && git fetch --depth 1 origin "${COMMITTISH}" \
  && git reset --hard FETCH_HEAD

# ----------------------------------------------------------------------------
FROM netdisco-static-image AS netdisco-builder-image

# grab the fetched file from the second stage.
# if Build.PL has not changed, Docker's cache remains valid.
COPY --from=fetcher /fetch/Build.PL /tmp/netdisco-tree/Build.PL
COPY Netdisco.pm /tmp/netdisco-tree/lib/App/Netdisco.pm
COPY Builder.pm /tmp/netdisco-tree/lib/App/Netdisco/Builder.pm

RUN --mount=type=cache,target=${WORK_DIR}/.cpanm,sharing=locked \
    export PERL5LIB="${WORK_DIR}" \
           PERL_CPANM_HOME="${WORK_DIR}/.cpanm" && \
    /tmp/cpanm --quiet --notest --local-lib "${WORK_DIR}/perl5" \
      --installdeps /tmp/netdisco-tree

# in github actions the COMMITTISH is set to latest release version
#
# NETDISCO_GIT_URL lets CI / local builds point at a fork (or PR)
# without editing the Dockerfile. Defaults to upstream, but can
# also be something like "/path/to/local/checkout" (yes, really).

ARG NETDISCO_GIT_URL=https://github.com/netdisco/netdisco.git
ARG COMMITTISH=HEAD

RUN --mount=type=cache,target=${WORK_DIR}/.cpanm,sharing=locked \
    export PERL5LIB="${WORK_DIR}" \
           PERL_CPANM_HOME="${WORK_DIR}/.cpanm" && \
    /tmp/cpanm --quiet --notest --local-lib "${WORK_DIR}/perl5" \
      "${NETDISCO_GIT_URL}@${COMMITTISH}"

RUN mv /home/netdisco /home/netdisco-build

# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest

ARG CACHE_BUST_OS=1
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add \
      shadow \
      findutils \
      libc6-compat \
      musl-dev \
      musl-obstack-dev \
      net-snmp-perl \
      expect \
      expect-dev \
      perl-crypt-rijndael \
      perl-dbd-pg \
      perl-io-socket-ssl \
      perl-ldap \
      perl-json \
      perl-lwp-protocol-https \
      perl-file-slurp \
      perl-regexp-common \
      perl-regexp-common-net-cidr \
      perl-regexp-ipv6 \
      perl-file-sharedir \
      perl-netaddr-ip \
      postgresql18-client \
      python3 \
      tzdata \
      bash \
      zstd \
      icu-data-full \
      jq

RUN groupadd -r netdisco -g 901 && \
    useradd -u 901 -r -p x -g netdisco -m -d /home/netdisco -s /bin/ash -c "netdisco user" netdisco
USER netdisco:netdisco

RUN for tgt in bin environments nd-site-local logs; \
      do mkdir /home/netdisco/$tgt; done && \
      ln -s /dev/stdout /home/netdisco/logs/netdisco-backend.log && \
      ln -s /dev/stdout /home/netdisco/logs/netdisco-web.log

# copy Netdisco from the bloated build image
COPY --chown=netdisco:netdisco --from=netdisco-builder-image \
  /home/netdisco-build /home/netdisco/

# replace default config with one that works better for docker install
COPY --chown=netdisco:netdisco deployment.yml \
  /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml

RUN for tgt in /home/netdisco/perl5/bin/netdisco-*; \
      do ln -sf $tgt /home/netdisco/bin/; done && \
    ln -sf /home/netdisco/perl5/bin/localenv /home/netdisco/bin/

# Make /home/netdisco writable under arbitrary UIDs (OpenShift random UID,
# kubectl runAsUser, etc.) by routing access via supplemental gid 0, which
# is added to every container by OpenShift. Harmless when the image runs
# as the netdisco user (the default in docker compose).
USER root
RUN chgrp -R 0 /home/netdisco && chmod -R g=u /home/netdisco

USER netdisco:netdisco
WORKDIR /home/netdisco

ENV PATH="/home/netdisco/bin:$PATH"
ENV SHELL=/bin/ash

## volumes can be optional, and controlled by docker-compose file
# VOLUME ["/home/netdisco/environments", "/home/netdisco/nd-site-local", "/home/netdisco/logs"]

CMD ["ash"]
