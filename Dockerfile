FROM phusion/baseimage
ENV NETDISCO_HOME "/netdisco"

RUN apt-get -yq update && \
    apt-get install -yq --no-install-recommends \
      libssl-dev \
      libdbd-pg-perl  \
      libsnmp-perl  \
      build-essential  \
      libnet-ldap-perl \
      postgresql-client  \
      curl &&  \
    apt-get clean &&   \
    rm -rf /var/lib/apt/lists/*
RUN mkdir ${NETDISCO_HOME}
RUN mkdir ${NETDISCO_HOME}/cron
WORKDIR $NETDISCO_HOME

ADD *.sh /
RUN chmod 755 /*.sh
 
# https://metacpan.org/pod/App::Netdisco#Installation
RUN curl -L https://cpanmin.us/ | perl - --notest --local-lib ~/perl5 App::Netdisco
RUN cd /tmp && curl -o oui.txt http://linuxnet.ca/ieee/oui.txt
ENV PATH $NETDISCO_HOME/perl5/bin:$PATH

#VOLUME /netdisco/environments
#EXPOSE 5000

ENTRYPOINT ["/startup.sh"]
