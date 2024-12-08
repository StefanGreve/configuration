# General
$global:DESKTOP = [Environment]::GetFolderPath("Desktop")
$global:DOCUMENTS = [Environment]::GetFolderPath("MyDocuments")
$global:PICTURES = [Environment]::GetFolderPath("MyPictures")
$global:MUSIC = [Environment]::GetFolderPath("MyMusic")
$global:VIDEOS = [Environment]::GetFolderPath("MyVideos")

# Windows
if ($IsWindows) {
    $global:HOSTS = "C:\Windows\System32\Drivers\etc\hosts"
    $global:DOWNLOADS = Join-Path -Path $HOME -ChildPath "Downloads"
}
