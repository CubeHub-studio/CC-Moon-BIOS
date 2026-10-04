# Moon BIOS

Moon BIOS is a BIOS-style boot environment for CC:Tweaked computers.

## Installation

**Moon BIOS now requires the Moon BIOS Installer.** Directly installing the BIOS core is no longer supported.

### Manual installation

On a CC:Tweaked computer with HTTP enabled:

~~~text
wget https://raw.githubusercontent.com/CubeHub-studio/CC-Moon-BIOS/main/installer.lua installer
installer
~~~

The installer detects the computer type, selects the compatible release, creates the /.moonbios/ installation tree, installs the BIOS core and updater, installs the /startup bootloader, backs up an existing /startup, writes an installation manifest, and installs /mooninstaller for future reinstallation.

The installer is intentionally the only supported way to create a Moon BIOS installation. This gives Moon BIOS a stable installation boundary for future modules, configuration, recovery, integrity checking, and upgrades.

### CC PKG

If CC PKG is installed:

~~~text
pkg install moon-bios
~~~

CC PKG should launch the Moon BIOS installer rather than placing the BIOS core directly in /startup.

## Installation layout

A normal installation looks like:

~~~text
/
├── startup
├── mooninstaller
└── .moonbios/
    ├── core/
    │   ├── bios.lua
    │   └── updater.lua
    ├── legacy/
    │   └── startup.backup
    └── manifest
~~~

`/startup` is only the bootloader. The actual BIOS lives under `/.moonbios/core/`.

The bootloader refuses to start the BIOS if the installation manifest or BIOS core is missing. It directs the user to the installer instead.

## Updating

Run:

~~~text
updatemoonbios
~~~

The updater is installed as part of Moon BIOS and updates the installed core through the same installation architecture.

## Boot shortcuts

During the Moon BIOS boot countdown:

- `1` → BIOS
- `2` → Boot Manager
- `3` → Safe Mode
- `ENTER` → boot immediately

Escape is not used as a BIOS GUI control.

## Releases

Current release sources are retained under:

~~~text
versions/
├── v1.2-mini/
├── v1.2-advance/
├── v1.3/
└── v1.3-pocket/
~~~

The current v1.3 sources are kept as release payloads. New Moon BIOS versions can be added as installer-managed cores without changing the bootloader architecture.

## Repository architecture

~~~text
installer/
├── installer.lua
├── startup
└── updater.lua

core/
└── v1.3/
    └── bios.lua

versions/
├── v1.2-mini/
├── v1.2-advance/
├── v1.3/
└── v1.3-pocket/
~~~

The installer architecture is designed so future Moon BIOS releases can add components without putting everything into /startup.

## License

This project is licensed under the LUNAR CUBES v1.0 License.