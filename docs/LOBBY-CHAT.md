# Fightcade lobby chat config

Send preset chat lines from your gamepad while you are in the **Fightcade lobby**
(home, rooms, queues). Hold **R1** and press a face button or **R2** to type the
message and send it.

Free-form typing still needs a keyboard. Lobby chat macros are for quick lines you
send often (`ggs!`, `wp`, `rematch?`, and so on).

## Contents

- [How to use](#how-to-use)
- [Config file](#config-file)
- [Editing your messages](#editing-your-messages)
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

## Config file

Your editable copy (created on first install):

```
/userdata/system/configs/fightcade-lobby-chat.conf
```

Shipped template (reference only; installer does not overwrite your copy on upgrade):

```
/userdata/system/fightcade-flatpak/input/fightcade-lobby-chat.conf
```

## Editing your messages

Open the config on your Batocera box with any text editor. Over SSH:

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

# Disable east (right click is still used for challenges in the lobby)
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
| `south` | SOUTH | Bottom face | `ggs!` |
| `east` | EAST | Right face | `wp` |
| `west` | WEST | Left face | `rematch?` |
| `north` | NORTH | Top face | `gg` |
| `r2` | R2 | Right trigger (as button) | `nice` |

## Defaults

Out of the box, the installer copies these lines into your config:

| Slot | Message |
|------|---------|
| **south** | `ggs!` |
| **east** | `wp` |
| **west** | `rematch?` |
| **north** | `gg` |
| **r2** | `nice` |

Change them to whatever your room or game community uses.

## After you save changes

Restart Fightcade so `fightcade-pad-mouse` reloads the file:

- Quit Fightcade from the lobby and launch it again from EmulationStation, or
- Run:

```bash
/userdata/system/fightcade-flatpak/input/fightcade-pad-mouse stop
/userdata/system/fightcade-flatpak/input/fightcade-pad-mouse daemon
```

## Troubleshooting

**Verify bindings and loaded macros** (diagnostic only; does not control Fightcade):

```bash
/userdata/system/fightcade-flatpak/input/fightcade-pad-mouse probe
```

Look for `Lobby chat macros (R1 + slot):` and your messages.

| Problem | Check |
|---------|--------|
| Nothing sent | Chat input focused? Are you in the **lobby**? Hold **R1** first, then tap the slot. |
| Wrong button | Run `probe`; slot names follow ES mapping, not plastic labels. |
| Old messages after edit | Restart Fightcade or pad-mouse (see above). |
| Config missing | Re-run `/userdata/system/fightcade-flatpak/install.sh`; first install creates the file. |

[← Controls & navigation](CONTROLS.md) · [← Main README](../README.md)
