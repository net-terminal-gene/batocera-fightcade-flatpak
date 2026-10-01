#!/usr/bin/env python3
"""
Generate lobby/vertical-allowlist.js from the KB vertical-matches research file.
Includes per-game name, emulator, and system so the JS can synthesize channel
objects for games not returned by Fightcade's paginated API (~2200 cap).

Usage:
  python3 scripts/gen-vertical-allowlist.py
  # Run from the root of batocera-fightcade-flatpak.

Output: lobby/vertical-allowlist.js
"""
import re
import json
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
KB_MD = (
    Path.home()
    / "Batocera-Development-KB"
    / "entries"
    / "2026-09-30_fightcade-vertical-library"
    / "research"
    / "vertical-matches.md"
)
OUT = REPO_ROOT / "lobby" / "vertical-allowlist.js"

# Map section heading → (emulator, system, optional Fightcade gameid prefix)
# Values match live Fightcade channel objects (dump 2026-10-01):
#   flycast_karous / flycast / NAOMI
#   snes_raiden    / snes9x  / Super NES
#   pce_sharrier   / fbneo   / PC-Engine
#   md_aburner2    / fbneo   / Megadrive
#   flycast_dc_*   / flycast / Dreamcast
SECTION_MAP = {
    "FinalBurn Neo": ("fbneo", "Arcade FC2", ""),
    "FinalBurn Neo, same title and a different id": ("fbneo", "Arcade FC2", ""),
    "NAOMI": ("flycast", "NAOMI", "flycast_"),
    "Super NES": ("snes9x", "Super NES", "snes_"),
    "PC Engine": ("fbneo", "PC-Engine", "pce_"),
    "NES": ("fbneo", "NES", "nes_"),
    "Mega Drive": ("fbneo", "Megadrive", "md_"),
    "Dreamcast": ("flycast", "Dreamcast", "flycast_dc_"),
}

text = KB_MD.read_text(encoding="utf-8")
lines_raw = text.splitlines()

# Parse section-by-section, extract (gameid, fightcade_title, emulator, system)
entries: dict[str, tuple[str, str, str]] = {}  # gameid → (name, emulator, system)
current_emulator = "fbneo"
current_system = "Arcade FC2"
current_prefix = ""

for line in lines_raw:
    m_sec = re.match(r'^## (.+)', line)
    if m_sec:
        heading = m_sec.group(1).strip()
        if heading in SECTION_MAP:
            current_emulator, current_system, current_prefix = SECTION_MAP[heading]
        continue
    # Table row: | Vertical title | `gameid` | Fightcade title |
    m_row = re.match(r'^\|\s*.+?\s*\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|', line)
    if m_row:
        gameid = m_row.group(1).strip()
        fc_title = m_row.group(2).strip()
        if current_prefix and not gameid.startswith(current_prefix):
            gameid = current_prefix + gameid
        if gameid and gameid not in entries:
            entries[gameid] = (fc_title, current_emulator, current_system)

entry_list = list(entries.items())

output_lines = [
    "// Auto-generated from Batocera-Development-KB/.../vertical-matches.md",
    "// Do not edit by hand. Re-run scripts/gen-vertical-allowlist.py to update.",
    f"// {len(entry_list)} unique Fightcade gameids for vertical-orientation games.",
    "// Format per entry: [fightcade_title, emulator, system]",
    "(function () {",
    "  if (window.__FC_VERTICAL_IDS) { return; }",
    "  window.__FC_VERTICAL_IDS = {",
]
for i, (gameid, (name, emulator, system)) in enumerate(entry_list):
    comma = "," if i < len(entry_list) - 1 else ""
    val = json.dumps([name, emulator, system])
    output_lines.append(f"    {json.dumps(gameid)}: {val}{comma}")
output_lines += [
    "  };",
    "})();",
    "",
]

OUT.write_text("\n".join(output_lines), encoding="utf-8")
print(f"Wrote {OUT} ({len(entry_list)} entries)")
