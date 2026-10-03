#!/usr/bin/env pwsh
#Requires -Version 7.4

# Claude Code status line
# (( model :: effort )) @ [reponame] (Y% context, Z% window remaining) [NNNk in / NNk out]
# Reads the Claude Code statusLine JSON from stdin and writes a single coloured line.

using namespace System.IO
using namespace System.Text

$InputJson = $input | Out-String
$Data = $InputJson | ConvertFrom-Json

# == model =====================================================================

$ModelName = $Data.model.display_name
if (-not $ModelName) { $ModelName = 'Claude' }

# == effort level - absent unless the current model supports the parameter =====

$EffortLevel = $Data.effort.level

# == repo name - git toplevel basename, falling back to the cwd leaf ===========

$CwdRaw   = $Data.workspace.current_dir
$RepoName = $null

if ($CwdRaw -and (Test-Path $CwdRaw)) {
    $TopLevel = git -C $CwdRaw rev-parse --show-toplevel 2>$null
    if ($TopLevel) { $RepoName = [Path]::GetFileName($TopLevel.Trim()) }
}

if (-not $RepoName -and $CwdRaw) {
    $RepoName = [Path]::GetFileName($CwdRaw.TrimEnd([Path]::DirectorySeparatorChar, '/'))
}

if (-not $RepoName) { $RepoName = '~' }

# == context remaining - null early in a session, fall back to used% ===========

$Remaining = $Data.context_window.remaining_percentage

if ($null -eq $Remaining -and $null -ne $Data.context_window.used_percentage) {
    $Remaining = 100 - $Data.context_window.used_percentage
}

# == 5-hour window remaining - absent until the first API response of a =========
# == session, for non-subscribers, and once the window has expired =============

$WindowRemaining = $null

if ($null -ne $Data.rate_limits.five_hour.used_percentage) {
    $WindowRemaining = 100 - $Data.rate_limits.five_hour.used_percentage
}

# == last-prompt token usage - null before first message and after /compact ====

function Format-Tokens ([long] $TokenCount) {
    return ($TokenCount -ge 1000) `
        ? "$([Math]::Round($TokenCount / 1000.0, 1))k" `
        : "$TokenCount"
}

$LastUsage  = $Data.context_window.current_usage
$LastInStr  = $null
$LastOutStr = $null

if ($null -ne $LastUsage) {
    $InRaw  = [long]($LastUsage.input_tokens ?? 0) `
            + [long]($LastUsage.cache_creation_input_tokens ?? 0) `
            + [long]($LastUsage.cache_read_input_tokens ?? 0)
    $OutRaw = [long]($LastUsage.output_tokens ?? 0)

    if ($InRaw -gt 0 -or $OutRaw -gt 0) {
        $LastInStr  = Format-Tokens $InRaw
        $LastOutStr = Format-Tokens $OutRaw
    }
}

# == assemble statusline =======================================================

$StatusLine = [StringBuilder]::new()

$null = & {
    # (( model :: effort )) @ [repo]
    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append("(( ")
    $StatusLine.Append($PSStyle.Foreground.BrightYellow)
    $StatusLine.Append($ModelName)

    if ($EffortLevel) {
        $StatusLine.Append($PSStyle.Foreground.BrightWhite)
        $StatusLine.Append(" :: ")
        $StatusLine.Append($PSStyle.Foreground.BrightYellow)
        $StatusLine.Append($EffortLevel)
    }

    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append(" )) @ [")
    $StatusLine.Append($PSStyle.Foreground.BrightGreen)
    $StatusLine.Append($RepoName)
    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append("]")

    # (Y% context, Z% window remaining)
    if ($null -ne $Remaining -or $null -ne $WindowRemaining) {
        $Parts = @()
        if ($null -ne $Remaining)       { $Parts += @{ Pct = [Math]::Floor([double]$Remaining);       Label = '% context' } }
        if ($null -ne $WindowRemaining) { $Parts += @{ Pct = [Math]::Floor([double]$WindowRemaining); Label = '% window'  } }

        # below 10% in either figure the whole segment turns bright red as a warning
        $IsLow     = [bool]($Parts | Where-Object { $_.Pct -lt 10 })
        $Frame     = $IsLow ? $PSStyle.Foreground.BrightRed : $PSStyle.Foreground.Blue
        $Highlight = $IsLow ? $PSStyle.Foreground.BrightRed : $PSStyle.Foreground.BrightBlue

        $StatusLine.Append(" ")
        $StatusLine.Append($Frame)
        $StatusLine.Append("(")

        for ($i = 0; $i -lt $Parts.Count; $i++) {
            if ($i -gt 0) { $StatusLine.Append(", ") }
            $StatusLine.Append($Highlight)
            $StatusLine.Append($Parts[$i].Pct)
            $StatusLine.Append($Frame)
            $StatusLine.Append($Parts[$i].Label)
        }

        $StatusLine.Append(" remaining)")
        $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    }

    # [NNNk in / NNk out]
    if ($null -ne $LastInStr) {
        $StatusLine.Append(" ")
        $StatusLine.Append($PSStyle.Foreground.Magenta)
        $StatusLine.Append("[")
        $StatusLine.Append($PSStyle.Foreground.BrightMagenta)
        $StatusLine.Append($LastInStr)
        $StatusLine.Append(" in / ")
        $StatusLine.Append($LastOutStr)
        $StatusLine.Append(" out")
        $StatusLine.Append($PSStyle.Foreground.Magenta)
        $StatusLine.Append("]")
        $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    }

    $StatusLine.Append($PSStyle.Reset)
}

# == emit ======================================================================

Write-Host -NoNewline $StatusLine.ToString()
