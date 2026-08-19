# HD Mode Validation Setup

## Branch: feat/hd-mode-validation

This branch contains a minimal Fightcade Flatpak installer designed to test vanilla Fightcade in HD mode without the additional integration layers that might be over-engineered.

## Installation Command

For HD mode validation testing, run the minimal installer:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/feat/hd-mode-validation/install-minimal.sh \
  | bash -s -- -y --branch feat/hd-mode-validation
```

For the full-featured installer (standard):

```bash
curl -fsSL \
  https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/feat/hd-mode-validation/install.sh \
  | bash -s -- -y --branch feat/hd-mode-validation
```

## Changes

### install.sh (Full Version - Default)
- Original full-featured installer with all integrations
- 574 lines
- Includes:
  - Controller setup (fightcade-pad-mouse, fightcade-cursor)
  - Switchres CRT wrapper
  - HD video presets
  - Game hooks
  - Flatpak xdg-open patching
  - Input configs
  - CLI tool symlinks
  - Diagnostic tools

### install-minimal.sh (Minimal Version - HD Validation)
- New minimal installer for HD mode validation
- 311 lines (~46% smaller)
- Includes ONLY:
  - Fightcade Flatpak installation
  - ROM folder symlinks (via fightcade-roms-sync)
  - Flatpak filesystem overrides for ROM access
  - EmulationStation artwork and gamelist entry

### What's Removed from install-minimal.sh
- **No controller setup**: No fightcade-pad-mouse or input scripts
- **No Switchres**: No CRT wrapper or display switching
- **No HD presets**: No video configuration overrides
- **No game hooks**: No custom scripts triggered by game events
- **No CLI tools**: No symlinks to /usr/bin
- **No xdg-open patching**: No fcade:// URL interception

## Testing Plan

1. Flash fresh Batocera v43 drive
2. Run minimal installer: `curl -fsSL https://raw.githubusercontent.com/net-terminal-gene/batocera-fightcade-flatpak/feat/hd-mode-validation/install-minimal.sh | bash -s -- -y --branch feat/hd-mode-validation`
3. Test Fightcade in HD mode with vanilla configuration
4. Compare behavior against expectations
5. Identify which features from install.sh are actually needed for HD mode

## Goal

Determine if the HD mode implementation is over-engineered by testing vanilla Fightcade first, then incrementally adding only the features that are actually needed.
