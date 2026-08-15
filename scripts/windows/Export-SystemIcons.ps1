#Requires -Version 5.1

using namespace System.Drawing
using namespace System.Drawing.Imaging

function Export-SystemIcons {
    <#
        .SYNOPSIS
        Exports every icon embedded in a Windows resource file (DLL or EXE) to individual PNG files.

        .DESCRIPTION
        Enumerates the icon resources of a Portable Executable via the shell32 ExtractIconEx API and
        writes each one as a separate PNG into the destination directory. The file name encodes the
        positional index used by shell "Icon" references (for example icon-005.png corresponds to
        imageres.dll,5), so the exported set can be browsed to pick an icon for a context menu verb or
        shortcut.

        Each written file is emitted to the pipeline as a FileInfo object.

        .PARAMETER Source
        Path to the resource file (DLL or EXE) to read icons from. Defaults to imageres.dll, the
        standard system icon library. Other common sources are shell32.dll, ddores.dll (devices),
        and netshell.dll (network).

        .PARAMETER Destination
        Directory that receives the exported PNG files. It is created if it does not already exist.

        .INPUTS
        None. You cannot pipe objects to this cmdlet.

        .OUTPUTS
        System.IO.FileInfo. One object per exported PNG file.

        .NOTES
        Requires the System.Drawing assembly and therefore only runs on Windows.

        A positive icon index is the zero-based position emitted by this cmdlet (imageres.dll,5).
        The shell itself often references icons by negative resource ID (imageres.dll,-5302); those
        IDs are stable across Windows versions, whereas positional indices can shift between builds.

        .EXAMPLE
        PS> Export-SystemIcons.ps1 -Destination "$HOME\Desktop\Icons"

        Exports every icon from imageres.dll into the Icons folder on the desktop.

        .EXAMPLE
        PS> Export-SystemIcons.ps1 -Source "$env:SystemRoot\System32\shell32.dll" -Destination .\shell32 -Verbose

        Exports the shell32.dll icon set into a local folder, reporting a summary on completion.
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Source = "$env:SystemRoot\System32\imageres.dll",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Destination
    )

    begin {
        if ($PSVersionTable.PSEdition -eq "Core" -and !$IsWindows) {
            Write-Error "This cmdlet only works on the Windows Operating System" `
                -Category DeviceError `
                -ErrorAction Stop
        }

        if (!(Test-Path -LiteralPath $Source -PathType Leaf)) {
            Write-Error "Source file not found: ${Source}" `
                -Category ObjectNotFound `
                -ErrorAction Stop
        }

        Add-Type -AssemblyName System.Drawing

        # Guard against re-adding the type when the script is dot-sourced more than once per session.
        if (!("Win32.Ico" -as [type])) {
            Add-Type -Namespace Win32 -Name Ico -MemberDefinition @"
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int ExtractIconEx(string file, int index, IntPtr[] large, IntPtr[] small, int count);

[DllImport("user32.dll")]
public static extern bool DestroyIcon(IntPtr hIcon);
"@
        }
    }
    process {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null

        # Passing an index of -1 returns the number of icons in the resource file.
        $Count = [Win32.Ico]::ExtractIconEx($Source, -1, $null, $null, 0)
        if ($Count -le 0) {
            Write-Warning "No icons found in ${Source}"
            return
        }

        # Zero-pad the index to at least three digits so file names sort naturally.
        $Padding = [Math]::Max(3, ([string]($Count - 1)).Length)
        $Activity = "Exporting icons from $(Split-Path -Path $Source -Leaf)"

        for ($Index = 0; $Index -lt $Count; $Index++) {
            Write-Progress -Activity $Activity `
                -Status "Icon $($Index + 1) of ${Count}" `
                -PercentComplete (($Index + 1) / $Count * 100)

            $Large = New-Object IntPtr[] 1
            if ([Win32.Ico]::ExtractIconEx($Source, $Index, $Large, $null, 1) -le 0 -or $Large[0] -eq [IntPtr]::Zero) {
                continue
            }

            $Icon = [Icon]::FromHandle($Large[0])
            $IconPath = Join-Path -Path $Destination -ChildPath ("icon-{0}.png" -f ([string]$Index).PadLeft($Padding, "0"))
            $Icon.ToBitmap().Save($IconPath, [ImageFormat]::Png)
            $Icon.Dispose()
            [Win32.Ico]::DestroyIcon($Large[0]) | Out-Null

            Get-Item -LiteralPath $IconPath
        }

        Write-Progress -Activity $Activity -Completed
        Write-Verbose "Exported ${Count} icons to ${Destination}"
    }
}
