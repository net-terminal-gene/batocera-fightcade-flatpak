<p align="center">
  <img src="images/batocera-logo.png" alt="Batocera" width="180">
  &nbsp;&nbsp;&nbsp;
  <img src="images/fightcade-logo.png" alt="Fightcade" width="180">
</p>

<h1 align="center">Fightcade Flatpak for Batocera</h1>

ROM path wiring and CRT Switchres support for Flatpak Fightcade on Batocera. One
command wires your existing `/userdata/roms` folders into the Fightcade Flatpak
data tree so games you already have show up without duplication. On CRT setups,
Switchres switches the display to each game's native resolution during gameplay;
the Fightcade lobby stays at your CRT menu timing (e.g. 640x480i).

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
5. Installs CRT Switchres support: on xorg CRT setups, games launched from Fightcade
   switch the display to their native resolution using your configured monitor profile.

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

Links always target `/userdata/roms/...`, the same paths EmulationStation and Batocera
use. This does not change [Storage Manager](https://wiki.batocera.org/storage_manager)
setup, mount points, or where your ROMs physically live. If your library is on a
secondary drive merged into `/userdata/roms` via Storage Manager, the symlinks still
work: Fightcade reads through the unified path, not a copy on internal storage.

## CRT / Switchres support

On CRT setups the installer gives Fightcade native-resolution switching during
gameplay, matching how Batocera's own emulators behave on a CRT. The Fightcade
lobby, queues, and settings run at your CRT menu timing (e.g. 640x480i from
EmulationStation or Advanced Game Settings), not at each game's native arcade
modeline. Switchres only changes the display when you start a game (TEST GAME,
online match, or training), applying the game's native modeline from your
`batocera.conf` `monitor=` profile, then restores menu timing when the game exits.

Switchres engages only when the display mode is `xorg` and the current width is below
1024 (i.e. a CRT menu resolution).

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
| `fightcade-roms-sync` | Re-scan your `/userdata/roms` folders and refresh Fightcade symlinks (new arcade `.zip` files, console dirs, etc.) |
| `fightcade-diagnose` | Print install state, link health, and CRT status |
| `fightcade-crt-watch stop` | Stop the CRT watcher and restore configs/display (recovery after a stuck Switchres state) |
| `fightcade-crt-watch daemon` | Start the CRT watcher manually (only needed if you ran `stop` while Fightcade is still open; otherwise relaunch Fightcade from ES) |
| `uninstall.sh` | Remove links, hook, overrides, and scripts (ROMs and Flatpak untouched) |
| `uninstall.sh --uninstall-flatpak` | Also uninstall the Fightcade Flatpak |

Advanced: optional `fightcade-switchres.disable` and `fightcade-switchres.force` files
under `/userdata/system/configs/` permanently opt out of Switchres or force it on;
`fightcade-diagnose` reports whether either flag is set.

## Re-running the installer

Re-running the installer over an existing install is safe. It creates missing links,
refreshes changed ones, and does not modify real user files.

License: [CC0 1.0](LICENSE)
