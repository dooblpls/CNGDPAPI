Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class CngDpapiHelper
{
[DllImport("ncrypt.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern int NCryptProtectSecret(
    IntPtr hDescriptor,
    uint dwFlags,
    string pwszProtectionDescriptor,
    IntPtr pMemPara,
    byte[] pbData,
    int cbData,
    out IntPtr ppbProtectedBlob,
    out int pcbProtectedBlob,
    out int pcbResult);

    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int NCryptUnprotectSecret(
        IntPtr hDescriptor,
        uint dwFlags,
        string pwszProtectionDescriptor,
        IntPtr pMemPara,
        byte[] pbProtectedBlob,
        int cbProtectedBlob,
        out IntPtr ppbData,
        out int pcbData,
        out int pcbResult);

    [DllImport("ncrypt.dll")]
    public static extern int NCryptFreeBuffer(IntPtr pvBuffer);
}
"@ -ErrorAction Stop

function Protect-CngDpapiString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$String,
        
        [Parameter(Mandatory=$true)]
        [string]$Principal
    )

    process {
        try {
            # SID-Resolution
            $account = New-Object System.Security.Principal.NTAccount($Principal)
            $sid = $account.Translate([System.Security.Principal.SecurityIdentifier]).Value
            $protectionDescriptor = "SID=$sid"
            Write-Verbose "Using protection descriptor: $protectionDescriptor"

            $data = [System.Text.Encoding]::Unicode.GetBytes($String)
            if ($data.Length -eq 0) {
                throw "Input data cannot be empty."
            }

            $hDescriptor = [IntPtr]::Zero
            $dwFlags = 0
            $pMemPara = [IntPtr]::Zero
            $cbData = $data.Length

            $ppbProtectedBlob = [IntPtr]::Zero
            $pcbProtectedBlob = 0
            $pcbResult = 0

            # Call NCryptProtectSecret
            $result = [CngDpapiHelper]::NCryptProtectSecret(
                $hDescriptor,
                $dwFlags,
                $protectionDescriptor,
                $pMemPara,
                $data,
                $cbData,
                [ref]$ppbProtectedBlob,
                [ref]$pcbProtectedBlob,
                [ref]$pcbResult
            )

            if ($result -ne 0) {
                throw "NCryptProtectSecret failed (HRESULT 0x$($result.ToString('X8')))"
            }

            $encryptedData = New-Object byte[] $pcbProtectedBlob
            [Runtime.InteropServices.Marshal]::Copy($ppbProtectedBlob, $encryptedData, 0, $pcbProtectedBlob)
            [CngDpapiHelper]::NCryptFreeBuffer($ppbProtectedBlob) | Out-Null

            [Convert]::ToBase64String($encryptedData)
        } catch {
            throw "Encryption failed: $_"
        }
    }
}

function Unprotect-CngDpapiString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$EncryptedString
    )

    process {
        try {
            $encryptedData = [Convert]::FromBase64String($EncryptedString)
            $hDescriptor = [IntPtr]::Zero
            $dwFlags = 0
            $pMemPara = [IntPtr]::Zero
            $cbProtectedBlob = $encryptedData.Length
            $ppbData = [IntPtr]::Zero
            $pcbData = 0
            $pcbResult = 0

            $result = [CngDpapiHelper]::NCryptUnprotectSecret(
                $hDescriptor,
                $dwFlags,
                $null,
                $pMemPara,
                $encryptedData,
                $cbProtectedBlob,
                [ref]$ppbData,
                [ref]$pcbData,
                [ref]$pcbResult
            )

            if ($result -ne 0) {
                throw "NCryptUnprotectSecret failed (HRESULT 0x$($result.ToString('X8')))"
            }

            $decryptedData = New-Object byte[] $pcbData
            [Runtime.InteropServices.Marshal]::Copy($ppbData, $decryptedData, 0, $pcbData)
            [CngDpapiHelper]::NCryptFreeBuffer($ppbData) | Out-Null

            [System.Text.Encoding]::Unicode.GetString($decryptedData).TrimEnd([char]0)
        } catch {
            throw "Decryption failed: $_"
        }
    }
}

Export-ModuleMember -Function Protect-CngDpapiString, Unprotect-CngDpapiString