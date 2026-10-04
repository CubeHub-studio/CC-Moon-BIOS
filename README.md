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

The repository also contains `.pkg` and `.pkgignore`. The `.pkg` file describes the installer-first package workflow, while `.pkgignore` keeps repository-only documentation and development material out of a future CC-PKG build.

### CC PKG

Moon BIOS is designed as an installer-backed package rather than a package that blindly replaces `/startup`. The package definition is kept in `.pkg`, and `.pkgignore` defines files that are repository/build material rather than installed package content.

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

## Boot Registration

Moon BIOS can locally register a computer from **BIOS Settings → Registration**.

When a boot file is launched by Moon BIOS, it receives registration and Moon information in its program environment:

- `MOONBIOS` — table containing version, registration data, computer ID/label, and Moon phase data.
- `MOONBIOS_VERSION`
- `MOONBIOS_REGISTERED`
- `MOONBIOS_REGISTRATION_ID`
- `MOONBIOS_REGISTRATION_DATE`
- `MOONBIOS_COMPUTER_ID`
- `MOONBIOS_COMPUTER_LABEL`
- `MOONBIOS_MOON_PHASE`
- `MOONBIOS_MOON_PHASE_AGE`
- `MOONBIOS_MOON_ICON`

The Moon icon shown by the BIOS is selected from the current lunar phase as a small visual Easter egg. Registration is local to the computer; it does not send registration data to a server.

## Phase 1

The first Phase 1 improvements now include:

- Moon Kernel log viewer.
- Boot history.
- Multiple Moon phase icons.
- Current Moon phase Easter egg.
- Local computer registration.
- Registration variables exposed directly to the configured boot file.
