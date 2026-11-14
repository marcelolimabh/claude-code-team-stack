#!/usr/bin/env bash
# ------------------------------------------------------------------
# claude-code-team-stack: per-machine setup for macOS, Linux and WSL2
#
# Usage (run from the root of a repo that already has .claude/settings.json):
#   ./setup-claude-stack.sh            # uses the current directory
#   ./setup-claude-stack.sh ~/dev/api  # or pass the repo path
#
# What it does:
#   1. Checks prerequisites (claude, git, python3, node)
#   2. Installs the LSP binaries the repo's settings.json asks for
#      (jdtls for Java, typescript-language-server for TS/JS)
#   3. Registers the marketplaces and installs the plugins listed in
#      enabledPlugins / extraKnownMarketplaces
# Idempotent: safe to run again.
# ------------------------------------------------------------------
set -euo pipefail

REPO_DIR="${1:-$PWD}"
SETTINGS="$REPO_DIR/.claude/settings.json"
OS="$(uname -s)"
JDTLS_HOME="$HOME/.local/share/jdtls"
LOCAL_BIN="$HOME/.local/bin"

info()  { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[ ok ]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }
has()   { command -v "$1" >/dev/null 2>&1; }

# ---------- 0. Context ----------
[[ -f "$SETTINGS" ]] || fail "No $SETTINGS found. Copy one of the templates/ into the repo first."

if grep -qi microsoft /proc/version 2>/dev/null; then PLATFORM="wsl"
elif [[ "$OS" == "Darwin" ]]; then PLATFORM="mac"
elif [[ "$OS" == "Linux" ]]; then PLATFORM="linux"
else fail "Unsupported system ($OS). On Windows use setup-claude-stack-windows.ps1."
fi
info "Platform: $PLATFORM | Repository: $REPO_DIR"

if [[ "$PLATFORM" == "wsl" && "$REPO_DIR" == /mnt/* ]]; then
  warn "The repo is under /mnt/ (Windows drive). Clone it inside WSL (e.g. ~/dev): much faster and avoids LSP path issues."
fi

# Reads the plugins/marketplaces the project declares
read_settings() {
  python3 - "$SETTINGS" "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
what = sys.argv[2]
if what == "plugins":
    for name, enabled in data.get("enabledPlugins", {}).items():
        if enabled:
            print(name)
elif what == "marketplaces":
    for name, cfg in data.get("extraKnownMarketplaces", {}).items():
        src = cfg.get("source", {})
        if src.get("source") == "github":
            print(src["repo"])
        elif src.get("url"):
            print(src["url"])
PY
}

# ---------- 1. Prerequisites ----------
has python3 || fail "python3 not found (needed by security-guidance and jdtls). Install Python 3.9+."
has git     || fail "git not found."
has claude  || fail "Claude Code not found. Install: curl -fsSL https://claude.ai/install.sh | bash"
ok "claude $(claude --version 2>/dev/null | head -n1)"

PLUGINS="$(read_settings plugins)"
MARKETPLACES="$(read_settings marketplaces)"

if [[ "$PLATFORM" == "mac" ]] && ! has brew; then
  warn "Homebrew not found (https://brew.sh). jdtls will use the direct download instead."
fi

# ---------- 2. LSP binaries ----------
# Downloads jdtls from Eclipse into ~/.local/share/jdtls. Returns 1 (without
# aborting the setup) when it cannot be installed.
download_jdtls() {
  if ! has java; then
    warn "Java not found. jdtls needs JDK 21+ to run. Install one and run again."
    return 1
  fi
  JAVA_MAJOR="$(java -version 2>&1 | awk -F'"' '/version/ {split($2,v,"."); print (v[1]=="1"?v[2]:v[1])}')"
  if [[ "${JAVA_MAJOR:-0}" -lt 21 ]]; then
    warn "Java ${JAVA_MAJOR:-?} detected; jdtls needs 21+ to RUN (your project can still target 17)."
    warn "Install a JDK 21 (e.g. sudo apt install openjdk-21-jdk, or brew install openjdk@21) and run again."
    return 1
  fi
  info "Downloading jdtls (Eclipse JDT Language Server)..."
  mkdir -p "$JDTLS_HOME" "$LOCAL_BIN"
  TMP="$(mktemp -d)"
  if ! curl -fsSL -o "$TMP/jdtls.tar.gz" https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz \
     || ! tar -xzf "$TMP/jdtls.tar.gz" -C "$JDTLS_HOME"; then
    rm -rf "$TMP"
    warn "Could not download or extract jdtls."
    return 1
  fi
  rm -rf "$TMP"
  chmod +x "$JDTLS_HOME/bin/jdtls"
  ln -sf "$JDTLS_HOME/bin/jdtls" "$LOCAL_BIN/jdtls"
  case ":$PATH:" in *":$LOCAL_BIN:"*) ;; *)
    warn "Add this to your ~/.bashrc or ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"";;
  esac
}

install_jdtls() {
  if has jdtls; then ok "jdtls already installed ($(command -v jdtls))"; return; fi

  if [[ "$PLATFORM" == "mac" ]]; then
    info "Installing jdtls with Homebrew (pulls the OpenJDK it needs)..."
    if has brew && brew install jdtls; then ok "jdtls installed"; return; fi
    # Homebrew has no prebuilt packages for some Macs (e.g. Intel) and the
    # source build can fail: fall back to the Eclipse download.
    warn "Homebrew could not install jdtls; trying the direct download instead."
  fi

  if download_jdtls; then
    ok "jdtls installed"
  else
    warn "jdtls was NOT installed: the jdtls-lsp plugin will not work until it is. Continuing with the plugins."
  fi
}

install_ts_lsp() {
  if has typescript-language-server; then ok "typescript-language-server already installed"; return; fi
  has npm || fail "npm not found. Install Node.js LTS."
  info "Installing typescript-language-server..."
  npm install -g typescript-language-server typescript
  ok "typescript-language-server installed"
}

if grep -q '^jdtls-lsp@' <<<"$PLUGINS"; then install_jdtls; fi
if grep -q '^typescript-lsp@' <<<"$PLUGINS"; then install_ts_lsp; fi

# ---------- 3. Marketplaces and plugins ----------
info "Refreshing the official marketplace..."
claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
claude plugin marketplace update claude-plugins-official >/dev/null 2>&1 || true

while IFS= read -r mk; do
  [[ -z "$mk" ]] && continue
  info "Registering marketplace $mk"
  claude plugin marketplace add "$mk" >/dev/null 2>&1 || true
done <<<"$MARKETPLACES"

FAILED=()
cd "$REPO_DIR"
while IFS= read -r plugin; do
  [[ -z "$plugin" ]] && continue
  if claude plugin install "$plugin" --scope project >/dev/null 2>&1; then
    ok "plugin $plugin"
  else
    warn "failed: $plugin"
    FAILED+=("$plugin")
  fi
done <<<"$PLUGINS"

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
  warn "Plugins that did not install: ${FAILED[*]}"
  warn "Open Claude Code in the repo and run /plugin to install them manually."
fi
ok "Done. Open Claude Code in the repo folder, trust the folder and run /plugin to check."
info "The github plugin asks you to authenticate with GitHub on first use."
