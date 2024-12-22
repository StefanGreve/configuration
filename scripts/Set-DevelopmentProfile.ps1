function Set-DevelopmentProfile {
    param(
        [ValidateSet("Work", "Personal", "Hentai")]
        [Parameter(Mandatory)]
        [string] $Account
    )

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
                git config --local user.email "greve.stefan@outlook.jp"

                # configure commit signing via gpg
                git config --local commit.gpgsign true
                git config --local user.signingkey F380062B9F847687

                if ($IsWindows) {
                    git config --local core.autocrlf input
                    git config --local core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
                    git config --local gpg.program "C:/Program Files (x86)/GnuPG/bin/gpg.exe"
                } elseif ($IsMacOS) {
                    git config --local core.sshCommand $(which ssh)
                    git config --local gpg.program "$(which gpg)"
                } elseif ($IsLinux) {
                    Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
                } else {
                    Write-Error "TODO" -Category NotImplemented -ErrorAction Stop
                }
            }
            "Hentai" {
                git config --local user.name hentai-chan
                git config --local user.email "dev.hentai-chan@outlok.com"
            }
        }
    }
}
