function Stop-Work {
    $RemoteDesktopClient = "mstsc"
    $Apps = @("lync", "ms-teams", "outlook", $RemoteDesktopClient)

    Get-Process | Where-Object { $Apps.Contains($_.Name.ToLower()) } | Stop-Process -Force

    if (!$IsAdmin) {
        # If UAC (User Account Control) is enabled, network drives are mapped on
        # a separate account for security reasons [1]. This behavior can be changed
        # through the registry by creating a new DWORD entry (value = 1) with the name
        # EnableLinkedConnections [2].
        # [1] https://support.microsoft.com/en-us/topic/programs-may-be-unable-to-access-some-network-locations-after-you-turn-on-user-account-control-in-windows-vista-or-newer-operating-systems-a3dd1683-9769-8ae2-7ec7-eae45147280b
        # [2] HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Policies/System
        Get-SmbMapping | Remove-SmbMapping -Force
    }
}
