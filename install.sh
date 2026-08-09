#!/bin/bash
set -eu

REPO="net-terminal-gene/batocera-fightcade-flatpak"
BRANCH="${FIGHTCADE_FLATPAK_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
APP_ID="com.fightcade.Fightcade"
PROJECT_DIR="/userdata/system/fightcade-flatpak"
SCRIPTS_DIR="/userdata/system/scripts"
LOG_DIR="/userdata/system/logs"

# Files fetched from the repo and installed to PROJECT_DIR.
FILES="install.sh fightcade-roms-sync fightcade-game-hook fightcade-crt-watch fightcade-diagnose uninstall.sh"

# Artwork fetched from the repo and installed to the ES flatpak images dir.
ART_FILE="Fightcade-image.png"
FLATPAK_ROMS_DIR="/userdata/roms/flatpak"
GAMELIST="${FLATPAK_ROMS_DIR}/gamelist.xml"
ES_SERVER="http://127.0.0.1:1234"

AUTO_YES=0
INSTALL_FIGHTCADE=0

info()   { printf '%s\n'       "$*"; }
notice() { printf '[INFO] %s\n' "$*"; }
ok()     { printf '[ OK ] %s\n' "$*"; }
warn()   { printf '[WARN] %s\n' "$*"; }
fail()   { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<USAGE
Usage: install.sh [options]

Options:
  -y, --yes                 Accept all prompts automatically.
      --install-fightcade   Install Fightcade Flatpak if missing.
  -h, --help                Show this help.

Environment:
  FIGHTCADE_FLATPAK_BRANCH  GitHub branch or tag to download from (default: main).
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes)                AUTO_YES=1 ;;
        --install-fightcade)     INSTALL_FIGHTCADE=1 ;;
        -h|--help)               usage; exit 0 ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift
done

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

is_local_source() {
    [ -n "${BASH_SOURCE[0]:-}" ] && \
    [ -f "${BASH_SOURCE[0]}" ] && \
    [ -f "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/fightcade-roms-sync" ]
}

# curl | bash feeds the script on stdin. While flatpak install runs for several
# minutes, that pipe + Flatpak's progress-bar terminal control sequences can
# leave bash with a truncated script (everything after flatpak never runs).
# Bootstrap: download this script to a temp file and re-exec from disk.
bootstrap_off_pipe_if_needed() {
    [ -n "${FIGHTCADE_INSTALL_BOOTSTRAPPED:-}" ] && return 0
    is_local_source && return 0

    command -v curl >/dev/null 2>&1 || fail "curl is required for direct GitHub installation."

    local bootstrap
    bootstrap=$(mktemp /tmp/fightcade-flatpak-install.XXXXXX.sh)
    curl -fsSL --retry 3 --connect-timeout 15 \
        "${RAW_BASE}/install.sh" -o "${bootstrap}" \
        || fail "Could not download install.sh from ${RAW_BASE}."
    chmod +x "${bootstrap}"
    export FIGHTCADE_INSTALL_BOOTSTRAPPED=1

    # "$@" is empty here (args were already parsed above); rebuild flags.
    local reexec_args=()
    [ "${AUTO_YES}" -eq 1 ] && reexec_args+=(-y)
    [ "${INSTALL_FIGHTCADE}" -eq 1 ] && reexec_args+=(--install-fightcade)
    exec bash "${bootstrap}" "${reexec_args[@]}"
}

fetch_files() {
    local destination="$1"
    local file source_dir
    mkdir -p "${destination}"

    if is_local_source; then
        source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        for file in ${FILES} ${ART_FILE}; do
            cp "${source_dir}/${file}" "${destination}/${file}"
        done
    else
        command -v curl >/dev/null 2>&1 || fail "curl is required for direct GitHub installation."
        for file in ${FILES} ${ART_FILE}; do
            curl -fsSL --retry 3 --connect-timeout 15 \
                "${RAW_BASE}/${file}" -o "${destination}/${file}" \
                || fail "Could not download ${file} from ${RAW_BASE}."
        done
    fi
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
    notice "Flatpak output logged to ${log}"

    # Plain progress avoids the animated bar that corrupts SSH sessions.
    export FLATPAK_PROGRESS=plain
    if flatpak install --system -y flathub "${APP_ID}" >>"${log}" 2>&1; then
        if flatpak info --system "${APP_ID}" >/dev/null 2>&1; then
            ok "Fightcade Flatpak installed system-wide"
        else
            fail "Flatpak reported success but the system-wide Fightcade installation could not be verified. See ${log}"
        fi
    else
        fail "Fightcade could not be installed. See ${log} or install via Batocera's Flatpak Manager and run this installer again."
    fi
}

# ---------------------------------------------------------------------------
# Flatpak filesystem overrides required for every linked host path.
# ---------------------------------------------------------------------------

apply_overrides() {
    notice "Applying Flatpak filesystem overrides..."

    local paths
    paths=(
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

# ---------------------------------------------------------------------------
# Artwork + gamelist.xml for the ES Ports entry.
# batocera-flatpak-update installs the app icon as images/Fightcade.png; we add
# the splash artwork (Fightcade-image.png) and a gamelist entry pointing at it.
# ---------------------------------------------------------------------------

fightcade_game_entry() {
    cat <<'ENTRY'
  <game>
    <path>./Fightcade.flatpak</path>
    <name>Fightcade</name>
    <image>./images/Fightcade-image.png</image>
    <thumbnail>./images/Fightcade.png</thumbnail>
  </game>
ENTRY
}

install_artwork() {
    notice "Installing Fightcade artwork..."

    mkdir -p "${FLATPAK_ROMS_DIR}/images"
    install -m 0644 "${TMP_DIR}/${ART_FILE}" "${FLATPAK_ROMS_DIR}/images/${ART_FILE}"
    ok "Artwork installed: ${FLATPAK_ROMS_DIR}/images/${ART_FILE}"

    if [ ! -f "${GAMELIST}" ]; then
        {
            printf '%s\n' '<?xml version="1.0"?>'
            printf '%s\n' '<gameList>'
            fightcade_game_entry
            printf '%s\n' '</gameList>'
        } > "${GAMELIST}"
        ok "Created ${GAMELIST} with Fightcade entry"
    elif grep -q '<path>\./Fightcade\.flatpak</path>' "${GAMELIST}"; then
        notice "Existing gamelist already has a Fightcade entry; leaving it unchanged"
    else
        awk -v entry="$(fightcade_game_entry)" \
            '/<\/gameList>/ { print entry } { print }' \
            "${GAMELIST}" > "${GAMELIST}.tmp" && mv "${GAMELIST}.tmp" "${GAMELIST}"
        ok "Added Fightcade entry to existing ${GAMELIST}"
    fi

    # Update a running EmulationStation in place so the artwork shows without a
    # restart. ES merges by <path>, marks the entry dirty, and persists it.
    if command -v curl >/dev/null 2>&1; then
        es_payload="<gameList>$(fightcade_game_entry)</gameList>"
        if curl -s -m 5 -X POST \
            -H "Content-type: application/x-www-form-urlencoded" \
            "${ES_SERVER}/addgames/flatpak" \
            --data-binary "${es_payload}" >/dev/null 2>&1; then
            ok "EmulationStation entry updated with artwork"
        else
            notice "EmulationStation not reachable; artwork will show after the next ES restart"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

bootstrap_off_pipe_if_needed "$@"

printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Fightcade Flatpak ROMs Installer for Batocera'
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

# Fetch and install scripts
TMP_DIR=$(mktemp -d /tmp/fightcade-flatpak.XXXXXX)
trap 'rm -rf "${TMP_DIR}"' EXIT INT TERM

notice "Fetching scripts..."
fetch_files "${TMP_DIR}"

mkdir -p "${PROJECT_DIR}" "${SCRIPTS_DIR}" "${LOG_DIR}"

for file in ${FILES}; do
    install -m 0755 "${TMP_DIR}/${file}" "${PROJECT_DIR}/${file}"
done
ok "Scripts installed to ${PROJECT_DIR}"

# Install game hook into Batocera user scripts directory
install -m 0755 "${PROJECT_DIR}/fightcade-game-hook" "${SCRIPTS_DIR}/fightcade-game-hook"
ok "Game hook installed to ${SCRIPTS_DIR}/fightcade-game-hook"

# Apply Flatpak filesystem overrides
apply_overrides

# First sync
notice "Running initial ROM sync..."
"${PROJECT_DIR}/fightcade-roms-sync"

# Update ES games list so Fightcade appears in Ports if freshly installed
if command -v batocera-flatpak-update >/dev/null 2>&1; then
    notice "Updating EmulationStation Flatpak entries..."
    batocera-flatpak-update 2>/dev/null && ok "EmulationStation Flatpak entries updated" || \
        warn "batocera-flatpak-update did not complete cleanly; restart EmulationStation if Fightcade does not appear under Ports."
fi

# Install splash artwork and gamelist entry (after batocera-flatpak-update so
# the Fightcade.flatpak entry and icon already exist).
install_artwork

printf '\n'
printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Installation complete'
printf '%s\n' '------------------------------------------------------------'
info ""
info "Fightcade ROMs are now linked from /userdata/roms into the Flatpak data tree."
info ""
info "Drop Fightcade-format ROM sets (.zip with correct shortnames) into:"
info "  Arcade (FBNeo):  /userdata/roms/fbneo/"
info "  Megadrive:       /userdata/roms/megadrive/"
info "  SNES:            /userdata/roms/snes/"
info "  Naomi/AW:        /userdata/roms/naomi|naomi2|atomiswave/"
info "  Dreamcast:       /userdata/roms/dreamcast/  (Fightcade CHD format)"
info ""
info "Dreamcast note: the BIOS (dc_boot.bin, dc_flash.bin) must live at:"
info "  /userdata/saves/flatpak/data/.var/app/${APP_ID}/config/flycast/data/"
info ""
info "CRT (Switchres): on xorg CRT setups, games switch to their native"
info "modeline automatically via the configured monitor profile. Disable with:"
info "  touch /userdata/system/configs/fightcade-switchres.disable"
info ""
info "To check install state: ${PROJECT_DIR}/fightcade-diagnose"
info "To remove:              ${PROJECT_DIR}/uninstall.sh"
info ""
