<p align="center">
  <img src="images/batocera-logo.png" alt="Batocera" width="180">
  &nbsp;&nbsp;&nbsp;
  <img src="images/Fightcade.png" alt="Fightcade" width="180">
</p>

<h1 align="center">Fightcade Flatpak for Batocera</h1>

ROM path wiring for Flatpak Fightcade on Batocera. One command links your
existing `/userdata/roms` folders into the Fightcade Flatpak data tree so games
you already have show up without duplication.

## Contents

#### Quick Install & Setup
- [Install](#install)
- [ROM format and BIOS](#rom-format--bios-requirements)
- [ROM path mapping](#rom-path-mapping)

#### Advanced
- [Controls and Navigation](#controls--navigation)
  - [Game controller mapping](#game-controller-mapping)
  - [Keyboard shortcuts (HD)](#keyboard-shortcuts-hd)
- [Commands](#commands)
- [Re-running the installer](#re-running-the-installer)
- [CRT / Switchres support](docs/CRT.md)
  - [Controls and navigation](docs/CRT.md#controls--navigation)
    - [Game controller mapping](docs/CRT.md#game-controller-mapping)
  - [Switchres flags](docs/CRT.md#switchres-flags)
  - [Recovery](docs/CRT.md#recovery)
  - [After a Fightcade Flatpak update](docs/CRT.md#after-a-fightcade-flatpak-update)

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
4. Drops a `_fightcade.txt` note (same style as Batocera's `_info.txt`) into each linked
   `/userdata/roms/<system>` folder describing Fightcade's ROM format and BIOS requirements.
5. Installs controller settings for gamepad navigation in the lobby and in-game menus
   (see [Controls & Navigation](#controls--navigation)).
6. Installs CRT / Switchres support on xorg CRT setups (see [CRT / Switchres support](docs/CRT.md)).
7. Installs Ports artwork under `/userdata/roms/flatpak/images/` (`Fightcade.png` logo,
   `Fightcade-logo.png` marquee, `Fightcade-thumb.png` thumbnail) and wires `gamelist.xml`.

## ROM Format & BIOS Requirements

Fightcade uses specific ROM sets and emulators. Standard Batocera dumps often will not
work. See the official [Fightcade help](https://www.fightcade.com/help) for ROM setup
and validation details.

- **fbneo (FightcadeFBNeo):** Based on FBNeo v0.2.97.44; compatible with the latest
  MAME arcade ROM set. Arcade games use FBNeo shortname `.zip` files (e.g. `mslug3.zip`);
  filenames must match FBNeo's internal database exactly. Console games under
  `ROMs/fbneo/<system>/` (megadrive, nes, pce, etc.) also use Fightcade-format `.zip`
  sets with FBNeo shortnames, not normal Batocera long-title dumps or `.7z` archives.
- **ggpofba (legacy FightcadeFBA):** Based on GGPOFBA. Used for older FC1 titles only;
  most users need `fbneo` instead. ROM requirements follow Fightcade's legacy FBA rules
  (see the help link above).
- **snes9x (FightcadeSNES):** Based on SNES9x. Fightcade shortname `.zip` sets are the
  safe choice; `.smc` and `.sfc` may work if they match Fightcade's ROM database.
  Long-title dumps or `.7z` archives will not work.
- **flycast (Flycast-Dojo):** Flycast-Dojo build by blueminder. **Dreamcast games** must
  be Fightcade CHD format with hashes matching the Fightcade ROM database; standard
  Batocera CHD rips will fail Fightcade's hash check.
- **Dreamcast BIOS:** Fightcade's Flycast emulator reads the BIOS from its own config path,
  not from the `ROMs/flycast/` tree. Copy `dc_boot.bin` and `dc_flash.bin` to:

  ```
  /userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/config/flycast/data/
  ```

- **Naomi / Atomiswave (flycast):** Fightcade `.zip` BIOS + game sets via the flycast
  links. No separate BIOS path; those BIOS ZIPs live alongside the game ZIPs in the ROM
  folder.

## ROM Path Mapping

Place Fightcade-format ROM sets in the Batocera folders below (`/userdata/roms/<system>/`).
The installer symlinks those sources into Fightcade's Flatpak ROM tree; you do not copy
files into the Flatpak data directory by hand (except Dreamcast BIOS, above).

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
| `ROMs/fbneo/nes_fds/` | `/userdata/roms/fds` | Dir symlink |
| `ROMs/fbneo/sms/` | `/userdata/roms/mastersystem` | Dir symlink |
| `ROMs/fbneo/spectrum/` | `/userdata/roms/zxspectrum` | Dir symlink |
| `ROMs/fbneo/sgx/` | `/userdata/roms/supergrafx` | Dir symlink |
| `ROMs/fbneo/tg16/` | `/userdata/roms/pcengine` | Dir symlink (TG-16 is the US PC Engine; Batocera keeps both in one folder) |
| `ROMs/snes9x` | `/userdata/roms/snes` | Dir symlink |
| `ROMs/flycast/atomiswave/` | `/userdata/roms/atomiswave` | Dir symlink |
| `ROMs/flycast/naomi/` | `/userdata/roms/naomi` | Dir symlink |
| `ROMs/flycast/naomi2/` | `/userdata/roms/naomi2` | Dir symlink |
| `ROMs/flycast/dreamcast/` | `/userdata/roms/dreamcast` | Dir symlink |

When a source directory does not exist, an empty real directory is created instead.

> [!TIP]
> Links always target `/userdata/roms/...`, the same paths EmulationStation and Batocera
> use. This does not change [Storage Manager](https://wiki.batocera.org/storage_manager)
> setup, mount points, or where your ROMs physically live. If your library is on a
> secondary drive merged into `/userdata/roms` via Storage Manager, the symlinks still
> work: Fightcade reads through the unified path, not a copy on internal storage.

## Controls & Navigation

> Fightcade is designed to be used with a **keyboard and mouse**, especially for
> **chat**. This installer adds **gamepad navigation** so you can move the cursor
> and open menus without a mouse. **Chat still requires a keyboard.**

### Game controller mapping

**Lobby** = Fightcade UI (home, search, rooms, chat, settings). **FBNeo / SNES menu**
= emulator menu bar visible. **Flycast menu** = in-game overlay with cursor visible.

| Where you are | Left Analog/D-pad | Left Analog/D-pad + B | A | SELECT + X | SELECT + Y | SELECT + R1 |
|---------------|---------------|-----------|---|------------|------------|-------------|
| **Lobby** | Move cursor (Fast) | Move cursor (Slow) | Left Click | — | — | Focus Open Windows (ES vs EMU vs Fightcade) |
| **FBNeo playing** | — | — | — | Open FBNeo menu (ESC) | — | — |
| **FBNeo menu open** | Move cursor (Fast) | Move cursor (Slow) | Left Click | — | Resume game | Focus Open Windows (ES vs EMU vs Fightcade) |
| **SNES playing** | — | — | — | Open Snes9x menu (ESC) | — | — |
| **SNES menu open** | Move cursor (Fast) | Move cursor (Slow) | Left Click | — | Resume game | Focus Open Windows (ES vs EMU vs Fightcade) |
| **Flycast playing** | — | — | — | Open Menu | Resume game | — |
| **Flycast menu** | Move cursor (Fast) | Move cursor (Slow) | Left Click | Open Menu | Resume game | — |

### Keyboard shortcuts (HD)

Three separate layers: **Fightcade** (the client), **this installer** (extra
menu keys for FBNeo / Snes9x), and **emulator defaults** (in-game play). Remap
in-game keys with **F5**.

| Key | Layer | Action |
|-----|-------|--------|
| **Alt+Enter** | Fightcade | Windowed / fullscreen |
| **Esc** | Fightcade | Quit game, return to channel |
| **Backspace** | Fightcade | Network ping during a match |
| **F5** | Fightcade | Input configuration |
| **ESC** | Installer | Open FBNeo / Snes9x menu (not the same as Fightcade **Esc**) |
| **Alt+Delete** | Installer | Close menu, return to fullscreen |
| **Alt+Enter** | Installer | Dismiss menu bar after Alt+Delete |
| **5** / **Shift** / Numpad **+** | Emulator | Coin / credit |
| **1** / **Enter** | Emulator | Player 1 start |
| **Arrows** / **W A S D** | Emulator | Movement |
| **U I O P** / Numpad | Emulator | Action buttons (varies by game) |

FBNeo and Snes9x quirk: Alt+Delete can return to fullscreen while the menu bar
stays visible until Alt+Enter. Gamepad **SELECT + Y** sends Alt+Delete and
Alt+Enter for you.

## Commands

| Command | What it does |
|---------|--------------|
| `fightcade-roms-sync` | Re-scan your `/userdata/roms` folders and refresh Fightcade symlinks |
| `fightcade-diagnose` | Print install state, link health, and artwork / patch status |
| `uninstall.sh` | Remove links, hook, overrides, xdg-open patch, and scripts (ROMs and Flatpak untouched) |
| `uninstall.sh --uninstall-flatpak` | Also uninstall the Fightcade Flatpak |

## Re-running the installer

Re-running the installer over an existing install is safe. It creates missing links,
refreshes changed ones, and does not modify real user files.

License: [CC0 1.0](LICENSE)
