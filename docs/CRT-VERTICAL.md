# CRT vertical lobby

> [!IMPORTANT]
> Vertical mode is **CRT only**. The **VERTICAL MODE** switch is listed in
> Advanced Game Options on a CRT cabinet. You will not see it in HD, and the
> lobby will not rotate if a leftover setting is still in `batocera.conf`.

The lobby, the ROMs / Window / Help menu, and the in-room layout are rotated for a
cabinet standing on its side. Gameplay still uses Switchres the same way as landscape
CRT: the display changes to the game's native modeline when a match, test, training,
replay, or live spectate starts.

## Contents

- [Turn it on in EmulationStation](#turn-it-on-in-emulationstation)
- [Rotated lobby](#rotated-lobby)
- [Lobby zoom](#lobby-zoom)
- [Rooms](#rooms)
- [Search: Vertical games](#search-vertical-games)

## Turn it on in EmulationStation

1. Highlight **Fightcade** in the EmulationStation game list (Ports).
2. Open **Advanced Game Options**.
3. Set **VERTICAL MODE** to on.
4. Back **all the way out** to the game list, then launch Fightcade from there.

Do **not** use the **LAUNCH** entry inside Advanced Game Options. EmulationStation
saves the switch when you close that menu. Launching from inside it starts Fightcade
before the change is written, so you get the old landscape lobby.

To go back to the normal landscape lobby, turn **VERTICAL MODE** off the same way,
leave the menu, and launch again.

## Rotated lobby

The whole Fightcade window is rotated 90 degrees to match a TATE cabinet. The pointer,
chat, Search, and the top **ROMs / Window / Help** menu rotate with it, so those
menus stay upright on the CRT instead of opening sideways.

Video Mode still has to resolve to **640×480**. See [CRT / Switchres](CRT.md#fightcade-resolution).

## Lobby zoom

Lobby zoom is under **Text** in the top nav menu (**Zoom In** / **Zoom Out**).
Those values are saved separately for **landscape** and **vertical**. Changing
zoom in vertical mode does not change the landscape lobby, and the other way
around. You can run a tighter or looser lobby on the TATE cabinet without
touching the zoom you use when the cabinet is in landscape.

## Rooms

Inside a game room the layout is stacked for the tall screen:

- **Looking to Play** sits above **Chat** (40% / 60%). The chat pane is taller.
- You scroll the room the same way as the landscape lobby: move the pointer, click
  Join / Challenge / chat as usual.

## Search: Vertical games

On Search, open the **Genre** filter and pick **Vertical**. That list is the
vertical-orientation games (shmups, and other titles that play tall).

You can keep filtering on top of that:

| Next filter | What you get |
|-------------|--------------|
| **System → PC-Engine** | HuCard vertical games |
| **System → NAOMI** | Naomi vertical games (Flycast) |
| **System → Super NES** | SNES vertical games |

Leave **System** on All to browse every vertical title. Ranked, year, and the text
search box still apply to the Vertical list the same way they do on All Games.
