# vim: ft=Dockerfile
ARG COMMITTISH=latest
FROM localhost:5000/netdisco:${COMMITTISH}-base

LABEL org.label-schema.name="netdisco-web" \
      org.label-schema.description="Web Frontend for Netdisco"

EXPOSE 5000
ENTRYPOINT ["/home/netdisco/bin/netdisco-web"]
CMD ["foreground"]
