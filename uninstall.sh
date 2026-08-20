#!/bin/bash
# Uninstaller for the Fightcade Flatpak ROMs installer.
#
# Removes:
#   - Patched Flatpak xdg-open (restored from backup)
#   - CRT host watcher, Switchres wrapper, recovery helper, pad kbd blocker
#   - Game hook from /userdata/system/scripts/
#   - Managed symlinks under ROMs/ (arcade per-zip and dir links)
#   - Flatpak filesystem overrides for the managed host paths
#   - Installer scripts from /userdata/system/fightcade-flatpak/ (input/, crt/, etc.)
#
# Note: fightcade-pad-mouse may keep running until Fightcade is closed; the
# project dir is removed so it cannot restart after uninstall.
#
# Does NOT remove (default light uninstall):
#   - The Fightcade Flatpak itself (use --uninstall-flatpak to also remove it)
#   - Real ROMs or any user files
#   - The ROMs/ scaffold directories (real dirs remain so Fightcade still starts)
#
# Full wipe (--purge, implies --uninstall-flatpak) ALSO removes:
#   - The Flatpak app-data tree (config + downloaded game assets, hundreds of MB)
#   - The EmulationStation launcher entry, artwork, and gamelist node in ROMs/flatpak
#   - Fightcade logs (/userdata/system/logs) and configs (/userdata/system/configs)
#   - Orphaned flatpak runtimes (only when no other flatpak app remains)
#   - Dangling flatpak overrides and OSTree repo refs
#   Real ROMs under /userdata/roms/* and /userdata/bios are NEVER touched.

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
UNINSTALL_FLATPAK=0
PURGE=0

info()   { printf '%s\n'       "$*"; }
ok()     { printf '[ OK ] %s\n' "$*"; }
notice() { printf '[INFO] %s\n' "$*"; }
warn()   { printf '[WARN] %s\n' "$*"; }
fail()   { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<USAGE
Usage: uninstall.sh [options]

Options:
  -y, --yes               Accept all prompts automatically.
      --uninstall-flatpak Also uninstall the Fightcade Flatpak (com.fightcade.Fightcade).
      --purge, --all      Full wipe: remove the app, its data tree, launcher entry,
                          logs, configs, orphaned runtimes, and repo refs.
                          Implies --uninstall-flatpak. Keeps roms and bios.
  -h, --help              Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -y|--yes)               AUTO_YES=1 ;;
        --uninstall-flatpak)    UNINSTALL_FLATPAK=1 ;;
        --purge|--all)          PURGE=1; UNINSTALL_FLATPAK=1 ;;
        -h|--help)              usage; exit 0 ;;
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
printf '%s\n' ' Fightcade Flatpak ROMs Uninstaller'
printf '%s\n' '------------------------------------------------------------'
printf '\n'

ask_yes_no "Remove Fightcade Flatpak ROMs installer (links, hook, overrides, scripts)?" "yes" || {
    info "Uninstall cancelled."
    exit 0
}

# ---------------------------------------------------------------------------
# 0. CRT recovery + restore patched Flatpak xdg-open
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
# 1. Remove game hook
# ---------------------------------------------------------------------------
HOOK="${SCRIPTS_DIR}/fightcade-game-hook"
if [ -f "$HOOK" ]; then
    rm -f "$HOOK"
    ok "Removed game hook: ${HOOK}"
else
    notice "Game hook not found (already removed)"
fi

# ---------------------------------------------------------------------------
# 2. Remove managed dir symlinks
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
# 3. Remove managed arcade per-zip symlinks
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
# 3a. Remove managed Dreamcast per-file symlinks (ROMs/flycast/*.chd|.cdi)
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
# 3b. Remove _fightcade.txt requirement notes
# ---------------------------------------------------------------------------
notice "Removing _fightcade.txt notes..."

for sysdir in fbneo megadrive nes gamegear colecovision pcengine sg1000 msx1 \
              fds mastersystem zxspectrum supergrafx snes \
              atomiswave naomi naomi2 dreamcast; do
    rm -f "${HOST_ROMS}/${sysdir}/_fightcade.txt"
done

ok "_fightcade.txt notes removed"

# ---------------------------------------------------------------------------
# 4. Remove Flatpak filesystem overrides
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
# 5. Remove installer scripts
# ---------------------------------------------------------------------------
if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
    ok "Removed installer scripts: ${PROJECT_DIR}"
else
    notice "Project dir not found (already removed)"
fi

# ---------------------------------------------------------------------------
# 6. Optionally uninstall the Flatpak itself
# ---------------------------------------------------------------------------
if [ "${UNINSTALL_FLATPAK}" -eq 1 ]; then
    notice "Uninstalling Fightcade Flatpak..."
    if flatpak info --system "${APP_ID}" >/dev/null 2>&1; then
        flatpak uninstall --system -y "${APP_ID}" && ok "Fightcade Flatpak uninstalled" || \
            warn "Flatpak uninstall did not complete cleanly"
    else
        notice "Fightcade Flatpak was not installed system-wide; nothing to remove"
    fi
fi

# ---------------------------------------------------------------------------
# 7. Full purge (--purge): app data, ES launcher, logs, configs, runtimes, refs
#    Every deletion below is pinned to an exact Fightcade path. Real ROMs under
#    /userdata/roms/* and /userdata/bios are never touched.
# ---------------------------------------------------------------------------
if [ "${PURGE}" -eq 1 ]; then
    notice "Purging all remaining Fightcade data..."

    # Stop the pad-mouse daemon if it somehow survived the project-dir removal.
    if pkill -f fightcade-pad-mouse 2>/dev/null; then
        ok "Stopped fightcade-pad-mouse daemon"
    fi

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

    # Fightcade logs and configs.
    rm -f "${LOGS_DIR}"/fightcade-*.log \
          "${CONFIGS_DIR}"/fightcade-*.conf
    ok "Removed Fightcade logs and configs"

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
fi

printf '\n'
printf '%s\n' '------------------------------------------------------------'
printf '%s\n' ' Uninstall complete'
printf '%s\n' '------------------------------------------------------------'
info ""
if [ "${PURGE}" -eq 1 ]; then
    info "Full purge done. Fightcade, its app data, launcher, logs, configs,"
    info "and orphaned runtimes were removed. Your ROMs under /userdata/roms"
    info "and /userdata/bios were not touched."
else
    info "The ROMs scaffold directories under ROMs/ were left in place so"
    info "Fightcade can still start. Your actual ROM files are untouched."
    info "Run with --purge to also remove the app data, launcher, and runtimes."
fi
info ""
