# HD video defaults

On HD LCD / HDMI setups (1080p, 1440p, 4K, and so on), stock Fightcade emulators
often launch windowed or stretch the image past the screen edges. The installer
applies HD-friendly fullscreen, aspect, and vsync settings for **FBNeo, SNES9x,
and Flycast** (what most V2 players use daily). Fightcade's library is **4:3**;
HD presets keep correct aspect at your panel resolution. For **native CRT modelines
per game**, see [CRT / Switchres](CRT.md).

`install.sh` runs `hd/patch-hd-video.sh` after the initial ROM sync. That script:

1. Reads the **current display resolution** from `batocera-resolution` (falls back to
   `xrandr` if needed; default 1920×1080 when detection fails, e.g. SSH with no X session).
2. Copies preset configs from `hd/presets/` when an emulator config file does not
   exist yet (so you do not have to launch each emulator once before install can help).
3. Patches existing configs in place at the detected resolution so re-running the
   installer refreshes the same keys.

If you change display mode (e.g. switch from 1080p to 1440p), re-run
`hd/patch-hd-video.sh` or the full installer so emulator fullscreen sizes match.

| Emulator | Fullscreen | Aspect | Vsync |
|----------|------------|--------|-------|
| FBNeo (`fcadefbneo.ini`) | Auto-switch fullscreen at detected resolution | Correct aspect, no full stretch | On + triple buffer |
| SNES9x (`fcadesnes9x.conf`) | Detected resolution, emulate fullscreen, lock config | Maintain 4:3 (base width 299) | On |
| Flycast (`emu.cfg`) | `fullscreen = yes` at detected resolution | (game default) | `rend.vsync = yes` |
| GGPOFBA (`ggpofba.ini`) | Legacy **FC1** channels only (optional) | — | On + triple buffer (if config exists) |

GGPOFBA is the old FightcadeFBA emulator. Fightcade V2 still launches it for **FC1**
legacy channels, but you can ignore it unless you play in those rooms. The HD patch
only touches `ggpofba.ini` when that file already exists (after you launch legacy FBA
once).

## Settings persistence

**All emulator settings persist normally** after the initial install (DIP switches, input remaps, video settings, sound volume). The installer applies HD defaults once during setup, then Fightcade behaves like stock.

If you change display mode (e.g. switch from 1080p to 1440p), manually re-run `hd/patch-hd-video.sh` to update emulator fullscreen sizes.

**CRT users:** Global video settings reset after each game because Switchres restoration runs the HD patch to restore the lobby baseline. See [CRT.md — Settings persistence](CRT.md#settings-persistence). Per-game settings always persist.

Preset files live in the Flatpak data tree:

```
/userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/data/config/
  fcadefbneo/fcadefbneo.ini
  snes9x/fcadesnes9x.conf
  flycast/emu.cfg
  ggpofba/ggpofba.ini          # legacy FC1 only; optional
```

Re-apply HD defaults any time (after a Flatpak update, or if an emulator reset its config):

```bash
/userdata/system/fightcade-flatpak/hd/patch-hd-video.sh
```

Or re-run the full installer; it is safe on an existing install.

> [!NOTE]
> **CRT users:** HD presets set the lobby / HD baseline. During a CRT game,
> [Switchres](CRT.md) temporarily overrides FBNeo and SNES9x video settings for
> native resolution, then restores the HD baseline when the game exits. CRT gameplay
> is not changed by these presets.

> [!TIP]
> **Gamepad in the emulator menu (HD):**
> - **No pad cursor after opening the menu?** Press **SELECT + WEST** again to bring it back.
> - **Clicks not landing?** Press **SELECT + R1** a few times to focus the window you are on.
> - **Back to fullscreen game:** press **SELECT + NORTH**.
>
> Full layout: [Controls & navigation](CONTROLS.md#emulator-menus-fbneo--snes).

> [!WARNING]
> **If you open the in-game menu and change anything, quit the game and launch it again.**
> Once the emulator menu has been opened mid-game, some button combos (**WEST** / **NORTH**
> together with another button) can be misread afterward. Quit to the lobby
> (**SELECT + Start**) and relaunch the game so it starts in a clean state.

[← Back to main README](../README.md)
