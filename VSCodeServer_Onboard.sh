#!/usr/bin/env bash

set -euo pipefail

MASTER_USER="hakcer"
SKEL_DIR="/opt/code-stack/skel-vscode"
LOG_FILE="/var/log/code-server/onboarding.log"
AUTOBOT_SCRIPT="/usr/local/bin/code-server_autobot.sh"
OAUTH2_LOG="/var/log/nginx/access.log"  # Update this if your access logs differ

mkdir -p "$(dirname "$LOG_FILE")"


# --- color setup
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

tput bold; tput setaf 2
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
            Name :                            haKC.ai VSCoderServer Post-Install Onboard
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

echo "[+] Bootstrapping autobot..."

# ------------------------------------------------------------------------------
# 1. Create the autobot script
# ------------------------------------------------------------------------------
cat > "$AUTOBOT_SCRIPT" <<'EOS'
#!/usr/bin/env bash

set -euo pipefail

MASTER_USER="hakcer"
SKEL_DIR="/opt/code-stack/skel-vscode"
LOG_FILE="/var/log/code-server/onboarding.log"
OAUTH2_LOG="/var/log/nginx/access.log"
NEW_USERS=()

mkdir -p "$(dirname "$LOG_FILE")"

# Build skeleton if missing
if [ ! -d "$SKEL_DIR/User" ]; then
  echo "[+] Creating skeleton from ${MASTER_USER}"
  mkdir -p "$SKEL_DIR/User"
  cp -r "/home/${MASTER_USER}/.local/share/code-server/extensions" "$SKEL_DIR/" || true
  cp "/home/${MASTER_USER}/.local/share/code-server/User/settings.json" "$SKEL_DIR/User/" || true
  sudo -u "$MASTER_USER" code-server --install-extension github.vscode-pull-request-github || true
fi

# Extract GitHub usernames from access log
mapfile -t RECENT_USERS < <(grep 'X-Auth-Request-User' "$OAUTH2_LOG" \
  | grep -oE 'X-Auth-Request-User=[a-zA-Z0-9_-]+' \
  | cut -d= -f2 \
  | sort -u)

# Onboard new users
for USERNAME in "${RECENT_USERS[@]}"; do
  if id "$USERNAME" &>/dev/null; then continue; fi
  echo "[+] New GitHub user: $USERNAME"
  NEW_USERS+=("$USERNAME")
  useradd -m -s /bin/bash "$USERNAME"
  HOME_DIR="/home/$USERNAME"
  CODE_DIR="${HOME_DIR}/.local/share/code-server"
  mkdir -p "$CODE_DIR/User"
  cp -r "$SKEL_DIR/extensions" "$CODE_DIR/" || true
  cp "$SKEL_DIR/User/settings.json" "$CODE_DIR/User/" || true
  chown -R "$USERNAME:$USERNAME" "$CODE_DIR"
  echo "[+] Onboarded $USERNAME at $(date)" >> "$LOG_FILE"
done

if [ "${#NEW_USERS[@]}" -eq 0 ]; then
  echo "[✓] No new users to onboard."
else
  echo "[✓] Onboarded users: ${NEW_USERS[*]}"
fi
EOS

chmod +x "$AUTOBOT_SCRIPT"

# ------------------------------------------------------------------------------
# 2. Create systemd service + timer if not present
# ------------------------------------------------------------------------------
SERVICE_FILE="/etc/systemd/system/code-server-autobot.service"
TIMER_FILE="/etc/systemd/system/code-server-autobot.timer"

if [ ! -f "$SERVICE_FILE" ]; then
  echo "[+] Writing systemd service unit..."
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Auto-onboard new GitHub users for code-server

[Service]
ExecStart=$AUTOBOT_SCRIPT
EOF
fi

if [ ! -f "$TIMER_FILE" ]; then
  echo "[+] Writing systemd timer unit..."
  cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Run code-server autobot every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
Persistent=true

[Install]
WantedBy=timers.target
EOF
fi

# ------------------------------------------------------------------------------
# 3. Enable and start the timer
# ------------------------------------------------------------------------------
echo "[+] Enabling and starting code-server-autobot.timer..."
systemctl daemon-reload
systemctl enable --now code-server-autobot.timer

echo "[✓] Autobot fully deployed and running."
