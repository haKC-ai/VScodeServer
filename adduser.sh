#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Prompt
read -rp "New username: " NEWUSER
read -rp "Lock user to own directory? [y/n]: " LOCK_USER
read -rp "Grant shared directory access? [y/n]: " SHARED_ACCESS
read -rp "Force password reset on first login? [y/n]: " FORCE_RESET
read -rp "Disable shell access? [y/n]: " NO_SHELL
read -rp "User email address: " USER_EMAIL

# Create stack directory and .env if missing or append if exists
ENV_FILE="/opt/code-stack/users.env"
mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"
if grep -q "^${NEWUSER}=" "$ENV_FILE"; then
  echo "User $NEWUSER already exists in .env"
  exit 1
fi

# Create user
if id "$NEWUSER" &>/dev/null; then
  echo "User already exists"
  exit 1
fi

USERADD_OPTS="-m"
if [[ "$NO_SHELL" =~ ^[Yy] ]]; then
  USERADD_OPTS+=" -s /usr/sbin/nologin"
else
  USERADD_OPTS+=" -s /bin/bash"
fi
useradd $USERADD_OPTS "$NEWUSER"

# Set password
PASSWORD=$(openssl rand -base64 16)
echo "${NEWUSER}:${PASSWORD}" | chpasswd
if [[ "$FORCE_RESET" =~ ^[Yy] ]]; then
  chage -d 0 "$NEWUSER"
fi

# Directory isolation
if [[ "$LOCK_USER" =~ ^[Yy] ]]; then
  BASE="/srv/users/${NEWUSER}"
  mkdir -p "${BASE}/home/${NEWUSER}"
  chown root:root "${BASE}"
  chmod 755 "${BASE}"
  usermod -d "${BASE}/home/${NEWUSER}" "$NEWUSER"
  chown "${NEWUSER}:${NEWUSER}" "${BASE}/home/${NEWUSER}"
fi

# Shared directories
if [[ "$SHARED_ACCESS" =~ ^[Yy] ]]; then
  read -rp "Enter shared directories (comma-separated full paths): " SHARED_DIRS
  GROUP="shared_${NEWUSER}"
  groupadd -f "$GROUP"
  usermod -aG "$GROUP" "$NEWUSER"
  IFS=',' read -ra DIRS <<< "$SHARED_DIRS"
  for DIR in "${DIRS[@]}"; do
    mkdir -p "$DIR"
    chgrp "$GROUP" "$DIR"
    chmod 770 "$DIR"
  done
fi

# Install dependencies
apt update
apt install -y libpam-google-authenticator qrencode postfix

# TOTP setup
su - "$NEWUSER" -c "google-authenticator -t -d -f -r 3 -R 30 -W -Q > ~/.ga.txt"
SECRET=$(grep 'Secret key' /home/$NEWUSER/.ga.txt | awk '{print $NF}')
URI=$(grep 'otpauth://' /home/$NEWUSER/.ga.txt)

mkdir -p /opt/code-stack/qr_codes
QR_PATH="/opt/code-stack/qr_codes/${NEWUSER}.png"
qrencode -o "$QR_PATH" "$URI"
chmod 600 "$QR_PATH"
chown "$NEWUSER:$NEWUSER" "$QR_PATH"
chmod 600 "/home/$NEWUSER/.ga.txt"
chown "$NEWUSER:$NEWUSER" "/home/$NEWUSER/.ga.txt"

# Save user credentials to .env
SALTED_PASS=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
echo "${NEWUSER}_EMAIL=${USER_EMAIL}" >> "$ENV_FILE"
echo "${NEWUSER}_PASSWORD_HASH=${SALTED_PASS}" >> "$ENV_FILE"
echo "${NEWUSER}_TOTP_SECRET=${SECRET}" >> "$ENV_FILE"

# Send email via local postfix relay
cat <<EOF | sendmail -t
To: $USER_EMAIL
Subject: Credentials for $NEWUSER on secure server

User: $NEWUSER
Password: $PASSWORD
TOTP Secret: $SECRET
Provisioning URI: $URI

QR code file path: $QR_PATH
EOF

# Configure PAM for TOTP
if ! grep -q "pam_google_authenticator.so" /etc/pam.d/sshd; then
  sed -i '/^#@include common-auth/a auth required pam_google_authenticator.so' /etc/pam.d/sshd
  sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/#UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config
  systemctl reload sshd
fi

# Install and configure auditd
apt install -y auditd
auditctl -w /home/$NEWUSER -p war -k user_$NEWUSER
echo "-w /home/$NEWUSER -p wra -k user_${NEWUSER}" >> /etc/audit/rules.d/audit.rules
systemctl restart auditd

# Log summary
echo "User $NEWUSER has been created."
echo "Password, TOTP secret, and QR-file sent to email."
echo "SSH TOTP enabled. Actions of $NEWUSER are logged."
