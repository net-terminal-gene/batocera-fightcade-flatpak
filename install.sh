#!/bin/bash
set -eu

REPO="net-terminal-gene/batocera-fightcade-flatpak"
# Install from a GitHub branch before it merges to main (kept for maintainer use;
# not documented for end users). Keep the curl URL on main/install.sh; --branch (or
# FIGHTCADE_FLATPAK_BRANCH) selects which ref all files come from:
#   curl -fsSL https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh | bash -s -- -y --branch BRANCH
BRANCH="${FIGHTCADE_FLATPAK_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
APP_ID="com.fightcade.Fightcade"
PROJECT_DIR="/userdata/system/fightcade-flatpak"
INSTALL_BRANCH_FILE="${PROJECT_DIR}/.install-branch"
SCRIPTS_DIR="/userdata/system/scripts"
LOG_DIR="/userdata/system/logs"

# Files fetched from the repo and installed to PROJECT_DIR.
FILES="install.sh fightcade-roms-sync fightcade-game-hook fightcade-lobby-zoom input/fightcade-pad-mouse input/fightcade-pad-mouse.conf input/fightcade-lobby-chat.conf input/fightcade-cursor crt/fightcade-crt-block-pad-kbd crt/fightcade-crt-switchres crt/fightcade-crt-hostd crt/fightcade-crt-recover crt/patch-flatpak-xdg-open.sh hd/patch-hd-video.sh hd/presets/fcadefbneo.ini hd/presets/fcadesnes9x.conf hd/presets/flycast/emu.cfg emulationstation/es_features_fightcade.cfg fightcade-diagnose fightcade-collect-logs uninstall.sh"

# Artwork fetched from the repo and installed to the ES flatpak images dir.
ART_FILES="images/Fightcade.png images/Fightcade-logo.png images/Fightcade-thumb.png"
FLATPAK_ROMS_DIR="/userdata/roms/flatpak"
GAMELIST="${FLATPAK_ROMS_DIR}/gamelist.xml"
ES_SERVER="http://127.0.0.1:1234"

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
Usage: install.sh [options]

Options:
  -y, --yes                 Accept all prompts automatically.
      --install-fightcade   Install Fightcade Flatpak if missing.
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
    notice "Bootstrapping installer from ${RAW_BASE}/install.sh"
    curl -fsSL --retry 3 --connect-timeout 15 \
        "${RAW_BASE}/install.sh" -o "${bootstrap}" \
        || fail "Could not download install.sh from ${RAW_BASE}."
    chmod +x "${bootstrap}"
    export FIGHTCADE_INSTALL_BOOTSTRAPPED=1
    # Keep branch selection across re-exec even if the env was only on curl.
    export FIGHTCADE_FLATPAK_BRANCH="${BRANCH}"

    # "$@" is empty here (args were already parsed above); rebuild flags.
    local reexec_args=()
    [ "${AUTO_YES}" -eq 1 ] && reexec_args+=(-y)
    [ "${INSTALL_FIGHTCADE}" -eq 1 ] && reexec_args+=(--install-fightcade)
    reexec_args+=(--branch "${BRANCH}")
    exec bash "${bootstrap}" "${reexec_args[@]}"
}

fetch_files() {
    local destination="$1"
    local file source_dir dest_dir
    mkdir -p "${destination}"

    if is_local_source; then
        source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        for file in ${FILES} ${ART_FILES}; do
            dest_dir=$(dirname "${destination}/${file}")
            [ "${dest_dir}" != "${destination}" ] && mkdir -p "${dest_dir}"
            cp "${source_dir}/${file}" "${destination}/${file}"
        done
    else
        command -v curl >/dev/null 2>&1 || fail "curl is required for direct GitHub installation."
        for file in ${FILES} ${ART_FILES}; do
            dest_dir=$(dirname "${destination}/${file}")
            [ "${dest_dir}" != "${destination}" ] && mkdir -p "${dest_dir}"
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
    : >"${log}"
    notice "Flatpak progress below (also saved to ${log})"

    # Plain progress avoids the animated bar that corrupts SSH sessions.
    # tee keeps the console live while still writing the log.
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

# ---------------------------------------------------------------------------
# Flatpak filesystem overrides required for every linked host path.
# ---------------------------------------------------------------------------

flatpak_deploy_dir() {
    flatpak info --system --show-location "${APP_ID}" 2>/dev/null
}

patch_flatpak_xdg_open() {
    local patch_script="${PROJECT_DIR}/crt/patch-flatpak-xdg-open.sh"
    [ -x "${patch_script}" ] || fail "xdg-open patch script missing: ${patch_script}"
    "${patch_script}"
    ok "Patched Flatpak xdg-open for fcade:// Switchres wrapper"
}

migrate_input_layout() {
  local pd="$1" name
  mkdir -p "${pd}/input"
  for name in fightcade-pad-mouse fightcade-cursor; do
    if [ -f "${pd}/${name}" ] && [ ! -e "${pd}/input/${name}" ]; then
      mv "${pd}/${name}" "${pd}/input/${name}"
    fi
  done
}

migrate_crt_layout() {
  local pd="$1" name
  mkdir -p "${pd}/crt"
  for name in fightcade-crt-hostd fightcade-crt-recover fightcade-crt-block-pad-kbd; do
    if [ -f "${pd}/${name}" ] && [ ! -e "${pd}/crt/${name}" ]; then
      mv "${pd}/${name}" "${pd}/crt/${name}"
    fi
  done
  if [ -f "${pd}/switchres_fightcade_wrap.sh" ] && [ ! -e "${pd}/crt/fightcade-crt-switchres" ]; then
    mv "${pd}/switchres_fightcade_wrap.sh" "${pd}/crt/fightcade-crt-switchres"
  fi
  if [ -f "${pd}/crt/switchres_fightcade_wrap.sh" ] && [ ! -e "${pd}/crt/fightcade-crt-switchres" ]; then
    mv "${pd}/crt/switchres_fightcade_wrap.sh" "${pd}/crt/fightcade-crt-switchres"
  fi
  if [ -f "${pd}/crt/fightcade-switchres" ] && [ ! -e "${pd}/crt/fightcade-crt-switchres" ]; then
    mv "${pd}/crt/fightcade-switchres" "${pd}/crt/fightcade-crt-switchres"
  fi
}

migrate_hd_layout() {
  local pd="$1"
  mkdir -p "${pd}/hd"
  if [ -f "${pd}/crt/patch-hd-video.sh" ] && [ ! -e "${pd}/hd/patch-hd-video.sh" ]; then
    mv "${pd}/crt/patch-hd-video.sh" "${pd}/hd/patch-hd-video.sh"
  fi
  if [ -d "${pd}/crt/hd-presets" ] && [ ! -d "${pd}/hd/presets" ]; then
    mv "${pd}/crt/hd-presets" "${pd}/hd/presets"
  fi
}

remove_legacy_duplicates() {
  local pd="$1"
  if [ -x "${pd}/input/fightcade-pad-mouse" ] && [ -f "${pd}/fightcade-pad-mouse" ]; then
    rm -f "${pd}/fightcade-pad-mouse"
  fi
  if [ -x "${pd}/input/fightcade-cursor" ] && [ -f "${pd}/fightcade-cursor" ]; then
    rm -f "${pd}/fightcade-cursor"
  fi
  if [ -x "${pd}/crt/fightcade-crt-switchres" ] && [ -f "${pd}/switchres_fightcade_wrap.sh" ]; then
    rm -f "${pd}/switchres_fightcade_wrap.sh"
  fi
  if [ -x "${pd}/crt/fightcade-crt-hostd" ] && [ -f "${pd}/fightcade-crt-hostd" ]; then
    rm -f "${pd}/fightcade-crt-hostd"
  fi
  if [ -x "${pd}/crt/fightcade-crt-recover" ] && [ -f "${pd}/fightcade-crt-recover" ]; then
    rm -f "${pd}/fightcade-crt-recover"
  fi
  if [ -x "${pd}/hd/patch-hd-video.sh" ] && [ -f "${pd}/crt/patch-hd-video.sh" ]; then
    rm -f "${pd}/crt/patch-hd-video.sh"
  fi
  if [ -d "${pd}/hd/presets" ] && [ -d "${pd}/crt/hd-presets" ]; then
    rm -rf "${pd}/crt/hd-presets"
  fi
}

link_cli_tools() {
  local pd="$1"
  mkdir -p /usr/bin
  ln -sf "${pd}/input/fightcade-pad-mouse" /usr/bin/fightcade-pad-mouse
  ln -sf "${pd}/input/fightcade-cursor" /usr/bin/fightcade-cursor
  ln -sf "${pd}/fightcade-lobby-zoom" /usr/bin/fightcade-lobby-zoom
  ln -sf "${pd}/fightcade-diagnose" /usr/bin/fightcade-diagnose
  ln -sf "${pd}/fightcade-collect-logs" /usr/bin/fightcade-collect-logs
}

install_chat_config() {
  local src="${PROJECT_DIR}/input/fightcade-lobby-chat.conf"
  local dst="/userdata/system/configs/fightcade-lobby-chat.conf"
  local legacy="/userdata/system/configs/fightcade-pad-mouse-chat.conf"
  mkdir -p /userdata/system/configs
  if [ ! -f "${dst}" ]; then
    if [ -f "${legacy}" ]; then
      cp -a "${legacy}" "${dst}"
      ok "Fightcade lobby chat config migrated to ${dst}"
    else
      install -m 0644 "${src}" "${dst}"
      ok "Fightcade lobby chat config installed at ${dst}"
    fi
  else
    ok "Fightcade lobby chat config: ${dst} (unchanged)"
  fi
}

install_pad_mouse_config() {
  local src="${PROJECT_DIR}/input/fightcade-pad-mouse.conf"
  local dst="/userdata/system/configs/fightcade-pad-mouse.conf"
  mkdir -p /userdata/system/configs
  if [ ! -f "${dst}" ]; then
    install -m 0644 "${src}" "${dst}"
    ok "Fightcade pad-mouse config installed at ${dst}"
  else
    ok "Fightcade pad-mouse config: ${dst} (unchanged)"
  fi
}

seed_lobby_chat_settings() {
  # Seed the per-game EDIT LOBBY CHAT keys from the current chat config so the
  # Advanced Game Options fields show the active macros instead of blanks. Only
  # seed a key that is ABSENT so a value the user already set in ES is never
  # clobbered, and the first launch after install does not wipe the defaults.
  local conf="/userdata/system/configs/fightcade-lobby-chat.conf"
  local bconf="/userdata/system/batocera.conf"
  local slot key val line seeded=0
  [ -f "${conf}" ] || return 0
  command -v batocera-settings-set >/dev/null 2>&1 || return 0
  for slot in south east west north r2; do
    key="flatpak[\"Fightcade.flatpak\"].fclobby_${slot}"
    grep -Fq -- "${key}=" "${bconf}" 2>/dev/null && continue
    line=$(grep -E "^${slot}=" "${conf}" | tail -1) || true
    [ -n "${line}" ] || continue
    val="${line#*=}"
    batocera-settings-set "${key}" "${val}" 2>/dev/null || true
    seeded=1
  done
  [ "${seeded}" -eq 1 ] && ok "EDIT LOBBY CHAT fields seeded from ${conf}" || true
}

ES_FEATURES_CHANGED=0
install_es_features() {
  # Batocera merges es_features_*.cfg from this dir with the system es_features.cfg
  # at EmulationStation startup. Dropping our additive file here adds the per-game
  # "Debug Logging" toggle to the flatpak emulator's Advanced Game Options without
  # touching the read-only /usr/share copy. ES only reads it at startup, so a change
  # here means ES must be restarted for the toggle to appear/update.
  local src="${PROJECT_DIR}/emulationstation/es_features_fightcade.cfg"
  local dir="/userdata/system/configs/emulationstation"
  local dst="${dir}/es_features_fightcade.cfg"
  [ -f "${src}" ] || { warn "es_features_fightcade.cfg missing; Debug toggle will not appear"; return 0; }
  mkdir -p "${dir}"
  if [ -f "${dst}" ] && cmp -s "${src}" "${dst}"; then
    ok "ES Debug toggle feature: ${dst} (unchanged)"
  else
    install -m 0644 "${src}" "${dst}"
    ES_FEATURES_CHANGED=1
    ok "ES Debug toggle feature installed at ${dst}"
  fi
}

restart_emulationstation() {
  # killall -9 is the reliable path on Batocera: the init supervisor immediately
  # respawns ES clean. Only fire when ES is actually running so installing from a
  # pure SSH session (no ES up) does not error, and only when the feature file
  # changed so re-running the installer does not needlessly yank the user home.
  if ! pgrep -f emulationstation >/dev/null 2>&1; then
    notice "EmulationStation is not running; the Debug toggle appears on next ES start"
    return 0
  fi
  notice "Restarting EmulationStation to enable the Debug toggle..."
  killall -9 emulationstation 2>/dev/null || true
  ok "EmulationStation restarted"
}

stop_legacy_crt_watch() {
    local legacy="${PROJECT_DIR}/fightcade-crt-watch"
    if [ -x "${legacy}" ]; then
        "${legacy}" stop 2>/dev/null || true
        rm -f "${legacy}"
        ok "Removed legacy fightcade-crt-watch log daemon"
    fi
    rm -f /tmp/fightcade-crt-watch.pid /tmp/fightcade-crt-watch.lock \
          /tmp/fightcade-crt-watch.state /tmp/fightcade-crt-watch.pause
}

apply_overrides() {
    notice "Applying Flatpak filesystem overrides..."

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

    # Snes9x renders through Wine DirectDraw (ddraw -> wined3d -> Mesa), and its vsync
    # request does not survive that translation, which tears on CRT. vblank_mode=3 is
    # Mesa's "force vsync on", applied regardless of what the application asks for.
    if flatpak override --system --env=vblank_mode=3 "${APP_ID}" 2>/dev/null; then
        ok "Forced vsync override applied (vblank_mode=3)"
    else
        warn "Could not apply vblank_mode override; SNES may tear on CRT"
    fi
}

# ---------------------------------------------------------------------------
# Artwork + gamelist.xml for the ES Ports entry.
# batocera-flatpak-update may install images/Fightcade.png from the Flatpak icon;
# we ship Fightcade.png (logo), Fightcade-logo.png (marquee), and
# Fightcade-thumb.png (thumbnail splash) and wire gamelist.xml to match.
# ---------------------------------------------------------------------------

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
        notice "Existing gamelist has a Fightcade entry; refreshing artwork via EmulationStation"
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

record_install_branch() {
    mkdir -p "${PROJECT_DIR}"
    printf '%s\n' "${BRANCH}" > "${INSTALL_BRANCH_FILE}"
}

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
migrate_input_layout "${PROJECT_DIR}"
migrate_crt_layout "${PROJECT_DIR}"
migrate_hd_layout "${PROJECT_DIR}"
remove_legacy_duplicates "${PROJECT_DIR}"

# install(1) does not create missing parent dirs; nested FILES like
# hd/presets/... and hd/presets/flycast/... need mkdir -p first.
for file in ${FILES}; do
    dest_dir=$(dirname "${PROJECT_DIR}/${file}")
    mkdir -p "${dest_dir}"
    case "${file}" in
        *.ini|*.conf|*/emu.cfg) mode=0644 ;;
        *) mode=0755 ;;
    esac
    install -m "${mode}" "${TMP_DIR}/${file}" "${PROJECT_DIR}/${file}"
done
record_install_branch
link_cli_tools "${PROJECT_DIR}"
install_chat_config
seed_lobby_chat_settings
install_pad_mouse_config
install_es_features
ok "Scripts installed to ${PROJECT_DIR}"

# Install game hook into Batocera user scripts directory
install -m 0755 "${PROJECT_DIR}/fightcade-game-hook" "${SCRIPTS_DIR}/fightcade-game-hook"
ok "Game hook installed to ${SCRIPTS_DIR}/fightcade-game-hook"

# Apply Flatpak filesystem overrides
apply_overrides

# Patch Flatpak xdg-open (fcade:// intercept; re-applied after Flatpak updates)
patch_flatpak_xdg_open
stop_legacy_crt_watch

# First sync
notice "Running initial ROM sync..."
"${PROJECT_DIR}/fightcade-roms-sync"

if [ -x "${PROJECT_DIR}/hd/patch-hd-video.sh" ]; then
    notice "Applying HD video defaults (FBNeo, SNES9x, Flycast)..."
    "${PROJECT_DIR}/hd/patch-hd-video.sh" && ok "HD video defaults applied" || \
        warn "HD video patch did not complete; re-run ${PROJECT_DIR}/hd/patch-hd-video.sh"
fi

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
info "CRT (Switchres): on xorg CRT setups, fcade:// launches are wrapped for"
info "native-resolution switching (no log daemon). Disable with:"
info "  touch /userdata/system/configs/fightcade-switchres.disable"
info "Recovery after a stuck display:"
info "  ${PROJECT_DIR}/crt/fightcade-crt-recover"
info ""
info "To check install state: ${PROJECT_DIR}/fightcade-diagnose"
info "To collect debug logs:  ${PROJECT_DIR}/fightcade-collect-logs        (snapshot)"
info "                        ${PROJECT_DIR}/fightcade-collect-logs --watch 300  (before reproducing)"
info "To remove:              ${PROJECT_DIR}/uninstall.sh"
info ""

# Last step: only restart ES when the feature file changed, so the Debug toggle
# is live immediately without needlessly interrupting re-runs.
if [ "${ES_FEATURES_CHANGED}" -eq 1 ]; then
    restart_emulationstation
fi
