# Debugging & bug reports

When something misbehaves (the FBNeo/SNES in-game menu not appearing on
**SELECT + WEST**, Switchres dropping mid-game, cursor/window trouble, and so on),
turn on **DEBUG LOGGING**, reproduce the problem, and send back the single report
file. This works the same on **HD** and **CRT** setups.

> [!NOTE]
> Debug logging is **OFF by default** and should stay off for normal play. It writes
> extra detail every session and can slightly affect performance, so only turn it on
> when you are actively troubleshooting, then turn it back off.

## Contents

- [Turn on debug logging](#turn-on-debug-logging)
- [Reproduce and collect](#reproduce-and-collect)
- [Where the report is saved](#where-the-report-is-saved)
- [Send the report](#send-the-report)
- [Turn debug logging off](#turn-debug-logging-off)
- [What the report contains](#what-the-report-contains)
- [Advanced: run the collector by hand](#advanced-run-the-collector-by-hand)

## Turn on debug logging

The toggle lives in EmulationStation, no terminal required.

> [!IMPORTANT]
> **The change only takes effect on your next launch from EmulationStation.**
> EmulationStation saves this setting when you back out of the menus, not while the
> game is starting. So after toggling, back all the way out to the game list, then
> launch Fightcade. Do not launch straight from the options menu, or the game can
> start before the setting is saved and logging will not turn on.

1. Highlight **Fightcade** in EmulationStation.
2. **Hold SOUTH** to open its options, then select **ADVANCED GAME OPTIONS**.
3. Toggle **FIGHTCADE DEBUG LOGGING** on.
4. Press **B / Back** to leave ADVANCED GAME OPTIONS, then **B / Back** again to
   return to the game list. Backing out is what saves the setting.
5. Launch Fightcade normally (press **SOUTH**).

## Reproduce and collect

1. Play and reproduce the problem, whatever your symptom is. For example: open the
   emulator menu with **SELECT + WEST**, trigger the lobby issue, or keep playing
   until Switchres drops.
2. Quit Fightcade back to EmulationStation (**SELECT + Start**, then exit).

On exit, **one report file is written automatically**. You do not need a terminal
and you do not need to run any command.

## Where the report is saved

```
/userdata/system/logs/fightcade-debug-<timestamp>.txt
```

The name is stamped with the date and time you quit Fightcade
(`fightcade-debug-YYYYMMDD-HHMMSS.txt`), so **the newest file is the one with the
largest number**. Each debug session writes its own new file; nothing is
overwritten.

You can grab it from any PC over Batocera's network share (no terminal):

| From | Path |
|------|------|
| Windows (SMB) | `\\BATOCERA\share\system\logs\` |
| macOS (Finder) | `smb://batocera.local/share/` then `system/logs` |
| FileZilla (SFTP, port 22) | `/userdata/system/logs/` |

Batocera shares `/userdata` as the **`share`** folder, so `share/system/logs` is the
same as `/userdata/system/logs`.

No PC or network? You can copy it to a USB drive right on the device:

1. Plug an external drive into the Batocera machine.
2. From the EmulationStation main menu, press **F1** to open Batocera's file manager.
3. Browse to `/userdata/system/logs`, then drag and drop the
   `fightcade-debug-<timestamp>.txt` onto your drive.

## Send the report

It is one plain-text file, so pick whichever is easiest:

- **Drag and drop** the `.txt` into a GitHub issue or a Discord message.
- **Paste the whole thing** inline (small sessions): `cat <report>`
- **Paste only the key lines** (best for Discord): run the grep below. The exact
  command, pre-filled with the report's own path, is printed at the **top of every
  report**.

```bash
grep -nE '\[dbg\]|SELECT\+' /userdata/system/logs/fightcade-debug-<timestamp>.txt
```

That pulls just the high-signal lines: the verbose `[dbg]` entries (Switchres
lifecycle and the FBNeo/SNES menu decisions) plus the `SELECT+` combo lines.

## Turn debug logging off

Do the same thing in reverse, and remember the same launch caveat:

1. Highlight **Fightcade**, **hold SOUTH**, then open **ADVANCED GAME OPTIONS**.
2. Turn **FIGHTCADE DEBUG LOGGING** off.
3. Press **B / Back** out to the game list (this saves it).
4. It takes effect the next time you launch Fightcade.

## What the report contains

One file with clearly marked `===== section =====` blocks:

| Section | What it shows |
|---------|---------------|
| Environment | Batocera version, kernel, install type, Switchres binary presence |
| Config flags | Kill-switch / force flags, pad-mouse and lobby-chat config |
| Runtime state | Switchres pause/lock/session flag files under `/tmp` |
| Display | `batocera-resolution`, `xrandr`, active modes, emulator window geometry |
| Processes | Running Fightcade / Switchres / emulator / pad-mouse processes |
| Emulator configs | `fcadefbneo.ini`, `fcadesnes9x.conf`, flycast `emu.cfg` |
| Logs | Switchres log, pad-mouse log, install log, ES launch logs |

What to look for, per symptom:

- **Menu not appearing (SELECT + WEST):** the pad-mouse
  `[dbg] SELECT+WEST edge: ...` / `SELECT+NORTH edge: ...` lines show the full
  decision state (`fbneo_avail`, `switchres`, `crt_paused`, `menu_open`).
- **Switchres dropping mid-game (CRT only):** the switchres `[dbg]` lifecycle,
  `dispatch begin` → `pre_play` → `applying switchres` → `settled` →
  `crt-pause` / `crt-resume` → `loop exited; restoring display`.

> [!NOTE]
> On **HD** setups there is no Switchres, so the switchres section is short (just
> "not used" notes). The pad-mouse / menu diagnostics still apply on HD.

## Advanced: run the collector by hand

The auto-report at Fightcade exit is the easy path. If you have a terminal, the same
collector can be run directly:

| Command | What it does |
|---------|--------------|
| `/userdata/system/fightcade-flatpak/fightcade-collect-logs` | One-shot snapshot → single `.txt` (includes an interactive pad probe: press SELECT + WEST/NORTH when prompted) |
| `/userdata/system/fightcade-flatpak/fightcade-collect-logs --watch [SECS]` | Sample display + logs every second for `SECS` (default 180), then write the `.txt`. Start it, then reproduce the bug in-game |
| `/userdata/system/fightcade-flatpak/fightcade-diagnose` | Print install state, CRT flags, and quick health checks |

`--auto` is the mode the game hook uses at exit (no interactive probe, no delay).

[← Back to main README](../README.md)
