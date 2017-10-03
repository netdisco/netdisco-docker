FROM phusion/baseimage
ENV NETDISCO_HOME "/netdisco"
ENV PATH $NETDISCO_HOME/perl5/bin:$PATH

ADD *.sh /

RUN apt-get -yq update && \
    apt-get install -yq --no-install-recommends  \
      libssl-dev  \
      libdbd-pg-perl  \
      libsnmp-perl  \
      build-essential  \
      libnet-ldap-perl  \
      postgresql-client  \
      curl &&  \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${NETDISCO_HOME}/cron && \
    chmod 755 /*.sh
WORKDIR $NETDISCO_HOME

# https://metacpan.org/pod/App::Netdisco#Installation
RUN curl -L https://cpanmin.us/ | perl - --notest --local-lib ~/perl5 App::Netdisco && \
    cd /tmp && curl -o oui.txt http://linuxnet.ca/ieee/oui.txt


#VOLUME /netdisco/environments
#EXPOSE 5000

ENTRYPOINT ["/startup.sh"]
