FROM alpine:latest

# نصب ابزارها
RUN apk add --no-cache wget unzip ca-certificates

# دانلود Xray
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm Xray-linux-64.zip

# کپی کانفیگ
COPY config.json /etc/xray/config.json

# Expose پورت
EXPOSE 8080

# اجرای مستقیم
CMD ["/usr/local/bin/xray", "run", "-c", "/etc/xray/config.json"]
