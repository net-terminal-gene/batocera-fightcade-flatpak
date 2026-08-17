<p align="center">
  <img src="images/batocera-logo.png" alt="Batocera" width="180">
  &nbsp;&nbsp;&nbsp;
  <img src="images/Fightcade.png" alt="Fightcade" width="180">
</p>

<h1 align="center">Fightcade Flatpak for Batocera</h1>

Fightcade on Batocera, built for a **single controller**: navigate the lobby, send chat
lines, and open emulator menus without a keyboard and mouse. **One install command**
links your ROM library and layers Batocera-specific features on top of stock Fightcade.

> **Added Bonus - Play it the way it was drawn.**
>
> Every game in Fightcade was originally released before the introduction of digital
> 16:9 widescreen monitors. This version enables you to play these games on the exact
> analog hardware they were originally intended for: a **CRT** (Cathode Ray Tube) monitor.
>
> With the help of [**Batocera-CRT-Script**](https://github.com/ZFEbHVUE/Batocera-CRT-Script),
> Batocera switches the display to **that game's native resolution** the moment you start
> a match using its built-in **Switchres** capabilities. That means **pixel-perfect
> modelines** that no downscaler would ever achieve. Not every game shares the exact same
> resolution, but there is no need to worry. Batocera changes automatically with zero custom
> setup. The same pixels, speed, and picture the developers signed off on, with no guessing
> or "close enough."

HD presets, CRT setup, and full guides are in [Added features](#added-features).

## Beta testing

This installer is in **beta**. Before you report issues, walk through
[docs/beta-test-checklist.md](docs/beta-test-checklist.md) for **HD mode** (LCD / HDMI)
and **CRT mode** (xorg + Switchres + Batocera-CRT-Script). **CRT testers:** set Fightcade
to **640×480** first ([docs/CRT.md](docs/CRT.md#fightcade-resolution)). Each mode covers **TEST GAME**,
**TRAINING**, **ONLINE MATCH**, **REPLAY**, and **LIVE SPECTATING**. Include output from
`/userdata/system/fightcade-flatpak/fightcade-diagnose` in your report. Post feedback in the [Discord beta thread](https://discord.com/channels/357518249883205632/1536626216105148436).

## Contents

- [Install](#install)
- [ROM format and BIOS](#rom-format--bios-requirements)
- [ROM path mapping](#rom-path-mapping)
- [Commands](#commands)
- [Re-running the installer](#re-running-the-installer)
- [Added features](#added-features)

## Install

[SSH into your Batocera device](https://wiki.batocera.org/access_the_batocera_via_ssh), or open **xterm** from the file manager (F1 → Applications) on xorg builds, then run:

> [!NOTE]
> Your Batocera device must be **connected to the internet**. The installer downloads
> scripts from GitHub and may install Fightcade from Flathub.

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
5. Installs Ports artwork under `/userdata/roms/flatpak/images/` and wires `gamelist.xml`.
6. Installs [added features](#added-features) (gamepad navigation, chat, HD/CRT display).

## ROM format & BIOS requirements

Fightcade uses specific ROM sets and emulators. Standard Batocera dumps often will not
work. See the official [Fightcade help](https://www.fightcade.com/help) for ROM setup
and validation details.

- **fbneo (FightcadeFBNeo):** Based on FBNeo v0.2.97.44; compatible with the latest
  MAME arcade ROM set. Arcade games use FBNeo shortname `.zip` files (e.g. `mslug3.zip`);
  filenames must match FBNeo's internal database exactly. Console games under
  `ROMs/fbneo/<system>/` (megadrive, nes, pce, etc.) also use Fightcade-format `.zip`
  sets with FBNeo shortnames, not normal Batocera long-title dumps or `.7z` archives.
- **snes9x (FightcadeSNES):** Based on SNES9x. Fightcade shortname `.zip` sets are the
  safe choice; `.smc` and `.sfc` may work if they match Fightcade's ROM database.
  Long-title dumps or `.7z` archives will not work.
- **flycast (Flycast-Dojo):** Flycast-Dojo build by blueminder. **Dreamcast games** must
  be Fightcade CHD format with hashes matching the Fightcade ROM database; standard
  Batocera CHD rips will fail Fightcade's hash check.
- **Dreamcast BIOS:** Fightcade's Flycast emulator reads the BIOS from its own config path,
  not from the `ROMs/flycast/` tree. If you already have Dreamcast set up in Batocera, the
  BIOS files are normally already at `/userdata/bios/dc/` (`dc_boot.bin` and
  `dc_flash.bin`; see the [Batocera Dreamcast wiki](https://wiki.batocera.org/systems:dreamcast)).
  Copy those into Fightcade's path:

  ```
  /userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/config/flycast/data/
  ```

  Example if your BIOS are already installed:

  ```bash
  mkdir -p /userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/config/flycast/data
  cp /userdata/bios/dc/dc_boot.bin /userdata/bios/dc/dc_flash.bin \
    /userdata/saves/flatpak/data/.var/app/com.fightcade.Fightcade/config/flycast/data/
  ```

- **Naomi / Atomiswave (flycast):** Fightcade `.zip` BIOS + game sets via the flycast
  links. No separate BIOS path; those BIOS ZIPs live alongside the game ZIPs in the ROM
  folder.
- **ggpofba (legacy FightcadeFBA):** Optional. Still present in Fightcade V2 for **legacy
  FC1** channels only (look for **FC1** in the channel list). Normal V2 arcade play uses
  **fbneo** instead. You can ignore this emulator unless you join FC1 rooms. ROM
  requirements follow Fightcade's legacy FBA rules (see the help link above). This
  installer creates an empty `ROMs/ggpofba` folder but does not link Batocera ROMs into
  it.

## ROM path mapping

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
| `ROMs/flycast/*.chd` (and `.cdi`) | `/userdata/roms/dreamcast/*` | Per-file symlinks at Flycast root (Fightcade expects Dreamcast games top-level, not under a `dreamcast/` subfolder) |

When a source directory does not exist, an empty real directory is created instead.

> [!TIP]
> Links always target `/userdata/roms/...`, the same paths EmulationStation and Batocera
> use. This does not change [Storage Manager](https://wiki.batocera.org/storage_manager)
> setup, mount points, or where your ROMs physically live. If your library is on a
> secondary drive merged into `/userdata/roms` via Storage Manager, the symlinks still
> work: Fightcade reads through the unified path, not a copy on internal storage.

## Commands

| Command | What it does |
|---------|--------------|
| `/userdata/system/fightcade-flatpak/fightcade-roms-sync` | Re-scan your `/userdata/roms` folders and refresh Fightcade symlinks |
| `/userdata/system/fightcade-flatpak/hd/patch-hd-video.sh` | Apply HD fullscreen, aspect, and vsync defaults (see [HD.md](docs/HD.md)) |
| `/userdata/system/fightcade-flatpak/input/fightcade-pad-mouse status` | Show whether the pad-mouse daemon is running |
| `/userdata/system/configs/fightcade-pad-mouse.conf` | Cursor speed (HD vs CRT, lobby, menus, R1/R2 slow) |
| `/userdata/system/configs/fightcade-lobby-chat.conf` | Lobby chat macros (R1 + face / R2) |
| `/userdata/system/fightcade-flatpak/fightcade-diagnose` | Print install state, link health, and artwork / patch status |
| `/userdata/system/fightcade-flatpak/uninstall.sh` | Remove links, hook, overrides, xdg-open patch, and scripts (ROMs and Flatpak untouched) |
| `/userdata/system/fightcade-flatpak/uninstall.sh --uninstall-flatpak` | Also uninstall the Fightcade Flatpak |

## Re-running the installer

Re-running the installer over an existing install is safe. It creates missing links,
refreshes changed ones, reapplies HD video defaults, and does not modify real user files.

## Added features

| Topic | Guide |
|-------|--------|
| Gamepad, cursor speeds, Batocera hotkeys | [docs/CONTROLS.md](docs/CONTROLS.md) |
| Lobby chat config (`fightcade-lobby-chat.conf`) | [docs/LOBBY-CHAT.md](docs/LOBBY-CHAT.md) |
| HD fullscreen / aspect / vsync | [docs/HD.md](docs/HD.md) |
| CRT / Switchres / native modelines | [docs/CRT.md](docs/CRT.md) |
| Beta test checklist | [docs/beta-test-checklist.md](docs/beta-test-checklist.md) |

License: [CC0 1.0](LICENSE)
