#!/bin/bash
# Apply HD monitor video defaults for Fightcade Flatpak emulators (LCD / HDMI).
# Detects the current display resolution and sets fullscreen, aspect, and vsync.
# CRT / Switchres sessions override these temporarily during native-res gameplay.

set -euo pipefail

APP_ID="com.fightcade.Fightcade"
FC_DATA="/userdata/saves/flatpak/data/.var/app/${APP_ID}/data"
FBNEO_INI="${FC_DATA}/config/fcadefbneo/fcadefbneo.ini"
SNES_CONF="${FC_DATA}/config/snes9x/fcadesnes9x.conf"
FLYCAST_CFG="${FC_DATA}/config/flycast/emu.cfg"
GGPO_INI="${FC_DATA}/config/ggpofba/ggpofba.ini"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PRESETS_DIR="${SCRIPT_DIR}/presets"

HD_WIDTH=1920
HD_HEIGHT=1080

log() { printf 'patch-hd-video: %s\n' "$*"; }

detect_display_resolution() {
    local raw w h

    if command -v batocera-resolution >/dev/null 2>&1; then
        raw=$(DISPLAY=:0 batocera-resolution currentResolution 2>/dev/null | head -n1 | tr -d '[:space:]')
    fi
    if [ -z "$raw" ] && command -v xrandr >/dev/null 2>&1; then
        raw=$(DISPLAY=:0 xrandr --currentResolution 2>/dev/null | tail -n1 | awk '{print $1}')
    fi
    if [ -z "$raw" ] && command -v xrandr >/dev/null 2>&1; then
        raw=$(DISPLAY=:0 xrandr --query 2>/dev/null | awk '/\*/{print $1; exit}')
    fi

    if [[ "$raw" =~ ^([0-9]+)x([0-9]+) ]]; then
        w="${BASH_REMATCH[1]}"
        h="${BASH_REMATCH[2]}"
        if [ "$w" -ge 640 ] && [ "$h" -ge 480 ]; then
            HD_WIDTH="$w"
            HD_HEIGHT="$h"
        fi
    fi

    log "display resolution: ${HD_WIDTH}x${HD_HEIGHT}"
}

install_hd_preset() {
    local preset="$1" dest="$2"
    local dest_dir

    [ -f "$preset" ] || return 0
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"
    if [ ! -f "$dest" ]; then
        cp "$preset" "$dest"
        log "installed preset $(basename "$dest")"
    fi
}

install_hd_presets() {
    install_hd_preset "${PRESETS_DIR}/fcadefbneo.ini" "$FBNEO_INI"
    install_hd_preset "${PRESETS_DIR}/fcadesnes9x.conf" "$SNES_CONF"
    install_hd_preset "${PRESETS_DIR}/flycast/emu.cfg" "$FLYCAST_CFG"
}

patch_fbneo_hd_ini() {
    local ini="$1"
    [ -f "$ini" ] || { log "skip fbneo (no ini; preset missing from ${PRESETS_DIR})"; return 0; }
    sed -i "s/^nVidHorWidth .*/nVidHorWidth ${HD_WIDTH}/" "$ini"
    sed -i "s/^nVidHorHeight .*/nVidHorHeight ${HD_HEIGHT}/" "$ini"
    sed -i "s/^nVidVerWidth .*/nVidVerWidth ${HD_WIDTH}/" "$ini"
    sed -i "s/^nVidVerHeight .*/nVidVerHeight ${HD_HEIGHT}/" "$ini"
    sed -i 's/^bVidFullStretch .*/bVidFullStretch 0/' "$ini"
    sed -i 's/^bVidCorrectAspect .*/bVidCorrectAspect 1/' "$ini"
    sed -i 's/^bVidAutoSwitchFull .*/bVidAutoSwitchFull 0/' "$ini"
    sed -i 's/^bVidDX9WinFullscreen .*/bVidDX9WinFullscreen 0/' "$ini"
    sed -i 's/^bVidArcaderesHor .*/bVidArcaderesHor 0/' "$ini"
    sed -i 's/^bVidArcaderesVer .*/bVidArcaderesVer 0/' "$ini"
    sed -i 's/^bMonitorAutoCheck .*/bMonitorAutoCheck 1/' "$ini"
    sed -i 's/^bVidVSync .*/bVidVSync 1/' "$ini"
    sed -i 's/^bVidTripleBuffer .*/bVidTripleBuffer 1/' "$ini"
    sed -i 's/^nWindowPosX .*/nWindowPosX 0/' "$ini"
    sed -i 's/^nWindowPosY .*/nWindowPosY 0/' "$ini"
    log "fbneo ini: ${HD_WIDTH}x${HD_HEIGHT}, correct aspect, windowed menu, vsync"
}

patch_ggpofba_hd_ini() {
    local ini="$1"
    [ -f "$ini" ] || return 0
    sed -i 's/^bVidVSync .*/bVidVSync 1/' "$ini"
    sed -i 's/^bVidTripleBuffer .*/bVidTripleBuffer 1/' "$ini"
    log "ggpofba ini: vsync on"
}

patch_snes9x_hd_conf() {
    local conf="$1"
    [ -f "$conf" ] || { log "skip snes9x (no conf; preset missing from ${PRESETS_DIR})"; return 0; }
    sed -i 's/^\([[:space:]]*Fullscreen:Enabled[[:space:]]*=\).*/\1 TRUE/' "$conf"
    sed -i "s/^\([[:space:]]*Fullscreen:Width[[:space:]]*=\).*/\1 ${HD_WIDTH}/" "$conf"
    sed -i "s/^\([[:space:]]*Fullscreen:Height[[:space:]]*=\).*/\1 ${HD_HEIGHT}/" "$conf"
    sed -i 's/^\([[:space:]]*Fullscreen:Depth[[:space:]]*=\).*/\1 32/' "$conf"
    sed -i 's/^\([[:space:]]*Fullscreen:EmulateFullscreen[[:space:]]*=\).*/\1 TRUE/' "$conf"
    sed -i 's/^\([[:space:]]*HideMenu[[:space:]]*=\).*/\1 TRUE/' "$conf"
    sed -i 's/^\([[:space:]]*Stretch:MaintainAspectRatio[[:space:]]*=\).*/\1 TRUE/' "$conf"
    sed -i 's/^\([[:space:]]*Stretch:AspectRatioBaseWidth[[:space:]]*=\).*/\1 299/' "$conf"
    sed -i 's/^\([[:space:]]*Stretch:BilinearFilter[[:space:]]*=\).*/\1 FALSE/' "$conf"
    sed -i 's/^\([[:space:]]*Vsync[[:space:]]*=\).*/\1 TRUE/' "$conf"
    sed -i 's/^Lock .*/Lock          = TRUE/' "$conf"
    log "snes9x conf: ${HD_WIDTH}x${HD_HEIGHT} fullscreen, 4:3 aspect, vsync"
}

patch_flycast_hd_cfg() {
    local cfg="$1"
    [ -f "$cfg" ] || { log "skip flycast (no cfg; preset missing from ${PRESETS_DIR})"; return 0; }
    sed -i 's/^fullscreen = .*/fullscreen = yes/' "$cfg"
    sed -i 's/^rend\.vsync = .*/rend.vsync = yes/' "$cfg"
    sed -i "s/^width = .*/width = ${HD_WIDTH}/" "$cfg"
    sed -i "s/^height = .*/height = ${HD_HEIGHT}/" "$cfg"
    log "flycast cfg: ${HD_WIDTH}x${HD_HEIGHT} fullscreen, vsync on"
}

detect_display_resolution
install_hd_presets
patch_fbneo_hd_ini "$FBNEO_INI"
patch_ggpofba_hd_ini "$GGPO_INI"
patch_snes9x_hd_conf "$SNES_CONF"
patch_flycast_hd_cfg "$FLYCAST_CFG"
