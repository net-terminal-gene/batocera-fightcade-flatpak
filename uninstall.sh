#!/bin/bash
# Uninstaller for the Fightcade Flatpak installer.
#
# Completely removes Fightcade and all related files:
#   - All running Fightcade processes (switchres, emulators, daemons)
#   - The Fightcade Flatpak application
#   - Flatpak app-data tree (config + downloaded game assets)
#   - CRT host watcher, Switchres wrapper, recovery helper, pad kbd blocker
#   - Game hook from /userdata/system/scripts/
#   - ROM symlinks (arcade per-zip and dir links)
#   - Flatpak filesystem overrides
#   - Installer scripts from /userdata/system/fightcade-flatpak/
#   - EmulationStation launcher entry, artwork, and gamelist node
#   - Fightcade logs and configs
#   - Orphaned flatpak runtimes (only when no other flatpak app remains)
#   - Restarts EmulationStation so the removed entry + DEBUG toggle disappear
#
# Your ROM files under /userdata/roms/* and /userdata/bios are NEVER touched.

set -eu

APP_ID="com.fightcade.Fightcade"
PROJECT_DIR="/userdata/system/fightcade-flatpak"
SCRIPTS_DIR="/userdata/system/scripts"
FLATPAK_APP_ROOT="/userdata/saves/flatpak/data/.var/app/${APP_ID}"
FLATPAK_DATA="${FLATPAK_APP_ROOT}/data"
ROMS_ROOT="${FLATPAK_DATA}/ROMs"
HOST_ROMS="/userdata/roms"
FLATPAK_ROMS="/userdata/roms/flatpak"
FLATPAK_REPO="/userdata/saves/flatpak/binaries/repo"
FLATPAK_OVERRIDES="/userdata/saves/flatpak/binaries/overrides"
LOGS_DIR="/userdata/system/logs"
CONFIGS_DIR="/userdata/system/configs"

AUTO_YES=0

info()   { printf '%s\n'       "$*"; }
ok()     { printf '[ OK ] %s\n' "$*"; }
notice() { printf '[INFO] %s\n' "$*"; }
warn()   { printf '[WARN] %s\n' "$*"; }
fail()   { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<USAGE
Usage: uninstall.sh [options]

Completely removes Fightcade and all related files.
Your ROM files and BIOS are never touched.

Options:
  -y, --yes    Accept all prompts automatically.
  -h, --help   Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes) AUTO_YES=1 ;;
        -h|--help) usage; exit 0 ;;
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

printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Fightcade Flatpak Complete Removal'
printf '%s\n' '------------------------------------------------------------'
printf '\n'

ask_yes_no "Completely remove Fightcade and all related files? (ROMs/BIOS untouched)" "yes" || {
    info "Uninstall cancelled."
    exit 0
}

# ---------------------------------------------------------------------------
# 0. Kill all running Fightcade processes
# ---------------------------------------------------------------------------
notice "Stopping all Fightcade processes..."
pkill -f fightcade-crt-switchres 2>/dev/null || true
pkill -f fightcade-crt-hostd 2>/dev/null || true
pkill -f fightcade-pad-mouse 2>/dev/null || true
pkill -f fcadefbneo 2>/dev/null || true
pkill -f fcadesnes9x 2>/dev/null || true
pkill -f flycast 2>/dev/null || true
sleep 1
ok "All Fightcade processes stopped"

# ---------------------------------------------------------------------------
# 1. CRT recovery + restore patched Flatpak xdg-open
# ---------------------------------------------------------------------------
CRT_RECOVER="${PROJECT_DIR}/crt/fightcade-crt-recover"
LEGACY_CRT_RECOVER="${PROJECT_DIR}/fightcade-crt-recover"
LEGACY_WATCH="${PROJECT_DIR}/fightcade-crt-watch"

if [ -x "$CRT_RECOVER" ]; then
    "$CRT_RECOVER" 2>/dev/null || true
    ok "CRT recovery run"
elif [ -x "$LEGACY_CRT_RECOVER" ]; then
    "$LEGACY_CRT_RECOVER" 2>/dev/null || true
    ok "CRT recovery run (legacy path)"
elif [ -x "$LEGACY_WATCH" ]; then
    "$LEGACY_WATCH" stop 2>/dev/null || true
    ok "Legacy CRT watcher stopped"
fi
rm -f /tmp/fightcade-crt-watch.pid /tmp/fightcade-crt-watch.state \
      /tmp/fightcade-crt-watch.lock /tmp/fightcade-switchres-wrap.lock

deploy=$(flatpak info --system --show-location "${APP_ID}" 2>/dev/null || true)
if [ -n "$deploy" ]; then
    xdg_open="${deploy}/files/bin/xdg-open"
    backup="${xdg_open}.fc-original"
    if [ -f "$backup" ]; then
        mv -f "$backup" "$xdg_open"
        chmod 0755 "$xdg_open"
        ok "Restored Flatpak xdg-open from backup"
    fi
fi

# ---------------------------------------------------------------------------
# 2. Remove game hook
# ---------------------------------------------------------------------------
HOOK="${SCRIPTS_DIR}/fightcade-game-hook"
if [ -f "$HOOK" ]; then
    rm -f "$HOOK"
    ok "Removed game hook: ${HOOK}"
else
    notice "Game hook not found (already removed)"
fi

# ---------------------------------------------------------------------------
# 3. Remove managed dir symlinks
# ---------------------------------------------------------------------------
notice "Removing managed dir symlinks..."

remove_managed_link() {
    local link="$1"
    local expected_target="$2"
    if [ -L "$link" ]; then
        actual=$(readlink "$link")
        if [ "$actual" = "$expected_target" ]; then
            rm "$link"
            notice "removed: $link"
        else
            warn "skipping $link — unexpected target '$actual' (not managed)"
        fi
    fi
}

remove_managed_link "${ROMS_ROOT}/snes9x"              "${HOST_ROMS}/snes"
remove_managed_link "${ROMS_ROOT}/fbneo/megadrive"     "${HOST_ROMS}/megadrive"
remove_managed_link "${ROMS_ROOT}/fbneo/nes"           "${HOST_ROMS}/nes"
remove_managed_link "${ROMS_ROOT}/fbneo/gamegear"      "${HOST_ROMS}/gamegear"
remove_managed_link "${ROMS_ROOT}/fbneo/coleco"        "${HOST_ROMS}/colecovision"
remove_managed_link "${ROMS_ROOT}/fbneo/pce"           "${HOST_ROMS}/pcengine"
remove_managed_link "${ROMS_ROOT}/fbneo/sg1000"        "${HOST_ROMS}/sg1000"
remove_managed_link "${ROMS_ROOT}/fbneo/msx"           "${HOST_ROMS}/msx1"
remove_managed_link "${ROMS_ROOT}/fbneo/nes_fds"       "${HOST_ROMS}/fds"
remove_managed_link "${ROMS_ROOT}/fbneo/sms"           "${HOST_ROMS}/mastersystem"
remove_managed_link "${ROMS_ROOT}/fbneo/spectrum"      "${HOST_ROMS}/zxspectrum"
remove_managed_link "${ROMS_ROOT}/fbneo/sgx"           "${HOST_ROMS}/supergrafx"
remove_managed_link "${ROMS_ROOT}/fbneo/tg16"          "${HOST_ROMS}/pcengine"
remove_managed_link "${ROMS_ROOT}/flycast/atomiswave"  "${HOST_ROMS}/atomiswave"
remove_managed_link "${ROMS_ROOT}/flycast/naomi"       "${HOST_ROMS}/naomi"
remove_managed_link "${ROMS_ROOT}/flycast/naomi2"      "${HOST_ROMS}/naomi2"
# Legacy Dreamcast dir symlink (replaced by per-file links at flycast root).
remove_managed_link "${ROMS_ROOT}/flycast/dreamcast"   "${HOST_ROMS}/dreamcast"

ok "Dir symlinks removed"

# ---------------------------------------------------------------------------
# 4. Remove managed arcade per-zip symlinks
# ---------------------------------------------------------------------------
notice "Removing managed arcade per-zip symlinks..."
arcade_removed=0

if [ -d "${ROMS_ROOT}/fbneo" ]; then
    for dst_link in "${ROMS_ROOT}/fbneo"/*.zip; do
        [ -L "$dst_link" ] || continue
        target=$(readlink "$dst_link")
        case "$target" in
            "${HOST_ROMS}/fbneo/"*)
                rm "$dst_link"
                arcade_removed=$((arcade_removed + 1))
                ;;
        esac
    done
fi

ok "Arcade symlinks removed: ${arcade_removed}"

# ---------------------------------------------------------------------------
# 4a. Remove managed Dreamcast per-file symlinks (ROMs/flycast/*.chd|.cdi)
# ---------------------------------------------------------------------------
notice "Removing managed Dreamcast per-file symlinks..."
dc_removed=0

if [ -d "${ROMS_ROOT}/flycast" ]; then
    for dst_link in "${ROMS_ROOT}/flycast"/*.{chd,cdi}; do
        [ -L "$dst_link" ] || continue
        target=$(readlink "$dst_link")
        case "$target" in
            "${HOST_ROMS}/dreamcast/"*)
                rm "$dst_link"
                dc_removed=$((dc_removed + 1))
                ;;
        esac
    done
fi

ok "Dreamcast symlinks removed: ${dc_removed}"

# ---------------------------------------------------------------------------
# 4b. Remove _fightcade.txt requirement notes
# ---------------------------------------------------------------------------
notice "Removing _fightcade.txt notes..."

for sysdir in fbneo megadrive nes gamegear colecovision pcengine sg1000 msx1 \
              fds mastersystem zxspectrum supergrafx snes \
              atomiswave naomi naomi2 dreamcast; do
    rm -f "${HOST_ROMS}/${sysdir}/_fightcade.txt"
done

ok "_fightcade.txt notes removed"

# ---------------------------------------------------------------------------
# 5. Remove Flatpak filesystem overrides
# ---------------------------------------------------------------------------
notice "Removing Flatpak filesystem overrides..."

local_paths=(
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

for path in "${local_paths[@]}"; do
    flatpak override --system --nofilesystem="${path}" "${APP_ID}" 2>/dev/null || true
done

# Drop the forced-vsync env override applied by install.sh.
flatpak override --system --unset-env=vblank_mode "${APP_ID}" 2>/dev/null || true

ok "Flatpak overrides removed"

# ---------------------------------------------------------------------------
# 6. Remove installer scripts
# ---------------------------------------------------------------------------
if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
    ok "Removed installer scripts: ${PROJECT_DIR}"
else
    notice "Project dir not found (already removed)"
fi

# ---------------------------------------------------------------------------
# 7. Uninstall the Fightcade Flatpak application (not Flatpak itself)
# ---------------------------------------------------------------------------
notice "Uninstalling Fightcade Flatpak application..."
if flatpak info --system "${APP_ID}" >/dev/null 2>&1; then
    flatpak uninstall --system -y "${APP_ID}" && ok "Fightcade Flatpak application uninstalled" || \
        warn "Flatpak uninstall did not complete cleanly"
else
    notice "Fightcade Flatpak was not installed system-wide; nothing to remove"
fi

# ---------------------------------------------------------------------------
# 8. Remove app data, ES launcher, logs, configs, runtimes, refs
#    Every deletion below is pinned to an exact Fightcade path. Real ROMs under
#    /userdata/roms/* and /userdata/bios are never touched.
# ---------------------------------------------------------------------------
notice "Removing all remaining Fightcade data..."

# Flatpak app-data tree: config + everything Fightcade downloaded (game assets).
if [ -d "$FLATPAK_APP_ROOT" ]; then
    rm -rf "$FLATPAK_APP_ROOT"
    ok "Removed Flatpak app data: ${FLATPAK_APP_ROOT}"
else
    notice "Flatpak app data already absent"
fi

# EmulationStation launcher entry + artwork + stale gamelist backup.
rm -f "${FLATPAK_ROMS}/Fightcade.flatpak" \
      "${FLATPAK_ROMS}/images/Fightcade-logo.png" \
      "${FLATPAK_ROMS}/images/Fightcade-thumb.png" \
      "${FLATPAK_ROMS}/images/Fightcade.png" \
      "${FLATPAK_ROMS}/gamelist.xml.bak"
ok "Removed EmulationStation launcher entry and artwork"

# Drop the Fightcade <game> node from the flatpak gamelist (keep the file so
# the ES Flatpak system stays valid for other apps).
if [ -f "${FLATPAK_ROMS}/gamelist.xml" ] && \
   grep -q "Fightcade.flatpak" "${FLATPAK_ROMS}/gamelist.xml"; then
    cat > "${FLATPAK_ROMS}/gamelist.xml" <<'XML'
<?xml version="1.0"?>
<gameList>
	<game>
		<lang>en</lang>
	</game>
</gameList>
XML
    ok "Cleaned Fightcade entry from ${FLATPAK_ROMS}/gamelist.xml"
fi

# Fightcade logs, collected debug reports, and configs.
rm -f "${LOGS_DIR}"/fightcade-*.log \
      "${LOGS_DIR}"/fightcade-debug-*.txt \
      "${LOGS_DIR}"/fightcade-collect-*.tar.gz \
      "${CONFIGS_DIR}"/fightcade-*.conf
ok "Removed Fightcade logs and configs"

# Additive ES feature file (the Debug Logging toggle). Removing it drops the
# toggle from Advanced Game Options on the next ES restart.
rm -f "${CONFIGS_DIR}/emulationstation/es_features_fightcade.cfg"
ok "Removed ES Debug toggle feature file"

# CLI tool symlinks in /usr/bin.
for tool in fightcade-pad-mouse fightcade-cursor fightcade-lobby-zoom \
            fightcade-diagnose fightcade-collect-logs; do
    [ -L "/usr/bin/${tool}" ] && rm -f "/usr/bin/${tool}"
done

# Remove orphaned flatpak runtimes (Wine + Freedesktop pulled in for Fightcade),
# but only when no other flatpak app remains, so we never break another app.
if [ -z "$(flatpak list --app --columns=application 2>/dev/null)" ]; then
    flatpak uninstall --system --unused -y >/dev/null 2>&1 || true
    ok "Removed unused flatpak runtimes"
else
    notice "Other flatpak apps present; kept shared runtimes"
fi

# Dangling override + OSTree repo refs left behind after the app is gone.
rm -f "${FLATPAK_OVERRIDES}/${APP_ID}"
rm -rf "${FLATPAK_REPO}/refs/heads/deploy/app/${APP_ID}" \
       "${FLATPAK_REPO}/refs/heads/deploy/runtime/${APP_ID}.Locale" \
       "${FLATPAK_REPO}/refs/remotes/flathub/app/${APP_ID}" \
       "${FLATPAK_REPO}/refs/remotes/flathub/runtime/${APP_ID}.Locale"
flatpak repair --system >/dev/null 2>&1 || true
ok "Removed dangling flatpak refs and pruned repo"

printf '\n'
printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Complete removal finished'
printf '%s\n' '------------------------------------------------------------'
info ""
info "Fightcade has been completely removed, including:"
info "  - The Fightcade Flatpak application (com.fightcade.Fightcade)"
info "  - All configuration and downloaded game assets"
info "  - ROM symlinks and installer scripts"
info "  - Game hooks, logs, and configs"
info "  - EmulationStation launcher entry"
info ""
info "Flatpak itself remains available for other applications."
info "Your ROM files under /userdata/roms and /userdata/bios were not touched."
info ""
info "You can reinstall anytime with:"
info "  curl -fsSL https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh | bash -s -- -y"
info ""

# ---------------------------------------------------------------------------
# 9. Restart EmulationStation last, after all output above has printed.
#    ES only reads gamelist.xml and es_features_*.cfg at startup, so the removed
#    Fightcade launcher entry and the DEBUG LOGGING toggle would otherwise linger
#    in the running UI until the next restart. killall -9 is the reliable path on
#    Batocera: the init supervisor immediately respawns ES clean. Guard on ES
#    actually running so uninstalling from a pure SSH session does not error.
# ---------------------------------------------------------------------------
if pgrep -f emulationstation >/dev/null 2>&1; then
    notice "Restarting EmulationStation to drop the Fightcade entry and DEBUG toggle..."
    killall -9 emulationstation 2>/dev/null || true
    ok "EmulationStation restarted"
else
    notice "EmulationStation is not running; changes apply on next ES start"
fi
