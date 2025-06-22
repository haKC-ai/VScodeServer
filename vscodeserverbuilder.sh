#!/usr/bin/env bash
INSTALL_LOG="/var/log/hakc_vsc_install.log"
touch "$INSTALL_LOG"

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "hakcer ALL=(ALL) NOPASSWD: /bin/systemctl enable *, /bin/systemctl start *, /bin/systemctl daemon-reexec, /bin/systemctl daemon-reload" | sudo tee /etc/sudoers.d/99-hakcer-systemd > /dev/null

# --- color setup
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# --- resume setup
if [[ -f "$INSTALL_LOG" ]]; then
  STEP=$(cat "$INSTALL_LOG")
else
  STEP=0
fi

TOTAL_STEPS=14

progress() {
  STEP=$((STEP+1))
  echo "${STEP}" > "$INSTALL_LOG"
  printf "\n${YELLOW}[${STEP}/${TOTAL_STEPS}] ${GREEN}%s${RESET}\n\n" "$1"
}

# --- toggle env lock

toggle_env_lock() {
  local env_file="/opt/code-stack/.env"

  if [[ ! -f "$env_file" ]]; then
    echo "Env file not found: $env_file"
    return 1
  fi

  if lsattr "$env_file" | grep -q 'i'; then
    echo "[*] Unlocking ${env_file} for editing..."
    chattr -i "$env_file"
  else
    echo "[*] Locking ${env_file} to prevent modification..."
    chattr +i "$env_file"
  fi
}


# --- banner
tput bold; tput setaf 4
cat <<'ASCII'
                                          
                 ██████████                                                              
                █▓       ░██                                                             
                █▒        ██                                                  
    █████████████░        █████████████████ ████████████ ████████████      ████████████  
   ██         ███░        ███▓▒▒▒▒▒▒▒▒▒▒▒██ █▒▒▒▒▒▒▒▒▓████        █████████▓          ▒█  
   ██         ███         ███▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████▓        ███▓▒      ▒▓░       ▒█  
   ██         ███        ░██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓██▓▒▒▒▒▒▒▒▒█▓        ███░       ░██░       ▒█  
   ██         ███        ▒██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▒▒▒▒▒▒▒▓▒        ██  ▓        ██░       ▓█  
   ██         ██▓        ███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▓▒▒▒▒▒▒▒▓▒       ██   █        ██░       ▓  
   ██         ██▒        ██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▓▒      ██    █        ▓█████████  
   ██                    ██▒▒▒▒▒▒▒▒█▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒   ▒███████ █░       ░▓        █  
   ██         ░░         ██▒▒▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ ▓        ░█ ▓       ░▒       ░█  
   ██         ██░       ░█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ █░        ▒ █                ░█ 
   ██         ██        ▓█▒▒▒▒▒▒▒▒▒██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█ █░        ▒ █░               ▒█  
    ██████████  ███████████▓██▓▓█▓█  █▓▒▒▒▒▒▒▒▒▒▓██▓██   █▓▓▓▓▓▓▓█    █▓▓▓▓▓▓▓▓▓▓▓▓▓▓██ 
  .:/====================█▓██▓██=========████▓█▓█ ███======> [ P R E S E N T S ] ====\:.
        /\                 ██▓██           █▓▓▓██ ██                                    
 _ __  /  \__________________█▓█_____________██▓██______________________________ _  _    _ 
_ __ \/ /\____________________██_____________ ███________ _________ __ _______ _  
    \  /         T H E   P I N A C L E    O F   H A K C I N G   Q U A L I T Y  
     \/             
            Name :                            haKC.ai VSCoderServer Build
            Collective:                       haKC.ai
            System:                           UNIX / Linux / MacOS / WinD0$3
            Size:                             1 Script + 1 Disk Worth of Cool
            Supplied by:                      corykennedy     
            Release date:                     Jun 2025 or 1994   
                                                                          /\        
       _ __ ___________________________________________________________  /  \__ _ _ 
       __ __ __ ______________________________________________________ \/ /\____ ___
                                                                      \  /         
                                                                       \/
                                                                                 
ASCII
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
dmesg | grep -i kill

STEP=0
TOTAL_STEPS=14

tput sgr0


progress "▒▒▒[01/14]▒▒▒ ⇨ Initializing Host Recon & Signal Bootstrapping"

# --- color prompts
printf "%s" "${BLUE}Domain (e.g. code.example.com): ${RESET}"
read DOMAIN

printf "%s" "${BLUE}GitHub Client ID: ${RESET}"
read GH_ID

printf "%s" "${BLUE}GitHub Client Secret: ${RESET}"
read GH_SECRET

printf "%s" "${BLUE}GitHub Org (optional): ${RESET}"
read GH_ORG

printf "%s\n" "${GREEN}Proxy choices: 1) Nginx  2) Traefik${RESET}"
printf "%s" "${YELLOW}Select proxy [1/2]: ${RESET}"
read PROXY_CHOICE

progress "▓▓▓[02/14]▓▓▓ ⇨ Creating Dedicated haKC User & Shell Hardening"

STACK_DIR="/opt/code-stack"
ENV_FILE="${STACK_DIR}/.env"
CODE_PORT="48722"
COOKIE_SECRET=$(openssl rand -base64 32 | tr '+/' '_-' | tr -d '\n')
CODE_PASS_HASH=$(openssl passwd -6 "$(openssl rand -base64 16)")
OS_USER="hakcer"

mkdir -p "${STACK_DIR}/banner" "${STACK_DIR}/logs"
chown "${OS_USER}:${OS_USER}" "${STACK_DIR}"

# --- prerequisites ----------------------------------------------------------
OS_USER="hakcer"
id -u "${OS_USER}" &>/dev/null || useradd -m -s /bin/bash "${OS_USER}"

# wait for locks
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
  echo "Waiting for unattended-upgrades…"
  sleep 3
done
progress "░░░[03/14]░░░ ⇨ Installing Trusted Supply Modules ░ apt-utils, zsh, git"


export DEBIAN_FRONTEND=noninteractive
progress "███[04/14]███ ⇨ Injecting CODE Server Binary into System Bus"

apt-get update -q
apt-get -qy \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  install curl ca-certificates gnupg2 lsb-release \
          logrotate fail2ban certbot python3-certbot-nginx \
          fonts-powerline figlet lolcat zsh git

progress "▒▒▒[05/14]▒▒▒ ⇨ Seeding Dynamic Auth Token & Hashed Access Vector"

# --- .env
toggle_env_lock
cat >"${ENV_FILE}" <<ENV
DOMAIN=${DOMAIN}
CODE_PORT=${CODE_PORT}
CODE_PASS_HASH=${CODE_PASS_HASH}
COOKIE_SECRET=${COOKIE_SECRET}
GH_CLIENT_ID=${GH_ID}
GH_CLIENT_SECRET=${GH_SECRET}
GH_ORG=${GH_ORG}
ENV
chmod 600 "${ENV_FILE}"
toggle_env_lock  

progress "▓▓▓[06/14]▓▓▓ ⇨ Generating Obfuscated GitHub OAuth Interface"
progress "░░░[07/14]░░░ ⇨ Encrypting Secrets and Baking Immutable .env"
progress "███[08/14]███ ⇨ Deploying OAuth2 Proxy Agent to Shadow Layer"

# --- code-server installation
curl -fsSL https://code-server.dev/install.sh | sh
sudo -u "${OS_USER}" mkdir -p /home/${OS_USER}/.config/code-server
sudo -u "${OS_USER}" tee /home/${OS_USER}/.config/code-server/config.yaml >/dev/null <<CFG
bind-addr: 127.0.0.1:${CODE_PORT}
auth: password
hashed-password: ${CODE_PASS_HASH}
cert: false
CFG
sudo -u "${OS_USER}" systemctl enable --now code-server@${OS_USER}
apt-get install -y jq

progress "▒▒▒[09/14]▒▒▒ ⇨ Activating Reverse Proxy via ⬠ NGINX ⬠ or ⟁ Traefik ⟁"

# --- Fetch latest tag and URL for linux-amd64
O2P_VERSION=$(curl -s https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest | jq -r '.tag_name')
O2P_FILE="oauth2-proxy-${O2P_VERSION}.linux-amd64.tar.gz"
O2P_URL="https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${O2P_VERSION}/${O2P_FILE}"

echo "[*] Latest oauth2-proxy version: ${O2P_VERSION}"
echo "[*] Downloading from: ${O2P_URL}"

curl -fsSL "$O2P_URL" -o /tmp/o2p.tgz

# validate gzip
if file /tmp/o2p.tgz | grep -q 'gzip compressed data'; then
  tar -xzf /tmp/o2p.tgz -C /tmp
  install /tmp/oauth2-proxy-*/oauth2-proxy /usr/local/bin/
  echo "[+] oauth2-proxy ${O2P_VERSION} installed successfully."
else
  echo "[!] Download failed or file is not a valid gzip archive. Aborting."
  exit 1
fi


cat >/etc/oauth2-proxy.cfg <<O2PCFG
provider = "github"
client_id = "${GH_ID}"
client_secret = "${GH_SECRET}"
redirect_url = "https://${DOMAIN}/oauth2/callback"
cookie_secret = "${COOKIE_SECRET}"
email_domains = ["*"]
upstreams = ["http://127.0.0.1:${CODE_PORT}/"]
${GH_ORG:+github_org = "${GH_ORG}"}
O2PCFG

cat >/etc/systemd/system/oauth2-proxy.service <<O2PSV
[Unit]
Description=OAuth2 Proxy
After=network.target
[Service]
EnvironmentFile=${ENV_FILE}
ExecStart=/usr/local/bin/oauth2-proxy --config /etc/oauth2-proxy.cfg
Restart=always
User=${OS_USER}
[Install]
WantedBy=multi-user.target
O2PSV
systemctl daemon-reload
systemctl enable --now oauth2-proxy

progress "▓▓▓[10/14]▓▓▓ ⇨ Forging TLS Armor with Let's Encrypt Spellcraft"

NGINX_CONF="/etc/nginx/sites-available/code-stack"
DUMMY_CERT_DIR="/etc/letsencrypt/live/${DOMAIN}-dummy"
REAL_CERT_DIR=$(find /etc/letsencrypt/live -maxdepth 1 -type d -name "${DOMAIN}-*" | grep -v dummy | sort | tail -n 1)
REAL_CERT_FILE="${REAL_CERT_DIR}/fullchain.pem"
REAL_KEY_FILE="${REAL_CERT_DIR}/privkey.pem"
DUMMY_CERT_LOG="/var/log/code-stack_tls.log"

{
  echo "[*] Checking currently served cert on ${DOMAIN}..."
  CURRENT_CERT_END=$(echo | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
  CURRENT_EPOCH=$(date -d "$CURRENT_CERT_END" +%s)
  NOW_EPOCH=$(date +%s)
  TIME_LEFT=$(( CURRENT_EPOCH - NOW_EPOCH ))

  if [[ $TIME_LEFT -lt 86400 ]]; then
    echo "[!] Currently served cert expires in less than a day — likely dummy"
    echo "[*] Switching NGINX to real cert at $REAL_CERT_DIR"

    sudo sed -i \
      -e "s|ssl_certificate .*|ssl_certificate ${REAL_CERT_FILE};|" \
      -e "s|ssl_certificate_key .*|ssl_certificate_key ${REAL_KEY_FILE};|" \
      "$NGINX_CONF"

    sudo chmod 600 "$REAL_KEY_FILE"
    sudo chmod 644 "$REAL_CERT_FILE"

    ARCHIVE_DIR="/etc/letsencrypt/archive/$(basename "$REAL_CERT_DIR")"
    if [[ -d "$ARCHIVE_DIR" ]]; then
      sudo chmod 600 "$ARCHIVE_DIR"/privkey*.pem
      sudo chmod 644 "$ARCHIVE_DIR"/fullchain*.pem
    fi

    echo "[*] Reloading NGINX..."
    sudo nginx -t && sudo systemctl reload nginx

    echo "[+] Real TLS cert activated from ${REAL_CERT_DIR}"

    if [[ -d "$DUMMY_CERT_DIR" ]]; then
      echo "[*] Removing dummy cert directory ${DUMMY_CERT_DIR}"
      sudo rm -rf "$DUMMY_CERT_DIR"
    fi
  else
    echo "[+] Active TLS cert is valid — no patching needed"
  fi
} | tee -a "$DUMMY_CERT_LOG"

# --- reverse proxy and TLS
if [[ "${PROXY_CHOICE}" == "2" ]]; then
  apt install -y traefik
  mkdir -p /etc/traefik
  cat >/etc/traefik/traefik.yml <<T1
entryPoints:
  web: {address=":80"}
  websecure: {address=":443"}
providers:
  file: {filename="/etc/traefik/dynamic.yml"}
certificatesResolvers:
  letsencrypt:
    acme:
      email: "admin@${DOMAIN}"
      storage: "/etc/traefik/acme.json"
      httpChallenge: {entryPoint: web}
T1
  touch /etc/traefik/acme.json; chmod 600 /etc/traefik/acme.json
  cat >/etc/traefik/dynamic.yml <<T2
http:
  routers:
    codesrv:
      rule: "Host(\`${DOMAIN}\`)"
      entryPoints: [websecure]
      service: codesvc
      tls: {certResolver: letsencrypt}
      middlewares: [auth]
  middlewares:
    auth:
      forwardAuth: {address: "http://127.0.0.1:4180/oauth2/auth", trustForwardHeader: true}
  services:
    codesvc:
      loadBalancer: {servers: [{url: "http://127.0.0.1:${CODE_PORT}"}]}
T2
  systemctl enable --now traefik
else
  apt install -y nginx
cat >/etc/nginx/sites-available/code-stack <<NGX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://${DOMAIN}\$request_uri;
}

server {
    listen 443 ssl;
    http2  on;
    server_name ${DOMAIN};

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    location /oauth2/ {
        proxy_pass http://127.0.0.1:4180/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Auth-Request-Redirect \$request_uri;
    }

    location = /oauth2/auth {
        internal;
        proxy_pass http://127.0.0.1:4180/oauth2/auth;
        proxy_set_header Host \$host;
        proxy_set_header X-Original-URI \$request_uri;
    }

    location / {
        auth_request /oauth2/auth;
        error_page   401 = @e;
        proxy_pass   http://127.0.0.1:${CODE_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location @e {
        return 302 /oauth2/start?rd=\$request_uri;
    }

    root  ${STACK_DIR}/banner;
    index index.html;

    access_log ${STACK_DIR}/logs/nginx.access.log;
    error_log  ${STACK_DIR}/logs/nginx.error.log;
}
NGX


  ln -sf /etc/nginx/sites-available/code-stack /etc/nginx/sites-enabled/
  nginx -t
  systemctl reload nginx
fi
progress "░░░[11/14]░░░ ⇨ Configuring Fail2Ban Intrusion Dampener"

# --- Fail2Ban & logrotate
cat >/etc/fail2ban/jail.d/code-stack.conf <<JF
[proxy-auth]
enabled=true; filter=nginx-http-auth
logpath=${STACK_DIR}/logs/*error.log
maxretry=3; findtime=10m; bantime=1h
JF
systemctl enable --now fail2ban

cat >/etc/logrotate.d/code-stack <<RL
${STACK_DIR}/logs/*.log {
  daily; rotate 7; compress; missingok; notifempty
  sharedscripts
  postrotate
    systemctl reload nginx 2>/dev/null || systemctl reload traefik || true
  endscript
}
RL
progress "███[12/14]███ ⇨ Engaging Logrotate Temporal Cleanup Daemon"

# --- certbot self-heal systemd unit
cat >/etc/systemd/system/certbot-renew.service <<EOF
[Unit]
Description=Renew Let's Encrypt certificates

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --post-hook "systemctl reload nginx || systemctl reload traefik"
EOF

cat >/etc/systemd/system/certbot-renew.timer <<EOF
[Unit]
Description=Daily Let's Encrypt renewal

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

progress "▒▒▒[13/14]▒▒▒ ⇨ Scheduling Certbot Self-Heal TimeLoop"

# Reload systemd daemon and enable the timer
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer || {
  echo "[!] Failed to enable certbot-renew.timer — check the unit files above." >&2
  exit 1
}


progress "▓▓▓[14/14]▓▓▓ ⇨ Installing ZSH HyperShell with Powerlevel10k Injection"
OS_USER="hakcer"


# --- set shell to zsh
usermod -s "$(command -v zsh)" "$OS_USER" || echo "[!] Could not change shell for $OS_USER"

# --- execute the ZSH config in user context
sudo -u "$OS_USER" --login bash <<'ZSHSET'
set +u  # Allow unset variables temporarily

HOME=$(getent passwd "$USER" | cut -d: -f6)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install Oh-My-Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Clone themes and plugins
git -C "$ZSH_CUSTOM" clone --depth=1 https://github.com/romkatv/powerlevel10k.git themes/powerlevel10k 2>/dev/null || true
git -C "$ZSH_CUSTOM" clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git plugins/zsh-syntax-highlighting 2>/dev/null || true
git -C "$ZSH_CUSTOM" clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git plugins/zsh-autosuggestions 2>/dev/null || true

# Patch zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
sed -i 's/^plugins=.*/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' "$HOME/.zshrc"

# Fun banner
if ! grep -q FIGLET_FONT "$HOME/.zshrc"; then
  echo 'FIGLET_FONT=3d' >>"$HOME/.zshrc"
  echo '[[ -x /usr/bin/figlet ]] && figlet "Welcome" | lolcat' >>"$HOME/.zshrc"
fi
ZSHSET






echo -e "${GREEN} ▒▒▒[HAKCing complete]▒▒▒ ⇨ visit https://${DOMAIN}${RESET}"

rm -f "$INSTALL_LOG"

echo -e "\n${GREEN}▒▒▒[Service Validation]▒▒▒ ⇨ Running final health checks...${RESET}"

# Define services to check
SERVICES=(
  "code-server@${OS_USER}"
  "nginx"
  "fail2ban"
  "certbot-renew.timer"
)

# Check services
for service in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service"; then
    echo -e "[ OK ] $service is active"
  else
    echo -e "[FAIL] $service is NOT running"
  fi
done

# Check cert
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
  echo "[ OK ] TLS certificate exists for $DOMAIN"
else
  echo "[FAIL] TLS certificate missing for $DOMAIN"
fi

# Check code-server port (default: 8080)
if ss -tulwn | grep ':48722' >/dev/null; then
  echo "[ OK ] code-server is listening on port 8080"
else
  echo "[FAIL] code-server is NOT listening on port 8080"
fi

# ZSH Check
if grep -q 'powerlevel10k' "/home/${OS_USER}/.zshrc"; then
  echo "[ OK ] ZSH configured with powerlevel10k for ${OS_USER}"
else
  echo "[WARN] ZSH not fully configured for ${OS_USER}"
fi
