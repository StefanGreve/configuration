# Installs the GCC compiler on Windows

if (!$IsWindows) {
    Write-Error "Unsupported Operating System" -ErrorAction Stop -Category DeviceError
}

$Archive = "MinGW64.zip"
$Uri = "https://github.com/GorvGoyl/MinGW64/releases/download/v2.0/MinGW64.zip"

Push-Location -Path $([Environment]::GetFolderPath("Desktop"))

Invoke-WebRequest -Uri $Uri -OutFile $Archive
Expand-Archive -Path $Archive -DestinationPath "C:/Program Files" -Force
Remove-Item -Path $Archive

[Environment]::SetEnvironmentVariable("PATH", "C:/Program Files/MinGW64/bin", [EnvironmentVariableTarget]::User)

Pop-Location
