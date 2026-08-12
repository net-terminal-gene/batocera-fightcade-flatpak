# Beta test checklist

Use this while testing [Fightcade Flatpak for Batocera](../README.md) before we call the
installer done. Check off each item and note anything that fails.

**Report problems** with Batocera version, GPU, output (HDMI / VGA / etc.), display
mode and resolution, what you launched, game + emulator (FBNeo / SNES / Flycast),
expected vs actual behavior, and the output of:

```bash
/userdata/system/fightcade-flatpak/fightcade-diagnose
```

Post results in the **beta thread on Discord**: https://discord.com/channels/357518249883205632/1536626216105148436

---

## Beta unlock script (beta testers only)

Use this to install or upgrade to a **GitHub branch** before it merges to `main`.
No repo clone required: the installer downloads scripts over HTTPS from GitHub.

Replace `BRANCH` with the branch under test (e.g. `fix/my-feature`):

```bash
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh \
  | bash -s -- -y --branch BRANCH
```

- Keep the curl URL on `main/install.sh`; `--branch` selects which ref all files come from.
- Re-running over an existing install is safe (overwrites `/userdata/system/fightcade-flatpak/`).
- Records the branch in `.install-branch`; `fightcade-diagnose` shows **Installer source branch**.
- **Exit Fightcade and relaunch** after upgrading so background helpers reload.

Alternative (same behavior):

```bash
export FIGHTCADE_FLATPAK_BRANCH=BRANCH
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh \
  | bash -s -- -y
```

Return to stable `main`:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/main/install.sh \
  | bash -s -- -y
```

---

## Before you start (all testers)

- [ ] Batocera is online during install
- [ ] Install completed without errors (stable `main` from [README](../README.md#install),
      or [beta unlock script](#beta-unlock-script-beta-testers-only) for a PR branch)
- [ ] `/userdata/system/fightcade-flatpak/fightcade-diagnose` runs and you saved the output
      (if using a branch, confirm **Installer source branch** matches)
- [ ] Fightcade appears under **Ports** in EmulationStation (Flatpak entry + artwork)
- [ ] At least one Fightcade-format ROM set for each system is in `/userdata/roms` (see README mapping)
- [ ] You can sign into Fightcade and reach a channel lobby

---

## Gamepad and menu controls (all testers)

Full mapping tables: [README controls](../README.md#controls--navigation) ·
[CRT controls](CRT.md#controls--navigation). Test on **HD** and **CRT** where you
run each mode below.

Chat still needs a keyboard. If gamepad navigation does nothing, check
`/userdata/system/fightcade-flatpak/fightcade-diagnose` for
`/userdata/system/configs/fightcade-pad-mouse.disable`.

### Lobby (Fightcade UI)

- [ ] Left stick / D-pad moves cursor (fast)
- [ ] Left stick / D-pad + **B** moves cursor (slow)
- [ ] **A** = left click
- [ ] **SELECT + R1** cycles focus between open windows (EmulationStation vs emulator vs Fightcade)

### FBNeo (arcade and console cores)

**While playing:**

- [ ] **SELECT + X** opens the FBNeo menu (sends **ESC**)
- [ ] On **CRT** with Switchres active: display returns to **lobby / menu timing** while the menu is open; menu cursor is visible

**While FBNeo menu is open:**

- [ ] Stick / D-pad + **B** move the menu cursor (fast / slow)
- [ ] **A** = left click in the menu
- [ ] **SELECT + Y** resumes the game and hides the menu cursor
- [ ] On **CRT** with Switchres active: display returns to the game's **native modeline** after resume
- [ ] **SELECT + R1** cycles window focus

**Keyboard (optional, FBNeo / SNES):**

- [ ] **ESC** opens the emulator menu (installer layer; not Fightcade **Esc** quit)
- [ ] **Alt+Delete** then **Alt+Enter** dismisses a stuck menu bar if **SELECT + Y** leaves the bar visible

### SNES9x

**While playing:**

- [ ] **SELECT + X** opens the Snes9x menu

**While Snes9x menu is open:**

- [ ] Menu cursor navigation (**A**, stick, stick + **B**) works
- [ ] **SELECT + Y** resumes the game
- [ ] On **CRT**: same Switchres pause / resume behavior as FBNeo when a Switchres session is active

### Flycast (Dreamcast / Naomi / Atomiswave)

**While playing:**

- [ ] **SELECT + X** opens the Flycast menu overlay
- [ ] **SELECT + Y** resumes the game (Dreamcast titles)

**While Flycast menu is open:**

- [ ] Menu cursor navigation works
- [ ] **SELECT + X** / **SELECT + Y** toggle the menu overlay as expected
- [ ] **SELECT + R1** cycles window focus (where applicable)

---

## HD mode (LCD / HDMI)

Use this path when EmulationStation and Fightcade run at your normal HD resolution
(1080p, 1440p, 4K, etc.). CRT Switchres is not required for this section.

### Install and ROM wiring

- [ ] Re-running `/userdata/system/fightcade-flatpak/install.sh` on an existing install is safe (no broken links)
- [ ] Adding a new arcade `.zip` in `/userdata/roms/fbneo/` that didn't exist during install sync will automatically appears in Fightcade after launching the App
  (gameStart hook + `/userdata/system/fightcade-flatpak/fightcade-roms-sync`)
- [ ] Symlinks point at `/userdata/roms` (not duplicate copies inside Flatpak data)

### Fightcade session paths (HD)

Test each path below at your normal HD resolution (1080p, 1440p, 4K, etc.). Use at
least one **FBNeo** title for every path; also run **SNES** and **Flycast** when you have
ROMs and BIOS for them. In the Fightcade UI, you can easily filter for games under a specific system by going into Search 🔍 > Filter 🎚️ > SYSTEM.

#### TEST GAME

- [ ] **TEST GAME** launches fullscreen at correct aspect (not stretched off-screen)
- [ ] Image is not windowed in a small corner
- [ ] Gameplay runs without obvious vsync tearing (fighters / scrollers)
- [ ] Gamepad menu controls work (**SELECT + X** / **SELECT + Y**; see [controls checklist](#gamepad-and-menu-controls-all-testers))
- [ ] Exiting returns to the Fightcade lobby at HD resolution (no black screen)

#### TRAINING

- [ ] **TRAINING** launches and runs like **TEST GAME** (fullscreen, correct aspect)
- [ ] Menus and gamepad navigation work during training
- [ ] Leaving training returns to the lobby at HD resolution

#### ONLINE MATCH

- [ ] **ONLINE MATCH** starts and runs a full match at HD resolution
- [ ] Match end returns to the lobby cleanly (no stuck game window)
- [ ] A second consecutive match still launches and displays correctly

#### REPLAY

- [ ] **REPLAY** loads and plays at HD resolution
- [ ] Leaving replay returns to the lobby at HD resolution

#### LIVE SPECTATING

- [ ] **LIVE SPECTATING** enters a live session and video plays at HD resolution
- [ ] Leaving spectate returns to the lobby at HD resolution

### Emulator coverage (HD)

- [ ] **FBNeo** (arcade or console core): tested in at least one session path above
- [ ] **SNES9x**: game launches fullscreen with 4:3 aspect; menu controls verified in [controls checklist](#gamepad-and-menu-controls-all-testers)
- [ ] **Flycast** (Dreamcast / Naomi / Atomiswave): fullscreen; Naomi / Atomiswave load when BIOS + ROM sets are correct; menu controls verified

### HD video patch

- [ ] After install, `/userdata/system/fightcade-flatpak/hd/patch-hd-video.sh` reports your current resolution
- [ ] After changing Ports > Fightcade > Advanced Game Settings > Video Mode (e.g. 1080p → 1440p), re-run `/userdata/system/fightcade-flatpak/hd/patch-hd-video.sh` and games still fill the screen

---

## CRT mode (xorg + Switchres)

Use this path on a **CRT** setup with **xorg** display mode and menu timing below HD
(e.g. 640×480i). Requires [**Batocera-CRT-Script**](https://github.com/ZFEbHVUE/Batocera-CRT-Script)
installed and configured first.

See [CRT.md](CRT.md) for controls, flags, and recovery.

### Prerequisites

- [ ] [Batocera-CRT-Script](https://github.com/ZFEbHVUE/Batocera-CRT-Script) installed and CRT menu timing works for other emulators
- [ ] `batocera-resolution getDisplayMode` reports **xorg**
- [ ] Ports > Fightcade > Advanced Game Settings > Video Mode is at AUTO / CRT timing (not HD resolution) before opening Fightcade
- [ ] `/userdata/system/fightcade-flatpak/fightcade-diagnose` shows CRT host watcher installed (and running while Fightcade is open)
- [ ] Lobby controls from [gamepad checklist](#gamepad-and-menu-controls-all-testers) work at CRT menu timing
- [ ] No Switchres flag files present (see [Switchres on/off](#switchres-onoff-crt) below):
  ```bash
  rm -f /userdata/system/configs/fightcade-switchres.disable
  rm -f /userdata/system/configs/fightcade-switchres.force
  ```

### Lobby (CRT menu timing)

- [ ] Fightcade lobby readable at menu resolution (not HD-sized window)

### Fightcade session paths (CRT / Switchres)

These paths test **normal Switchres** (per-game resolution switching turned **on**). Do not
create `/userdata/system/configs/fightcade-switchres.disable` or
`/userdata/system/configs/fightcade-switchres.force` until you finish this section.

When a game starts, the CRT should switch to that game's native resolution. When you
leave the game, the display should return to lobby / menu timing (e.g. 640×480i).

#### TEST GAME

- [ ] **TEST GAME** switches display to the game's **native modeline** (resolution + refresh)
- [ ] Gameplay fills the CRT as expected for that title
- [ ] **SELECT + X** during gameplay: lobby timing + emulator menu (Switchres paused)
- [ ] **SELECT + Y** from menu: native modeline restored, gameplay resumes
- [ ] Exiting the game restores **lobby / menu timing**
- [ ] No black screen stuck after exit

#### TRAINING

- [ ] **TRAINING** switches to native modeline like **TEST GAME**
- [ ] Training session runs at native resolution during play
- [ ] Leaving training restores **lobby / menu timing**

#### ONLINE MATCH

- [ ] **ONLINE MATCH** runs at native resolution during play
- [ ] Match end returns to lobby timing cleanly
- [ ] Second consecutive match still switches resolution correctly

#### REPLAY

- [ ] **REPLAY** loads at native resolution
- [ ] Leaving replay restores lobby timing

#### LIVE SPECTATING

- [ ] **LIVE SPECTATING** applies the correct modeline for the spectated game
- [ ] Leaving spectate restores lobby timing

Use at least one **FBNeo** title for every path; also run **SNES** and **Flycast** when
you have ROMs and BIOS. Filter by system in Fightcade: Search 🔍 → Filter 🎚️ → SYSTEM.

### Emulator coverage (CRT)

- [ ] **FBNeo** tested in at least one session path above (not only arcade)
- [ ] At least one of **SNES** or **Flycast** tested on CRT in at least one session path

### Switchres on/off (CRT)

Switchres is the piece that changes CRT resolution per game. You control it with two
optional files under `/userdata/system/configs/`:

| Mode | Flag file | What happens when you start a game |
|------|-----------|-------------------------------------|
| **On** (default) | neither file exists | CRT switches to the game's native resolution; lobby timing returns when you exit |
| **Off** | `fightcade-switchres.disable` | CRT stays at lobby timing; no per-game resolution change |
| **Forced on** | `fightcade-switchres.force` | Switchres runs even when default rules would skip it (e.g. wide lobby on xorg) |

Details: [Switchres flags](CRT.md#switchres-flags).

#### Step 1 — Normal mode (required for all CRT testers)

You already exercised this if the [session paths](#fightcade-session-paths-crt--switchres)
above passed. Confirm with diagnose:

```bash
/userdata/system/fightcade-flatpak/fightcade-diagnose
```

- [ ] Diagnose shows **xorg** and a line like **Switchres will engage on game launch** (CRT menu is usually under 1024 px wide)
- [ ] Session paths above passed (that is the real proof Switchres is working)

#### Step 2 — Turn Switchres off (optional)

Only if you want to verify the kill switch. Create the file, test, then delete it.

```bash
touch /userdata/system/configs/fightcade-switchres.disable
/userdata/system/fightcade-flatpak/fightcade-diagnose   # should say DISABLED
```

- [ ] **TEST GAME**: display **does not** change resolution (stays at lobby timing)
- [ ] **SELECT + X** / **SELECT + Y** still open and close emulator menus

```bash
rm -f /userdata/system/configs/fightcade-switchres.disable
```

#### Step 3 — Force Switchres on (optional, edge-case testers only)

Skip unless your lobby is **wide** (width ≥ 1024 on xorg) and diagnose says Switchres
would **NOT** engage in normal mode. Create the file, test, then delete it.

```bash
touch /userdata/system/configs/fightcade-switchres.force
/userdata/system/fightcade-flatpak/fightcade-diagnose   # should say FORCED on
```

- [ ] **TEST GAME** switches to the game's native resolution (even though normal mode would not)
- [ ] Exit returns to lobby timing; **SELECT + X** / **SELECT + Y** still work

```bash
rm -f /userdata/system/configs/fightcade-switchres.force
```

### Recovery and edge cases

- [ ] `/userdata/system/fightcade-flatpak/crt/fightcade-crt-recover` restores lobby timing after a forced quit or stuck session
- [ ] No leftover `*.bak.switchres` files after normal game exit (`/userdata/system/fightcade-flatpak/fightcade-diagnose` should not FAIL on these)
- [ ] Re-run `/userdata/system/fightcade-flatpak/install.sh` after a Fightcade Flatpak update; game launch + Switchres still work

---

## Notes

| Field | Your value |
|-------|------------|
| Batocera version | |
| GPU / output | |
| Display mode (HD / CRT) | |
| Menu / lobby resolution | |
| Tester | |
| Date | |

**What worked:**

**What failed (steps to reproduce):**

---

[← Back to main README](../README.md) · [CRT / Switchres details](CRT.md)
