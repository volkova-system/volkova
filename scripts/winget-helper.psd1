@{
    RootModule           = 'winget-helper.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = '00000000-0000-0000-0000-000000000000'
    Author               = 'Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>'
    CompanyName          = 'vs-scripts'
    Copyright            = '(c) 2026 Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>. All rights reserved.'
    Description          = 'Collection of winget helper functions.'
    PowerShellVersion    = '7.5.4'
    FunctionsToExport    = @(
        'Get-WingetInstallPath'
    )
    RequiredModules      = @(
        'concise-log'
    )
    PrivateData          = @{
        PSData           = @{
            Tags         = @(
                'winget',
                'package-management',
                'windows',
                'winget-helper'
            )
            ProjectUri   = 'https://github.com/vs-scripts/winget-helper'
            LicenseUri   = 'https://github.com/vs-scripts/winget-helper/LICENSE'
            ReleaseNotes = 'Work in progress'
        }
    }
}
