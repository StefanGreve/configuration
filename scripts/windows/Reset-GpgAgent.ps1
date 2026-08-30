#Requires -Version 7.4

using namespace System
using namespace System.Collections.Generic
using namespace System.Management.Automation

function Reset-GpgAgent {
    <#
        .SYNOPSIS
        Recovers a stuck GnuPG agent on Windows by resetting its daemons and sockets.

        .DESCRIPTION
        On Windows GnuPG has no real Unix domain sockets, so it emulates them with small
        files (each holding a localhost port and a nonce) under the socket directory. When
        gpg-agent exits uncleanly - after sleep, hibernation, or a killed terminal - those
        files are orphaned and still point at a dead port. The next signing operation then
        stalls while gpg discovers the stale socket, tears it down, and rebinds, which is
        the "stuck agent" symptom.

        A graceful "gpgconf --kill" does not recover from this, because it reaches the agent
        over the same wedged socket and hangs as well. This cmdlet therefore performs a hard
        reset:

          1. Attempts a graceful "gpgconf --kill all", but abandons it if it hangs.
          2. Force-terminates any surviving GnuPG processes.
          3. Deletes the orphaned socket files from the socket directory.
          4. Relaunches gpg-agent and verifies that it answers promptly.

        This cmdlet is Windows-only and emits its progress on the verbose and debug streams;
        pass -Verbose to follow along or -Debug for per-step diagnostics.

        .PARAMETER TimeoutSeconds
        Time budget, in seconds, allowed for the graceful kill and for the final probe
        before each is treated as hung. The default is 8.

        .PARAMETER Force
        Skips the confirmation prompt before terminating processes and deleting sockets.

        .INPUTS
        None. You can't pipe objects to this cmdlet.

        .OUTPUTS
        None. Progress is written to the verbose and debug streams.

        .EXAMPLE
        PS> Reset-GpgAgent

        Resets the agent, prompting once before it terminates anything.

        .EXAMPLE
        PS> Reset-GpgAgent -Force -Verbose

        Resets the agent without prompting - handy inside another script or an alias - while
        printing each step to the verbose stream.

        .LINK
        https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param(
        [ValidateRange(1, 120)]
        [int] $TimeoutSeconds = 8,

        [switch] $Force
    )

    begin {
        if (!$IsWindows) {
            $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new(
                [PlatformNotSupportedException]::new(
                    "This cmdlet resets GnuPG on Windows; on Unix use 'gpgconf --kill all' directly."),
                "WindowsOnly", [ErrorCategory]::NotImplemented, $null))
        }

        # Resolve the tools from PATH so the cmdlet is independent of the install location.
        $GpgConf = (Get-Command "gpgconf.exe" -ErrorAction SilentlyContinue)?.Source
        $Agent = (Get-Command "gpg-connect-agent.exe" -ErrorAction SilentlyContinue)?.Source

        if (!$GpgConf -or !$Agent) {
            $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new(
                [IO.FileNotFoundException]::new(
                    "gpgconf.exe / gpg-connect-agent.exe were not found in PATH; is GnuPG installed?"),
                "GnuPgNotFound", [ErrorCategory]::NotInstalled, $null))
        }

        # gpg is the parent that spawns the rest; pinentry is included in case a prompt is wedged.
        $ProcessNames = @(
            "gpg-agent", "gpgconf", "gpg-connect-agent", "dirmngr",
            "keyboxd", "scdaemon", "gpg", "pinentry", "pinentry-basic"
        )

        # Track background jobs so the clean block can reap them if the run is interrupted.
        $ActiveJobs = [List[Job]]::new()
    }

    process {
        if (!($Force.IsPresent -or $PSCmdlet.ShouldProcess("GnuPG agent", "Terminate daemons and remove stale sockets"))) {
            return
        }

        # 1 - A stuck agent makes the graceful kill hang too, so run it in a job and abandon it on timeout.
        Write-Verbose "Requesting graceful shutdown (gpgconf --kill all)."
        $KillJob = Start-Job -ScriptBlock { & $using:GpgConf --kill all 2>&1 }
        $ActiveJobs.Add($KillJob)

        if (Wait-Job -Job $KillJob -Timeout $TimeoutSeconds) {
            Write-Debug "Graceful shutdown completed within $TimeoutSeconds second(s)."
        } else {
            Stop-Job -Job $KillJob
            Write-Verbose "Graceful shutdown hung; forcing."
        }

        Remove-Job -Job $KillJob -Force
        [void] $ActiveJobs.Remove($KillJob)

        # 2 - Force-terminate survivors. Killing one daemon can respawn helpers, so sweep a few times.
        Write-Verbose "Force-terminating GnuPG processes."

        foreach ($Attempt in 1..3) {
            $Running = Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue
            if (!$Running) { break }

            Write-Debug "Attempt $Attempt : terminating $($Running.Count) process(es)."
            $Running | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 400
        }

        $Survivors = Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue

        if ($Survivors) {
            Write-Warning "These GnuPG processes could not be terminated: $($Survivors.Id -join ', ')."
        } else {
            Write-Debug "All GnuPG processes terminated."
        }

        # 3 - Remove the orphaned socket files. gpgconf reports the socket directory URL-encoded (e.g. C%3a\...).
        Write-Verbose "Removing stale socket files."
        $SocketDirectory = [Uri]::UnescapeDataString((& $GpgConf --list-dirs socketdir))
        Write-Debug "Socket directory: $SocketDirectory"
        $Sockets = Get-ChildItem -LiteralPath $SocketDirectory -Filter "S.*" -Force -File -ErrorAction SilentlyContinue

        if ($Sockets) {
            $Sockets | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Debug "Removed $($Sockets.Count) socket file(s)."
        } else {
            Write-Debug "No stale socket files found."
        }

        # 4 - Relaunch the agent so the next gpg call does not pay the cold-start cost.
        Write-Verbose "Relaunching gpg-agent."
        & $GpgConf --launch gpg-agent
        Start-Sleep -Milliseconds 500

        # 5 - Confirm the agent answers quickly; a probe that hangs means the reset did not take.
        Write-Verbose "Verifying the agent responds."
        $ProbeJob = Start-Job -ScriptBlock { & $using:Agent "getinfo pid" "/bye" 2>&1 }
        $ActiveJobs.Add($ProbeJob)

        if (Wait-Job -Job $ProbeJob -Timeout $TimeoutSeconds) {
            $Response = Receive-Job -Job $ProbeJob
            Remove-Job -Job $ProbeJob -Force
            [void] $ActiveJobs.Remove($ProbeJob)

            $AgentPid = ($Response | Select-String -Pattern "^D\s+(\d+)").Matches.Groups[1].Value
            Write-Debug "Agent probe response: $($Response -join ' ')"
            Write-Verbose $($AgentPid ? "GnuPG agent is responding (pid $AgentPid)." : "GnuPG agent is responding.")
        } else {
            Stop-Job -Job $ProbeJob
            Remove-Job -Job $ProbeJob -Force
            [void] $ActiveJobs.Remove($ProbeJob)

            $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new(
                [TimeoutException]::new("gpg-agent did not come up within $TimeoutSeconds seconds."),
                "AgentProbeTimeout", [ErrorCategory]::OperationTimeout, $null))
        }

        Write-Verbose "GnuPG agent has been reset."
    }

    clean {
        # Reap any jobs still outstanding if the process block threw or was interrupted (Ctrl-C).
        foreach ($Job in $ActiveJobs) {
            Stop-Job -Job $Job -ErrorAction SilentlyContinue
            Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
        }
    }
}
