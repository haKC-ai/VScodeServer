#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# haKC.ai – Post-Install Hardening & Fix-Up Script
# ---------------------------------------------------------------------------
#   • Disables public code-server password screen (auth handled by OAuth2-Proxy)
#   • Configures OAuth2-Proxy to forward user headers with correct env vars
#   • Patches NGINX vhost with Let’s Encrypt certs, Remote-User header, and
#     correct code-server upstream port
#   • Idempotent: Safe to re-run anytime
#   • Automatically quotes .env values containing $ to prevent parsing errors
#   • Handles immutable .env file with chattr
#   • Diagnoses NGINX config errors and 500 errors with detailed logging
#   • Adds WebSocket headers for code-server
#   • Uses ss instead of netstat for port checks
# ---------------------------------------------------------------------------

# Ensure script runs in Bash
if [ -z "$BASH_VERSION" ]; then
  echo "[!] Error: This script must be run with Bash (bash patch.sh), not sh" >&2
  exit 1
fi

set -euo pipefail

# Configuration variables
STACK_DIR="/opt/code-stack"
ENV_FILE="$STACK_DIR/.env"
OS_USER="hakcer"
CODE_CFG="/home/${OS_USER}/.config/code-server/config.yaml"
NGINX_VHOST="/etc/nginx/sites-available/code-stack"
SYSTEMD_DROPIN="/etc/systemd/system/oauth2-proxy.service.d/env.conf"
DEFAULT_CODE_PORT=3000
OAUTH2_PORT=4180

# Log function for consistent output
log() {
  echo "[+] $1"
}

# Error function to log and exit with formatted output
error() {
  printf "[!] %b\n" "$1" >&2
  exit 1
}

# Toggle immutable attribute on .env file
toggle_env_lock() {
  env_file="$1"
  action="$2" # "unlock" or "lock"

  if [ ! -f "$env_file" ]; then
    error "Env file not found: $env_file"
  fi

  if [ "$action" = "unlock" ]; then
    if lsattr "$env_file" 2>/dev/null | grep -q 'i'; then
      log "    → Unlocking ${env_file} for editing..."
      chattr -i "$env_file" || error "Failed to unlock $env_file with chattr -i"
    else
      log "    → $env_file is already unlocked"
    fi
  elif [ "$action" = "lock" ]; then
    log "    → Locking ${env_file} to prevent modification..."
    chattr +i "$env_file" || error "Failed to lock $env_file with chattr +i"
  fi
}
# --- color setup
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

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
            Name :                            haKC.ai VSCoderServer Post-Install Hardening
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

     • Disables public code-server password screen (auth handled by OAuth2-Proxy)
     • Configures OAuth2-Proxy to forward user headers with correct env vars
     • Patches NGINX vhost with Let’s Encrypt certs, Remote-User header, and
       correct code-server upstream port
     • Idempotent: Safe to re-run anytime
     • Automatically quotes .env values containing $ to prevent parsing errors
     • Handles immutable .env file with chattr
     • Diagnoses 500 errors with detailed logging

ASCII
# Stop services safely
log "Stopping services for clean setup..."
for svc in nginx oauth2-proxy "code-server@${OS_USER}"; do
  systemctl stop "$svc" 2>/dev/null || log "    → $svc already stopped or not running"
done

# Validate required files
log "Checking required files..."
if [ ! -e "$ENV_FILE" ]; then
  error "Missing .env file at $ENV_FILE"
elif [ ! -f "$ENV_FILE" ]; then
  error ".env at $ENV_FILE is not a regular file (e.g., symlink or directory)"
elif [ ! -r "$ENV_FILE" ]; then
  error ".env file at $ENV_FILE is not readable"
fi
if [ ! -f "$NGINX_VHOST" ]; then
  error "Missing NGINX vhost at $NGINX_VHOST"
elif [ ! -r "$NGINX_VHOST" ]; then
  error "NGINX vhost at $NGINX_VHOST is not readable"
fi
log "    → Required files validated"

# Pre-process .env file to quote values containing $
log "Pre-processing .env file to quote values with \$..."
toggle_env_lock "$ENV_FILE" "unlock"
if grep -q '=\$[0-9a-zA-Z]' "$ENV_FILE"; then
  log "    → Found unquoted \$ in .env values. Adding single quotes..."
  sed -i.bak '/^[^#]/ s/^\([^=]*\)=\(.*\$\S*\)$/\1='\''\2'\''/' "$ENV_FILE" || error "Failed to update .env file"
  log "    → .env file updated successfully"
else
  log "    → No unquoted \$ found in .env values"
fi
# Optionally re-lock .env file (uncomment if desired)
# toggle_env_lock "$ENV_FILE" "lock"

# Parse .env file
log "Parsing .env file..."
if ! source "$ENV_FILE" 2>/dev/null; then
  log "    → Warning: Sourcing .env failed. Falling back to grep parsing."
  DOMAIN=$(grep -E '^DOMAIN=' "$ENV_FILE" | cut -d= -f2- | sed "s/^'\(.*\)'$/\1/")
  GH_CLIENT_ID=$(grep -E '^GH_CLIENT_ID=' "$ENV_FILE" | cut -d= -f2- | sed "s/^'\(.*\)'$/\1/")
  GH_CLIENT_SECRET=$(grep -E '^GH_CLIENT_SECRET=' "$ENV_FILE" | cut -d= -f2- | sed "s/^'\(.*\)'$/\1/")
  CODE_PORT=$(grep -E '^CODE_PORT=' "$ENV_FILE" | cut -d= -f2- | sed "s/^'\(.*\)'$/\1/" || echo "$DEFAULT_CODE_PORT")
else
  log "    → Sourced .env successfully"
fi
for var in DOMAIN GH_CLIENT_ID GH_CLIENT_SECRET; do
  if [ -z "$(eval echo \$"$var")" ]; then
    error "Variable $var missing or empty in $ENV_FILE"
  fi
  log "    → $var is set"
done
# Use default CODE_PORT if not set
if [ -z "$CODE_PORT" ]; then
  CODE_PORT=$DEFAULT_CODE_PORT
fi
log "    → CODE_PORT set to $CODE_PORT"

# Clean user session artifacts
log "Cleaning user session artifacts..."
if rm -rf "/home/${OS_USER}/.local/share/code-server/"* 2>/dev/null; then
  log "    → Session artifacts removed"
else
  log "    → No session artifacts found or unable to remove (continuing)"
fi

# Validate code-server port
log "Validating code-server port..."
if ! echo "$CODE_PORT" | grep -q '^[0-9]\+$' || [ "$CODE_PORT" -lt 1024 ] || [ "$CODE_PORT" -gt 65535 ]; then
  log "    → Warning: Invalid CODE_PORT ($CODE_PORT). Defaulting to $DEFAULT_CODE_PORT"
  CODE_PORT=$DEFAULT_CODE_PORT
fi
log "    → Using code-server port: $CODE_PORT"

# Update code-server config
log "Updating code-server config at $CODE_CFG"
mkdir -p "$(dirname "$CODE_CFG")" || error "Failed to create directory for $CODE_CFG"
cat > "$CODE_CFG" <<EOF
auth: none
bind-addr: 127.0.0.1:${CODE_PORT}
EOF
log "    → Code-server config updated"

# Validate SSL certificates
log "Locating SSL certificates..."
REAL_CERT_DIR=$(readlink -f "/etc/letsencrypt/live/${DOMAIN}" 2>/dev/null || true)
if [ -z "$REAL_CERT_DIR" ]; then
  error "No certificate directory found for ${DOMAIN}"
fi
LE_CERT="$REAL_CERT_DIR/fullchain.pem"
LE_KEY="$REAL_CERT_DIR/privkey.pem"
if [ ! -f "$LE_CERT" ] || [ ! -f "$LE_KEY" ]; then
  error "Certificate files missing at $REAL_CERT_DIR"
fi
log "    → SSL certs located at $REAL_CERT_DIR"

# Log variable values for debugging
log "NGINX configuration variables..."
log "    → DOMAIN: $DOMAIN"
log "    → CODE_PORT: $CODE_PORT"
log "    → OAUTH2_PORT: $OAUTH2_PORT"

# Validate initial NGINX config
log "Validating initial NGINX configuration..."
if ! nginx -t 2>/dev/null; then
  log "    → Warning: Initial NGINX config is invalid. Attempting to clean up..."
  # Clean up duplicate server blocks
  awk '
    BEGIN { in_server=0; server_count=0; keep=1 }
    /^server[[:space:]]*{/ {
      server_count++;
      if (server_count > 2) { keep=0; next }
      in_server=1
    }
    in_server && /}/ { in_server=0 }
    keep { print }
  ' "$NGINX_VHOST" > "${NGINX_VHOST}.tmp"
  if [ -s "${NGINX_VHOST}.tmp" ] && nginx -t 2>/dev/null; then
    mv "${NGINX_VHOST}.tmp" "$NGINX_VHOST"
    log "    → NGINX config cleaned up successfully"
  else
    log "    → Cleanup failed or produced empty config. Replacing with valid template..."
    cat > "$NGINX_VHOST" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;

    ssl_certificate $LE_CERT;
    ssl_certificate_key $LE_KEY;

    location = /oauth2/auth {
        internal;
        proxy_pass http://127.0.0.1:$OAUTH2_PORT/oauth2/auth;
        proxy_set_header Host \$host;
        proxy_set_header Remote-User \$remote_user;
        proxy_set_header X-Original-URI \$request_uri;
    }

    access_log /opt/code-stack/logs/nginx.access.log;
    error_log /opt/code-stack/logs/nginx.error.log;
}
EOF
    if ! nginx -t 2>/dev/null; then
      error "Failed to create valid NGINX config.\nConfig:\n$(cat "$NGINX_VHOST")"
    fi
    log "    → Valid template config applied"
  fi
else
  log "    → Initial NGINX config is valid"
fi

# Validate and clean NGINX vhost location blocks
log "Validating NGINX vhost block..."
set -x
if ! ls -l "$NGINX_VHOST"; then
  error "Cannot access $NGINX_VHOST"
fi
LOC_LINE_COUNT=$(grep -c 'location[[:space:]]*/[[:space:]]*\({' "$NGINX_VHOST" 2>/dev/null || echo 0)
log "    → Found $LOC_LINE_COUNT 'location /' blocks"

if [ "$LOC_LINE_COUNT" -gt 1 ]; then
  log "    → Multiple 'location /' blocks detected. Cleaning..."
  awk '
    BEGIN { d=0 }
    /^\s*location[[:space:]]+\/[[:space:]]*{/ { d=1; next }
    d && /\{/ { d++ }
    d && /\}/ { d--; next }
    d { next }
    { print }
  ' "$NGINX_VHOST" > "${NGINX_VHOST}.tmp" && mv "${NGINX_VHOST}.tmp" "$NGINX_VHOST"
elif [ "$LOC_LINE_COUNT" -eq 0 ]; then
  log "    → No 'location /' block found. Will add one later."
else
  log "    → Single 'location /' block found. Will replace later."
fi

log "    → Validating NGINX config after cleanup..."
if ! nginx -t 2>/dev/null; then
  error "NGINX config test failed after cleanup.\nConfig:\n$(cat "$NGINX_VHOST")"
fi
set +x

# Prepare NGINX vhost for proxy setup
log "Preparing NGINX vhost for proxy setup..."
log "    → Commenting out server-level root and index directives"
sed -i 's/^[[:space:]]*root[[:space:]]\+.*$/    # &/' "$NGINX_VHOST"
sed -i 's/^[[:space:]]*index[[:space:]]\+.*$/    # &/' "$NGINX_VHOST"

# Update SSL certificates and proxy pass
log "Updating NGINX vhost with SSL and proxy settings..."
sed -i \
  -e "s|ssl_certificate[[:space:]]\+[^;]*|ssl_certificate ${LE_CERT}|" \
  -e "s|ssl_certificate_key[[:space:]]\+[^;]*|ssl_certificate_key ${LE_KEY}|" \
  -e "s|proxy_pass[[:space:]]\+http://127\.0\.0\.1:[0-9]\+;|proxy_pass http://127.0.0.1:${CODE_PORT};|" \
  "$NGINX_VHOST"

# Patch NGINX vhost
log "Patching NGINX vhost..."
set -x

# Ensure @e redirect handler
if ! grep -q 'location @e' "$NGINX_VHOST"; then
  log "    → Adding @e handler"
  sed -i "/listen[[:space:]]\+443[[:space:]]\+ssl;/a \
    location @e {\
        return 302 /oauth2/start?rd=\$request_uri;\
    }\
" "$NGINX_VHOST"
fi

# Ensure Remote-User header
if ! grep -q 'proxy_set_header[[:space:]]\+Remote-User' "$NGINX_VHOST"; then
  log "    → Inserting Remote-User header"
  sed -i "/proxy_set_header[[:space:]]\+Host/a \
    proxy_set_header Remote-User \$remote_user;\
" "$NGINX_VHOST"
fi

# Strip existing location / blocks
log "    → Stripping old location / blocks"
awk '
  BEGIN { d=0 }
  /^\s*location[[:space:]]+\/[[:space:]]*{/ { d=1; next }
  d && /\{/ { d++ }
  d && /\}/ { d--; next }
  d { next }
  { print }
' "$NGINX_VHOST" > "${NGINX_VHOST}.tmp" && mv "${NGINX_VHOST}.tmp" "$NGINX_VHOST"

# Inject new location / block with WebSocket headers
log "    → Injecting new location / block"
sed -i "/listen[[:space:]]\+443[[:space:]]\+ssl;/a \
    location / {\
        auth_request /oauth2/auth;\
        error_page 401 = @e;\
        proxy_pass http://127.0.0.1:$CODE_PORT;\
        proxy_set_header Host \$host;\
        proxy_set_header X-Real-IP \$remote_addr;\
        proxy_set_header X-Scheme \$scheme;\
        proxy_set_header X-Auth-Request-User \$remote_user;\
        proxy_set_header Remote-User \$remote_user;\
        proxy_set_header Cookie \$http_cookie;\
        proxy_set_header Upgrade \$http_upgrade;\
        proxy_set_header Connection \"upgrade\";\
        proxy_http_version 1.1;\
    }\
" "$NGINX_VHOST"

# Update or add location /oauth2/ block
if ! grep -q 'location /oauth2/' "$NGINX_VHOST"; then
  log "    → Injecting location /oauth2/ block"
  sed -i "/listen[[:space:]]\+443[[:space:]]\+ssl;/a \
    location /oauth2/ {\
        proxy_pass http://127.0.0.1:$OAUTH2_PORT;\
        proxy_set_header Host \$host;\
        proxy_set_header X-Real-IP \$remote_addr;\
        proxy_set_header X-Scheme \$scheme;\
        proxy_http_version 1.1;\
    }\
" "$NGINX_VHOST"
else
  log "    → Updating existing location /oauth2/ block to use port ${OAUTH2_PORT}"
  sed -i "s|proxy_pass[[:space:]]\+http://127\.0\.0\.1:[0-9]\+/;|proxy_pass http://127.0.0.1:${OAUTH2_PORT};|" "$NGINX_VHOST"
fi

# Final NGINX config test and reload
log "Finalizing NGINX configuration..."
if ! nginx -t; then
  error "NGINX config test failed after patching.\nConfig:\n$(cat "$NGINX_VHOST")"
fi
log "    → Ensuring NGINX is running..."
if ! systemctl is-active --quiet nginx; then
  log "    → Starting NGINX..."
  systemctl start nginx || error "Failed to start NGINX"
fi
log "    → Reloading NGINX..."
systemctl reload nginx || error "Failed to reload NGINX"
log "    → NGINX reloaded OK"
set +x

# Configure OAuth2-Proxy
log "Building OAuth2 env config..."
# Use provided COOKIE_SECRET if available, otherwise generate a new one
if [ -n "${COOKIE_SECRET:-}" ]; then
  log "    → Using COOKIE_SECRET from .env"
else
  COOKIE_SECRET=$(openssl rand -base64 32 | tr '+/' '_-')
  log "    → Generated new COOKIE_SECRET"
fi
mkdir -p "$(dirname "$SYSTEMD_DROPIN")" || error "Failed to create directory for $SYSTEMD_DROPIN"
cat > "$SYSTEMD_DROPIN" <<EOF
[Service]
Environment="OAUTH2_PROXY_HTTP_ADDRESS=127.0.0.1:${OAUTH2_PORT}"
Environment="OAUTH2_PROXY_COOKIE_HTTPONLY=true"
Environment="OAUTH2_PROXY_COOKIE_DOMAIN=${DOMAIN}"
Environment="OAUTH2_PROXY_COOKIE_SECURE=true"
Environment="OAUTH2_PROXY_REDIRECT_URL=https://${DOMAIN}/oauth2/callback"
Environment="OAUTH2_PROXY_PROVIDER=github"
Environment="OAUTH2_PROXY_CLIENT_ID=${GH_CLIENT_ID}"
Environment="OAUTH2_PROXY_CLIENT_SECRET=${GH_CLIENT_SECRET}"
Environment="OAUTH2_PROXY_COOKIE_SECRET=${COOKIE_SECRET}"
Environment="OAUTH2_PROXY_EMAIL_DOMAINS=*"
Environment="OAUTH2_PROXY_UPSTREAMS=http://127.0.0.1:${CODE_PORT}"
Environment="OAUTH2_PROXY_PASS_USER_HEADERS=true"
Environment="OAUTH2_PROXY_SET_AUTHORIZATION_HEADER=true"
EOF
log "    → OAuth2-Proxy config written to $SYSTEMD_DROPIN"

# Restart services
log "Restarting services..."
systemctl daemon-reload || error "Failed to reload systemd daemon"
for svc in "code-server@${OS_USER}" oauth2-proxy; do
  systemctl restart "$svc" || error "Failed to restart $svc"
  log "    → $svc restarted"
done
# NGINX was already reloaded, no need to restart

# Final validation with diagnostics
log "Checking for 500 errors..."
# Check service status
log "    → Checking service status..."
nginx_status=$(systemctl is-active nginx)
code_server_status=$(systemctl is-active "code-server@${OS_USER}")
oauth2_status=$(systemctl is-active oauth2-proxy)
log "    → NGINX: $nginx_status"
log "    → code-server: $code_server_status"
log "    → oauth2-proxy: $oauth2_status"

# Check running processes
log "    → Checking running processes..."
if pgrep -f "code-server" >/dev/null; then
  log "    → Code-server process running"
else
  log "    → Warning: No code-server process found"
fi
if pgrep -f "oauth2-proxy" >/dev/null; then
  log "    → OAuth2-Proxy process running"
else
  log "    → Warning: No oauth2-proxy process found"
fi

# Check port availability with ss
log "    → Checking port availability..."
if command -v ss >/dev/null; then
  if ! ss -tuln | grep -q ":${CODE_PORT}"; then
    log "    → Warning: No service listening on port ${CODE_PORT} (code-server)"
  else
    log "    → Port ${CODE_PORT} is open (code-server)"
  fi
  if ! ss -tuln | grep -q ":${OAUTH2_PORT}"; then
    log "    → Warning: No service listening on port ${OAUTH2_PORT} (oauth2-proxy)"
  else
    log "    → Port ${OAUTH2_PORT} is open (oauth2-proxy)"
  fi
else
  log "    → Warning: ss command not found, cannot check ports"
fi

# Test upstream services
log "    → Testing code-server connectivity..."
code_server_test=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${CODE_PORT}" || echo "failed")
log "    → Code-server response: $code_server_test"
log "    → Testing oauth2-proxy connectivity..."
oauth2_test=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${OAUTH2_PORT}/ping" || echo "failed")
log "    → OAuth2-Proxy response: $oauth2_test"

# Test GitHub OAuth callback URL
log "    → Testing GitHub OAuth callback URL..."
oauth2_redirect_test=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/oauth2/callback" || echo "failed")
log "    → OAuth2 callback response: $oauth2_redirect_test"

# Final site test
FINAL_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" || echo "failed")
if [ "$FINAL_STATUS" = "500" ]; then
  error "Received 500 error from https://${DOMAIN}/\n" \
        "NGINX error logs:\n$(journalctl -u nginx --no-pager --since '5 min ago' | tail -50)\n" \
        "Code-server logs:\n$(journalctl -u code-server@${OS_USER} --no-pager --since '5 min ago' | tail -50)\n" \
        "OAuth2-Proxy logs:\n$(journalctl -u oauth2-proxy --no-pager --since '5 min ago' | tail -50)"
elif [ "$FINAL_STATUS" = "failed" ]; then
  error "Failed to connect to https://${DOMAIN}/\n" \
        "NGINX status: $nginx_status\n" \
        "Code-server status: $code_server_status\n" \
        "OAuth2-Proxy status: $oauth2_status\n" \
        "Check service logs for details."
fi

# Report success
log "Setup Complete"
echo " → NGINX:       $nginx_status"
echo " → code-server: $code_server_status"
echo " → oauth2-proxy:$oauth2_status"
echo " → CODE_PORT:   $CODE_PORT"
echo " → DOMAIN:      $DOMAIN"
echo -e "\nVisit https://${DOMAIN} to test."