#Requires -Version 5.1

<#
    .SYNOPSIS
    Adds (or removes) a "Copy File Hash" cascading entry to the Windows file context menu.

    .DESCRIPTION
    Registers a cascading shell verb under the per-user classes hive so that right-clicking
    any file exposes a "Copy File Hash" submenu with one entry per supported algorithm
    (SHA256, SHA1, MD5, SHA512). Invoking a child computes the file hash with Get-FileHash
    and copies the resulting hex digest to the clipboard.

    The submenu is implemented with ExtendedSubCommandsKey, which references a ContextMenus
    tree under HKEY_CURRENT_USER\Software\Classes. This avoids the HKLM CommandStore and
    therefore requires no administrative privileges; only the current user is affected.

    .PARAMETER Remove
    If specified, removes the previously registered context menu entry (parent verb and the
    backing ContextMenus tree) instead of creating it.

    .PARAMETER Label
    The text displayed for the parent submenu. Defaults to "Copy File Hash".

    .INPUTS
    None. You cannot pipe objects to this script.

    .OUTPUTS
    None. This script does not produce any output.

    .NOTES
    On Windows 11 this appears in the classic context menu (Shift+F10 or "Show more options").
    The modern top-level menu requires a packaged IExplorerCommand handler, which cannot be
    expressed with registry commands alone.

    Filenames containing a single quote (') are not supported by the generated command and
    would break hashing for those specific files.

    .EXAMPLE
    PS> .\CopyFileHashContextMenu.ps1

    Adds the "Copy File Hash" submenu to the file context menu.

    .EXAMPLE
    PS> .\CopyFileHashContextMenu.ps1 -Remove

    Removes the "Copy File Hash" submenu from the file context menu.
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([void])]
param(
    [Parameter()]
    [switch] $Remove,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Label = "Copy File Hash"
)

begin {
    if (!$IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
        Write-Error "This script only works on the Windows Operating System" `
            -Category DeviceError `
            -ErrorAction Stop
    }

    $ClassesRoot = "Registry::HKEY_CURRENT_USER\Software\Classes"

    # Parent verb ("*" applies to all file types) and the backing submenu container.
    $VerbName = "CopyFileHash"
    $ParentKey = "${ClassesRoot}\*\shell\${VerbName}"
    $SubMenuRelativeKey = "ContextMenus\${VerbName}"
    $SubMenuShellKey = "${ClassesRoot}\${SubMenuRelativeKey}\shell"

    # Submenu order is driven by the (alphabetical) key names, so each entry is prefixed
    # with a sort token while its visible label comes from MUIVerb.
    $Algorithms = [ordered]@{
        "1_MD5"    = "MD5"
        "2_SHA1"   = "SHA1"
        "3_SHA256" = "SHA256"
        "4_SHA512" = "SHA512"
    }
}
process {
    if ($Remove.IsPresent) {
        foreach ($Key in @($ParentKey, "${ClassesRoot}\${SubMenuRelativeKey}")) {
            if (Test-Path -Path $Key) {
                if ($PSCmdlet.ShouldProcess($Key, "Remove context menu entry")) {
                    Remove-Item -Path $Key -Recurse -Force
                }
            }
        }

        Write-Verbose "Removed context menu entry '${Label}'"
        return
    }

    if ($PSCmdlet.ShouldProcess($ParentKey, "Add context menu entry '${Label}'")) {
        # Parent is a container (no command); ExtendedSubCommandsKey is resolved relative
        # to HKEY_CURRENT_USER\Software\Classes.
        New-Item -Path $ParentKey -Force | Out-Null
        Set-ItemProperty -Path $ParentKey -Name "MUIVerb" -Value $Label
        Set-ItemProperty -Path $ParentKey -Name "Icon" -Value "imageres.dll,-5302"
        Set-ItemProperty -Path $ParentKey -Name "ExtendedSubCommandsKey" -Value $SubMenuRelativeKey

        foreach ($Entry in $Algorithms.GetEnumerator()) {
            $Algorithm = $Entry.Value
            $ChildKey = "${SubMenuShellKey}\$($Entry.Key)"
            $ChildCommandKey = "${ChildKey}\command"

            # NOTE: %1 is expanded by the shell to the full path of the selected file.
            # 'conhost.exe --headless' attaches PowerShell to a pseudoconsole with no visible
            # window, avoiding the brief terminal flash that '-WindowStyle Hidden' still shows
            # (the console host is created before the hidden style can be applied).
            $Command = "conhost.exe --headless powershell.exe -NoProfile -Command " +
                """Set-Clipboard -Value (Get-FileHash -LiteralPath '%1' -Algorithm ${Algorithm}).Hash"""

            New-Item -Path $ChildCommandKey -Force | Out-Null
            Set-ItemProperty -Path $ChildKey -Name "MUIVerb" -Value $Algorithm
            Set-ItemProperty -Path $ChildCommandKey -Name "(Default)" -Value $Command
        }

        Write-Verbose "Added context menu entry '${Label}'"
    }
}
