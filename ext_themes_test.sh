#!/usr/bin/env bash

set -euo pipefail

OS_USER="hakcer"
CODE_DIR="/home/${OS_USER}/.local/share/code-server"
SETTINGS_DIR="${CODE_DIR}/User"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

EXTENSIONS=(
  github.vscode-pull-request-github
  enkia.tokyo-night
  ms-python.python
  ms-toolsai.jupyter
  ms-toolsai.jupyter-keymap
  ms-toolsai.jupyter-renderers
  ms-python.isort
  ms-python.black-formatter
  eamodio.gitlens
)

echo "[+] Installing VS Code extensions for $OS_USER..."

for ext in "${EXTENSIONS[@]}"; do
  if ! sudo -u "$OS_USER" code-server --list-extensions | grep -q "$ext"; then
    echo "    → Installing $ext"
    sudo -u "$OS_USER" code-server --install-extension "$ext"
  else
    echo "    → $ext already installed"
  fi
done

echo "[+] Writing settings.json to $SETTINGS_FILE..."

mkdir -p "$SETTINGS_DIR"

cat > "$SETTINGS_FILE" <<EOF
{
  "workbench.colorTheme": "Tokyo Night Storm",
  "workbench.startupEditor": "none",
  "editor.fontFamily": "Fira Code, monospace",
  "editor.fontLigatures": true,
  "editor.tabSize": 2,
  "editor.detectIndentation": false,
  "editor.formatOnSave": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "telemetry.enableTelemetry": false,
  "telemetry.enableCrashReporter": false,
  "update.mode": "none",
  "python.formatting.provider": "black",
  "python.formatting.blackArgs": ["--line-length", "88"],
  "python.sortImports.args": ["--profile", "black"],
  "python.dataScience.sendSelectionToInteractiveWindow": true,
  "jupyter.askForKernelRestart": false,
  "jupyter.enablePlotViewer": true,
  "jupyter.showCellInputCode": true,
  "github.enterpriseServerUri": "https://github.com",
  "security.workspace.trust.untrustedFiles": "open",
  "extensions.ignoreRecommendations": false
}
EOF

chown -R "$OS_USER:$OS_USER" "$CODE_DIR"

echo "[✓] Extensions and settings installed for user: $OS_USER"
