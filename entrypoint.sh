#!/bin/bash

# entrypoint.sh
set -e

# Function to set terminal colors
set_colors() {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    MAGENTA='\033[1;35m'
    CYAN='\033[1;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
}

# Function to get IP address
get_ip() {
    echo -e "${CYAN}[*] Getting IP address...${NC}"
    local ip_services=(
        "https://api.ipify.org"
        "https://ifconfig.me/ip"
        "https://icanhazip.com"
        "https://ident.me"
    )
    
    for service in "${ip_services[@]}"; do
        IP=$(timeout 5 curl -s "$service" || true)
        if [ -n "$IP" ] && [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "${GREEN}[✓] Got IP from $service${NC}"
            echo "$IP"
            return 0
        fi
    done
    echo "Unknown"
}

# Function to get country info
get_country() {
    echo -e "${CYAN}[*] Getting country information...${NC}"
    local country_info=$(timeout 5 curl -s "https://ipinfo.io/json" || true)
    
    if [ -n "$country_info" ]; then
        local country_code=$(echo "$country_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        local city=$(echo "$country_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        local country_name=$(echo "$country_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        
        # Convert to uppercase for flag detection
        country_name_upper=$(echo "$country_name" | tr '[:lower:]' '[:upper:]')
        
        # Get flag emoji
        case "$country_name_upper" in
            "US") flag="🇺🇸" ;;
            "GB"|"UK") flag="🇬🇧" ;;
            "DE") flag="🇩🇪" ;;
            "FR") flag="🇫🇷" ;;
            "JP") flag="🇯🇵" ;;
            "KR") flag="🇰🇷" ;;
            "CN") flag="🇨🇳" ;;
            "RU") flag="🇷🇺" ;;
            "BR") flag="🇧🇷" ;;
            "IN") flag="🇮🇳" ;;
            "CA") flag="🇨🇦" ;;
            "AU") flag="🇦🇺" ;;
            "SG") flag="🇸🇬" ;;
            "NL") flag="🇳🇱" ;;
            "SE") flag="🇸🇪" ;;
            "NO") flag="🇳🇴" ;;
            "FI") flag="🇫🇮" ;;
            "DK") flag="🇩🇰" ;;
            "ES") flag="🇪🇸" ;;
            "IT") flag="🇮🇹" ;;
            "TR") flag="🇹🇷" ;;
            "SA") flag="🇸🇦" ;;
            "AE") flag="🇦🇪" ;;
            "EG") flag="🇪🇬" ;;
            "ZA") flag="🇿🇦" ;;
            "MY") flag="🇲🇾" ;;
            "TH") flag="🇹🇭" ;;
            "VN") flag="🇻🇳" ;;
            "ID") flag="🇮🇩" ;;
            "PH") flag="🇵🇭" ;;
            *) flag="🏳️" ;;
        esac
        
        echo -e "${GREEN}[✓] Location detected: $city, $country_name${NC}"
        echo "$flag $city, $country_name"
    else
        echo "🏳️ Unknown Location"
    fi
}

# Function to display banner
display_banner() {
    clear
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                  RAILWAY SSH SERVER WITH NGROK                ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to configure and start SSH
setup_ssh() {
    echo -e "${YELLOW}[1/6] Configuring SSH Server...${NC}"
    
    # Create user if not exists
    if ! id "$SSH_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$SSH_USER"
        echo "$SSH_USER:$SSH_PASS" | chpasswd
        echo -e "${GREEN}[✓] User $SSH_USER created${NC}"
    fi
    
    # Configure SSH
    cat > /etc/ssh/sshd_config << EOF
Port $TCP_PORT
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
ClientAliveInterval 60
ClientAliveCountMax 3
AllowUsers $SSH_USER
EOF
    
    # Generate SSH keys if not exist
    ssh-keygen -A
    
    # Start SSH
    /usr/sbin/sshd -D &
    echo -e "${GREEN}[✓] SSH Server started on port $TCP_PORT${NC}"
}

# Function to start UDP Gateway
setup_udpgw() {
    echo -e "${YELLOW}[2/6] Starting UDP Gateway...${NC}"
    cd /opt/udpgw/cmd
    ./server run > /tmp/udpgw.log 2>&1 &
    echo -e "${GREEN}[✓] UDP Gateway started on port $UDP_PORT${NC}"
}

# Function to configure Ngrok
setup_ngrok() {
    echo -e "${YELLOW}[3/6] Configuring Ngrok with provided token...${NC}"
    
    # Check if token is set
    if [ -z "$NGROK_TOKEN" ]; then
        echo -e "${RED}[✗] ERROR: NGROK_TOKEN is empty!${NC}"
        exit 1
    fi
    
    # Configure ngrok
    ngrok config add-authtoken "$NGROK_TOKEN" > /dev/null 2>&1
    echo -e "${GREEN}[✓] Ngrok configured successfully${NC}"
    echo -e "${CYAN}[*] Token: ${NGROK_TOKEN:0:15}...${NC}"
}

# Function to start Ngrok tunnels
start_tunnels() {
    echo -e "${YELLOW}[4/6] Starting Ngrok Tunnels...${NC}"
    
    # Start TCP tunnel for SSH
    echo -e "${CYAN}  • Starting TCP tunnel on port $TCP_PORT...${NC}"
    nohup ngrok tcp "$TCP_PORT" --log=stdout > /tmp/ngrok_tcp.log 2>&1 &
    TCP_PID=$!
    sleep 3
    
    # Start UDP tunnel
    echo -e "${CYAN}  • Starting UDP tunnel on port $UDP_PORT...${NC}"
    nohup ngrok udp "$UDP_PORT" --log=stdout > /tmp/ngrok_udp.log 2>&1 &
    UDP_PID=$!
    sleep 3
    
    echo -e "${GREEN}[✓] Ngrok tunnels started${NC}"
}

# Function to get tunnel URLs
get_tunnel_urls() {
    echo -e "${YELLOW}[5/6] Fetching tunnel URLs...${NC}"
    
    # Wait for tunnels to initialize
    sleep 5
    
    # Get TCP tunnel URL
    for i in {1..15}; do
        TCP_URL=$(timeout 5 curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'tcp://[^"]*' || true)
        if [ -n "$TCP_URL" ]; then
            echo -e "${GREEN}[✓] TCP Tunnel: $TCP_URL${NC}"
            break
        fi
        sleep 2
    done
    
    # Get UDP tunnel URL
    UDP_URL=$(timeout 5 curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'udp://[^"]*' || true)
    if [ -n "$UDP_URL" ]; then
        echo -e "${GREEN}[✓] UDP Tunnel: $UDP_URL${NC}"
    fi
    
    # Extract host and port from TCP URL
    if [ -n "$TCP_URL" ]; then
        HOST_PORT=$(echo "$TCP_URL" | sed 's/tcp:\/\///')
        HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
        PORT=$(echo "$HOST_PORT" | cut -d':' -f2)
    fi
}

# Function to display final results
display_results() {
    echo -e "${YELLOW}[6/6] Preparing connection details...${NC}"
    
    # Get server information
    IP_ADDRESS=$(get_ip)
    COUNTRY_INFO=$(get_country)
    
    # Display banner
    display_banner
    
    # Display server info
    echo -e "${YELLOW}                  SERVER INFORMATION${NC}"
    echo -e "${CYAN}• IP Address:${WHITE} $IP_ADDRESS${NC}"
    echo -e "${CYAN}• Location:${WHITE} $COUNTRY_INFO${NC}"
    echo -e "${CYAN}• Platform:${WHITE} Railway + Docker + Ngrok${NC}"
    echo ""
    
    # Display account details
    echo -e "${YELLOW}                  ACCOUNT DETAILS${NC}"
    echo -e "${CYAN}• Username:${WHITE} $SSH_USER${NC}"
    echo -e "${CYAN}• Password:${WHITE} $SSH_PASS${NC}"
    echo ""
    
    # Display tunnel information
    echo -e "${YELLOW}                  TUNNEL INFORMATION${NC}"
    if [ -n "$TCP_URL" ]; then
        echo -e "${CYAN}• TCP Tunnel:${WHITE} $TCP_URL${NC}"
        echo -e "${CYAN}• SSH Command:${WHITE} ssh $SSH_USER@$HOST -p $PORT${NC}"
    else
        echo -e "${RED}• TCP Tunnel: Not available${NC}"
    fi
    
    if [ -n "$UDP_URL" ]; then
        echo -e "${CYAN}• UDP Tunnel:${WHITE} $UDP_URL${NC}"
    else
        echo -e "${RED}• UDP Tunnel: Not available${NC}"
    fi
    
    echo ""
    
    # Display connection string for HTTP Custom
    echo -e "${YELLOW}                  CONNECTION STRING${NC}"
    if [ -n "$HOST" ] && [ -n "$PORT" ]; then
        echo -e "${CYAN}• For HTTP Custom/Proxy:${NC}"
        echo -e "${WHITE}  $HOST:$PORT@$SSH_USER:$SSH_PASS${NC}"
        echo ""
        echo -e "${CYAN}• For SSH Clients:${NC}"
        echo -e "${WHITE}  Host: $HOST${NC}"
        echo -e "${WHITE}  Port: $PORT${NC}"
        echo -e "${WHITE}  User: $SSH_USER${NC}"
        echo -e "${WHITE}  Pass: $SSH_PASS${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}• Channel: ${BLUE}D_S_D_C1.T.ME${NC}"
    echo -e "${MAGENTA}• Developer: ${BLUE}l_s_I_I.T.ME${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[*] Status: All services are running${NC}"
    echo -e "${CYAN}[*] Check Railway logs for tunnel status${NC}"
    echo -e "${CYAN}[*] Container is running in background${NC}"
}

# Function to monitor services
monitor_services() {
    echo -e "${CYAN}[*] Starting service monitor...${NC}"
    while true; do
        # Check SSH
        if ! pgrep sshd > /dev/null; then
            echo -e "${RED}[!] SSH service stopped, restarting...${NC}"
            /usr/sbin/sshd -D &
        fi
        
        # Check Ngrok TCP
        if ! pgrep -f "ngrok tcp" > /dev/null; then
            echo -e "${RED}[!] Ngrok TCP tunnel stopped, restarting...${NC}"
            nohup ngrok tcp "$TCP_PORT" --log=stdout > /tmp/ngrok_tcp.log 2>&1 &
        fi
        
        # Check Ngrok UDP
        if ! pgrep -f "ngrok udp" > /dev/null; then
            echo -e "${RED}[!] Ngrok UDP tunnel stopped, restarting...${NC}"
            nohup ngrok udp "$UDP_PORT" --log=stdout > /tmp/ngrok_udp.log 2>&1 &
        fi
        
        sleep 30
    done
}

# Main function
main() {
    # Initialize colors
    set_colors
    
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}            AUTOMATED SSH SERVER DEPLOYMENT                   ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Set environment from Dockerfile
    export TERM=xterm
    export NGROK_TOKEN=${NGROK_TOKEN:-37cNdtLNPnD1G7GJsjoeVM6RegX_6zdX6QEcwCBPgUeQPCebK}
    export SSH_USER=${SSH_USER:-telegram}
    export SSH_PASS=${SSH_PASS:-@d_s_d_c1}
    export TCP_PORT=${TCP_PORT:-22}
    export UDP_PORT=${UDP_PORT:-7300}
    
    echo -e "${CYAN}[*] Configuration Loaded:${NC}"
    echo -e "${WHITE}  • Ngrok Token: ${NGROK_TOKEN:0:15}...${NC}"
    echo -e "${WHITE}  • SSH User: $SSH_USER${NC}"
    echo -e "${WHITE}  • SSH Pass: $SSH_PASS${NC}"
    echo -e "${WHITE}  • TCP Port: $TCP_PORT${NC}"
    echo -e "${WHITE}  • UDP Port: $UDP_PORT${NC}"
    echo ""
    
    # Setup services
    setup_ssh
    setup_udpgw
    setup_ngrok
    start_tunnels
    get_tunnel_urls
    display_results
    
    # Start monitoring in background
    monitor_services &
    
    # Keep container alive
    echo -e "${GREEN}[✓] Deployment complete. Container is running.${NC}"
    echo -e "${CYAN}[*] Press Ctrl+C to stop${NC}"
    
    # Wait forever
    tail -f /dev/null
}

# Run main function
main "$@"
