#!/bin/bash
set -eu

# Minimal Fightcade Flatpak installer for HD mode validation
# This version installs vanilla Fightcade without controller setup or Switchres.

REPO="net-terminal-gene/batocera-fightcade-flatpak"
BRANCH="${FIGHTCADE_FLATPAK_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
APP_ID="com.fightcade.Fightcade"
PROJECT_DIR="/userdata/system/fightcade-flatpak"
SCRIPTS_DIR="/userdata/system/scripts"
LOG_DIR="/userdata/system/logs"

# Minimal file list: just ROM sync and artwork
FILES="fightcade-roms-sync"
ART_FILES="images/Fightcade.png images/Fightcade-logo.png images/Fightcade-thumb.png"
FLATPAK_ROMS_DIR="/userdata/roms/flatpak"
GAMELIST="${FLATPAK_ROMS_DIR}/gamelist.xml"

AUTO_YES=0
INSTALL_FIGHTCADE=0
BRANCH_FROM_ARGS=""

info()   { printf '%s\n'       "$*"; }
notice() { printf '[INFO] %s\n' "$*"; }
ok()     { printf '[ OK ] %s\n' "$*"; }
warn()   { printf '[WARN] %s\n' "$*"; }
fail()   { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

set_branch() {
    BRANCH="$1"
    RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
}

usage() {
    cat <<USAGE
Minimal Fightcade Flatpak installer for HD mode validation.

Usage: install-minimal.sh [options]

Options:
  -y, --yes                 Accept all prompts automatically.
      --install-fightcade   Install Fightcade Flatpak if missing.
      --branch <name>       Fetch files from a specific branch or tag.
  -h, --help                Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes)                AUTO_YES=1 ;;
        --install-fightcade)     INSTALL_FIGHTCADE=1 ;;
        --branch)
            [ "$#" -ge 2 ] || fail "--branch requires a branch or tag name"
            BRANCH_FROM_ARGS="$2"
            shift
            ;;
        -h|--help)               usage; exit 0 ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift
done

# --branch wins over the environment default set above.
if [ -n "${BRANCH_FROM_ARGS}" ]; then
    set_branch "${BRANCH_FROM_ARGS}"
fi

ask_yes_no() {
    local prompt="$1"
    local default="${2:-no}"
    local answer=""

    if [ "${AUTO_YES}" -eq 1 ]; then
        return 0
    fi

    if [ ! -r /dev/tty ]; then
        [ "${default}" = "yes" ]
        return
    fi

    if [ "${default}" = "yes" ]; then
        printf '%s [Y/n] ' "${prompt}" > /dev/tty
    else
        printf '%s [y/N] ' "${prompt}" > /dev/tty
    fi
    IFS= read -r answer < /dev/tty || answer=""
    answer=$(printf '%s' "${answer}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    case "${answer}" in
        y|Y|yes|YES) return 0 ;;
        n|N|no|NO)   return 1 ;;
        '')          [ "${default}" = "yes" ]; return ;;
        *)           return 1 ;;
    esac
}

fetch_files() {
    local destination="$1"
    local file source_dir dest_dir
    mkdir -p "${destination}"

    command -v curl >/dev/null 2>&1 || fail "curl is required for direct GitHub installation."
    for file in ${FILES} ${ART_FILES}; do
        dest_dir=$(dirname "${destination}/${file}")
        [ "${dest_dir}" != "${destination}" ] && mkdir -p "${dest_dir}"
        curl -fsSL --retry 3 --connect-timeout 15 \
            "${RAW_BASE}/${file}" -o "${destination}/${file}" \
            || fail "Could not download ${file} from ${RAW_BASE}."
    done
}

has_system_flathub() {
    flatpak remotes --system 2>/dev/null | awk '{print $1}' | grep -qx "flathub"
}

ensure_system_flathub() {
    if has_system_flathub; then
        return 0
    fi

    notice "System-wide Flathub remote is missing. Adding it..."
    if flatpak remote-add --if-not-exists --system flathub \
        https://flathub.org/repo/flathub.flatpakrepo; then
        if has_system_flathub; then
            ok "System-wide Flathub remote added"
            return 0
        fi
    fi

    fail "Could not add the system-wide Flathub remote. Add it manually with: flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo"
}

install_fightcade_flatpak() {
    notice "Installing Fightcade Flatpak system-wide (several minutes, ~1.5 GB download)..."
    ensure_system_flathub

    mkdir -p "${LOG_DIR}"
    local log="${LOG_DIR}/fightcade-flatpak-install.log"
    : >"${log}"
    notice "Flatpak progress below (also saved to ${log})"

    export FLATPAK_PROGRESS=plain
    set +e
    set -o pipefail
    flatpak install --system -y flathub "${APP_ID}" 2>&1 | tee -a "${log}"
    local fc_install_rc=${PIPESTATUS[0]}
    set +o pipefail
    set -e

    if [ "${fc_install_rc}" -eq 0 ] && flatpak info --system "${APP_ID}" >/dev/null 2>&1; then
        ok "Fightcade Flatpak installed system-wide"
    elif [ "${fc_install_rc}" -eq 0 ]; then
        fail "Flatpak reported success but the system-wide Fightcade installation could not be verified. See ${log}"
    else
        fail "Fightcade could not be installed. See ${log} or install via Batocera's Flatpak Manager and run this installer again."
    fi
}

apply_overrides() {
    notice "Applying Flatpak filesystem overrides for ROM access..."

    local paths
    paths=(
        /userdata/system/fightcade-flatpak
        /userdata/roms/fbneo
        /userdata/roms/megadrive
        /userdata/roms/nes
        /userdata/roms/gamegear
        /userdata/roms/colecovision
        /userdata/roms/pcengine
        /userdata/roms/sg1000
        /userdata/roms/msx1
        /userdata/roms/fds
        /userdata/roms/mastersystem
        /userdata/roms/zxspectrum
        /userdata/roms/supergrafx
        /userdata/roms/snes
        /userdata/roms/atomiswave
        /userdata/roms/naomi
        /userdata/roms/naomi2
        /userdata/roms/dreamcast
    )

    for path in "${paths[@]}"; do
        flatpak override --system --filesystem="${path}" "${APP_ID}" 2>/dev/null || \
            warn "Could not apply override for ${path} (path may not exist; safe to ignore)"
    done

    ok "Flatpak filesystem overrides applied"
}

fightcade_game_entry() {
    cat <<'ENTRY'
  <game>
    <path>./Fightcade.flatpak</path>
    <name>Fightcade</name>
    <image>./images/Fightcade.png</image>
    <marquee>./images/Fightcade-logo.png</marquee>
    <thumbnail>./images/Fightcade-thumb.png</thumbnail>
  </game>
ENTRY
}

install_artwork() {
    notice "Installing Fightcade artwork..."

    mkdir -p "${FLATPAK_ROMS_DIR}/images"
    local art
    for art in ${ART_FILES}; do
        install -m 0644 "${TMP_DIR}/${art}" "${FLATPAK_ROMS_DIR}/images/$(basename "${art}")"
        ok "Artwork installed: ${FLATPAK_ROMS_DIR}/images/$(basename "${art}")"
    done

    if [ ! -f "${GAMELIST}" ]; then
        {
            printf '%s\n' '<?xml version="1.0"?>'
            printf '%s\n' '<gameList>'
            fightcade_game_entry
            printf '%s\n' '</gameList>'
        } > "${GAMELIST}"
        ok "Created ${GAMELIST} with Fightcade entry"
    elif grep -q '<path>\./Fightcade\.flatpak</path>' "${GAMELIST}"; then
        notice "Existing gamelist has a Fightcade entry"
    else
        awk -v entry="$(fightcade_game_entry)" \
            '/<\/gameList>/ { print entry } { print }' \
            "${GAMELIST}" > "${GAMELIST}.tmp" && mv "${GAMELIST}.tmp" "${GAMELIST}"
        ok "Added Fightcade entry to existing ${GAMELIST}"
    fi
}

# Main
printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Minimal Fightcade Flatpak Installer (HD Mode Validation)'
printf '%s\n' '------------------------------------------------------------'
printf '\n'

# Batocera check
if [ -f /etc/batocera-release ] || grep -qi batocera /etc/os-release 2>/dev/null; then
    ok "Batocera detected"
else
    fail "This installer is intended for Batocera."
fi

# Flatpak check
command -v flatpak >/dev/null 2>&1 || fail "Flatpak is not available on this Batocera installation."
ok "Flatpak is available"

# Fightcade Flatpak check
if flatpak info --system "${APP_ID}" >/dev/null 2>&1; then
    ok "Fightcade Flatpak is installed system-wide"
else
    warn "Fightcade Flatpak (${APP_ID}) is not installed system-wide."

    if flatpak info --user "${APP_ID}" >/dev/null 2>&1; then
        warn "A user-only Fightcade installation was detected."
        fail "This installer requires the system-wide Fightcade Flatpak. Remove the user installation first: flatpak uninstall --user ${APP_ID}"
    fi

    if [ "${INSTALL_FIGHTCADE}" -eq 1 ] || ask_yes_no "Install Fightcade system-wide from Flathub now?" "yes"; then
        install_fightcade_flatpak
    else
        info ""
        info "Install Fightcade from Batocera's Flatpak Manager, or run:"
        info "  flatpak install --system flathub ${APP_ID}"
        info ""
        fail "Fightcade Flatpak is required before the installer can continue."
    fi
fi

# Fetch and install ROM sync script and artwork
TMP_DIR=$(mktemp -d /tmp/fightcade-flatpak.XXXXXX)
trap 'rm -rf "${TMP_DIR}"' EXIT INT TERM

notice "Fetching ROM sync script and artwork..."
fetch_files "${TMP_DIR}"

mkdir -p "${PROJECT_DIR}"
install -m 0755 "${TMP_DIR}/fightcade-roms-sync" "${PROJECT_DIR}/fightcade-roms-sync"
ok "ROM sync script installed to ${PROJECT_DIR}"

# Apply Flatpak filesystem overrides
apply_overrides

# First sync
notice "Running initial ROM sync..."
"${PROJECT_DIR}/fightcade-roms-sync"

# Update ES games list
if command -v batocera-flatpak-update >/dev/null 2>&1; then
    notice "Updating EmulationStation Flatpak entries..."
    batocera-flatpak-update 2>/dev/null && ok "EmulationStation Flatpak entries updated" || \
        warn "batocera-flatpak-update did not complete cleanly; restart EmulationStation if Fightcade does not appear under Ports."
fi

# Install artwork
install_artwork

printf '\n'
printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Minimal installation complete (HD mode validation)'
printf '%s\n' '------------------------------------------------------------'
info ""
info "Fightcade Flatpak is installed with vanilla configuration."
info ""
info "This minimal installer provides:"
info "  - Fightcade Flatpak installation"
info "  - ROM folder symlinks"
info "  - EmulationStation artwork"
info ""
info "NOT included (for HD mode validation):"
info "  - Controller setup (fightcade-pad-mouse)"
info "  - Switchres CRT wrapper"
info "  - HD video presets"
info "  - Game hooks"
info ""
info "Drop Fightcade-format ROM sets (.zip with correct shortnames) into:"
info "  Arcade (FBNeo):  /userdata/roms/fbneo/"
info "  SNES:            /userdata/roms/snes/"
info "  Megadrive:       /userdata/roms/megadrive/"
info "  Naomi/AW:        /userdata/roms/naomi|naomi2|atomiswave/"
info "  Dreamcast:       /userdata/roms/dreamcast/  (Fightcade CHD format)"
info ""
info "For full installation with CRT support, use install-v1.sh"
info ""
