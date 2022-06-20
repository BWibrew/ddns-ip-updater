FROM alpine:3.16

RUN apk update && \
    apk add \
        curl \
        bind-tools \
        jq

COPY ./scripts/update_ip.sh /etc/periodic/15min/update_ip

RUN chmod +x /etc/periodic/15min/update_ip

CMD [ "/bin/sh", "-c", "crond -f -l 8" ]
