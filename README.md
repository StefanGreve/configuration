# Configuration

This project is a collection of configuration files and scripts that I use on my
personal computer. They have been open-sourced for my own convenience, so you may
use anything you see here at your own risk.

The tools repository defines some custom Cmdlets which are implicitly dot-sourced
through my PowerShell profile.

As a successor to
[`confiles`](https://github.com/StefanGreve/confiles),
this repository has been meticulously designed with cross-platform compatibility
in mind.

## Prerequisites

You will need to have [`pwsh`](https://github.com/PowerShell/PowerShell) installed
on your platform of choice in order to run any of the scripts, as well as an
appropriate execution policy, e.g.

```powershell
Set-ExecutionPolicy RemoteSigned
```

in addition to the following platform-specific prerequisites:

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

Update everything. You may need to re-load your session before this function gets
recognized as a Cmdlet.

> ⚠ This script depends on global variables defined by my custom profile

```powershell
Update-System -All
```

## Personal Notes

- Prior to the Windows 10 Creator Update, creating symbolic links required elevated
  permissions. Enabling the `Developer Mode` in the settings app lifts this restriction
- Running `configure.ps1` will add user-customized settings to `.gitconfig`, because
  this config file cannot expand variables such as `$home`. Use `git stash` to get
  around that
- Import the GPG key for signing commits with the following command:

```powershell
gpg --import .\gpg-private-key.asc
```

- Clone all my public repositories on GitHub:

```powershell
Import-Repository -All -Path $desktop/repos/private -Verbose
```

- In order to use the `Set-DevelopmentProfile` script, you need to define the
  environment variables `GitWorkUserName` and `GitWorkUserEmail` first.
