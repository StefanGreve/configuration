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
            $UseLegacySigniningKeyAttribute = [ParameterAttribute]::new()

            $AttributeCollection = [Collection[Attribute]]::new()
            $AttributeCollection.Add($UseLegacySigniningKeyAttribute)

            $UseLegacySigniningKeyParameter = [RuntimeDefinedParameter]::new("UseLegacySigniningKey", [switch], $AttributeCollection)

            $ParamDictionary.Add("UseLegacySigniningKey", $UseLegacySigniningKeyParameter)
        }

        return $ParamDictionary
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
                git config --local user.email $($UseLegacySigniningKey ? "greve.stefan@outlook.jp" : "stefan.ohlsen.greve@gmail.com")

                # configure commit signing via gpg
                git config --local commit.gpgsign true

                # use legacy key with previous primary email address
                if ($UseLegacySigniningKey) {
                    git config --local user.signingkey F380062B9F847687
                } else { # prefer a per-device signing key configuration
                    Write-Host "NOTE: Configure local signing key for this device" -ForegroundColor Yellow
                }

                if ($IsWindows) {
                    git config --local core.autocrlf input
                    git config --local core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
                    git config --local gpg.program "C:\Program Files\GnuPG\bin\gpg.exe"
                } elseif ($IsMacOS -or $IsLinux) {
                    git config --local core.sshCommand $(which ssh)
                    git config --local gpg.program "$(which gpg)"
                } else {
                    Write-Error "ERROR: Unreachable Path" -Category NotImplemented -ErrorAction Stop
                }
            }
        }
    }
}
