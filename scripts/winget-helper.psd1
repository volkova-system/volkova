@{
    RootModule           = 'winget-helper.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '12345678-1234-1234-1234-123456789012'
    Author               = 'WinGet Helper Team <winget-helper@example.com>'
    CompanyName          = 'WinGet Helper'
    Copyright            = '(c) 2026 WinGet Helper Team. All rights reserved.'
    Description          = 'Locates installation paths for WinGet packages'
    PowerShellVersion    = '7.5.4'
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
