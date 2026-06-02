# vim: ft=Dockerfile
# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS fetcher

# retrieve Build.PL to use as a cache invalidation test (whether to rebuild
# netdisco dependencies which is a very slow task)

RUN --mount=type=cache,target=/var/cache/apk \
    apk add git

WORKDIR /fetch

# NETDISCO_GIT_URL lets CI / local builds point at a fork (e.g. to test a PR)
# without editing the Dockerfile. Defaults to upstream.

ARG NETDISCO_GIT_URL=https://github.com/netdisco/netdisco.git
ARG COMMITTISH=HEAD

RUN git init \
  && git remote add origin "${NETDISCO_GIT_URL}" \
  && git fetch --depth 1 origin "${COMMITTISH}" \
  && git reset --hard FETCH_HEAD

# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest AS netdisco-common-base

# temporary bloated image used for building Netdisco.
# netdisco-base will copy the built Netdisco files from this image

ARG CACHE_BUST_OS=1
RUN --mount=type=cache,target=/var/cache/apk \
    apk update && \
    apk add \
      bash \
      ca-certificates \
      curl \
      expect \
      expect-dev \
      findutils \
      icu-data-full \
      jq \
      libc6-compat \
      musl-dev \
      musl-obstack-dev \
      net-snmp-perl \
      openssh-client \
      perl-crypt-rijndael \
      perl-dbd-pg \
      perl-file-sharedir \
      perl-file-slurp \
      perl-io-socket-ssl \
      perl-json \
      perl-ldap \
      perl-lwp-protocol-https \
      perl-netaddr-ip \
      perl-regexp-common \
      perl-regexp-common-net-cidr \
      perl-regexp-ipv6 \
      postgresql18-client \
      python3 \
      shadow \
      tar \
      tzdata \
      zstd && \
    apk fix --no-cache perl perl-dev

# ----------------------------------------------------------------------------
FROM netdisco-common-base AS netdisco-builder-image

# temporary bloated image used for building Netdisco.
# netdisco-base will copy the built Netdisco files from this image

RUN --mount=type=cache,target=/var/cache/apk \
    apk add \
      g++ \
      gcc \
      git \
      linux-headers \
      make \
      openssl-dev \
      perl-dev \
      postgresql18-dev \
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
FROM netdisco-common-base

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
