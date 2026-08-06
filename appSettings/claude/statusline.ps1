#!/usr/bin/env pwsh

# Claude Code status line
# (( model )) @ [reponame] (context remaining) [NNNk in / NNk out]
# Reads the Claude Code statusLine JSON from stdin and writes a single coloured line.

using namespace System.IO
using namespace System.Text

$InputJson = $input | Out-String
$Data = $InputJson | ConvertFrom-Json

# == model =====================================================================

$ModelName = $Data.model.display_name
if (-not $ModelName) { $ModelName = 'Claude' }

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
    # (( model )) @ [repo]
    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append("(( ")
    $StatusLine.Append($PSStyle.Foreground.BrightYellow)
    $StatusLine.Append($ModelName)
    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append(" )) @ [")
    $StatusLine.Append($PSStyle.Foreground.BrightGreen)
    $StatusLine.Append($RepoName)
    $StatusLine.Append($PSStyle.Foreground.BrightWhite)
    $StatusLine.Append("]")

    # (context remaining)
    if ($null -ne $Remaining) {
        $Pct = [Math]::Floor([double]$Remaining)
        $StatusLine.Append(" ")

        if ($Pct -lt 10) {
            # below 10% the whole segment turns bright red as a warning
            $StatusLine.Append($PSStyle.Foreground.BrightRed)
            $StatusLine.Append("(")
            $StatusLine.Append($Pct)
            $StatusLine.Append("% remaining)")
        } else {
            $StatusLine.Append($PSStyle.Foreground.Blue)
            $StatusLine.Append("(")
            $StatusLine.Append($PSStyle.Foreground.BrightBlue)
            $StatusLine.Append($Pct)
            $StatusLine.Append("% remaining")
            $StatusLine.Append($PSStyle.Foreground.Blue)
            $StatusLine.Append(")")
        }

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
