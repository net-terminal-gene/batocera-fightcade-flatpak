#!/bin/bash
# Re-apply Fightcade Flatpak xdg-open patch (game URLs → play.pending).
set -eu

APP_ID="com.fightcade.Fightcade"
PROJECT_DIR="/userdata/system/fightcade-flatpak"

deploy=$(flatpak info --system --show-location "${APP_ID}" 2>/dev/null) || {
    echo "Could not locate Flatpak deploy dir for ${APP_ID}" >&2
    exit 1
}

xdg_open="${deploy}/files/bin/xdg-open"
backup="${xdg_open}.fc-original"

[ -f "${xdg_open}" ] || {
    echo "Flatpak xdg-open not found at ${xdg_open}" >&2
    exit 1
}

if [ ! -f "${backup}" ]; then
    cp -a "${xdg_open}" "${backup}"
fi

cat > "${xdg_open}" <<XDGOPEN
#!/bin/bash
# Patched by ${PROJECT_DIR}/install.sh for Batocera CRT Switchres.
# Game fcade:// URLs write play.pending for fightcade-crt-hostd (normalized to fcade://play).
# Schemes: play, served (incoming online), training, stream (replay / spectate).
# Non-game URLs (checkrom, autoupdate, userstatus, ...) pass through unchanged.

if [[ "\$1" == fcade://* ]]; then
  pending_url=""
  if [[ "\$1" =~ ^fcade://(play|served|training|stream)/([^/]+)/([^/]+) ]]; then
    pending_url="fcade://play/\${BASH_REMATCH[2]}/\${BASH_REMATCH[3]}"
  fi
  if [ -n "\$pending_url" ]; then
    printf '%s\n' "\$pending_url" > "${PROJECT_DIR}/play.pending"
  fi
  exec /app/bin/fcade-quark "\$@"
fi

if [[ "\$1" =~ ^(http|https):// ]] && [ -x "/app/steamos/bin/min-browser" ]; then
    /app/steamos/bin/min-browser "\$@"
    exit 0
fi

/usr/bin/xdg-open "\$@"
XDGOPEN
chmod 0755 "${xdg_open}"
echo "Patched ${xdg_open}"
