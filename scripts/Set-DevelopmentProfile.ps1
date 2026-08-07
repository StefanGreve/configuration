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
        $UseLegacySigningKey = [bool]$PSBoundParameters["UseLegacySigningKey"]
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
                    git config --local core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
                    git config --local gpg.program "C:/Program Files/GnuPG/bin/gpg.exe"
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
