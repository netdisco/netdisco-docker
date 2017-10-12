FROM debian:stable-slim
ENV NETDISCO_HOME "/netdisco"
ENV PATH $NETDISCO_HOME/perl5/bin:$PATH

ADD *.sh /
ADD netdiscologrotate /etc/logrotate.d/

RUN touch /usr/share/man/man1/ && \
    apt-get -yq update && \
    apt-get install -yq --no-install-recommends \
      libssl-dev \
      libdbd-pg-perl \
      libsnmp-perl \
      libio-socket-ssl-perl \
      build-essential \
      libnet-ldap-perl \
      postgresql-client \
      curl \
      iputils-ping \
      snmp \
      procps \
      ca-certificates \
      cron && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${NETDISCO_HOME}/cron && \
    chmod 755 /*.sh && \
    ls -l /

#libnetssleay-perl \

WORKDIR $NETDISCO_HOME


# https://metacpan.org/pod/App::Netdisco#Installation
RUN curl -L https://cpanmin.us/ | perl - --notest --local-lib ${NETDISCO_HOME}/perl5 App::Netdisco && \
    curl -o /${NETDISCO_HOME}/oui.txt https://raw.githubusercontent.com/netdisco/upstream-sources/master/ieee/oui.txt && \
    ln -s /netdisco/perl5/bin/ /netdisco/bin 


#VOLUME /netdisco/environments
#EXPOSE 5000

ENTRYPOINT ["/startup.sh"]
