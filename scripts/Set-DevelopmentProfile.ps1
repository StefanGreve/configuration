function Set-DevelopmentProfile {
    param(
        [ValidateSet("Work", "Personal")]
        [Parameter(Mandatory)]
        [string] $Account
    )

    process {
        switch ($Account) {
            "Work" {
                git config --local user.name $env:GitWorkUserName
                git config --local user.email $env:GitWorkUserEmail
                git config --local core.autocrlf false
                git config --local commit.gpgsign false
             }
            Default {
                # TODO: configure ssh and gpg for non-Windows platforms
                git config --local user.name "StefanGreve"
                git config --local user.email "greve.stefan@outlook.jp"
                git config --local core.autocrlf input
                git config --local core.sshCommand $IsWindows ? "C:/Windows/System32/OpenSSH/ssh.exe" : $null

                # GPG commit signing
                git config --local commit.gpgsign true
                git config --local user.signingkey F380062B9F847687
                git config --local gpg.program $IsWindows ? "C:/Program Files (x86)/GnuPG/bin/gpg.exe" : $null
            }
        }
    }
}
