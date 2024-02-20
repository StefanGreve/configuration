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
                git config --local user.mail $env:GitWorkEmail
                git config --local core.autocrlf false
                git config --local commit.gpgsign false
             }
            Default {
                git config --local user.name "StefanGreve"
                git config --local user.mail "greve.stefan@outlook.jp"
                git config --local core.autocrlf input
                git config --local core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

                # GPG commit signing
                git config --local commit.gpgsign true
                git config --local user.signingkey F380062B9F847687
                git config --local gpg.program "C:/Program Files (x86)/GnuPG/bin/gpg.exe"
            }
        }
    }
}
