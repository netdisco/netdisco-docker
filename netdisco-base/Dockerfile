# vim: ft=Dockerfile
FROM debian:stable-slim

# since we are using a slim image, we must make any directories that packages
# want to symlink man pages into
RUN for i in 1 2 3 4 5 6 7 8 ; do mkdir -p /usr/share/man/man$i ; done && \
    apt-get -yq update && \
    apt-get install -yq --no-install-recommends \
      build-essential \
      ca-certificates \
      cpanminus \
      curl \
      daemontools-run \
      git \
      jq \
      libdbd-pg-perl \
      libio-socket-ssl-perl \
      libnet-ldap-perl \
      libsnmp-perl \
      libssl-dev \
      postgresql-client && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/*

ENV NETDISCO_HOME "/home/netdisco"
RUN groupadd -r netdisco -g 901 && \
    useradd -u 901 -r -g netdisco -m -d $NETDISCO_HOME -s /bin/bash -c "netdisco user" netdisco
USER netdisco:netdisco

ENV SHELL "/bin/bash"
WORKDIR $NETDISCO_HOME

RUN curl -s https://api.github.com/repos/netdisco/netdisco/tags | \
  jq '.[]|.name|select(test("^\\d+\\.\\d+$"))|"https://github.com/netdisco/netdisco.git@"+.' | \
  sort -rg | head -n1 | PERL5LIB='.' xargs -n1 cpanm --quiet --notest --local-lib $NETDISCO_HOME/perl5

CMD bash
