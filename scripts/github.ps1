using namespace System.IO

function Test-Repository {
    [OutputType([bool])]
    param(
        [string] $Path
    )

    process {
        # d = directory, h = hidden, a = archive
        $Exists = (Test-Path $Path) -and (Get-ChildItem -Path $Path -Attributes d,a,h).Count -ne 0
        Write-Output $Exists
    }
}

function Import-Repository {
    [Alias("clone")]
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Name")]
        [string] $User = $(git config --global user.name),

        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Name")]
        [string] $Path = $PWD,

        [Parameter(ParameterSetName = "Name", Mandatory)]
        [string] $Name,

        [Parameter(ParameterSetName = "All", Mandatory)]
        [switch] $All
    )

    begin {
        $TargetDirectory = New-Item -Path $Path -ItemType Directory -Force | Select-Object -ExpandProperty FullName
    }
    process {
        if ($All.IsPresent) {
            $Response = Invoke-RestMethod -Uri "https://api.github.com/users/${User}/repos"
            $Repositories = $Response | Select-Object ssh_url, name | Where-Object name -ne "profile"

            foreach ($Repository in $Repositories) {
                $Path = [Path]::Combine($TargetDirectory, $Repositories.name)

                if (Test-Repository $Path) { continue }

                Write-Verbose "Clone $($Repository.name) . . ."
                git clone $Repository.SSH_URL $Path --quiet
            }
        } else {
            $Path = [Path]::Combine($TargetDirectory, $Name)

            if (Test-Repository $Path) { return }

            Write-Verbose "Clone $Name . . ."
            git clone "git@github.com:$User/$Name.git" $Path --quiet
        }
    }
}
