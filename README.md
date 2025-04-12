# 🔒 CNGDPAPI | Secure Secret Encryption for PowerShell [![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/dooblpls/CNGDPAPI) [![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

> **Your Secrets, Fort Knox Strong. No Passwords. Just PowerShell.**  
> *Leverage Windows CNG DPAPI to encrypt/decrypt secrets instantly. Built for teams, designed for security.*

---

## 🚀 Why Choose CNGDPAPI?

Tired of managing passwords, certificates, or complex key exchanges? **This module revolutionizes secret handling** by integrating directly with Windows' native CNG DPAPI (Cryptography Next Generation Data Protection API). Encrypt strings in seconds, share them securely, and let authorized users decrypt them **using their existing Windows Session**. No secrets left unsecured. No extra steps. Just *pure PowerShell magic*.

---

## ✨ Features

- 🔥 **Zero Configuration** – Works out-of-the-box on Windows 10/11 and Windows Server 2016+
- ⚡ **Lightning-Fast** – Encrypt/decrypt strings in milliseconds
- 🔗 **Principal-Based Access** – Secrets decryptable **only** by the intended Windows user/group
- 🧪 **Custom Descriptor Rules** – Use advanced CNG descriptor strings like `LOCAL=user` or `SID=S-1-5-...`
- 🔄 **Cross-Machine Support** – Secure secrets for use on multiple machines
- 📦 **PS Module Simplicity** – Just `Install-Module` and you’re ready
- 🔐 **Military-Grade Security** – Backed by Microsoft’s CNG DPAPI (AES-256, RSA-2048)

---

## 🛠️ Quick Start

### Install the Module
```powershell
Install-Module -Name CNGDPAPI -Scope CurrentUser -Force
```

---

### 🔒 Encrypt Like a Pro

#### **Encrypt for an AD Group** (Team Secrets)
```powershell
# Target a security group (requires admin privileges)
$encrypted = "Secret" | Protect-CngDpapiString -Principal "DOMAIN\ADGroup"
Write-Output "Share this safely: $encrypted"
```

#### **Encrypt with Custom Descriptor Rule**
```powershell
# Use raw CNG descriptor logic (e.g. LOCAL=user for local user session)
$encrypted = "Secret" | Protect-CngDpapiString -Descriptor "LOCAL=user"
Write-Output "Share this safely: $encrypted"
```

---

### 🔓 Decrypt Effortlessly

```powershell
# Any authorized principal can decrypt (no parameters needed!)
$decrypted = Unprotect-CngDpapiString -EncryptedString "base64encoded blob"
Write-Output "Decrypted secret: $decrypted"
```
*Works seamlessly if:*
- You belong to the specified AD group
- Or your session matches the custom descriptor rule

---

## 🧠 How It Works

### Behind the Scenes
- **CNG DPAPI** encrypts data using a **specific principal’s identity** or custom rule.
- Encrypted strings are **portable** – share via config files, pipelines, or even emails.
- Decryption requires **the exact Windows principal context** used during encryption. No match? No decryption.

---

## 🎯 Usage Scenarios

1. **Securely embed credentials in scripts**  
   ```powershell
   $apiKey = Unprotect-CngDpapiString -EncryptedString "BwIAAACk...ABBAAB"
   Invoke-RestApi -Url $url -Header @{"Authorization"=$apiKey}
   ```

2. **Share team-wide secrets via source control**  
   *`config.json`:*
   ```json
   {
     "EncryptedDbSecret": "BwIAAACk...AgAA"
   }
   ```

3. **Encrypt locally without needing AD**  
   ```powershell
   Protect-CngDpapiString -String "dev secret" -Descriptor "LOCAL=user"
   ```

4. **Rotate secrets without re-deploying**  
   Just re-encrypt and redistribute!

---

## 🔥 Security Best Practices

- **🚫 No Plaintext Logs**: Avoid logging raw secrets. Encrypt *first*.
- **👮 Principal Least Privilege**: Restrict decryption to specific security groups or descriptors.

---

## ❓ FAQ

**Q:** *Can I encrypt for multiple principals?*  
**A:** Yes, using custom descriptors like `"SID=S-1-5-21-... OR SID=S-1-5-32-544"`. These are passed directly via `-Descriptor`.

**Q:** *What’s the difference between `-Principal` and `-Descriptor`?*  
**A:** `-Principal` is simpler and auto-converted to a SID. `-Descriptor` gives you full control with logical expressions and policy rules (e.g. `LOCAL=user`, `WEBCREDENTIALS=...`, `AND`, `OR`). [Microsoft - Cryptography API: Next Generation - Protection Descriptors](https://learn.microsoft.com/en-us/windows/win32/seccng/protection-descriptors)

**Q:** *What if the principal is deleted?*  
**A:** Decryption becomes impossible. Always encrypt under groups for long-term secrets.

**Q:** *Works in PowerShell Core?*  
**A:** Only Windows PowerShell 5.1+ is supported (CNG DPAPI is Windows-specific).

---

## 📜 License

MIT License – Go wild, but credit `dooblpls`.

---

**🛡️ Your Secrets Deserve Better. Stop Compromising.**  
Crafted with rage against plaintext by [dooblpls](https://github.com/dooblpls).  
