# Controls & navigation

> Fightcade is designed to be used with a **keyboard and mouse**, especially for
> **chat**. This installer adds **gamepad navigation** so you can move the cursor
> and open menus without a mouse. For preset lobby chat lines from the gamepad, see
> [Fightcade lobby chat config](LOBBY-CHAT.md).

## Contents

- [Game controller mapping](#game-controller-mapping)
- [Batocera hotkeys (SELECT)](#batocera-hotkeys-select)
- [Context table](#context-table)
- [Keyboard shortcuts (HD)](#keyboard-shortcuts-hd)

## Game controller mapping

Fightcade gamepad controls use the same layout as **EmulationStation**. On a fresh
Batocera install with a common controller (Xbox, PlayStation, 8BitDo, and similar),
you can navigate Fightcade immediately with no extra setup.

**The label printed on the plastic does not matter.** Only which **slot** you
assigned matters: **SOUTH**, **EAST**, **NORTH**, **WEST**, and the rest. If you
put **SOUTH** on the right-hand button in **ES Controller Mapping**, left click
moves to the right. The slot is the role; you choose which physical button fills it.

### Stock layout (default)

Out of the box, on a standard diamond face layout:

| Slot | Stock position | Fightcade action |
|------|----------------|------------------|
| **SOUTH** | Bottom face button | Left click |
| **EAST** | Right face button | Right click |
| **WEST** + **SELECT** | Left face button | Pause / open emulator menu |
| **NORTH** + **SELECT** | Top face button | Resume game |
| **D-pad** | D-pad | Move cursor |
| **Left analog** | Left stick | Move cursor |
| **R2** (held alone) | Right trigger | Slow cursor |
| **R1** + **SOUTH** / **EAST** / **WEST** / **NORTH** / **R2** | Face buttons / R2 | Send lobby chat line ([lobby chat config](LOBBY-CHAT.md)) |
| **Right shoulder** + **SELECT** | Right bumper | Alt+Tab (cycle windows) |
| **START** + **SELECT** | Start button | Alt+F4 (quit emulator, return to lobby) |

That is the default for most pads Batocera already knows. EmulationStation menus and
Fightcade lobby controls use the same assignments.

### ES Controller Mapping (optional)

Open **System Settings → ES Controller Mapping** only if you want to change the
stock layout, for example:

- Accessibility (move a slot to a different physical button)
- Fight sticks or unusual button layouts
- A pad that does not feel right until you remap it once

Map each controller the same way (same slots, same roles). Fightcade follows whatever
you set in **ES Controller Mapping** for that pad. The **slot → action** table above
does not change; only which physical button you assign to each slot changes.

**Lobby** = Fightcade UI (home, search, rooms, chat, settings). **FBNeo / SNES menu**
= emulator menu bar visible. **Flycast menu** = in-game overlay with cursor visible.

**Cursor speed:** move the stick or D-pad normally for fast cursor movement. Hold **R2**
alone while moving the stick or D-pad for slow, precise movement (lobby and emulator menus).

**Clicks:** **SOUTH** = left click, **EAST** = right click (challenge flow, context menus).

**Window focus:** **SELECT + right shoulder** sends Alt+Tab to cycle EmulationStation, Fightcade,
and any open emulator window.

**Quit game:** **SELECT + Start** sends Alt+F4 to close the emulator and return to the
Fightcade lobby (while a game is running).

To challenge someone in a room: **EAST** (right click) on their name, then **SOUTH** (left click)
**Challenge**.

Diagnostic: `/userdata/system/fightcade-flatpak/input/fightcade-pad-mouse probe`

## Batocera hotkeys (SELECT)

On Batocera, **SELECT** is usually the controller **hotkey** button. While Fightcade
(or any game) is running, Batocera also listens for **Hotkey + face button** combos.
Those are **global Batocera bindings**, not Fightcade features.

Default mapping (Batocera ES slot names):

| Hotkey + | ES slot | Batocera action |
|----------|---------|-----------------|
| **A** | **EAST** | Batocera Control Center (game info, record, system) |
| **B** | **SOUTH** | Menu |
| **X** | **NORTH** | Load state |
| **Y** | **WEST** | Save state |
| **R1** (pagedown) | Right shoulder | Auto-translate (libretro cores) |

This installer uses **SELECT** for pause, resume, Alt+Tab, and quit. When you press
**SELECT + WEST** or **SELECT + NORTH**, Batocera may receive the same chord as
**Hotkey + save/load** at the OS level.

**What we found in practice**

- **Hotkey + EAST** (Control Center) can open during Fightcade. That is the overlap
  users notice most often.
- **Hotkey + WEST/NORTH** (save/load) share the same physical buttons as pause/resume,
  but Fightcade runs as a **Flatpak** port. Batocera's Flatpak hotkey context only wires
  **exit**, not save/load, so those combos are unlikely to create Batocera save-state
  files during Fightcade play.
- Lobby chat uses **R1 + slot** (not SELECT) so chat lines do not open Control Center.
  See [Fightcade lobby chat config](LOBBY-CHAT.md).

**Do not globally disable Batocera hotkeys** (for example
`batocera-joysticks-hotkeys --a none`) unless you want that everywhere on the box.
That affects every emulator, not just Fightcade.

Optional: if Control Center still gets in the way, check whether your Batocera build
exposes **exit hotkey only** (or similar) for the Fightcade port. That limits
in-game overlays for Fightcade only without changing other systems.

View or change global bindings: `batocera-joysticks-hotkeys` (see
[Batocera wiki](https://wiki.batocera.org/)).

## Context table

| Where you are | Left Analog/D-pad | + R2 (held) | SOUTH | EAST | SELECT + WEST | SELECT + NORTH | SELECT + R shoulder | SELECT + Start |
|---------------|-------------------|-------------|-------|------|---------------|----------------|---------------------|----------------|
| **Lobby** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | — | Alt+Tab (cycle windows) | — |
| **FBNeo playing** | — | — | — | — | Open FBNeo menu (ESC) | — | — | Quit emulator (lobby) |
| **FBNeo menu open** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | Resume game | Alt+Tab (cycle windows) | Quit emulator (lobby) |
| **SNES playing** | — | — | — | — | Open Snes9x menu (ESC) | — | — | Quit emulator (lobby) |
| **SNES menu open** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | Resume game | Alt+Tab (cycle windows) | Quit emulator (lobby) |
| **Flycast playing** | — | — | — | — | Open menu | Resume game | — | Quit emulator (lobby) |
| **Flycast menu** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | Open menu | Resume game | — | Quit emulator (lobby) |

CRT users: **ESC** and **Alt+Delete** for FBNeo/SNES menus at native resolution are
documented in [CRT.md — Keyboard](CRT.md#keyboard-fbneo--snes).

## Keyboard shortcuts (HD)

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
stays visible until Alt+Enter. Gamepad **SELECT + NORTH** triggers CRT resume
(Alt+Delete / menu dismiss) on CRT setups.

[← Fightcade lobby chat config](LOBBY-CHAT.md) · [← Main README](../README.md)
