# Verschlüsseln für lokale Administratoren
$encrypted = Protect-CngDpapiString -String "Geheimnis" -Principal "BUILTIN\Administrators"

# Entschlüsseln (nur möglich wenn Benutzer in der Gruppe ist)
$decrypted = Unprotect-CngDpapiString -EncryptedString $encrypted