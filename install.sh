#!/usr/bin/env bash
set -euo pipefail

REPO="allye-app/allye-cli"
LATEST_URL="https://raw.githubusercontent.com/${REPO}/main/latest.json"
INSTALL_DIR="${ALLYE_INSTALL_DIR:-}"
TMP_DIR="$(mktemp -d)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
die()     { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ── Platform detection ────────────────────────────────────────────────────────
detect_platform() {
  local os arch

  case "$(uname -s)" in
    Linux)  os="linux"  ;;
    Darwin) os="darwin" ;;
    *)      die "Unsupported OS: $(uname -s). On Windows, use WSL or download the .zip manually from https://github.com/${REPO}/releases" ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)   arch="amd64" ;;
    arm64|aarch64)  arch="arm64" ;;
    *)               die "Unsupported architecture: $(uname -m)" ;;
  esac

  echo "${os}_${arch}"
}

# ── Install dir resolution ────────────────────────────────────────────────────
resolve_install_dir() {
  if [ -n "$INSTALL_DIR" ]; then
    echo "$INSTALL_DIR"
    return
  fi
  if [ -w "/usr/local/bin" ]; then
    echo "/usr/local/bin"
  else
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"
    echo "$local_bin"
  fi
}

# ── Ensure install dir is on PATH ─────────────────────────────────────────────
ensure_on_path() {
  local dir="$1"
  if [[ ":$PATH:" != *":${dir}:"* ]]; then
    warn "${dir} is not on your PATH."
    warn "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "  export PATH=\"${dir}:\$PATH\""
    echo ""
  fi
}

# ── Download helper ───────────────────────────────────────────────────────────
download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    die "curl or wget is required to install allye"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}Allye CLI Installer${NC}"
  echo ""

  local platform version asset_name asset_url checksum_url install_dir bin_path

  platform="$(detect_platform)"
  install_dir="$(resolve_install_dir)"

  info "Fetching latest version..."
  local latest_json
  latest_json="$(download "$LATEST_URL" /dev/stdout 2>/dev/null || true)"
  if [ -z "$latest_json" ]; then
    die "Could not fetch latest version from ${LATEST_URL}"
  fi

  version="$(echo "$latest_json" | grep -o '"version": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')"
  if [ -z "$version" ] || [ "$version" = "v0.0.0" ]; then
    die "No release available yet. Check https://github.com/${REPO}/releases"
  fi

  info "Installing allye ${version} for ${platform}..."

  asset_name="allye_${version}_${platform}.tar.gz"
  asset_url="https://github.com/${REPO}/releases/download/${version}/${asset_name}"
  checksum_url="https://github.com/${REPO}/releases/download/${version}/checksums.txt"

  info "Downloading ${asset_name}..."
  download "$asset_url" "${TMP_DIR}/${asset_name}"

  info "Verifying checksum..."
  download "$checksum_url" "${TMP_DIR}/checksums.txt"

  local expected actual
  expected="$(grep "${asset_name}" "${TMP_DIR}/checksums.txt" | awk '{print $1}')"
  if [ -z "$expected" ]; then
    die "Checksum not found for ${asset_name}"
  fi

  if command -v sha256sum &>/dev/null; then
    actual="$(sha256sum "${TMP_DIR}/${asset_name}" | awk '{print $1}')"
  elif command -v shasum &>/dev/null; then
    actual="$(shasum -a 256 "${TMP_DIR}/${asset_name}" | awk '{print $1}')"
  else
    warn "sha256sum/shasum not found — skipping checksum verification"
    actual="$expected"
  fi

  if [ "$actual" != "$expected" ]; then
    die "Checksum mismatch! Expected ${expected}, got ${actual}"
  fi
  success "Checksum verified"

  info "Extracting..."
  tar -xzf "${TMP_DIR}/${asset_name}" -C "$TMP_DIR"

  bin_path="${install_dir}/allye"
  install -m 0755 "${TMP_DIR}/allye" "$bin_path"

  success "allye ${version} installed to ${bin_path}"
  ensure_on_path "$install_dir"

  echo ""
  echo -e "Run ${BOLD}allye${NC} to get started."
  echo ""
}

main "$@"
