@echo off
setlocal
chcp 65001 >nul
title LP Support v2.0 - Leonardo Polato
set "LP_SUPPORT_FILE=%~f0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo Windows PowerShell nao encontrado.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:LP_SUPPORT_FILE); $m=[Environment]::NewLine+'#<LP_SUPPORT_POWERSHELL>'+[Environment]::NewLine; try { & ([scriptblock]::Create($s.Substring($s.IndexOf($m)+$m.Length))) } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "LP_EXIT=%ERRORLEVEL%"
echo.
echo LP Support - Desenvolvido por Leonardo Polato
pause
exit /b %LP_EXIT%
#<LP_SUPPORT_POWERSHELL>
# LP Support 2.0 | Desenvolvido por Leonardo Polato
# Windows PowerShell 5.1 / Windows 10 e 11. Sem dependencias externas.
$ErrorActionPreference = 'Stop'
$script:Version = '2.0'
$script:SourceFile = $env:LP_SUPPORT_FILE
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$script:Root = Join-Path $env:LOCALAPPDATA 'LP Support'
$script:Actions = New-Object 'System.Collections.Generic.List[object]'
$script:Closed = $false
$script:Seq = 0
function Wait-Key { [void](Read-Host 'Enter para continuar') }
function Header([string]$Section) {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  LP SUPPORT  |  CENTRAL DE SUPORTE TECNICO  |  v2.0' -ForegroundColor Cyan
    Write-Host '  Desenvolvido por Leonardo Polato' -ForegroundColor White
    Write-Host '============================================================' -ForegroundColor Cyan
    $mode = 'Padrao'; if ($script:IsAdmin) { $mode = 'Administrador' }
    Write-Host "$env:COMPUTERNAME | $env:USERNAME | $mode"
    if ($script:Session) { Write-Host "Chamado: $($script:Ticket) | Tecnico: $($script:Technician)" }
    Write-Host "`n$Section`n" -ForegroundColor Yellow
}
function Confirm-Change([string]$Message) {
    Write-Host $Message -ForegroundColor Yellow
    return ((Read-Host 'Digite SIM para executar; Enter cancela').Trim() -ieq 'SIM')
}
function Write-Audit([string]$Name, [string]$Status, [string]$Detail, [string]$OutputFile = '') {
    $row = [pscustomobject][ordered]@{
        Data = (Get-Date).ToString('o'); Sessao = $script:SessionID
        Chamado = $script:Ticket; Tecnico = $script:Technician
        Computador = $env:COMPUTERNAME; Usuario = $env:USERNAME
        Acao = $Name; Status = $Status; Detalhe = $Detail; Saida = $OutputFile
    }
    $script:Actions.Add($row)
    $row | ConvertTo-Json -Compress | Add-Content -LiteralPath $script:AuditFile -Encoding UTF8
}
function Save-Session {
    [pscustomobject][ordered]@{
        Produto = 'LP Support'; Versao = $script:Version; Autor = 'Leonardo Polato'
        Sessao = $script:SessionID; Chamado = $script:Ticket; Tecnico = $script:Technician
        Computador = $env:COMPUTERNAME; Usuario = $env:USERNAME
        Inicio = $script:Started.ToString('o'); Atualizado = (Get-Date).ToString('o')
        Sintoma = $script:Symptom; Encerrado = $script:Closed
        Validacao = $script:Validation; Pendencias = $script:Pending
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $script:Session 'Atendimento.json') -Encoding UTF8
    if ($script:Actions.Count -gt 0) {
        $safeRows = foreach ($row in $script:Actions) {
            $copy = [ordered]@{}
            foreach ($p in $row.PSObject.Properties) {
                $v = [string]$p.Value
                if ($v -match '^\s*[=+@-]') { $v = "'" + $v }
                $copy[$p.Name] = $v
            }
            [pscustomobject]$copy
        }
        $safeRows | Export-Csv -LiteralPath (Join-Path $script:Session 'Historico.csv') -NoTypeInformation -Encoding UTF8 -Delimiter ';'
    }
}
function Invoke-Native {
    param([string]$Exe, [string[]]$Arguments = @(), [int[]]$SuccessCodes = @(0))
    if (-not (Get-Command $Exe -ErrorAction SilentlyContinue)) { throw "Comando indisponivel: $Exe" }
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Exe @Arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($code -notin $SuccessCodes) { throw "$Exe retornou codigo $code. Consulte a saida; nenhuma correcao foi presumida." }
    "Codigo de saida: $code"
    if ($code -eq 3010) { 'O Windows informou que e necessario reiniciar. Reinicie manualmente quando conveniente.' }
}
function Run-Action {
    param([string]$Name, [scriptblock]$Body, [switch]$Admin, [string]$Warning = '')
    if ($Admin -and -not $script:IsAdmin) {
        Write-Host 'Esta acao exige administrador. Use a opcao A no menu principal.' -ForegroundColor Yellow
        Write-Audit $Name 'BLOQUEADO' 'Permissao de administrador necessaria'
        Save-Session; Wait-Key; return
    }
    if ($Warning -and -not (Confirm-Change $Warning)) {
        Write-Audit $Name 'CANCELADO' 'Cancelado pelo tecnico'; Save-Session; return
    }
    $script:ActionOutcome = 'CONCLUIDO'
    $script:Seq++
    $output = Join-Path $script:Session ('{0:D3}_Saida.txt' -f $script:Seq)
    Write-Audit $Name 'INICIADO' 'Execucao solicitada' $output
    Write-Host "`nExecutando: $Name" -ForegroundColor Cyan
    try {
        "LP Support v2.0 | Leonardo Polato`r`n$Name | $(Get-Date -Format o)" | Set-Content -LiteralPath $output -Encoding UTF8
        & $Body | Out-String -Stream -Width 180 | ForEach-Object {
            Add-Content -LiteralPath $output -Value $_ -Encoding UTF8
            Write-Host $_
        }
        Write-Audit $Name $script:ActionOutcome 'Consulte a saida e valide o resultado no atendimento' $output
        Write-Host "Resultado: $script:ActionOutcome. Confira a saida acima." -ForegroundColor Cyan
    } catch {
        $message = $_.Exception.Message
        Add-Content -LiteralPath $output -Value "ERRO: $message" -Encoding UTF8
        Write-Audit $Name 'FALHA' $message $output
        Write-Host "Falha: $message" -ForegroundColor Red
    }
    Save-Session
    Wait-Key
}
function Show-Menu([string]$Title, [System.Collections.IDictionary]$Items) {
    while ($true) {
        Header $Title
        foreach ($key in $Items.Keys) { Write-Host "[$key] $($Items[$key].Name)" }
        Write-Host '[0] Voltar'
        $choice = (Read-Host 'Opcao').Trim()
        if ($choice -eq '0') { return }
        if ($Items.Contains($choice)) {
            $item = $Items[$choice]
            Run-Action -Name $item.Name -Body $item.Body -Admin:([bool]$item.Admin) -Warning ([string]$item.Warning)
        } else { Write-Host 'Opcao invalida.' -ForegroundColor Yellow; Wait-Key }
    }
}
function New-ItemAction([string]$Name, [scriptblock]$Body, [bool]$Admin = $false, [string]$Warning = '') {
    return @{ Name = $Name; Body = $Body; Admin = $Admin; Warning = $Warning }
}
function Get-DiskSummary {
    Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID, VolumeName,
        @{n='Total_GB';e={[math]::Round($_.Size/1GB,2)}},
        @{n='Livre_GB';e={[math]::Round($_.FreeSpace/1GB,2)}},
        @{n='Livre_Pct';e={if ($_.Size) {[math]::Round(100*$_.FreeSpace/$_.Size,1)}}}
}
function Test-Network {
    'Um ping sem resposta pode indicar bloqueio de ICMP; nao prova indisponibilidade.'
    $targets = @([pscustomobject]@{Etapa='Pilha local';Alvo='127.0.0.1'})
    $configs = @(Get-NetIPConfiguration)
    foreach ($config in $configs) {
        foreach ($gateway in @($config.IPv4DefaultGateway)) {
            if ($gateway.NextHop) { $targets += [pscustomobject]@{Etapa="Gateway ($($config.InterfaceAlias))";Alvo=$gateway.NextHop} }
        }
    }
    if ($targets.Count -eq 1) { 'Nenhum gateway IPv4 encontrado. Verifique adaptadores, VPN e configuracao IPv6.' }
    $targets += [pscustomobject]@{Etapa='IP externo';Alvo='1.1.1.1'}
    foreach ($target in $targets) {
        $ping = New-Object System.Net.NetworkInformation.Ping
        try {
            $reply = $ping.Send([string]$target.Alvo,1500)
            "$($target.Etapa): $($target.Alvo) -> $($reply.Status) | $($reply.RoundtripTime) ms"
        } catch { "$($target.Etapa): erro -> $($_.Exception.Message)" }
        finally { $ping.Dispose() }
    }
    try { Resolve-DnsName 'www.microsoft.com' -DnsOnly -QuickTimeout | Select-Object Name,Type,IPAddress | Format-Table | Out-String }
    catch { "DNS: falha na consulta -> $($_.Exception.Message)" }
    $client = New-Object Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync('www.microsoft.com',443)
        if (-not $task.Wait(4000)) { 'TCP 443: tempo esgotado.' }
        elseif ($client.Connected) { 'TCP 443: conexao estabelecida com www.microsoft.com. Nao testa proxy ou autenticacao web.' }
    } catch { "TCP 443: falha -> $($_.Exception.Message)" }
    finally { $client.Dispose() }
}
function Write-Diagnostic {
    $sections = [ordered]@{
        'Windows' = { Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime | Format-List }
        'Equipamento' = { Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,Domain,@{n='RAM_GB';e={[math]::Round($_.TotalPhysicalMemory/1GB,2)}} | Format-List; Get-CimInstance Win32_BIOS | Select-Object SerialNumber,SMBIOSBIOSVersion | Format-List; Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors | Format-List }
        'Armazenamento' = { Get-DiskSummary | Format-Table -AutoSize }
        'Rede' = { Get-NetIPConfiguration -Detailed | Format-List; Get-DnsClientServerAddress | Select-Object InterfaceAlias,AddressFamily,ServerAddresses | Format-Table -AutoSize }
        'Impressoras' = { Get-CimInstance Win32_Printer | Select-Object Name,Default,DriverName,PortName,PrinterStatus,WorkOffline | Format-Table -AutoSize }
        'Servicos' = { Get-Service Spooler,wuauserv,BITS,Dnscache | Select-Object Name,Status,StartType | Format-Table -AutoSize }
        'Atualizacoes recentes (inventario parcial)' = { Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID,Description,InstalledOn | Format-Table -AutoSize }
        'Eventos criticos e erros de sistema - 24h (ate 30)' = {
            $events = @(Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2;StartTime=(Get-Date).AddDays(-1)} -MaxEvents 30 -ErrorAction SilentlyContinue -ErrorVariable eventErrors)
            if ($events.Count) { $events | Select-Object TimeCreated,Id,ProviderName,Message | Format-List }
            elseif ($eventErrors -and $eventErrors[0].FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw $eventErrors[0] }
            else { 'Nenhum evento correspondente encontrado.' }
        }
    }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    $base = Join-Path $script:Session "Diagnostico_${env:COMPUTERNAME}_$stamp"
    $text = "LP SUPPORT v2.0 | Desenvolvido por Leonardo Polato`r`nData: $(Get-Date -Format o)`r`nComputador: $env:COMPUTERNAME`r`nChamado: $script:Ticket`r`nTecnico: $script:Technician`r`nSintoma: $script:Symptom`r`n"
    $htmlSections = ''
    $failures = 0
    foreach ($name in $sections.Keys) {
        Write-Host "Coletando: $name..."
        try { $body = (& $sections[$name] | Out-String -Width 180) }
        catch { $body = "COLETA INDISPONIVEL: $($_.Exception.Message)"; $failures++ }
        $text += "`r`n===== $name =====`r`n$body"
        $htmlSections += '<section><h2>' + [Net.WebUtility]::HtmlEncode($name) + '</h2><pre>' + [Net.WebUtility]::HtmlEncode($body) + '</pre></section>'
    }
    $text | Set-Content -LiteralPath "$base.txt" -Encoding UTF8
    $intro = [Net.WebUtility]::HtmlEncode("Computador: $env:COMPUTERNAME | Chamado: $script:Ticket | Tecnico: $script:Technician | $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
    $symptom = [Net.WebUtility]::HtmlEncode($script:Symptom)
    $html = @"
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>LP Support | Diagnostico</title><style>
body{font:15px Segoe UI,Arial,sans-serif;background:#eef3f8;color:#16273b;margin:0}main{max-width:1080px;margin:32px auto;padding:0 24px}header{background:#102b46;color:white;padding:32px;border-radius:14px;border-top:5px solid #26c8c0}h1{margin:0 0 8px}h2{font-size:18px;color:#123c5c}section{background:white;border:1px solid #dbe5ef;border-radius:10px;margin-top:18px;padding:20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:12px Consolas,monospace}footer{padding:24px 0;color:#52667a}@media print{body{background:white}main{margin:0}section{break-inside:avoid}header{color:#102b46;background:white}}
</style></head><body><main><header><h1>LP SUPPORT <small>v2.0</small></h1><p>Central de Suporte Tecnico</p><p>Desenvolvido por Leonardo Polato</p></header><section><h2>Diagnostico do atendimento</h2><p>$intro</p><p>Sintoma: $symptom</p><p>Secoes indisponiveis: $failures. Coleta pontual; nao certifica a saude do equipamento.</p></section>$htmlSections<footer>Documento local. Revise dados do equipamento, usuario e rede antes de compartilhar.</footer></main></body></html>
"@
    $html | Set-Content -LiteralPath "$base.html" -Encoding UTF8
    if ($failures) { $script:ActionOutcome = 'PARCIAL'; Write-Audit 'Diagnostico' 'PARCIAL' "$failures secoes indisponiveis; consulte o relatorio" "$base.html" }
    "Relatorio TXT: $base.txt"
    "Relatorio HTML: $base.html"
    'O HTML pode ser aberto no navegador e impresso como PDF.'
}
$script:RegistryTargets = @{
    Privacy = @{Path='HKLM:\SYSTEM\CurrentControlSet\Control\Print';Name='RpcAuthnLevelPrivacyEnabled';Value=0}
    NamedPipe = @{Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC';Name='RpcUseNamedPipeProtocol';Value=1}
}
function Set-PrintCompatibility([string]$TargetID) {
    $target = $script:RegistryTargets[$TargetID]
    $exists = $false; $old = $null; $kind = 'DWord'
    if (Test-Path -LiteralPath $target.Path) {
        $key = Get-Item -LiteralPath $target.Path
        if ($key.GetValueNames() -contains $target.Name) {
            $exists = $true; $old = $key.GetValue($target.Name); $kind = [string]$key.GetValueKind($target.Name)
            if ($kind -ne 'DWord') { throw 'Valor existente nao e DWORD. Alteracao bloqueada para revisao manual.' }
        }
    }
    $backup = Join-Path $script:Session ('Registro_' + $TargetID + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff') + '.clixml')
    [pscustomobject]@{Formato='LP.Support.Registry.1';Computador=$env:COMPUTERNAME;Target=$TargetID;Exists=$exists;OldValue=$old;Kind=$kind} | Export-Clixml -LiteralPath $backup -Encoding UTF8
    if (-not (Test-Path -LiteralPath $target.Path)) { New-Item -Path $target.Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $target.Path -Name $target.Name -PropertyType DWord -Value $target.Value -Force | Out-Null
    $actual = (Get-ItemProperty -LiteralPath $target.Path -Name $target.Name).($target.Name)
    if ($actual -ne $target.Value) { throw "Verificacao falhou. Backup: $backup" }
    "Backup do valor anterior: $backup"
    'Valor gravado e conferido. Planeje reiniciar o servico/equipamento e valide a impressao.'
}
function Restore-PrintValue {
    $backups = @(Get-ChildItem -LiteralPath $script:Root -Filter 'Registro_*.clixml' -Recurse -File | Sort-Object LastWriteTime -Descending)
    if (-not $backups.Count) { throw 'Nenhum backup desta ferramenta encontrado para este perfil.' }
    for ($i=0; $i -lt $backups.Count; $i++) { Write-Host "[$($i+1)] $($backups[$i].FullName)" }
    $choice = 0
    if (-not [int]::TryParse((Read-Host 'Numero do backup; Enter cancela'),[ref]$choice) -or $choice -lt 1 -or $choice -gt $backups.Count) { throw 'Nenhum backup valido selecionado. Nada alterado.' }
    $backup = Import-Clixml -LiteralPath $backups[$choice-1].FullName
    if ($backup.Formato -ne 'LP.Support.Registry.1' -or $backup.Computador -ne $env:COMPUTERNAME -or -not $script:RegistryTargets.ContainsKey([string]$backup.Target) -or $backup.Kind -ne 'DWord' -or $backup.Exists -isnot [bool]) { throw 'Backup incompativel com esta ferramenta ou este computador.' }
    $target = $script:RegistryTargets[[string]$backup.Target]
    if (-not (Confirm-Change "Restaurar $($target.Name) para o estado salvo em $($backups[$choice-1].Name)?")) { $script:ActionOutcome = 'CANCELADO'; Write-Audit 'Restauracao de Registro' 'CANCELADO' 'Cancelado pelo tecnico'; return }
    if ($backup.Exists) {
        if (-not (Test-Path -LiteralPath $target.Path)) { New-Item -Path $target.Path -Force | Out-Null }
        New-ItemProperty -LiteralPath $target.Path -Name $target.Name -PropertyType DWord -Value ([int]$backup.OldValue) -Force | Out-Null
        if ((Get-ItemProperty -LiteralPath $target.Path -Name $target.Name).($target.Name) -ne [int]$backup.OldValue) { throw 'Verificacao de restauracao falhou.' }
    } elseif (Test-Path -LiteralPath $target.Path) {
        $key = Get-Item -LiteralPath $target.Path
        if ($key.GetValueNames() -contains $target.Name) { Remove-ItemProperty -LiteralPath $target.Path -Name $target.Name }
        if ((Get-Item -LiteralPath $target.Path).GetValueNames() -contains $target.Name) { throw 'Remocao do valor nao confirmada.' }
    }
    'Valor restaurado e conferido. Outros valores da chave foram preservados. Valide a impressao apos reiniciar o servico/equipamento.'
}
function Start-Elevated {
    if ($script:IsAdmin) { Write-Host 'Esta sessao ja esta elevada.'; Wait-Key; return }
    if (-not (Confirm-Change 'Abrir nova sessao como administrador? O historico atual sera salvo. Se usar outra conta, os arquivos ficarao no perfil dela.')) { return }
    Save-Session
    $quoted = $script:SourceFile.Replace("'","''")
    $bootstrap = '$env:LP_SUPPORT_FILE=' + "'$quoted'; " + '$s=[IO.File]::ReadAllText($env:LP_SUPPORT_FILE); $m=[Environment]::NewLine+"#<LP_SUPPORT_POWERSHELL>"+[Environment]::NewLine; & ([scriptblock]::Create($s.Substring($s.IndexOf($m)+$m.Length)))'
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($bootstrap))
    try {
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" | Out-Null
        Write-Audit 'Elevacao' 'SOLICITADO' 'Nova janela solicitada; sessao original permanece disponivel'
    } catch { Write-Audit 'Elevacao' 'FALHA' $_.Exception.Message; Write-Host 'Elevacao cancelada ou indisponivel.' }
    Wait-Key
}
function Show-Help {
    Header 'GUIA RAPIDO'
    @'
1. Identifique o chamado, o tecnico e o sintoma.
2. Execute o diagnostico antes de aplicar reparos.
3. Selecione apenas a acao adequada ao problema observado.
4. Verifique a saida; CONCLUIDO nao significa incidente resolvido.
5. Encerre o atendimento com validacao e pendencias.

Arquivos por atendimento:
  Atendimento.json  - identificacao, sintoma e encerramento
  Auditoria.jsonl   - inicio, resultado e erro das operacoes
  Historico.csv     - eventos para Excel/Power BI (separador ;)
  NNN_Saida.txt     - saida individual de cada acao
  Diagnostico*.html / .txt - relatorios, quando solicitados
  Registro*.clixml  - backups dos valores alterados na impressao

Requisitos previstos: Windows 10/11 e Windows PowerShell 5.1.
Sem WMIC, instalacao de pacotes ou envio automatico de dados.
O teste de rede consulta enderecos externos quando selecionado.
Ferramentas abertas em outra janela nao tem suas acoes auditadas.
Logs sao locais e editaveis: nao constituem trilha inviolavel.
Politicas corporativas e permissao de administrador continuam valendo.
Nao ha reinicio automatico do computador.
Fechar a janela abruptamente deixa o atendimento sem encerramento.
Antes de compartilhar relatorios, revise dados pessoais e de rede.
Backups de Registro restauram apenas os valores especificos da ferramenta.

IDENTIDADE
LP Support v2.0 | Desenvolvido por Leonardo Polato
Marca visual do projeto; nao representa registro legal de marca.
'@ | Write-Host
    Write-Host "`nPasta de dados: $script:Root" -ForegroundColor Cyan
    Wait-Key
}
try {
    if ($PSVersionTable.PSVersion -lt [version]'5.1') { throw 'Requer Windows PowerShell 5.1 ou superior.' }
    $Host.UI.RawUI.WindowTitle = 'LP Support v2.0 | Leonardo Polato'
    $script:Started = Get-Date
    $script:SessionID = $script:Started.ToString('yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
    $script:Session = Join-Path $script:Root (Join-Path 'Atendimentos' ($env:COMPUTERNAME + '_' + $script:SessionID))
    New-Item -Path $script:Session -ItemType Directory -Force | Out-Null
    $script:AuditFile = Join-Path $script:Session 'Auditoria.jsonl'
    Header 'NOVO ATENDIMENTO - campos opcionais'
    $script:Ticket = Read-Host 'Numero do chamado (Enter = avulso)'
    if ([string]::IsNullOrWhiteSpace($script:Ticket)) { $script:Ticket = 'AVULSO' }
    $script:Technician = Read-Host 'Tecnico (Enter = Leonardo Polato)'
    if ([string]::IsNullOrWhiteSpace($script:Technician)) { $script:Technician = 'Leonardo Polato' }
    $script:Symptom = Read-Host 'Sintoma ou objetivo do atendimento'
    $script:Validation = 'Nao registrada'; $script:Pending = ''
    Write-Audit 'Atendimento' 'ABERTO' $script:Symptom
    Save-Session
    $network = [ordered]@{
        '1' = (New-ItemAction 'Configuracao IP completa' { Invoke-Native 'ipconfig.exe' @('/all') })
        '2' = (New-ItemAction 'Teste por etapas: local, gateway, IP, DNS e TCP' { Test-Network })
        '3' = (New-ItemAction 'Limpar cache DNS' { Invoke-Native 'ipconfig.exe' @('/flushdns') } $true 'Limpar o cache local de resolucao DNS?')
        '4' = (New-ItemAction 'Liberar IP DHCP' { Invoke-Native 'ipconfig.exe' @('/release') } $true 'A conexao pode cair imediatamente, inclusive acesso remoto. Libera IPv4 das interfaces DHCP. Execute localmente.')
        '5' = (New-ItemAction 'Renovar IP DHCP' { Invoke-Native 'ipconfig.exe' @('/renew') } $true 'Renovar a concessao DHCP das interfaces? Pode interromper a conexao e demorar.')
        '6' = (New-ItemAction 'Tabela de rotas' { Invoke-Native 'route.exe' @('print') })
        '7' = (New-ItemAction 'Redefinir Winsock' { Invoke-Native 'netsh.exe' @('winsock','reset'); 'Reinicializacao manual pode ser necessaria.' } $true 'Redefinir o catalogo Winsock? Pode afetar clientes de rede/VPN e exigir reinicializacao.')
    }
    $printers = [ordered]@{
        '1' = (New-ItemAction 'Listar impressoras' { Get-CimInstance Win32_Printer | Select-Object Name,Default,DriverName,PortName,PrinterStatus,WorkOffline | Format-Table -AutoSize })
        '2' = (New-ItemAction 'Consultar spooler' { Get-Service Spooler | Format-List Name,Status,StartType })
        '3' = (New-ItemAction 'Reiniciar spooler' { Restart-Service Spooler -Force; (Get-Service Spooler).WaitForStatus('Running',[timespan]::FromSeconds(20)); Get-Service Spooler } $true 'Interrompe temporariamente todas as impressoes deste computador. Reiniciar spooler?')
        '4' = (New-ItemAction 'Listar trabalhos de impressao' { Get-Printer | ForEach-Object { Get-PrintJob -PrinterName $_.Name } | Select-Object PrinterName,ID,DocumentName,JobStatus,SubmittedTime | Format-Table -AutoSize })
    }
    $system = [ordered]@{
        '1' = (New-ItemAction 'Verificar arquivos do Windows - SFC' { Invoke-Native 'sfc.exe' @('/scannow') } $true 'SFC verifica e pode reparar arquivos protegidos. Pode demorar. Prosseguir?')
        '2' = (New-ItemAction 'DISM - CheckHealth' { Invoke-Native 'dism.exe' @('/Online','/Cleanup-Image','/CheckHealth') } $true)
        '3' = (New-ItemAction 'DISM - RestoreHealth' { Invoke-Native 'dism.exe' @('/Online','/Cleanup-Image','/RestoreHealth','/NoRestart') @(0,3010) } $true 'Reparar a imagem do Windows? Pode usar Windows Update, internet e levar varios minutos.')
        '4' = (New-ItemAction 'Atualizar politicas - GPUpdate' { Invoke-Native 'gpupdate.exe' @('/force','/wait:60') } $true 'Reaplica politicas da organizacao. Pode exigir logoff ou reinicio; nenhum reinicio automatico sera solicitado pela ferramenta.')
        '5' = (New-ItemAction 'Informacoes do sistema' { Invoke-Native 'systeminfo.exe' })
        '6' = (New-ItemAction 'Espaco em disco' { Get-DiskSummary | Format-Table -AutoSize })
        '7' = (New-ItemAction 'Abrir Limpeza de Disco do Windows' { Start-Process 'cleanmgr.exe'; 'Selecione e confirme os itens na janela do Windows. Resultado da limpeza nao auditado.' })
        '8' = (New-ItemAction 'Abrir configuracoes de armazenamento' { Start-Process 'ms-settings:storagesense'; 'Janela solicitada; operacoes feitas nela nao sao auditadas.' })
    }
    $toolsMenu = [ordered]@{
        '1' = (New-ItemAction 'Prompt de comando' { Start-Process 'cmd.exe'; 'Janela solicitada; comandos posteriores nao auditados.' })
        '2' = (New-ItemAction 'PowerShell' { Start-Process 'powershell.exe'; 'Janela solicitada; comandos posteriores nao auditados.' })
        '3' = (New-ItemAction 'Gerenciador de tarefas' { Start-Process 'taskmgr.exe' })
        '4' = (New-ItemAction 'Servicos' { Start-Process 'mmc.exe' -ArgumentList 'services.msc' })
        '5' = (New-ItemAction 'Editor de Registro' { Start-Process 'regedit.exe' } $false 'Abrir o Editor de Registro? Edicoes manuais nao terao backup nem auditoria pela LP Support.')
        '6' = (New-ItemAction 'Visualizador de Eventos' { Start-Process 'mmc.exe' -ArgumentList 'eventvwr.msc' })
        '7' = (New-ItemAction 'Gerenciamento do Computador' { Start-Process 'mmc.exe' -ArgumentList 'compmgmt.msc' })
    }
    $advanced = [ordered]@{
        '1' = (New-ItemAction 'CHKDSK - verificacao online' { Invoke-Native 'chkdsk.exe' @($env:SystemDrive,'/scan') } $true 'Verificacao online do volume do Windows; pode gerar carga de disco. /scan requer NTFS. Sem reparo offline agendado.')
        '2' = (New-ItemAction 'Listar atualizacoes de aplicativos - Winget' { Invoke-Native 'winget.exe' @('upgrade','--disable-interactivity') })
        '3' = (New-ItemAction 'Atualizar aplicativos - Winget' { Invoke-Native 'winget.exe' @('upgrade','--all','--disable-interactivity') } $false 'Atualiza aplicativos elegiveis e pode fechar programas. Salve o trabalho. Acordos nao sao aceitos automaticamente; itens que exigem interacao podem falhar. Instaladores externos podem ter comportamento proprio.')
        '4' = (New-ItemAction 'Sincronizar horario' { Invoke-Native 'w32tm.exe' @('/resync') } $true 'Solicitar sincronizacao com a fonte de horario configurada?')
        '5' = (New-ItemAction 'Desativar hibernacao' { Invoke-Native 'powercfg.exe' @('/hibernate','off') } $true 'Desativa hibernacao e pode desativar Inicializacao Rapida. Prosseguir?')
        '6' = (New-ItemAction 'Ativar hibernacao' { Invoke-Native 'powercfg.exe' @('/hibernate','on') } $true 'Ativa hibernacao e reserva espaco para o arquivo de hibernacao.')
        '7' = (New-ItemAction 'Impressao: compatibilidade RPC Named Pipes' { Set-PrintCompatibility 'NamedPipe' } $true 'Altera transporte RPC de impressao neste cliente. Nao e correcao universal para 0x00000709. Use somente com diagnostico e autorizacao do ambiente. Backup sera criado.')
        '8' = (New-ItemAction 'Impressao: compatibilidade legada de privacidade RPC' { Set-PrintCompatibility 'Privacy' } $true 'ATENCAO: reduz a protecao RPC de impressao no servidor/host. Nao e correcao universal para 0x0000011b. Prefira atualizacoes e drivers compativeis. Use somente como excecao temporaria autorizada. Backup sera criado.')
        '9' = (New-ItemAction 'Restaurar valor de Registro salvo pela LP Support' { Restore-PrintValue } $true)
    }
    while (-not $script:Closed) {
        Header 'MENU PRINCIPAL'
        @'
[1] Rede e conectividade
[2] Impressoras
[3] Sistema e manutencao
[4] Ferramentas do Windows
[5] Gerar diagnostico TXT + HTML
[6] Acoes avancadas e compatibilidade
[7] Abrir pasta deste atendimento
[8] Historico deste atendimento
[A] Abrir nova sessao como administrador
[H] Guia rapido e assinatura
[0] Encerrar atendimento e sair
'@ | Write-Host
        $choice = (Read-Host 'Opcao').Trim().ToUpperInvariant()
        switch ($choice) {
            '1' { Show-Menu 'REDE E CONECTIVIDADE' $network }
            '2' { Show-Menu 'IMPRESSORAS' $printers }
            '3' { Show-Menu 'SISTEMA E MANUTENCAO' $system }
            '4' { Show-Menu 'FERRAMENTAS DO WINDOWS' $toolsMenu }
            '5' { Run-Action 'Diagnostico completo' { Write-Diagnostic } }
            '6' { Show-Menu 'ACOES AVANCADAS - selecione conforme diagnostico' $advanced }
            '7' { Run-Action 'Abrir pasta do atendimento' { Start-Process 'explorer.exe' -ArgumentList ('"' + $script:Session + '"') } }
            '8' { $script:Actions | Format-Table Data,Acao,Status -AutoSize | Out-Host; Wait-Key }
            'A' { Start-Elevated }
            'H' { Show-Help }
            '0' {
                $script:Validation = Read-Host 'Resultado e validacao do usuario (Enter = nao registrada)'
                if ([string]::IsNullOrWhiteSpace($script:Validation)) { $script:Validation = 'Nao registrada' }
                $script:Pending = Read-Host 'Pendencias ou proximos passos'
                $script:Closed = $true
                Write-Audit 'Atendimento' 'ENCERRADO' $script:Validation
                Save-Session
                Write-Host "Atendimento salvo em: $script:Session" -ForegroundColor Green
            }
            default { Write-Host 'Opcao invalida.' -ForegroundColor Yellow; Wait-Key }
        }
    }
} catch {
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'A sessao foi interrompida. Os arquivos ja gravados permanecem na pasta do atendimento.'
    if ($script:Session) { Write-Host $script:Session }
    Wait-Key
    exit 1
}
