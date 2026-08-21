# Controls & navigation

> Fightcade was designed around a **keyboard and mouse**, but this installer lets you
> run the whole thing from a **game controller**. Gamepad navigation moves the cursor
> and opens menus without a mouse, and you get **custom preset chat lines** you can fire
> off with a **button combo** (see [Fightcade lobby chat config](LOBBY-CHAT.md)), so you
> can still greet people, say GG, and get by in the lobby without a keyboard. It is not
> as flexible as typing, but it covers the essentials.
>
> **One caveat with the controller:** you cannot chat during gameplay. Preset chat works
> in the **lobby**, not mid-match.

## Contents

- [Game controller mapping](#game-controller-mapping)
- [Batocera hotkeys (SELECT)](#batocera-hotkeys-select)
- [Emulator menus (FBNeo / SNES)](#emulator-menus-fbneo--snes)
- [Context table](#context-table)
- [Keyboard shortcuts (HD)](#keyboard-shortcuts-hd)

## Game controller mapping

Fightcade gamepad controls use the same layout as **EmulationStation**. On a fresh
Batocera install with a common controller (Xbox, PlayStation, Nintendo Switch Pro,
8BitDo, and similar), plug in the pad, launch Fightcade, and use it. If the pad
already works in EmulationStation menus, it should work in the Fightcade lobby with
no extra setup.

**If a button does the wrong thing** (wrong click, R2 does nothing, and so on), map
the pad once in **System Settings → ES Controller Mapping**, then quit and relaunch
Fightcade. Fightcade reads the same slot layout Batocera saves for that controller.

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
| **R2** (held alone) | Trigger | Slow cursor (HD and CRT) |
| **R1** + **SOUTH** / **EAST** / **WEST** / **NORTH** / **R2** | Face buttons / R2 | Send lobby chat line ([lobby chat config](LOBBY-CHAT.md)) |
| **R1** + **SELECT** | Right shoulder button | Alt+Tab (cycle windows) |
| **START** + **SELECT** | Start button | Alt+F4 (quit emulator, return to lobby) |

That is the default for most pads Batocera already knows. EmulationStation menus and
Fightcade lobby controls use the same assignments.

### ES Controller Mapping (optional)

Open **System Settings → ES Controller Mapping** when you want to change the
stock layout, or when Fightcade does not match how the pad behaves in
EmulationStation:

- Accessibility (move a slot to a different physical button)
- Fight sticks or unusual button layouts
- A pad that does not feel right until you remap it once

Map each controller the same way (same slots, same roles). Fightcade follows whatever
you set in **ES Controller Mapping** for that pad. The **slot → action** table above
does not change; only which physical button you assign to each slot changes.

### Cursor speed

The stick or D-pad moves the pointer, and the speed is tuned for you automatically. HD
and CRT get their own speeds (a CRT screen is much smaller, so the pointer moves slower
there), and it switches based on your display, no setup needed.

When you need fine, pixel-level aiming, hold **R2** while you move. It works the same in
both HD and CRT.

Most people never touch this. If you want to change the speeds, they live in
`/userdata/system/configs/fightcade-pad-mouse.conf`, with separate HD and CRT values
(and separate `max_*` / `slow_*` keys for in-game, lobby, and menus). The file's header
comments explain the naming. Quit and relaunch Fightcade after editing.

### Emulator menus (FBNeo / SNES)

**SELECT + WEST** opens the emulator menu (sends **ESC**). On **CRT** with Switchres
active, the display returns to lobby / menu timing while the menu is open and the
pad cursor is shown. **SELECT + NORTH** resumes the game (CRT: restores the game's
native modeline and dismisses the menu). All of these combos are in the stock-layout
table above and the [context table](#context-table) below.

> [!TIP]
> **Cursor, focus, and fullscreen (HD and CRT):**
> - **No pad cursor after opening the menu?** Press **SELECT + WEST** again to bring it back.
> - **Clicks not landing on a window/dialog?** Press **SELECT + R1** a few times to focus
>   the window you are pointing at (Alt+Tab cycles windows).
> - **Back to fullscreen game:** press **SELECT + NORTH**. This is the fullscreen/resume
>   combo in both HD and CRT.

> [!WARNING]
> **If you open the in-game menu and change anything, quit the game and launch it again.**
> Once the emulator menu has been opened mid-game, some button combos (**WEST** / **NORTH**
> together with another button) can be misread afterward and, on **CRT**, may toggle
> Switchres on or off. Quit to the lobby (**SELECT + Start**) and relaunch the game so it
> starts in a clean state.

**Menu bar** items (File, Input, Game, and so on) receive clicks on the main emulator
window.

**Modal dialogs** (for example **Input → Map game inputs**) are separate Wine windows
on top of the menu. The installer detects the dialog under the pointer, raises only
that surface, and sends the click to the control under the cursor (**OK**, **Cancel**,
or a list row). You should not need a keyboard or Alt+Tab to close **Map game inputs**
with **SOUTH** on **OK**.

To challenge someone in a room: **EAST** (right click) on their name, then **SOUTH** (left click)
**Challenge**.

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

This installer uses **SELECT** for pause, resume, Alt+Tab, and quit, so it can overlap
with those global combos. In practice the only one you tend to notice is **Hotkey +
EAST** opening the **Control Center** during Fightcade. Save/load (**Hotkey + WEST /
NORTH**) share buttons with pause/resume, but Fightcade runs as a **Flatpak** port whose
hotkey context only wires **exit**, so those combos will not write Batocera save states.
Lobby chat deliberately uses **R1 + slot** (not SELECT) so it never opens Control Center.

If Control Center gets in the way, check whether your Batocera build offers **exit hotkey
only** for the Fightcade port (limits overlays for Fightcade alone). **Do not** globally
disable hotkeys (for example `batocera-joysticks-hotkeys --a none`) unless you want that
on every emulator. View or change bindings with `batocera-joysticks-hotkeys` (see the
[Batocera wiki](https://wiki.batocera.org/)).

## Context table

| Where you are | Left Analog/D-pad | + slow (R2) | SOUTH | EAST | SELECT + WEST | SELECT + NORTH | SELECT + R1 | SELECT + Start |
|---------------|-------------------|-------------------------|-------|------|---------------|----------------|---------------------|----------------|
| **Lobby** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | — | Alt+Tab (cycle windows) | — |
| **FBNeo playing** | — | — | — | — | Open FBNeo menu (ESC) | — | — | Quit emulator (lobby) |
| **FBNeo menu open** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | Resume game | Alt+Tab (cycle windows) | Quit emulator (lobby) |
| **SNES playing** | — | — | — | — | Open Snes9x menu (ESC) | — | — | Quit emulator (lobby) |
| **SNES menu open** | Move cursor (fast) | Move cursor (slow) | Left click | Right click | — | Resume game | Alt+Tab (cycle windows) | Quit emulator (lobby) |
| **Flycast (Dojo)** | — | — | — | — | — | — | — | Quit emulator (lobby) |

Flycast is handled by Dojo itself: **SELECT** opens its in-game menu, which also quits
the game. No cursor is shown at any point in a Flycast session, and SELECT + WEST /
NORTH do nothing there.

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
