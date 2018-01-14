# vim: ft=Dockerfile
FROM docker.io/alpine:latest as netdisco-builder-image

RUN apk add --no-cache \
      ca-certificates \
      curl \
      g++ \
      gcc \
      git \
      jq \
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
RUN curl -sL https://api.github.com/repos/netdisco/netdisco/tags | \
  jq '.[]|.name|select(test("^\\d+\\.\\d+$"))|"https://github.com/netdisco/netdisco.git@"+.' | \
  sort -rg | head -n1 | \
  PERL5LIB='.' xargs -n1 /tmp/cpanm --quiet --notest --local-lib ./perl5 && \
  mv /home/netdisco /home/netdisco-build

FROM docker.io/alpine:latest as netdisco-base-image

ARG TAG
ENV TAG ${TAG:-master}

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

RUN for tgt in bin environments nd-site-local logs; \
      do mkdir /home/netdisco/$tgt; done

COPY deployment.yml /home/netdisco/environments/
COPY wait_to_start.sh /home/netdisco/bin/

# as Docker Cloud is not yet suppporting COPY --chown we can
# run this last phase with build --squash to achieve something similar.
FROM netdisco-base-image

COPY --from=netdisco-builder-image /home/netdisco-build /home/netdisco/
RUN for tgt in /home/netdisco/perl5/bin/netdisco-*; \
      do ln -sf $tgt /home/netdisco/bin/; done && \
    ln -sf /home/netdisco/perl5/bin/localenv /home/netdisco/bin/
RUN chown -R netdisco:netdisco /home/netdisco

WORKDIR /home/netdisco
USER netdisco:netdisco
ENV PATH "/home/netdisco/bin:$PATH"
ENV SHELL /bin/ash

VOLUME ["/home/netdisco/environments", "/home/netdisco/nd-site-local", "/home/netdisco/logs"]

CMD ["ash"]
