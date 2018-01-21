# vim: ft=Dockerfile
FROM docker.io/alpine:3.6 as netdisco-builder-image

ARG COMMITTISH=HEAD

RUN apk add --no-cache \
      ca-certificates \
      curl \
      g++ \
      gcc \
      git \
      libc6-compat \
      make \
      net-snmp-perl \
      openssl-dev \
      perl-crypt-rijndael \
      perl-dbd-pg \
      perl-dev \
      perl-io-socket-ssl \
      perl-ldap \
      postgresql-client \
      wget && \
    apk fix --no-cache perl perl-dev

WORKDIR /tmp
RUN curl -sL -o /tmp/cpanm https://cpanmin.us/ && \
  chmod +x /tmp/cpanm

WORKDIR /home/netdisco
RUN PERL5LIB='.' /tmp/cpanm --quiet --notest --local-lib ./perl5 \
  "https://github.com/netdisco/netdisco.git@${COMMITTISH}" && \
  mv /home/netdisco /home/netdisco-build

# ----------------------------------------------------------------------------
FROM docker.io/alpine:3.6

ARG TAG=latest

LABEL org.netdisco.maintainer="The Netdisco Project"
LABEL org.netdisco.version=${TAG}

RUN apk add --no-cache \
      libc6-compat \
      net-snmp-perl \
      perl-crypt-rijndael \
      perl-dbd-pg \
      perl-io-socket-ssl \
      perl-ldap \
      postgresql-client \
      shadow

RUN groupadd -r netdisco -g 901 && \
    useradd -u 901 -r -p x -g netdisco -m -d /home/netdisco -s /bin/ash -c "netdisco user" netdisco

USER netdisco:netdisco
RUN for tgt in bin environments nd-site-local logs; \
      do mkdir /home/netdisco/$tgt; done

COPY --chown=netdisco:netdisco --from=netdisco-builder-image \
  /home/netdisco-build /home/netdisco/

# replace default config with one that works better for docker install
COPY --chown=netdisco:netdisco deployment.yml \
  /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml
COPY --chown=netdisco:netdisco wait_to_start.sh /home/netdisco/bin/

RUN for tgt in /home/netdisco/perl5/bin/netdisco-*; \
      do ln -sf $tgt /home/netdisco/bin/; done && \
    ln -sf /home/netdisco/perl5/bin/localenv /home/netdisco/bin/

WORKDIR /home/netdisco
ENV PATH "/home/netdisco/bin:$PATH"
ENV SHELL /bin/ash

VOLUME ["/home/netdisco/environments", "/home/netdisco/nd-site-local", "/home/netdisco/logs"]

CMD ["ash"]
