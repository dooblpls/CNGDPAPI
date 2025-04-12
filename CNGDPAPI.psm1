# ----------------------------------------
# Module: CngDpapi
# Description: Encrypts and decrypts strings using DPAPI-NG via NCrypt APIs.
# OS Requirement: Windows (requires ncrypt.dll)
# ----------------------------------------

# Load the .NET wrapper for native NCrypt functions
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DpapiNgHelper
{
    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int NCryptCreateProtectionDescriptor(
        string pwszDescriptorString,
        uint dwFlags,
        out IntPtr phDescriptor);

    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int NCryptProtectSecret(
        IntPtr hDescriptor,
        uint dwFlags,
        byte[] pbData,
        int cbData,
        IntPtr pMemPara,
        IntPtr hWnd,
        out IntPtr ppbProtectedBlob,
        out int pcbProtectedBlob);

    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int NCryptUnprotectSecret(
        IntPtr hDescriptor,
        uint dwFlags,
        byte[] pbProtectedBlob,
        int cbProtectedBlob,
        IntPtr pMemPara,
        IntPtr hWnd,
        out IntPtr ppbData,
        out int pcbData);

    [DllImport("ncrypt.dll")]
    public static extern int NCryptCloseProtectionDescriptor(IntPtr hDescriptor);

    [DllImport("ncrypt.dll")]
    public static extern int NCryptFreeBuffer(IntPtr pvBuffer);
}
"@ -ErrorAction Stop

function Protect-CngDpapiString {
    <#
    .SYNOPSIS
        Encrypts a string using DPAPI-NG (CNG).

    .DESCRIPTION
        Uses the NCryptProtectSecret API to encrypt a UTF-8 string and return it as a Base64-encoded string.
        You can specify a user/group principal, or directly supply a descriptor rule string.

    .PARAMETER String
        The plaintext string you want to encrypt.

    .PARAMETER Principal
        The user or group (name or SID) allowed to decrypt the secret.
        Will be converted to a protection descriptor like "SID=S-1-5-32-544".

    .PARAMETER Descriptor
        A custom protection descriptor rule string (e.g. "SID=S-1-5-32-544" or "LOCAL=user").
        https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors

    .EXAMPLE
        "Secret" | Protect-CngDpapiString -Principal "DOMAIN\ADGroup"

    .EXAMPLE
        "Secret" | Protect-CngDpapiString -Descriptor "LOCAL=user"

    .NOTES
        Exactly one of -Principal or -Descriptor must be provided.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$String,

        [Parameter(Mandatory = $false)]
        [string]$Principal,

        [Parameter(Mandatory = $false)]
        [string]$Descriptor
    )

    begin {
        if ([string]::IsNullOrEmpty($Principal) -and [string]::IsNullOrEmpty($Descriptor)) {
            throw "You must provide either -Principal or -Descriptor."
        }
        if (-not [string]::IsNullOrEmpty($Principal) -and -not [string]::IsNullOrEmpty($Descriptor)) {
            throw "You may only provide one of -Principal or -Descriptor, not both."
        }
    }

    process {
        $hDescriptor = [IntPtr]::Zero
        $ppbProtectedBlob = [IntPtr]::Zero
        $pcbProtectedBlob = [IntPtr]::Zero

        try {
            if ($Principal) {
                $account = New-Object System.Security.Principal.NTAccount($Principal)
                $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
                $descriptorString = "SID=$($sid.Value)"
            } else {
                $descriptorString = $Descriptor
            }

            Write-Verbose "Using protection descriptor: $descriptorString"

            $result = [DpapiNgHelper]::NCryptCreateProtectionDescriptor($descriptorString, 0, [ref]$hDescriptor)
            if ($result -ne 0) {
                throw "NCryptCreateProtectionDescriptor failed (0x$($result.ToString('X8')))"
            }

            $data = [Text.Encoding]::UTF8.GetBytes($String)

            $result = [DpapiNgHelper]::NCryptProtectSecret(
                $hDescriptor,
                0,
                $data,
                $data.Length,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [ref]$ppbProtectedBlob,
                [ref]$pcbProtectedBlob
            )

            if ($result -ne 0) {
                throw "NCryptProtectSecret failed (0x$($result.ToString('X8')))"
            }

            $encryptedData = New-Object byte[] $pcbProtectedBlob
            [System.Runtime.InteropServices.Marshal]::Copy($ppbProtectedBlob, $encryptedData, 0, $pcbProtectedBlob) | Out-Null
            return [Convert]::ToBase64String($encryptedData)
        }
        finally {
            if ($hDescriptor -ne [IntPtr]::Zero) {
                [DpapiNgHelper]::NCryptCloseProtectionDescriptor($hDescriptor) | Out-Null
            }
            if ($ppbProtectedBlob -ne [IntPtr]::Zero) {
                [DpapiNgHelper]::NCryptFreeBuffer($ppbProtectedBlob) | Out-Null
            }
        }
    }
}


function Unprotect-CngDpapiString {
    <#
    .SYNOPSIS
        Decrypts a Base64-encoded string previously encrypted using DPAPI-NG.

    .DESCRIPTION
        Uses the NCryptUnprotectSecret API to decrypt data that was encrypted using Protect-CngDpapiString.

    .PARAMETER EncryptedString
        A Base64-encoded string previously returned by Protect-CngDpapiString.

    .EXAMPLE
        $plaintext = Unprotect-CngDpapiString -EncryptedString $ciphertext
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$EncryptedString
    )

    process {
        $ppbData = [IntPtr]::Zero
        $pcbData = [IntPtr]::Zero

        try {
            $encryptedData = [Convert]::FromBase64String($EncryptedString)
            $result = [DpapiNgHelper]::NCryptUnprotectSecret([IntPtr]::Zero, 0, $encryptedData, $encryptedData.Length, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$ppbData, [ref]$pcbData)
            if ($result -ne 0) {
                throw "NCryptUnprotectSecret failed (0x$($result.ToString('X8')))"
            }

            $decryptedData = New-Object byte[] $pcbData
            [System.Runtime.InteropServices.Marshal]::Copy($ppbData, $decryptedData, 0, $pcbData) | Out-Null
            return [Text.Encoding]::UTF8.GetString($decryptedData)
        }
        finally {
            if ($ppbData -ne [IntPtr]::Zero) {
                [DpapiNgHelper]::NCryptFreeBuffer($ppbData) | Out-Null
            }
        }
    }
}

Export-ModuleMember -Function Protect-CngDpapiString, Unprotect-CngDpapiString
