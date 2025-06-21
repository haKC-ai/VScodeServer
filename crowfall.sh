#!/usr/bin/env bash
set -euo pipefail

read -rp "Domain for Rocket.Chat (e.g. chat.example.com): " DOMAIN
read -rp "Email for Let's Encrypt registration: " EMAIL
read -rp "Rocket.Chat admin email (MAIL_FROM): " ADMIN_EMAIL

# Define secure credentials
MONGO_ROOT_USER="admin"
MONGO_ROOT_PASS="$(openssl rand -base64 24)"
RC_DB_USER="rocketchatuser"
RC_DB_PASS="$(openssl rand -base64 24)"

WORKDIR="/opt/rocketchat"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

apt update && apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx fail2ban logrotate

# Docker Compose
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  mongo:
    image: mongo:6
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_ROOT_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_ROOT_PASS}
    command: --auth
    volumes:
      - mongo-data:/data/db

  rocketchat:
    image: registry.rocket.chat/rocket.chat:latest
    depends_on:
      - mongo
    restart: unless-stopped
    environment:
      - PORT=3000
      - ROOT_URL=https://${DOMAIN}
      - MONGO_URL=mongodb://${RC_DB_USER}:${RC_DB_PASS}@mongo:27017/rocketchat?authSource=admin
      - MONGO_OPLOG_URL=mongodb://${RC_DB_USER}:${RC_DB_PASS}@mongo:27017/local?authSource=admin
      - MAIL_FROM=${ADMIN_EMAIL}
      - HTTP_FORWARDED_COUNT=1
    ports:
      - "3000:3000"

volumes:
  mongo-data:
EOF

# Start containers (wait for Mongo to initialize)
docker compose up -d
sleep 20

# Create Rocket.Chat DB user in Mongo
docker exec -i $(docker ps -qf name=mongo) mongosh -u ${MONGO_ROOT_USER} -p ${MONGO_ROOT_PASS} --authenticationDatabase admin <<EOF
use admin
db.createUser({
  user: "${RC_DB_USER}",
  pwd: "${RC_DB_PASS}",
  roles: [
    { role: "readWrite", db: "rocketchat" },
    { role: "read", db: "local" }
  ]
});
EOF

# Nginx config
cat > /etc/nginx/sites-available/rocketchat <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://${DOMAIN}\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.3;

    location / {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/rocketchat /etc/nginx/sites-enabled/
nginx -t
certbot --nginx -n --agree-tos --email "${EMAIL}" -d "${DOMAIN}"
systemctl reload nginx

# Fail2Ban
cat > /etc/fail2ban/jail.d/rocketchat.conf <<EOF
[sshd]
enabled = true
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
action = iptables
logpath = /var/log/nginx/*error.log
maxretry = 3
findtime = 10m
bantime = 1h
EOF

systemctl enable --now fail2ban

# Logrotate
cat > /etc/logrotate.d/rocketchat <<EOF
/var/log/nginx/*.log {
  daily
  rotate 7
  compress
  missingok
  notifempty
  sharedscripts
  postrotate
    systemctl reload nginx > /dev/null 2>&1 || true
  endscript
}
/var/lib/docker/containers/*/*.log {
  daily
  rotate 7
  compress
  missingok
  notifempty
  copytruncate
}
EOF

# Certbot renew timer
cat > /etc/systemd/system/certbot-renew.service <<EOF
[Unit]
Description=Renew Let's Encrypt certs

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --deploy-hook "systemctl reload nginx"
EOF

cat > /etc/systemd/system/certbot-renew.timer <<EOF
[Unit]
Description=Daily cert renewal

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now certbot-renew.timer

# Final output
echo "Rocket.Chat deployed at: https://${DOMAIN}"
echo "Mongo root: ${MONGO_ROOT_USER} / ${MONGO_ROOT_PASS}"
echo "Rocket.Chat DB user: ${RC_DB_USER} / ${RC_DB_PASS}"
echo "Next: Access Rocket.Chat, create admin user, and enable TOTP in Admin > Accounts > Two Factor Auth."
