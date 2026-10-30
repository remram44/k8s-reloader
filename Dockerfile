FROM docker.io/alpine/kubectl:1.36.4

# Needs:
#   kubectl
#   sh (busybox)
#   sed
#   jq
#   sha256sum
RUN apk add jq

RUN adduser -h /nonexistent -H -D -s /usr/sbin/nologin -u 998 reloader

COPY reloader.sh /reloader.sh
USER 998
ENTRYPOINT ["/bin/sh"]
CMD ["/reloader.sh"]
