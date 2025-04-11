@{
    RootModule        = 'CNGDPAPI.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'd0a9160f-6dd2-4c72-9d4b-2ebd4e4e4d7a'
    Author            = 'dooblpls'
    CompanyName       = 'dooblpls'
    Copyright         = '(c) dooblpls. All rights reserved.'
    Description       = 'Encrypts/decrypts strings using CNG DPAPI with principal-based access control'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Protect-CngDpapiString', 'Unprotect-CngDpapiString')
    RequiredModules   = @()
    NestedModules     = @()
}