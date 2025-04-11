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
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$String="TEST",
        
        [Parameter(Mandatory=$true)]
        [string]$Principal="Administratoren"        

    )

    process {
        $hDescriptor = [IntPtr]::Zero
        $ppbProtectedBlob = [IntPtr]::Zero
        $pcbProtectedBlob = [IntPtr]::Zero
        
        try {
            # Protection Descriptor erstellen
            $account = New-Object System.Security.Principal.NTAccount($Principal)
            $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
            $descriptorString="SID=$($sid.Value)"

            Write-Host "Using descriptor: $descriptorString"
            
            $result = [DpapiNgHelper]::NCryptCreateProtectionDescriptor(
                $descriptorString,
                0,
                [ref]$hDescriptor
            )

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
            
            $result = [DpapiNgHelper]::NCryptUnprotectSecret(
                [IntPtr]::Zero,
                0,
                $encryptedData,
                $encryptedData.Length,
                [IntPtr]::Zero,
                [IntPtr]::Zero,
                [ref]$ppbData,
                [ref]$pcbData
            )

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