@{
    RootModule           = 'concise-log.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = '00000000-0000-0000-0000-000000000000'
    Author               = 'Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>'
    CompanyName          = 'vs-scripts'
    Copyright            = '(c) 2026 Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>. All rights reserved.'
    Description          = 'Concise logging module using concise log format.'
    PowerShellVersion    = '7.6.0'
    FunctionsToExport    = @(
        'Write-DebugLog'
        'Write-InfoLog'
        'Write-WarningLog'
        'Write-ErrorLog'
        'Write-ExceptionLog'
    )
    PrivateData          = @{
        PSData           = @{
            Tags         = @(
                'logging',
                'concise-log',
                'module'
            )
            ProjectUri   = 'https://github.com/vs-scripts/concise-log'
            LicenseUri   = 'https://github.com/vs-scripts/concise-log/LICENSE'
            ReleaseNotes = 'Work in progress'
        }
    }
}
