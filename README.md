# batocera-fightcade-flatpak

ROM path wiring for Flatpak Fightcade on Batocera. One command wires your
existing `/userdata/roms` folders into the Fightcade Flatpak data tree so
games you already have show up in Fightcade without duplication.

## Install

SSH into your Batocera device, then run:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh \
  | bash -s -- -y
```

The installer:

1. Verifies Batocera and Flatpak are available.
2. Installs `com.fightcade.Fightcade` from Flathub if missing.
3. Creates the Fightcade ROMs scaffold and links your `/userdata/roms` folders into it.
4. Applies Flatpak filesystem overrides so the sandbox can read those paths.
5. Installs a game hook that refreshes arcade links automatically before each Fightcade launch.
6. Installs Fightcade splash artwork and a `gamelist.xml` entry so the ES Ports tile looks right.
7. Drops a `_fightcade.txt` note (same style as Batocera's `_info.txt`) into each linked
   `/userdata/roms/<system>` folder describing Fightcade's ROM format requirements.
8. Installs CRT Switchres support: on xorg CRT setups, games launched from Fightcade
   switch the display to their native resolution using your configured monitor profile.

## ROM format requirements

Fightcade uses specific ROM sets. Standard Batocera console dumps will not work.

- **Arcade (FBNeo):** FBNeo shortname `.zip` sets (e.g. `mslug3.zip`). Filenames must
  match FBNeo's internal database exactly.
- **Console systems (megadrive, nes, etc.):** Fightcade-format `.zip` sets matching
  FBNeo shortnames. Normal Batocera long-title dumps or `.7z` archives will not work.
- **Dreamcast:** Fightcade CHD format with hashes matching the Fightcade ROM database.
  Standard Batocera CHD rips will fail Fightcade's hash check.
- **Naomi / Atomiswave:** Fightcade `.zip` BIOS + game sets work via the flycast links.

## ROM path mapping

| Fightcade path | Batocera source | Method |
|----------------|-----------------|--------|
| `ROMs/fbneo/*.zip` | `/userdata/roms/fbneo/*.zip` | Per-zip symlinks |
| `ROMs/fbneo/megadrive/` | `/userdata/roms/megadrive` | Dir symlink |
| `ROMs/fbneo/nes/` | `/userdata/roms/nes` | Dir symlink |
| `ROMs/fbneo/gamegear/` | `/userdata/roms/gamegear` | Dir symlink |
| `ROMs/fbneo/coleco/` | `/userdata/roms/colecovision` | Dir symlink |
| `ROMs/fbneo/pce/` | `/userdata/roms/pcengine` | Dir symlink |
| `ROMs/fbneo/sg1000/` | `/userdata/roms/sg1000` | Dir symlink |
| `ROMs/fbneo/msx/` | `/userdata/roms/msx1` | Dir symlink |
| `ROMs/fbneo/nes_fds/` | `/userdata/roms/fds` | Dir symlink (when source exists) |
| `ROMs/fbneo/sms/` | `/userdata/roms/mastersystem` | Dir symlink (when source exists) |
| `ROMs/fbneo/spectrum/` | `/userdata/roms/zxspectrum` | Dir symlink (when source exists) |
| `ROMs/fbneo/sgx/` | `/userdata/roms/supergrafx` | Dir symlink (when source exists) |
| `ROMs/fbneo/tg16/` | `/userdata/roms/pcengine` | Dir symlink (TG-16 is the US PC Engine; Batocera keeps both in one folder) |
| `ROMs/snes9x` | `/userdata/roms/snes` | Dir symlink |
| `ROMs/flycast/atomiswave/` | `/userdata/roms/atomiswave` | Dir symlink |
| `ROMs/flycast/naomi/` | `/userdata/roms/naomi` | Dir symlink |
| `ROMs/flycast/naomi2/` | `/userdata/roms/naomi2` | Dir symlink |
| `ROMs/flycast/dreamcast/` | `/userdata/roms/dreamcast` | Dir symlink |

When a source directory does not exist, an empty real directory is created instead.

## Dreamcast BIOS

Fightcade's Flycast emulator reads the Dreamcast BIOS from its own config path, not
from the `ROMs/flycast/` tree. Copy the BIOS files to:

```
/userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/config/flycast/data/
```

Required files: `dc_boot.bin` and `dc_flash.bin`.

Naomi and Atomiswave do not need a separately placed BIOS; those BIOS ZIPs live
alongside the game ZIPs in the ROM folder.

## Artwork and gamelist

The Flatpak install only provides the app icon (`images/Fightcade.png`). The installer
adds splash artwork (`images/Fightcade-image.png`, shipped in this repo) and wires both
into `/userdata/roms/flatpak/gamelist.xml`:

- If no `gamelist.xml` exists, one is created with the Fightcade entry.
- If a `gamelist.xml` exists without a Fightcade entry, the entry is appended.
- If a Fightcade entry already exists, it is left untouched.

A running EmulationStation is updated in place through its HTTP API, so the artwork
shows immediately without restarting ES.

## Auto-refresh for arcade ROMs

A game hook at `/userdata/system/scripts/fightcade-game-hook` fires before every
Fightcade launch. It calls `fightcade-roms-sync --quiet` automatically, so `.zip`
files you add to `/userdata/roms/fbneo` are linked into Fightcade without re-running
the installer or rebooting.

## CRT / Switchres support

On CRT setups the installer gives Fightcade native-resolution switching, matching how
Batocera's own emulators behave on a CRT. When you start a game (TEST GAME, online match, or
training), the display switches to the game's native modeline via `switchres` and your
existing monitor profile (`batocera.conf` `monitor=` setting), then restores the menu
resolution when the game exits.

How it works:

- The game hook starts a watcher (`fightcade-crt-watch`) when Fightcade launches and
  stops it when Fightcade exits. On HD setups the watcher exits immediately and nothing
  changes.
- The watcher tails Fightcade's `fcade.log` for `fcade://play/<emulator>/<rom>` launch
  lines, resolves the game's native resolution (MAME lookup for arcade, fixed tables
  for console cores), patches the emulator config to fullscreen at native size, applies
  the Switchres modeline once the emulator is up, and restores everything on exit.
- Configs patched: FBNeo ini, Snes9x conf, Flycast cfg. The FC1 (`ggpofba`) config
  lives inside the read-only Flatpak image, so FC1 games get the resolution switch but
  no fullscreen config patch.

Switchres engages only when the display mode is `xorg` and the current width is below
1024 (i.e. a CRT menu resolution). Two control files override this:

```bash
# Disable Switchres for Fightcade entirely:
touch /userdata/system/configs/fightcade-switchres.disable

# Force Switchres on regardless of current resolution:
touch /userdata/system/configs/fightcade-switchres.force
```

**In-game menu hotkeys (CRT only, while a game is running):**

Low-resolution games make the FBNeo in-game menu hard to use at native Switchres timing.
These shortcuts only apply during gameplay, not in the Fightcade UI:

| Key | Action |
|-----|--------|
| **ESC** | Pause Switchres and restore the Batocera menu resolution (e.g. 640x480) so you can use the in-game menu, assign controls, or turn off scanlines |
| **Alt+Enter** | Resume Switchres and return to the game's native modeline |

When you exit the game normally (Game → Exit Game), Switchres still restores automatically.

## Commands

All scripts live in `/userdata/system/fightcade-flatpak/`.

| Command | What it does |
|---------|--------------|
| `fightcade-roms-sync` | Re-run scaffold and symlink sync manually |
| `fightcade-diagnose` | Print install state, link health, override contents, and CRT status |
| `fightcade-crt-watch stop` | Manually stop the CRT watcher and restore configs/display |
| `uninstall.sh` | Remove links, hook, overrides, and scripts (ROMs, artwork, and Flatpak untouched) |
| `uninstall.sh --uninstall-flatpak` | Also uninstall the Fightcade Flatpak |

## Re-running the installer

Re-running the installer over an existing install is safe. It creates missing links,
refreshes changed ones, and does not modify real user files.

## QA checklist

1. `install.sh` over an existing manual install: no duplicate links, no errors on re-run.
2. Add a new `.zip` to `/userdata/roms/fbneo`, launch Fightcade from ES Ports, and
   confirm the new game appears (hook test).
3. `fightcade-diagnose` reports all checks passed.
4. `uninstall.sh` removes links, hook, and overrides; real ROMs untouched.
5. CRT: from a CRT menu resolution, TEST GAME an arcade title and confirm the display
   switches to the native modeline and restores to the menu resolution on exit.
6. CRT: quit Fightcade mid-game and confirm the gameStop hook restores the display.

## License

MIT
