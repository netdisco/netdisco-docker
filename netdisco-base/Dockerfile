# vim: ft=Dockerfile
FROM docker.io/alpine:latest AS netdisco-builder-image

# temporary bloated image used for building Netdisco
# in github actions the COMMITTISH is set to latest release version
# netdisco-base will copy the built Netdisco files from this image

ARG COMMITTISH=HEAD

RUN apk add --no-cache \
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
      perl-io-tty \
      postgresql-client \
      python3 \
      tzdata \
      openssh-client \
      wget && \
    apk fix --no-cache perl perl-dev

WORKDIR /tmp
RUN curl -sL -o /tmp/cpanm https://cpanmin.us/ && \
  chmod +x /tmp/cpanm

WORKDIR /home/netdisco
RUN PERL5LIB='.' \
   /tmp/cpanm --quiet --notest --local-lib ./perl5 \
   "https://github.com/netdisco/netdisco.git@${COMMITTISH}" \
   Dancer::Debug \
   URL::Encode \
   REST::Client && \
  mv /home/netdisco /home/netdisco-build

# ----------------------------------------------------------------------------
FROM docker.io/alpine:latest

ARG BUILD_DATE
ARG COMMITTISH=HEAD

LABEL org.label-schema.docker.schema-version="1.0" \
      org.label-schema.vendor="The Netdisco Project" \
      org.label-schema.url="http://netdisco.org" \
      org.label-schema.name="Netdisco Base" \
      org.label-schema.description="Base Image for Netdisco" \
      org.label-schema.usage="https://github.com/netdisco/netdisco-docker/blob/master/README.md" \
      org.label-schema.version=${COMMITTISH} \
      org.label-schema.vcs-ref=${COMMITTISH} \
      org.label-schema.vcs-url="git://github.com/netdisco/netdisco.git" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.netdisco.maintainer="The Netdisco Project" \
      org.netdisco.version=${COMMITTISH}

RUN apk add --no-cache \
      findutils \
      jq \
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
      perl-io-tty \
      postgresql-client \
      python3 \
      tzdata \
      shadow

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

WORKDIR /home/netdisco
ENV PATH="/home/netdisco/bin:$PATH"
ENV SHELL=/bin/ash

## volumes can be optional, and controlled by docker-compose file
# VOLUME ["/home/netdisco/environments", "/home/netdisco/nd-site-local", "/home/netdisco/logs"]

CMD ["ash"]
