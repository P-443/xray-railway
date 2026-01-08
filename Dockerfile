FROM alpine:latest

RUN apk add --no-cache wget unzip ca-certificates bash

RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm Xray-linux-64.zip

COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
]
