# General
$global:DESKTOP = [Environment]::GetFolderPath("Desktop")
$global:DOCUMENTS = [Environment]::GetFolderPath("MyDocuments")
$global:PICTURES = [Environment]::GetFolderPath("MyPictures")
$global:MUSIC = [Environment]::GetFolderPath("MyMusic")
$global:VIDEOS = [Environment]::GetFolderPath("MyVideos")
$global:DOWNLOADS = Join-Path -Path $HOME -ChildPath "Downloads"

# Windows
$global:HOSTS = "C:\Windows\System32\Drivers\etc\hosts"
