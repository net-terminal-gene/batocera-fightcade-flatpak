# Fightcade lobby chat config

Send preset chat lines from your gamepad while you are in the **Fightcade lobby**
(home, rooms, queues). Hold **R1** and press a face button or **R2** to type the
message and send it.

Free-form typing still needs a keyboard. Lobby chat macros are for quick lines you
send often (`ggs!`, `wp`, `rematch?`, and so on).

## Contents

- [How to use](#how-to-use)
- [Edit from EmulationStation (no terminal)](#edit-from-emulationstation-no-terminal)
- [Config file](#config-file)
- [Editing your messages (text file)](#editing-your-messages-text-file)
- [Slot reference](#slot-reference)
- [Defaults](#defaults)
- [After you save changes](#after-you-save-changes)
- [Troubleshooting](#troubleshooting)

## How to use

1. Be in the **Fightcade lobby** (not in a game).
2. **Click the chat input** so Fightcade is ready to receive text.
3. Hold **R1** (right shoulder).
4. Press **SOUTH**, **EAST**, **WEST**, **NORTH**, or **R2** for the line you want.

**R1** is the chat modifier on purpose. **SELECT** is Batocera's hotkey button; using
SELECT + face buttons for chat opened Control Center and clashed with other combos.
See [Controls — Batocera hotkeys](CONTROLS.md#batocera-hotkeys-select).

In-game, **SELECT + WEST** and **SELECT + NORTH** still pause and resume. Lobby chat
macros do not run outside the lobby.

## Edit from EmulationStation (no terminal)

You can edit every slot from the gamepad, no text editor or SSH needed. This is
the easiest way for most people.

1. Highlight **Fightcade** in EmulationStation.
2. **Hold SOUTH** to open its options, then select **ADVANCED GAME OPTIONS**.
3. Scroll to the **EDIT LOBBY CHAT** group. You will see a row per slot:
   **NORTH**, **EAST**, **SOUTH**, **WEST**, **R2**, each showing its current text.
4. Select a slot to open the on-screen keyboard, type your message, and press the
   **circle checkmark** to save it and go back. Clear the text to **disable** that slot.
5. Press **B / Back** to leave ADVANCED GAME OPTIONS, then **B / Back** again to
   return to the game list. Backing out is what saves your changes.
6. Launch Fightcade normally (press **SOUTH**).

> [!IMPORTANT]
> **Changes only take effect on your next launch from EmulationStation.**
> ES saves these fields when you back out of the menus, not while the game starts.
> So after editing, back all the way out to the game list, then launch Fightcade.
> Do **not** use the **LAUNCH** entry inside the options menu, or the game can start
> before your edits are saved.

The values you set here are stored per game and written into the config file below
each time you launch, so the two methods stay in sync.

## Config file

Your editable copy (created on first install):

```
/userdata/system/configs/fightcade-lobby-chat.conf
```

Shipped template (reference only; installer does not overwrite your copy on upgrade):

```
/userdata/system/fightcade-flatpak/input/fightcade-lobby-chat.conf
```

## Editing your messages (text file)

Prefer a keyboard, or want to edit in bulk? Open the config on your Batocera box
with any text editor. Over SSH:

```bash
nano /userdata/system/configs/fightcade-lobby-chat.conf
```

Or edit the same path from a network share if you mount `/userdata` on your PC.

**Format:** one slot per line. Lines starting with `#` are comments.

```
slot=your message here
```

- **slot** is `south`, `east`, `west`, `north`, or `r2` (ES layout names, not plastic labels).
- **message** is the text sent to chat. It can include spaces and punctuation.
- Leave the value **empty** to disable a slot: `east=`

**Examples:**

```ini
# Short GG lines
south=ggs!
east=wp
west=rematch?
north=gg

# Leave a slot empty to disable it
east=

# R2 sends a longer line
r2=one more?
```

Slot names match **EmulationStation** controller mapping. If you remapped which
physical button fills each slot, the config still uses slot names (`south`, not
"bottom button"). See [Controls — Game controller mapping](CONTROLS.md#game-controller-mapping).

## Slot reference

| Config key | ES slot | Default button (stock layout) | Default message |
|------------|---------|-------------------------------|-----------------|
| `south` | SOUTH | Bottom face | `match` |
| `east` | EAST | Right face | `you quit?` |
| `west` | WEST | Left face | `great set!` |
| `north` | NORTH | Top face | `rematch?` |
| `r2` | R2 | Right trigger (as button) | `ggs!` |

## Defaults

Out of the box, the installer copies these lines into your config:

| Slot | Message |
|------|---------|
| **south** | `match` |
| **east** | `you quit?` |
| **west** | `great set!` |
| **north** | `rematch?` |
| **r2** | `ggs!` |

Change them to whatever your room or game community uses.

## After you save changes

Quit Fightcade and launch it again from EmulationStation.

## Troubleshooting

| Problem | Check |
|---------|--------|
| Nothing sent | Chat input focused? Are you in the **lobby**? Hold **R1** first, then tap the slot (not SELECT). |
| Wrong button | Slot names follow **ES Controller Mapping**, not plastic labels. Remap in ES if needed. |
| Old messages after edit | Quit and relaunch Fightcade from EmulationStation. |
| ES edits did nothing | Back **all the way out** to the game list (that saves them), then relaunch. Do not use the in-menu **LAUNCH**. |
| Config missing | Re-run `/userdata/system/fightcade-flatpak/install.sh`; first install creates the file. |

[← Controls & navigation](CONTROLS.md) · [← Main README](../README.md)
