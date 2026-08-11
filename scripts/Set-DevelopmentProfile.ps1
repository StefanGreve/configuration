using namespace System.Collections.ObjectModel
using namespace System.Management.Automation

function Set-DevelopmentProfile {
    param(
        [ValidateSet("Work", "Personal")]
        [Parameter(Mandatory)]
        [string] $Account
    )

    dynamicparam {
        $ParamDictionary = [RuntimeDefinedParameterDictionary]::new()

        if ($Account -eq "Personal") {
            $UseLegacySigningKeyAttribute = [ParameterAttribute]::new()

            $AttributeCollection = [Collection[Attribute]]::new()
            $AttributeCollection.Add($UseLegacySigningKeyAttribute)

            $UseLegacySigningKeyParameter = [RuntimeDefinedParameter]::new("UseLegacySigningKey", [switch], $AttributeCollection)

            $ParamDictionary.Add("UseLegacySigningKey", $UseLegacySigningKeyParameter)
        }

        return $ParamDictionary
    }

    begin {
        git rev-parse --is-inside-work-tree *> $null

        if ($LASTEXITCODE -ne 0) {
            Write-Error "The current directory is not inside a Git repository." `
                -Category ObjectNotFound `
                -ErrorAction Stop
        }

        $UseLegacySigningKey = [bool]$PSBoundParameters["UseLegacySigningKey"]

        # The resolved path is PATH-order dependent. Some toolchains ship their own
        # SSH: Git for Windows bundles an MSYS build (usr/bin/ssh.exe) that can
        # shadow the native Windows OpenSSH (System32/OpenSSH) depending on PATH order.
        function Resolve-ProgramPath([string] $Program) {
            return $(Resolve-Path (Get-Command $Program).Source).Path -replace '\\','/'
        }
    }
    process {
        switch ($Account) {
            "Work" {
                if (!$IsWindows) {
                    Write-Error "This is not your work machine." -Category DeviceError -ErrorAction Stop
                }

                git config --local user.name $env:GitWorkUserName
                git config --local user.email $env:GitWorkUserEmail
                git config --local core.autocrlf false
                git config --local commit.gpgsign false
             }
            "Personal" {
                git config --local user.name "StefanGreve"
                git config --local user.email $($UseLegacySigningKey ? "greve.stefan@outlook.jp" : "stefan.ohlsen.greve@gmail.com")

                # always configure commit signing via gpg on personal accounts
                git config --local commit.gpgsign true

                if ($UseLegacySigningKey) {
                    # use legacy key with previous primary email address
                    git config --local user.signingkey F380062B9F847687
                } else {
                    switch ($env:COMPUTERNAME) {
                        "STGR-BE-LAP02" {
                            git config --local user.signingkey 19328C2B09E1AC4C
                        }
                        default {
                            Write-Warning "Configure a local signing key for this device"
                        }
                    }
                }

                if ($IsWindows) {
                    git config --local core.autocrlf input
                    git config --local core.sshCommand "$(Resolve-ProgramPath ssh)"
                    git config --local gpg.program "$(Resolve-ProgramPath gpg)"
                } elseif ($IsMacOS -or $IsLinux) {
                    git config --local core.sshCommand "$(which ssh)"
                    git config --local gpg.program "$(which gpg)"
                } else {
                    Write-Error "ERROR: Unsupported Platform" -Category NotImplemented -ErrorAction Stop
                }
            }
        }
    }
}
