#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- banner
echo -e "\e[1;34m"
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

ASCII
echo -e "\e[0m"

# --- color prompts
GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"
read -rp "${BLUE}Domain (e.g. code.example.com): ${RESET}" DOMAIN
read -rp "${BLUE}GitHub Client ID: ${RESET}" GH_ID
read -rp "${BLUE}GitHub Client Secret: ${RESET}" GH_SECRET
read -rp "${BLUE}GitHub Org (optional): ${RESET}" GH_ORG
echo -e "${GREEN}Proxy choices: 1) Nginx  2) Traefik${RESET}"
read -rp "${YELLOW}Select proxy [1/2]: ${RESET}" PROXY_CHOICE

STACK_DIR="/opt/code-stack"
ENV_FILE="${STACK_DIR}/.env"
CODE_PORT="48722"
COOKIE_SECRET=$(openssl rand -base64 32 | tr '+/' '_-' | tr -d '\n')
CODE_PASS_HASH=$(openssl passwd -6 "$(openssl rand -base64 16)")
OS_USER="ubuntu"

mkdir -p "${STACK_DIR}/banner" "${STACK_DIR}/logs"
chown "${OS_USER}:${OS_USER}" "${STACK_DIR}"

apt update
apt install -y \
  curl ca-certificates gnupg2 lsb-release \
  logrotate fail2ban certbot python3-certbot-nginx \
  fonts-powerline figlet lolcat zsh git

# --- .env
cat >"${ENV_FILE}" <<ENV
DOMAIN=${DOMAIN}
CODE_PORT=${CODE_PORT}
CODE_PASS_HASH=${CODE_PASS_HASH}
COOKIE_SECRET=${COOKIE_SECRET}
GH_CLIENT_ID=${GH_ID}
GH_CLIENT_SECRET=${GH_SECRET}
GH_ORG=${GH_ORG}
ENV
chmod 600 "${ENV_FILE}" && chattr +i "${ENV_FILE}"

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

# --- oauth2-proxy
LATEST=$(curl -s https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)
curl -Lo /tmp/o2p.tgz "https://github.com/oauth2-proxy/oauth2-proxy/releases/download/${LATEST}/oauth2-proxy-${LATEST#v}.linux-amd64.tar.gz"
tar -xzf /tmp/o2p.tgz -C /tmp
install /tmp/oauth2-proxy-${LATEST#v}.linux-amd64/oauth2-proxy /usr/local/bin/

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
  listen 80; server_name ${DOMAIN};
  return 301 https://${DOMAIN}\$request_uri;
}
server {
  listen 443 ssl http2; server_name ${DOMAIN};
  ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  location /oauth2/ {
    proxy_pass http://127.0.0.1:4180/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Scheme \$scheme;
    proxy_set_header X-Auth-Request-Redirect \$request_uri;
  }
  location / {
    auth_request /oauth2/auth;
    error_page 401 = @e;
    proxy_pass http://127.0.0.1:${CODE_PORT};
    proxy_set_header Host \$host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_http_version 1.1;
  }
  location = /oauth2/auth {
    internal;
    proxy_pass http://127.0.0.1:4180/oauth2/auth;
    proxy_set_header Host \$host;
    proxy_set_header X-Original-URI \$request_uri;
  }
  location @e { return 302 /oauth2/start?rd=\$request_uri; }
  root ${STACK_DIR}/banner;
  index index.html;
  access_log ${STACK_DIR}/logs/nginx.access.log;
  error_log  ${STACK_DIR}/logs/nginx.error.log;
}
NGX
  ln -sf /etc/nginx/sites-available/code-stack /etc/nginx/sites-enabled/
  nginx -t
  certbot --nginx --non-interactive --agree-tos -m "admin@${DOMAIN}" -d "${DOMAIN}"
  systemctl reload nginx
fi

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

# --- certbot timer
cat >/etc/systemd/system/certbot-renew.service <<CRS
[Unit]Description=renew certs
[Service]Type=oneshot
ExecStart=/usr/bin/certbot renew --post-hook "systemctl reload nginx || systemctl reload traefik"
CRS
cat >/etc/systemd/system/certbot-renew.timer <<CRT
[Unit]Description=Daily cert renewal
[Timer]OnCalendar=daily; Persistent=true
[Install]WantedBy=timers.target
CRT
systemctl daemon-reload
systemctl enable --now certbot-renew.timer

# --- Zsh + Oh My Zsh + Powerlevel10k + splash
sudo -u "${OS_USER}" bash <<ZSHSET
chsh -s \$(which zsh) ${OS_USER}
if [ ! -d "\$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "\$ZSH_CUSTOM/themes/powerlevel10k"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "\$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-autosuggestions "\$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
  sed -i 's/^plugins=.*/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
  echo 'FIGLET_FONT=3d' >>~/.zshrc
  echo '[[ -x /usr/bin/figlet ]] && figlet \"Welcome\" | lolcat' >>~/.zshrc
fi
ZSHSET

echo -e "${GREEN} HAKCing complete - visit https://${DOMAIN}${RESET}"
