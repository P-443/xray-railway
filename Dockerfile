# Use Ubuntu base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    NGROK_TOKEN=37cNdtLNPnD1G7GJsjoeVM6RegX_6zdX6QEcwCBPgUeQPCebK \
    SSH_USER=telegram \
    SSH_PASS=@d_s_d_c1 \
    TCP_PORT=22 \
    UDP_PORT=7300

# Update and install required packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    openssh-server \
    python3 \
    python3-pip \
    python3-venv \
    socat \
    net-tools \
    iputils-ping \
    dnsutils \
    vim \
    nano \
    tzdata \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set timezone and locale
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Install Ngrok
RUN curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/ngrok

# Install Go for UDPGW
RUN wget -q https://go.dev/dl/go1.21.1.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz && \
    rm go1.21.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Clone and build UDPGW
RUN git clone https://github.com/mukswilly/udpgw.git /opt/udpgw && \
    cd /opt/udpgw/cmd && \
    go build -o server && \
    ./server -port 7300 generate

# Create startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Setup SSH directory
RUN mkdir -p /var/run/sshd

# Expose ports
EXPOSE 22 7300 4040

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
