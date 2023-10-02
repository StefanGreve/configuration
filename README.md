# Configuration

This repository primarily consists of configuration files geared toward power users.
As a successor to [`confiles`](https://github.com/StefanGreve/confiles), the following
improvements has been made:

- better ease of use
- cross-platform support
- updated default settings

## Prerequisites

You will need to have [`pwsh`](https://github.com/PowerShell/PowerShell) installed
on your platform of choice in order to run any of the scripts, in addition to the
following platform-specific prerequisites:

### Windows

- [ ] `winget`

### Linux

TODO

### MacOS

TODO

## Usage

Run the following scripts to bootstrap your system, preferably in order:

Install all required programs:

> ⚠ Cargo installs can be very time intensive, depending on your hardware specification.

```powershell
.\scripts\install.ps1
```

Symlink config files from the apps directory by force:

> ⚠ This script will override your custom settings and requires elevated permissions.

```powershell
.\scripts\link.ps1
```

## Notes

TODO
