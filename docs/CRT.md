# CRT / Switchres support

> [!CAUTION]
> CRT / Switchres support requires [**Batocera-CRT-Script**](https://github.com/ZFEbHVUE/Batocera-CRT-Script)
> to be installed and configured on your Batocera system. Without it, lobby
> timing and per-game native resolution switching will not work.

> [!IMPORTANT]
> **Fightcade's Video Mode must resolve to 640×480 on CRT.** In EmulationStation:
> **Ports → Fightcade → Advanced Game Settings → Video Mode**. Either:
> - Set **Video Mode = 640×480** directly, **or**
> - If you already set a global mode under **System Settings → Video Mode**, leave
>   **Advanced Game Settings → Video Mode = Auto** so it inherits that global mode.
>
> The lobby UI is laid out for 640×480. Other resolutions look wrong (cropped, oversized,
> or misaligned), and exiting an emulator back to the lobby is unreliable otherwise.

Fightcade's playable library is **4:3** and was authored for **CRTs at native
resolutions** (arcade modelines, 256×224 SNES, and the rest). Switchres on
Batocera restores that model: **menu timing for the lobby**, **per-game modelines
for gameplay**, then back to the lobby when the session ends.

Flycast is the exception: every Dreamcast, Naomi, Naomi 2, and Atomiswave title is
640×480, which is already the lobby resolution, so Flycast plays at lobby timing with
no mode change at all.

On CRT setups the installer gives Fightcade native-resolution switching during
gameplay, matching how Batocera's own emulators behave on a CRT. The Fightcade
lobby, queues, and settings run at your CRT menu timing (e.g. 640×480i from
EmulationStation or Advanced Game Settings).

Switchres only changes the display when you start a game (**TEST GAME**, **TRAINING**,
**ONLINE MATCH**, **REPLAY**, or **LIVE SPECTATING**), applies that game's native
resolution and refresh rate, then restores menu timing when the session ends.

## Contents

- [Fightcade resolution](#fightcade-resolution)
- [Controls (CRT)](#controls-crt)
- [Settings persistence](#settings-persistence)
- [Keyboard (FBNeo / SNES)](#keyboard-fbneo--snes)
- [Switchres flags](#switchres-flags)
- [Recovery](#recovery)
- [Debugging Switchres issues](#debugging-switchres-issues)
- [After a Fightcade Flatpak update](#after-a-fightcade-flatpak-update)

## Fightcade resolution

CRT play needs **xorg** display mode in addition to Batocera-CRT-Script (see caution
above).

Fightcade's Video Mode must resolve to **640×480** on CRT (set it directly, or leave
**Advanced Game Settings → Video Mode = Auto** if your global **System Settings → Video
Mode** is already 640×480). See the note at the [top of this page](#crt--switchres-support).

## Controls (CRT)

Full gamepad layout and Batocera hotkey notes: [Controls & navigation](CONTROLS.md).
Lobby chat: [Fightcade lobby chat config](LOBBY-CHAT.md).

On CRT, lobby and menus run at menu timing; in-game pause/resume uses **SELECT + WEST/NORTH**
as documented in the [context table](CONTROLS.md#context-table).

**FBNeo / SNES menu cursor:** Stick, D-pad, **SOUTH** / **EAST**, and modal dialogs
(for example **Input → Map game inputs**) are covered in
[Controls — Emulator menus](CONTROLS.md#emulator-menus-fbneo--snes).

> [!TIP]
> - **No pad cursor after opening the menu?** Press **SELECT + WEST** again to bring it back.
> - **Clicks not landing?** Press **SELECT + R1** a few times to focus the window you are on.
> - **Back to fullscreen game:** press **SELECT + NORTH**.

> [!WARNING]
> **If you open the in-game menu and change anything, quit the game and launch it again.**
> Once the emulator menu has been opened mid-game, some button combos (**WEST** / **NORTH**
> together with another button) can be misread afterward and may toggle Switchres on or off.
> Quit to the lobby (**SELECT + Start**) and relaunch the game so it starts in a clean state.

### Settings persistence

**Per-game settings persist** (DIP switches, input remaps, game-specific video tweaks, sound volume):
- Saved to `config/fcadefbneo/games/romname.ini` per ROM
- Never touched by the installer or CRT scripts

**Global video settings reset by design** (resolution, fullscreen mode, vsync, aspect ratio):
- Saved to main `config/fcadefbneo/fcadefbneo.ini`
- **Automatically reset** when returning to the lobby after a CRT game (Switchres restores HD baseline via `hd/patch-hd-video.sh`)
- This is intentional to ensure the lobby always has correct display settings

If you change global video settings in FBNeo's menu and they revert after exiting to the lobby, that's expected. CRT scripts restore the lobby baseline after each game. Per-game settings like DIP switches and controls always persist.

## Keyboard (FBNeo / SNES)

| Key | Action |
|-----|--------|
| **ESC** | Lobby resolution + open emulator menu (same as SELECT + WEST) |
| **Alt+Delete** | Resume native resolution (menu may stay open; press **Alt+Enter** to dismiss) |

Exiting the emulator from the menu returns to Fightcade. Launching a new game
applies native resolution again automatically.

## Switchres flags

Create an empty flag file to opt out of or force Switchres (content does not
matter; the file only needs to exist):

```bash
touch /userdata/system/configs/fightcade-switchres.disable   # disable Switchres
touch /userdata/system/configs/fightcade-switchres.force     # force Switchres on
```

Remove the file to undo. `/userdata/system/fightcade-flatpak/fightcade-diagnose` reports whether either flag is
present.

## Recovery

| Command | What it does |
|---------|--------------|
| `/userdata/system/fightcade-flatpak/crt/fightcade-crt-recover` | Restore lobby timing and clear stale game sessions |
| `/userdata/system/fightcade-flatpak/fightcade-diagnose` | Print install state and CRT flags |

## Debugging Switchres issues

If Switchres switches off mid-game, never applies, or the in-game menu will not
appear, turn on **DEBUG LOGGING**, reproduce it, and send the single report file.
It captures the full Switchres lifecycle (`dispatch begin` → `pre_play` →
`applying switchres` → `settled` → `crt-pause` / `crt-resume` →
`loop exited; restoring display`) and the pad-mouse menu decisions. Full steps:
[Debugging & bug reports](DEBUGGING.md).

## After a Fightcade Flatpak update

Re-run `/userdata/system/fightcade-flatpak/install.sh` after a Fightcade Flatpak update (Flathub can overwrite
`xdg-open`; the installer re-applies the patch from `xdg-open.fc-original`).

**Game modes and `fcade://` URLs.** Fightcade uses different URL schemes per mode. The installer
patch normalizes all game launches to `fcade://play/<emu>/<rom>` when writing `play.pending`:

| Mode | Fightcade URL | CRT |
|------|---------------|-----|
| TEST GAME / outgoing online | `fcade://play/...` | Yes |
| Incoming online challenge | `fcade://served/...` | Yes (normalized) |
| TRAINING | `fcade://training/...` | Yes (normalized) |
| REPLAY / LIVE SPECTATING | `fcade://stream/...` | Yes (normalized) |

Non-game URLs (`checkrom`, `autoupdate`, `userstatus`, ...) are not written to `play.pending`.

After testing, confirm dispatch in `/userdata/system/logs/fightcade-crt-switchres.log`
(`hostd: dispatch fcade://play/...`).

[← Back to main README](../README.md)
