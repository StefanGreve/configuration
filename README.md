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

**Run the following scripts to bootstrap your system, preferably in order.**

(Optional) Hook up the PowerShell profile file from the
[`profile`](https://github.com/StefanGreve/profile)
repository:

```powershell
.\scripts\setuprofile.ps1
```

The script above will clone the profile repository inside a `repos` directory on
your desktop by default. To use a different path, change the value of `$Repository`.

---

Install all required programs:

> ⚠ Cargo installs can be very time intensive, depending on your hardware specification.

```powershell
.\scripts\install.ps1 -All
```

The installer script also accepts individual flags for user-customized installations
and reads its definitions from the `settings` folder.

---

Symlink config files from the apps directory by force:

> ⚠ This script will override your custom settings and requires elevated permissions.

```powershell
.\scripts\configure.ps1
```

As a result of running this scripts, a new assets directory will be created in
`$home/.config/assets`.

## Notes

TODO
