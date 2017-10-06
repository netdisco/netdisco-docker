#FROM phusion/baseimage
FROM debian
ENV NETDISCO_HOME "/netdisco"
ENV PATH $NETDISCO_HOME/perl5/bin:$PATH

ADD *.sh /
ADD netdiscologrotate /etc/logrotate.d/

RUN apt-get -yq update && \
    apt-get install -yq --no-install-recommends \
      libssl-dev \
      libdbd-pg-perl \
      libsnmp-perl \
      build-essential \
      libnet-ldap-perl \
      postgresql-client \
      curl \
      iputils-ping \
      snmp && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${NETDISCO_HOME}/cron && \
    chmod 755 /*.sh && \
    ls -l /


WORKDIR $NETDISCO_HOME


# https://metacpan.org/pod/App::Netdisco#Installation
RUN curl -L https://cpanmin.us/ | perl - --notest --local-lib ${NETDISCO_HOME}/perl5 App::Netdisco && \
    cd ${NETDISCO_HOME} && \
    curl -o oui.txt https://raw.githubusercontent.com/netdisco/upstream-sources/master/ieee/oui.txt 
    
    
RUN ln -s /netdisco/perl5/bin /netdisco/bin 

#VOLUME /netdisco/environments
#EXPOSE 5000

ENTRYPOINT ["/startup.sh"]
