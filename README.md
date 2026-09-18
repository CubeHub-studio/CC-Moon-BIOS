# Moon BIOS

Moon BIOS is a BIOS-style boot environment for CC:Tweaked computers.

## Install

### Recommended: CC PKG

If CC PKG is installed, use:

```text
pkg install moon-bios
```

CC PKG automatically selects the compatible Moon BIOS version:

- `v1.3 pocket` → pocket computers
- `v1.3` → regular computers
- Any version whose name contains `pocket` is pocket-only.
- All other version names are regular-computer versions.

The regular-computer `v1.3` package currently serves the **v1.3 Fixed** source.

### Manual installation

For a regular computer, the current v1.3 source can be installed with:

```lua
wget https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/versions/v1.3/startup startup
wget https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/versions/v1.3/updatemoonbios updatemoonbios
reboot
```

For the pocket version:

```lua
wget https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/versions/v1.3-pocket/startup startup
wget https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/versions/v1.3-pocket/updatemoonbios updatemoonbios
reboot
```

## Updating

### Using CC PKG

Update the package manager first if needed:

```text
pkg self-update
```

Then upgrade installed packages:

```text
pkg upgrade
```

### Using the Moon BIOS updater

From the CC Shell, run:

```text
updatemoonbios
```

The updater downloads the version-specific Moon BIOS files.

## Boot shortcuts

During the Moon BIOS boot countdown:

- `1` → BIOS
- `2` → Boot Manager
- `3` → Safe Mode
- `ENTER` → boot immediately

Escape is not used as a BIOS GUI control.

## Moon BIOS v1.3 Fixed

The regular-computer `versions/v1.3/startup` source is synchronized with the **v1.3 Fixed** release source. This is the source served to CC PKG for the regular `v1.3` package.

## Files

```text
versions/
├── v1.2-mini/
├── v1.2-advance/
├── v1.3/
└── v1.3-pocket/
```

Each version directory contains its `startup` and `updatemoonbios` files.

## License

This project is licensed under the LUNAR CUBES v1.0 License.
