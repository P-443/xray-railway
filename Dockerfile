# Use Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    NGROK_TOKEN=YOUR_NGROK_TOKEN_HERE \
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
    && rm -rf /var/lib/apt/lists/*

# Install Ngrok
RUN curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/ngrok

# Install Go for UDPGW
RUN wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz && \
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
EXPOSE 22
EXPOSE 7300

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
