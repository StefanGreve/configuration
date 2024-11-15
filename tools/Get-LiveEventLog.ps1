using namespace System

function Get-LiveEventLog {
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [Parameter(Mandatory)]
        [string] $LogName,

        [string] $SourceName
    )

    begin {
        if (![OperatingSystem]::IsWindows()) {
            Write-Error "This Cmdlet only works on the Windows Operating System" -ErrorAction Stop
        }

        $Arguments = @{
            LogName = $LogName
        }

        if ($SourceName -ne [string]::Empty) {
            $Arguments.Add("FilterXPath", "*[System[Provider[@Name='$SourceName']]]")
        }

        Write-Verbose "Started event monitoring."

        try {
            $Id1 = Get-WinEvent @Arguments | Select-Object -First 1 -ExpandProperty RecordId
        }
        catch {
            Write-Error "Failed to retrieve events from the log $LogName" -ErrorAction Stop
        }
    }
    process {
        while ($true) {
            Start-Sleep -Seconds 1
            $Id2 = Get-WinEvent @Arguments | Select-Object -First 1 -ExpandProperty RecordId

            if ($Id2 -gt $Id1) {
                Get-WinEvent @Arguments -MaxEvents ($Id2 - $Id1) | Sort-Object -Property RecordId
            }

            $Id1 = $Id2
        }
    }
    clean {
        Write-Verbose "Stopped event monitoring."
    }
}
