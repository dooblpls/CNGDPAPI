@{
    # Script module file associated with this manifest.
    RootModule        = 'CNGDPAPI.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.2'

    # ID used to uniquely identify this module
    GUID              = 'd0a9160f-6dd2-4c72-9d4b-2ebd4e4e4d7a'

    # Author of this module
    Author            = 'dooblpls'

    # Company or vendor of this module
    CompanyName       = 'Independent'

    # Description of the functionality provided by this module
    Description       = 'Provides functions to encrypt and decrypt strings using Windows DPAPI-NG (NCrypt).'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Protect-CNGDPAPIString', 'Unprotect-CNGDPAPIString')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()

    # Private data to pass to the module specified in RootModule
    PrivateData = @{}

    # Help info URI
    HelpInfoURI = 'https://github.com/dooblpls/CNGDPAPI'

    # Default prefix for commands exported from this module. You can set this to $null to remove the default.
    DefaultCommandPrefix = ''

    # Compatible PSEditions
    CompatiblePSEditions = @('Desktop')
}
