#!/usr/bin/env bash

set -euo pipefail

BRANDING_DIR="/opt/code-stack/branding"
NGINX_VHOST="/etc/nginx/sites-available/code-stack"
FAVICON_URL="https://raw.githubusercontent.com/haKC-ai/haKCAssets/refs/heads/main/haKCAI.png"
LOGO_URL="https://raw.githubusercontent.com/haKC-ai/haKCAssets/refs/heads/main/438312068-d8bed95c-98c5-4356-843b-c4e936fe8d9f.png"
BANNER_MD_URL="https://raw.githubusercontent.com/haKC-ai/haKCAssets/main/banner.md"
BANNER_PNG="$BRANDING_DIR/banner.png"

echo "[+] Setting up haKC.ai landing page..."

mkdir -p "$BRANDING_DIR"

# -----------------------------
# Download assets
# -----------------------------
echo "    → Downloading favicon and logo"
curl -sSL "$FAVICON_URL" -o "$BRANDING_DIR/favicon.ico"
curl -sSL "$LOGO_URL" -o "$BRANDING_DIR/logo.png"

# -----------------------------
# Render markdown banner to image
# -----------------------------
echo "    → Fetching banner.md and rendering to image"
curl -sSL "$BANNER_MD_URL" -o "$BRANDING_DIR/banner.md"

if command -v pandoc &>/dev/null && command -v wkhtmltoimage &>/dev/null; then
  pandoc "$BRANDING_DIR/banner.md" -o "$BRANDING_DIR/banner.html"
  wkhtmltoimage --width 800 "$BRANDING_DIR/banner.html" "$BANNER_PNG"
else
  echo "     Skipping banner render — install pandoc + wkhtmltoimage for full support"
fi

# -----------------------------
# Create index.html
# -----------------------------
cat > "$BRANDING_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>haKC.ai Code Portal</title>
  <link rel="icon" href="/favicon.ico" type="image/x-icon">
  <style>
    body {
      margin: 0;
      background: #0c0c0c;
      color: #f1f1f1;
      font-family: 'Fira Code', monospace;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      text-align: center;
    }
    header img.logo {
      width: 120px;
      margin-bottom: 1em;
    }
    .banner {
      margin: 1em auto;
      max-width: 90%;
    }
    h1 {
      color: #66d9ef;
      font-size: 2.5em;
    }
    .login-btn {
      background: #66d9ef;
      color: #000;
      font-weight: bold;
      border: none;
      padding: 1em 2em;
      font-size: 1.2em;
      border-radius: 8px;
      cursor: pointer;
      margin-top: 1.5em;
      transition: background 0.2s ease-in-out;
    }
    .login-btn:hover {
      background: #5eb1d9;
    }
  </style>
</head>
<body>
  <header>
    <img src="/logo.png" class="logo" alt="haKC.ai Logo">
  </header>
  <main>
    <div class="banner">
      <img src="/banner.png" alt="Banner" style="width:100%">
    </div>
    <h1>Welcome to haKC.ai Code Server</h1>
    <a href="/oauth2/start"><button class="login-btn">Login with GitHub</button></a>
  </main>
</body>
</html>
EOF

# -----------------------------
# Update NGINX root
# -----------------------------
echo "    → Updating NGINX root to serve branding page"
sed -i "s|^\s*root\s\+.*;|\1root $BRANDING_DIR;|" "$NGINX_VHOST"
sed -i "s|^\s*index\s\+.*;|\1index index.html;|" "$NGINX_VHOST"

# -----------------------------
# Reload
# -----------------------------
echo "    → Reloading nginx"
nginx -t && systemctl reload nginx

echo "[✓] haKC.ai landing page installed at root"
