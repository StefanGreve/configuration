#Requires -Version 5.1

using namespace System.Drawing
using namespace System.Drawing.Imaging
using namespace System.Management.Automation

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
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)

            # Curated list of well-known icon libraries (path relative to %SystemRoot%, icon count).
            # Seeded statically so completion is instant; no directory scan or P/Invoke at Tab time.
            $KnownIconLibraries = @(
                @{ Rel = "System32\imageres.dll";         Count = 369 }
                @{ Rel = "System32\shell32.dll";          Count = 335 }
                @{ Rel = "System32\netshell.dll";         Count = 165 }
                @{ Rel = "System32\wmploc.dll";           Count = 159 }
                @{ Rel = "System32\ddores.dll";           Count = 151 }
                @{ Rel = "System32\moricons.dll";         Count = 113 }
                @{ Rel = "System32\ieframe.dll";          Count = 102 }
                @{ Rel = "System32\compstui.dll";         Count = 101 }
                @{ Rel = "System32\setupapi.dll";         Count = 62  }
                @{ Rel = "System32\pifmgr.dll";           Count = 38  }
                @{ Rel = "System32\dsuiext.dll";          Count = 36  }
                @{ Rel = "explorer.exe";                  Count = 23  }
                @{ Rel = "System32\wiashext.dll";         Count = 22  }
                @{ Rel = "System32\accessibilitycpl.dll"; Count = 22  }
                @{ Rel = "System32\sensorscpl.dll";       Count = 22  }
                @{ Rel = "System32\wpdshext.dll";         Count = 22  }
                @{ Rel = "System32\comres.dll";           Count = 20  }
                @{ Rel = "System32\urlmon.dll";           Count = 18  }
                @{ Rel = "System32\dmdskres.dll";         Count = 18  }
                @{ Rel = "System32\mmres.dll";            Count = 18  }
                @{ Rel = "System32\main.cpl";             Count = 16  }
                @{ Rel = "System32\mssvp.dll";            Count = 15  }
                @{ Rel = "System32\mstscax.dll";          Count = 15  }
                @{ Rel = "System32\netcenter.dll";        Count = 11  }
                @{ Rel = "System32\powercpl.dll";         Count = 6   }
            )

            # Strip any quote already typed, then match on the file name.
            $Word = $WordToComplete.Trim("'", '"')

            $KnownIconLibraries
                | Where-Object { (Split-Path -Path $_.Rel -Leaf) -like "*${Word}*" }
                | ForEach-Object {
                    $Path = Join-Path -Path $env:SystemRoot -ChildPath $_.Rel
                    [CompletionResult]::new(
                        "'${Path}'",
                        "${Path} ($($_.Count) icons)",
                        [CompletionResultType]::ParameterValue,
                        "${Path}`n$($_.Count) icons"
                    )
                }
        })]
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
        if (!("Win32.Ico" -as [Type])) {
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
