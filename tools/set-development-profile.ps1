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
                git config --local commit.gpgsign false
                git config --local core.autocrlf false
             }
            Default {
                git config --local user.name "StefanGreve"
                git config --local user.mail "greve.stefan@outlook.jp"
                git config --local commit.gpgsign true
                git config --local core.autocrlf input
            }
        }
    }
}
