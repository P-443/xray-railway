#!/bin/bash

clear

echo -e "\033[1;32m##########################################################################\033[0m"
echo -e "\033[1;31m#         Railway Deployment Script with SSH over Ngrok                  #\033[0m"
echo -e "\033[1;32m##########################################################################\033[0m"
echo ""

#--------- info Variables ---------#
read -r -p $'\033[1;33mEnter User (default: telegram): \033[0m' input_user
User=${input_user:-telegram}

read -r -p $'\033[1;33mEnter Pass (default: @d_s_d_c1): \033[0m' input_pass
Pass=${input_pass:-@d_s_d_c1}

read -r -p $'\033[1;33mEnter Ngrok Token: \033[0m' ngrok_token
if [ -z "$ngrok_token" ]; then
    echo -e "\033[1;31mError: Ngrok Token is required!\033[0m"
    exit 1
fi

read -r -p $'\033[1;33mTCP Port (default: 22): \033[0m' tcp_port
tcp_port=${tcp_port:-22}

read -r -p $'\033[1;33mUDP Port (default: 7300): \033[0m' udp_port
udp_port=${udp_port:-7300}

echo ""
echo "--------------------------------------------------------------------------"
echo -e "\033[1;32m                      Input Complete ✓                     \033[0m"
echo "--------------------------------------------------------------------------"
sleep 2
clear

#-------- Get IP and Country Info -----------#
echo -e "\033[1;33m# Getting IP and Country Information... \033[0m"

# Try multiple IP services
IP_SERVICES=(
    "https://api.ipify.org"
    "https://ifconfig.me/ip"
    "https://icanhazip.com"
    "https://ident.me"
)

for service in "${IP_SERVICES[@]}"; do
    IP_ADDRESS=$(curl -s --connect-timeout 5 "$service")
    if [ -n "$IP_ADDRESS" ] && [[ "$IP_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "\033[1;32m✓ Got IP from $service\033[0m"
        break
    fi
done

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS="Unable to fetch"
fi

# Get country
COUNTRY_SERVICES=(
    "https://ipapi.co/country"
    "https://ipinfo.io/country"
    "https://api.ip.sb/geoip"
)

for service in "${COUNTRY_SERVICES[@]}"; do
    COUNTRY_INFO=$(curl -s --connect-timeout 5 "$service")
    if [ -n "$COUNTRY_INFO" ]; then
        # Extract country code if it's JSON
        if [[ "$COUNTRY_INFO" == *"country"* ]]; then
            COUNTRY_CODE=$(echo "$COUNTRY_INFO" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
            COUNTRY_NAME=$(echo "$COUNTRY_INFO" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
        else
            COUNTRY_CODE="$COUNTRY_INFO"
            # Get country name from code
            COUNTRY_NAME=$(curl -s "https://restcountries.com/v3.1/alpha/$COUNTRY_CODE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        
        if [ -n "$COUNTRY_CODE" ]; then
            echo -e "\033[1;32m✓ Got country info from $service\033[0m"
            break
        fi
    fi
done

if [ -z "$COUNTRY_CODE" ]; then
    COUNTRY_CODE="Unknown"
    COUNTRY_NAME="Unknown"
fi

# Get flag emoji based on country code
get_flag_emoji() {
    local country_code=$1
    # Convert to uppercase
    country_code=$(echo "$country_code" | tr '[:lower:]' '[:upper:]')
    
    # List of common country flag emojis
    declare -A flags=(
        ["US"]="🇺🇸" ["GB"]="🇬🇧" ["DE"]="🇩🇪" ["FR"]="🇫🇷" ["JP"]="🇯🇵"
        ["KR"]="🇰🇷" ["CN"]="🇨🇳" ["RU"]="🇷🇺" ["BR"]="🇧🇷" ["IN"]="🇮🇳"
        ["CA"]="🇨🇦" ["AU"]="🇦🇺" ["SG"]="🇸🇬" ["NL"]="🇳🇱" ["SE"]="🇸🇪"
        ["NO"]="🇳🇴" ["FI"]="🇫🇮" ["DK"]="🇩🇰" ["ES"]="🇪🇸" ["IT"]="🇮🇹"
        ["TR"]="🇹🇷" ["SA"]="🇸🇦" ["AE"]="🇦🇪" ["EG"]="🇪🇬" ["ZA"]="🇿🇦"
        ["MX"]="🇲🇽" ["AR"]="🇦🇷" ["ID"]="🇮🇩" ["MY"]="🇲🇾" ["TH"]="🇹🇭"
        ["VN"]="🇻🇳" ["PH"]="🇵🇭" ["PK"]="🇵🇰" ["BD"]="🇧🇩" ["IR"]="🇮🇷"
        ["IQ"]="🇮🇶" ["SY"]="🇸🇾" ["YE"]="🇾🇪" ["IL"]="🇮🇱" ["JO"]="🇯🇴"
        ["KW"]="🇰🇼" ["QA"]="🇶🇦" ["OM"]="🇴🇲" ["BH"]="🇧🇭" ["LB"]="🇱🇧"
    )
    
    if [ -n "${flags[$country_code]}" ]; then
        echo "${flags[$country_code]}"
    else
        # Generate flag from country code (regional indicator symbols)
        if [[ ${#country_code} -eq 2 ]]; then
            local first=$(echo "${country_code:0:1}" | tr '[:upper:]' '[:lower:]')
            local second=$(echo "${country_code:1:1}" | tr '[:upper:]' '[:lower:]')
            echo "$(printf "\\U$(printf '%08x' $((0x1F1E6 + $(printf '%d' "'$first") - 97)) )")$(printf "\\U$(printf '%08x' $((0x1F1E6 + $(printf '%d' "'$second") - 97)) )")"
        else
            echo "🏳️"
        fi
    fi
}

FLAG_EMOJI=$(get_flag_emoji "$COUNTRY_CODE")
COUNTRY_VPS_AND_FLAG="$FLAG_EMOJI $COUNTRY_NAME ($COUNTRY_CODE)"

# Display information
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;33m                  VPS Information                            \033[0m"
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m• IP Address: \033[1;33m$IP_ADDRESS\033[0m"
echo -e "\033[1;36m• Country: \033[1;33m$COUNTRY_VPS_AND_FLAG\033[0m"
echo -e "\033[1;36m• User: \033[1;33m$User\033[0m"
echo -e "\033[1;36m• Password: \033[1;33m$Pass\033[0m"
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo ""

LOG_FILE="/tmp/railway_deploy.log"

# Check if we're on Railway
echo -e "\033[1;33m# Checking Railway environment... \033[0m"
if [ -n "$RAILWAY_ENVIRONMENT" ] || [ -n "$RAILWAY_PROJECT_ID" ] || [ -n "$RAILWAY_SERVICE_ID" ]; then
    echo -e "\033[1;32m✓ Running on Railway Platform\033[0m"
    IS_RAILWAY=true
else
    echo -e "\033[1;33m⚠ Not running on Railway (local deployment)\033[0m"
    IS_RAILWAY=false
fi

# Install required packages
echo -e "\033[1;33m# Installing required packages... \033[0m"
apt-get update >> $LOG_FILE 2>&1
apt-get install -y curl wget git openssh-server python3 python3-pip socat net-tools >> $LOG_FILE 2>&1

# Install Ngrok
echo -e "\033[1;33m# Installing Ngrok... \033[0m"
if [ ! -f /usr/local/bin/ngrok ]; then
    curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar xz -C /usr/local/bin/
    chmod +x /usr/local/bin/ngrok
fi

# Configure Ngrok
echo -e "\033[1;33m# Configuring Ngrok... \033[0m"
ngrok config add-authtoken "$ngrok_token" >> $LOG_FILE 2>&1

# Setup SSH
echo -e "\033[1;33m# Setting up SSH server... \033[0m"

# Create user if not exists
if ! id "$User" &>/dev/null; then
    useradd -m -s /bin/bash "$User"
    echo "$User:$Pass" | chpasswd
fi

# Configure SSH
mkdir -p /var/run/sshd
echo "Port $tcp_port" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "AllowUsers $User" >> /etc/ssh/sshd_config
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

# Start SSH
/usr/sbin/sshd -D >> $LOG_FILE 2>&1 &

# Install and setup UDP relay
echo -e "\033[1;33m# Setting up UDP relay... \033[0m"
if [ ! -d "/tmp/udpgw" ]; then
    git clone https://github.com/mukswilly/udpgw.git /tmp/udpgw >> $LOG_FILE 2>&1
    cd /tmp/udpgw || exit 1
    
    # Install Go if not present
    if ! command -v go &> /dev/null; then
        wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz >> $LOG_FILE 2>&1
        tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    cd cmd && go build -o server >> $LOG_FILE 2>&1
    ./server -port "$udp_port" generate >> $LOG_FILE 2>&1
    ./server run >> $LOG_FILE 2>&1 &
fi

# Function to get Ngrok tunnel URL
get_ngrok_url() {
    sleep 3
    NGROK_API="http://127.0.0.1:4040/api/tunnels"
    for i in {1..10}; do
        URL=$(curl -s "$NGROK_API" | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$URL" ]; then
            echo "$URL"
            return 0
        fi
        sleep 1
    done
    echo "Unable to get Ngrok URL"
}

# Start Ngrok tunnels
echo -e "\033[1;33m# Starting Ngrok tunnels... \033[0m"

# Start TCP tunnel
echo -e "\033[1;36m• Starting TCP tunnel on port $tcp_port...\033[0m"
ngrok tcp "$tcp_port" --log stdout >> $LOG_FILE 2>&1 &
TCP_PID=$!

# Start UDP tunnel
echo -e "\033[1;36m• Starting UDP tunnel on port $udp_port...\033[0m"
ngrok udp "$udp_port" --log stdout >> $LOG_FILE 2>&1 &
UDP_PID=$!

sleep 5

# Get tunnel URLs
TCP_URL=$(get_ngrok_url | grep "tcp://")
UDP_URL=$(ngrok tunnels list 2>/dev/null | grep "udp" | awk '{print $3}')

# Clear and show results
clear
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;31m                DEPLOYMENT SUCCESSFUL ✓                     \033[0m"
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo ""
echo -e "\033[1;33m                  VPS INFORMATION                          \033[0m"
echo -e "\033[1;36m• IP Address: \033[1;33m$IP_ADDRESS\033[0m"
echo -e "\033[1;36m• Country: \033[1;33m$COUNTRY_VPS_AND_FLAG\033[0m"
echo -e "\033[1;36m• Platform: \033[1;33mRailway\033[0m"
echo ""
echo -e "\033[1;33m                  ACCOUNT DETAILS                          \033[0m"
echo -e "\033[1;36m• Username: \033[1;33m$User\033[0m"
echo -e "\033[1;36m• Password: \033[1;33m$Pass\033[0m"
echo ""
echo -e "\033[1;33m                  TUNNEL URLs                             \033[0m"
if [ -n "$TCP_URL" ]; then
    echo -e "\033[1;36m• TCP Tunnel: \033[1;33m$TCP_URL\033[0m"
    HOST_PORT=$(echo "$TCP_URL" | sed 's/tcp:\/\///')
    HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
    PORT=$(echo "$HOST_PORT" | cut -d':' -f2)
    echo -e "\033[1;36m• SSH Connection: \033[1;33mssh $User@$HOST -p $PORT\033[0m"
else
    echo -e "\033[1;31m• TCP Tunnel: Not available\033[0m"
fi

if [ -n "$UDP_URL" ]; then
    echo -e "\033[1;36m• UDP Tunnel: \033[1;33m$UDP_URL\033[0m"
else
    echo -e "\033[1;31m• UDP Tunnel: Not available\033[0m"
fi
echo ""
echo -e "\033[1;33m                  CONNECTION STRINGS                      \033[0m"
if [ -n "$HOST" ] && [ -n "$PORT" ]; then
    echo -e "\033[1;36m• HTTP Custom Format:\033[0m"
    echo -e "\033[1;33m  $HOST:$PORT@$User:$Pass\033[0m"
    echo ""
    echo -e "\033[1;36m• For SSH Clients:\033[0m"
    echo -e "\033[1;33m  Host: $HOST\033[0m"
    echo -e "\033[1;33m  Port: $PORT\033[0m"
    echo -e "\033[1;33m  User: $User\033[0m"
    echo -e "\033[1;33m  Pass: $Pass\033[0m"
fi
echo ""
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;35m• Channel: \033[1;34mD_S_D_C1.T.ME\033[0m"
echo -e "\033[1;35m• Developer: \033[1;34ml_s_I_I.T.ME\033[0m"
echo -e "\033[1;32m══════════════════════════════════════════════════════════════\033[0m"

# Keep the script running
echo -e "\033[1;33m\n# Press Ctrl+C to stop the tunnels\n\033[0m"
echo -e "\033[1;33m# Tunnels are running in the background...\033[0m"

# Create railway.json for Railway deployment
cat > railway.json << EOF
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "chmod +x deploy.sh && ./deploy.sh",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
EOF

# Create a simpler deployment script for Railway
cat > deploy.sh << 'EOF'
#!/bin/bash

# Get Ngrok token from Railway variables
NGROK_TOKEN=${NGROK_TOKEN}
USER=${SSH_USER:-telegram}
PASS=${SSH_PASS:-@d_s_d_c1}
TCP_PORT=${TCP_PORT:-22}
UDP_PORT=${UDP_PORT:-7300}

if [ -z "$NGROK_TOKEN" ]; then
    echo "Error: NGROK_TOKEN environment variable is required!"
    exit 1
fi

# Install packages
apt-get update
apt-get install -y curl openssh-server

# Install Ngrok
curl -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar xz -C /usr/local/bin/
chmod +x /usr/local/bin/ngrok

# Configure Ngrok
ngrok config add-authtoken "$NGROK_TOKEN"

# Setup SSH
useradd -m -s /bin/bash "$USER"
echo "$USER:$PASS" | chpasswd

mkdir -p /var/run/sshd
echo "Port $TCP_PORT" > /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "AllowUsers $USER" >> /etc/ssh/sshd_config

# Start SSH
/usr/sbin/sshd -D &

# Start Ngrok tunnels
echo "Starting Ngrok TCP tunnel..."
ngrok tcp $TCP_PORT --log stdout &

echo "Starting Ngrok UDP tunnel..."
ngrok udp $UDP_PORT --log stdout &

# Keep container running
echo "Deployment complete. Tunnels are running."
echo "Check Railway logs for Ngrok URLs."
sleep infinity
EOF

chmod +x deploy.sh

echo -e "\033[1;32m✓ Created Railway configuration files\033[0m"
echo -e "\033[1;33m\nTo deploy on Railway:\n"
echo -e "1. Push this script to GitHub"
echo -e "2. Connect your repo to Railway"
echo -e "3. Set environment variables in Railway:"
echo -e "   - NGROK_TOKEN: Your Ngrok token"
echo -e "   - SSH_USER: (optional) SSH username"
echo -e "   - SSH_PASS: (optional) SSH password"
echo -e "4. Deploy!\033[0m"

# Wait for user interrupt
trap 'echo -e "\n\033[1;31mStopping tunnels...\033[0m"; kill $TCP_PID $UDP_PID 2>/dev/null; exit 0' INT TERM

# Keep script running
while true; do
    sleep 3600
done
