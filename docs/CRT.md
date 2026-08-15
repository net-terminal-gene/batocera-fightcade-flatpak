# CRT / Switchres support

> [!CAUTION]
> CRT / Switchres support requires [**Batocera-CRT-Script**](https://github.com/ZFEbHVUE/Batocera-CRT-Script)
> to be installed and configured on your Batocera system. Without it, lobby
> timing and per-game native resolution switching will not work.

On CRT setups the installer gives Fightcade native-resolution switching during
gameplay, matching how Batocera's own emulators behave on a CRT. The Fightcade
lobby, queues, and settings run at your CRT menu timing (e.g. 640x480i from
EmulationStation or Advanced Game Settings).

Switchres only changes the display when you start a game (**TEST GAME**, **TRAINING**,
**ONLINE MATCH**, **REPLAY**, or **LIVE SPECTATING**), applies that game's native
resolution and refresh rate, then restores menu timing when the session ends.

## Contents

- [Controls (CRT)](#controls-crt)
- [Keyboard (FBNeo / SNES)](#keyboard-fbneo--snes)
- [Switchres flags](#switchres-flags)
- [Beta test checklist](beta-test-checklist.md) (session paths, gamepad controls, Switchres on/off)
- [Recovery](#recovery)
- [After a Fightcade Flatpak update](#after-a-fightcade-flatpak-update)

## Controls (CRT)

Full gamepad layout and Batocera hotkey notes: [Controls & navigation](CONTROLS.md).
Lobby chat: [Fightcade lobby chat config](LOBBY-CHAT.md).

On CRT, lobby and menus run at menu timing; in-game pause/resume uses **SELECT + WEST/NORTH**
as documented in the [context table](CONTROLS.md#context-table).

**FBNeo / SNES menu cursor:** Stick, D-pad, **SOUTH** / **EAST**, and modal dialogs
(for example **Input → Map game inputs**) are covered in
[Controls — Emulator menus](CONTROLS.md#emulator-menus-fbneo--snes).

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
present. Walk through the [Switchres on/off steps](beta-test-checklist.md#switchres-onoff-crt) in the beta checklist (Step 2 and Step 3 are optional).

## Recovery

| Command | What it does |
|---------|--------------|
| `/userdata/system/fightcade-flatpak/crt/fightcade-crt-recover` | Restore lobby timing and clear stale game sessions |
| `/userdata/system/fightcade-flatpak/fightcade-diagnose` | Print install state and CRT flags |

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
