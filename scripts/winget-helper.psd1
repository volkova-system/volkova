@{
    RootModule           = 'winget-helper.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '12345678-1234-1234-1234-123456789012'
    Author               = 'WinGet Helper Team'
    CompanyName          = 'WinGet Helper'
    Copyright            = '2024 WinGet Helper'
    Description          = 'Locates installation paths for WinGet packages'
    PowerShellVersion    = '7.4'
    FunctionsToExport    = @('Get-WingetInstallPath')
    RequiredModules      = @('concise-log')
    PrivateData          = @{
        PSData           = @{
            Tags         = @('winget', 'package-management', 'windows')
            LicenseUri   = 'https://example.com/license'
            ProjectUri   = 'https://example.com/project'
            ReleaseNotes = 'Initial release'
        }
    }
}
