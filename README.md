# Configuration

![Windows](https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=F0F0F0)

This project is a collection of configuration files and scripts that I use on my
machine. They have been open-sourced for my own convenience, so you may use
anything you see here at your own risk. Some settings are tailored to meet my
personal needs, so running these scripts might not work for you out of the box.

As a successor to
[`confiles`](https://github.com/StefanGreve/confiles),
this repository has been meticulously designed with cross-platform compatibility
in mind.

> This repository has not been ported to a Linux-based platform yet. But in theory,
> it can be extended to support multiple operating systems.

## Prerequisites

The setting files are configured to use the classic Code Page 437 character set
from the original IBM PCs; the respective DOS VGA font can be downloaded from here:
<https://cp437.github.io/>.

You will need to have [`pwsh`](https://github.com/PowerShell/PowerShell) installed
on your platform of choice in order to run any of the scripts, as well as an
appropriate execution policy, e.g.

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
```

After that, follow the instructions on https://github.com/StefanGreve/profile
for importing the PowerShell profile (optional).

Ensure that you have the following commands in your `PATH`:

- `cargo`
- `pipx`

Additionally, you also need the following platform-specific prerequisites:

### Windows

- `winget`

### MacOS

- `brew`

### Linux

NOT IMPLEMENTED

## Usage

**Run the following scripts to bootstrap your system, preferably in order.**

Symlink config files from the `appSettings` directory by force:

```powershell
./bootstrap/configure.ps1 -All
```

As a result of running this scripts, a new assets directory will be created in
`$home/.config/assets`.

---

Install all required programs:

```powershell
./bootstrap/install.ps1 -All
```

The installer script also accepts individual flags for user-customized installations
and reads its definitions from the `settings` folder. You may need to restart your
terminal session for the changes to take effect fully.

---

Use this Cmdlet to maintain the system.

```powershell
Update-System -All
```

## Personal Notes

- The `hosts` file on Windows can *not* be replaced by a symbolic link
- Prior to the Windows 10 Creator Update, creating symbolic links required elevated
  permissions. Enabling the `Developer Mode` in the settings app lifts this restriction.
  Creating symbolic links doesn't require elevated rights on MacOS (or Linux?).
- The SSH config file is configured to look for two separate SSH keys
- Import the GPG key for signing commits with the following command:

```powershell
gpg --import .\gpg-private-key.asc
```

- In order to use the Work profile of `Set-DevelopmentProfile` script, you need to
  define the environment variables `GitWorkUserName` and `GitWorkUserEmail` first.
