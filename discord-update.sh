#!/usr/bin/env bash
# discord-update — install the latest Discord on Arch Linux
# Converts the official .deb release to a native pacman package via debtap.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
DISCORD_URL="https://discord.com/api/download?platform=linux"
WORK_DIR=""

# Disable colour codes when not writing to a terminal
if [[ -t 1 ]]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
  BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

info()    { printf "  ${BLUE}::${RESET} %s\n" "$*"; }
success() { printf "  ${GREEN}ok${RESET}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!!${RESET}  %s\n" "$*"; }
error()   { printf "  ${RED}!!${RESET}  %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

header() {
  local title="$*"
  printf "\n${BOLD}%s${RESET}\n" "${title}"
  printf '%*s\n' "${#title}" '' | tr ' ' '─'
}

usage() {
  cat <<EOF

${BOLD}Usage:${RESET} ${SCRIPT_NAME} [OPTIONS]

  Install the latest Discord release on Arch Linux by converting the
  official .deb package into a native pacman package via debtap.

${BOLD}Options:${RESET}
  -f, --force        Skip version check and reinstall
  -u, --update-db    Refresh the debtap package database first
  -h, --help         Show this help and exit

${BOLD}Examples:${RESET}
  ${SCRIPT_NAME}              Update Discord if a newer version is available
  ${SCRIPT_NAME} --force      Reinstall the current latest version
  ${SCRIPT_NAME} --update-db  Refresh debtap DB then update

EOF
}

OPT_FORCE=false
OPT_UPDATE_DB=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force)      OPT_FORCE=true     ;;
    -u|--update-db)  OPT_UPDATE_DB=true ;;
    -h|--help)       usage; exit 0      ;;
    *) die "Unknown option: '$1' — run '${SCRIPT_NAME} --help' for usage." ;;
  esac
  shift
done

cleanup() {
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

check_deps() {
  header "Dependencies"
  local -a missing=()

  for cmd in wget debtap pacman sudo; do
    if command -v "${cmd}" &>/dev/null; then
      success "${cmd}"
    else
      error "${cmd} not found"
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    warn "Missing: ${missing[*]}"
    [[ " ${missing[*]} " == *" debtap "* ]] && \
      info "Install debtap with: yay -S debtap"
    exit 1
  fi
}

update_debtap_db() {
  header "Updating debtap database"
  if sudo debtap -u; then
    success "database updated"
  else
    warn "database update failed, continuing with existing database"
  fi
}

resolve_remote_version() {
  header "Checking latest version"

  # Spider the download URL to read the 302 Location header and extract the
  # version number — avoids downloading the full package just to check.
  local redirect_url
  redirect_url=$(
    wget --quiet --server-response --spider "${DISCORD_URL}" 2>&1 \
      | grep -i 'Location:' \
      | tail -1 \
      | awk '{print $2}' \
      | tr -d '[:space:]'
  )

  REMOTE_VERSION=$(
    printf '%s' "${redirect_url}" | grep -oP '\d+\.\d+\.\d+' | head -1 || true
  )

  [[ -n "${REMOTE_VERSION}" ]] \
    || die "Could not parse version from redirect URL: '${redirect_url}'"

  success "latest: ${REMOTE_VERSION}"
}

check_version() {
  local installed
  installed=$(
    pacman -Q discord 2>/dev/null \
      | awk '{print $2}' \
      | sed 's/^[0-9]*://' \
      | sed 's/-[^-]*$//' \
    || echo "not installed"
  )

  info "installed: ${installed}"
  info "available: ${REMOTE_VERSION}"

  if [[ "${OPT_FORCE}" == false && "${installed}" == "${REMOTE_VERSION}" ]]; then
    success "already up-to-date"
    exit 0
  fi

  [[ "${OPT_FORCE}" == true && "${installed}" == "${REMOTE_VERSION}" ]] && \
    warn "--force set, reinstalling ${REMOTE_VERSION}"
}

download_deb() {
  header "Downloading Discord ${REMOTE_VERSION}"

  WORK_DIR=$(mktemp -d /tmp/discord-deb2arch.XXXXXX)
  DEB_FILE="${WORK_DIR}/discord.deb"

  wget --show-progress --quiet "${DISCORD_URL}" -O "${DEB_FILE}"
  success "download complete"
}

convert_package() {
  header "Converting to Arch package"

  cd "${WORK_DIR}"
  # Pipe a newline to skip the editor prompt on older debtap versions
  printf '\n' | debtap -q "${DEB_FILE}"

  PKG_FILE=$(find "${WORK_DIR}" -maxdepth 1 -name "*.pkg.tar.zst" | head -1 || true)
  [[ -n "${PKG_FILE}" ]] || die "debtap did not produce a .pkg.tar.zst"

  success "$(basename "${PKG_FILE}")"
}

install_package() {
  header "Installing Discord ${REMOTE_VERSION}"
  sudo pacman -U --noconfirm "${PKG_FILE}"
  success "Discord ${REMOTE_VERSION} installed"
}

main() {
  check_deps
  [[ "${OPT_UPDATE_DB}" == true ]] && update_debtap_db
  resolve_remote_version
  check_version
  download_deb
  convert_package
  install_package
}

main "$@"
