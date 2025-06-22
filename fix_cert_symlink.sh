#!/bin/bash

BASE_PATH="/etc/letsencrypt/live"
BASE_NAME="vanta.hakc.ai"
TARGET_LINK="${BASE_PATH}/${BASE_NAME}"

latest_cert=""
latest_expiry=0

for cert_dir in ${BASE_PATH}/${BASE_NAME}*; do
  fullchain="${cert_dir}/fullchain.pem"
  if [ -f "$fullchain" ]; then
    expiry_epoch=$(date -d "$(openssl x509 -in "$fullchain" -noout -enddate | cut -d= -f2)" +%s)
    if [ "$expiry_epoch" -gt "$latest_expiry" ]; then
      latest_expiry="$expiry_epoch"
      latest_cert="$cert_dir"
    fi
  fi
done

if [ -n "$latest_cert" ]; then
  echo "[*] Latest valid cert: $latest_cert"
  echo "[*] Updating symlink: $TARGET_LINK"
  sudo rm -rf "$TARGET_LINK"
  sudo ln -s "$latest_cert" "$TARGET_LINK"
  echo "[*] Reloading NGINX..."
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "[!] No valid certificates found."
  exit 1
fi
