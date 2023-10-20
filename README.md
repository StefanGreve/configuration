# Configuration

This project is a collection of configuration files and scripts that I use on my
personal computer. They have been open-sourced for my own convenience, so you may
use anything you see here at your own risk.

As a successor to
[`confiles`](https://github.com/StefanGreve/confiles),
this repository has been meticulously designed with cross-platform compatibility
in mind.

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

```powershell
.\scripts\configure.ps1 -All
```

As a result of running this scripts, a new assets directory will be created in
`$home/.config/assets`.

Update everything.

> ⚠ This script depends on global variables defined by my custom profile

```powershell
.\tools\update.ps1 -All
```

## Personal Notes

- Prior to the Windows 10 Creator Update, creating symbolic links required elevated
  permissions. Enabling the `Developer Mode` in the settings app lifts this restriction
- Running `configure.ps1` will add user-customized settings to `.gitconfig`, because
  this config file cannot expand variables such as `$home`. Use `git stash` to get
  around that
