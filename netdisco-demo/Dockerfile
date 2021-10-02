# vim: ft=Dockerfile
ARG TAG=latest
FROM docker.io/netdisco/netdisco:${TAG}-web

LABEL org.label-schema.name="netdisco-demo" \
      org.label-schema.description="Heroku Demo instance for Netdisco"

COPY --chown=netdisco:netdisco deployment.yml \
  /home/netdisco/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml

ENTRYPOINT ["/home/netdisco/bin/netdisco-web"]
CMD ["foreground"]
