$ErrorActionPreference='Stop'
$script:ShellExe = Join-Path $PSHOME 'pwsh'
if ($env:OS -eq 'Windows_NT') { $script:ShellExe = Join-Path $PSHOME 'powershell.exe'; if (-not (Test-Path -LiteralPath $script:ShellExe)) { $script:ShellExe = Join-Path $PSHOME 'pwsh.exe' } }
$tokens=$null; $errors=$null
$batPath = Join-Path (Split-Path $PSScriptRoot) 'LP_Support_v2.0.bat'
$batSource = [IO.File]::ReadAllText($batPath)
$marker = "`r`n#<LP_SUPPORT_POWERSHELL>`r`n"
if ($batSource.IndexOf($marker) -lt 0) { throw 'Marcador do BAT nao encontrado.' }
$core = $batSource.Substring($batSource.IndexOf($marker) + $marker.Length)
$ast=[System.Management.Automation.Language.Parser]::ParseInput($core,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach($f in $ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)) { . ([scriptblock]::Create($f.Extent.Text)) }
function Assert($test,$message) { if(-not $test){throw $message}; Write-Host "PASS: $message" }
$script:Session=Join-Path ([IO.Path]::GetTempPath()) ('LP-Support-Test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:Session -Force | Out-Null
$script:Root=$script:Session
$script:AuditFile=Join-Path $script:Session 'Auditoria.jsonl'
$script:SessionID='TEST'; $script:Version='2.0'; $script:Ticket='=TEST'; $script:Technician='<script>x</script>'
$script:Symptom='<img onerror=alert(1)>'; $script:Started=Get-Date
$script:Validation='Nao registrada'; $script:Pending=''; $script:Closed=$false
$script:Actions=New-Object 'System.Collections.Generic.List[object]'
$script:Seq=0; $script:IsAdmin=$false
function Wait-Key {}
function Confirm-Change { return $false }
Run-Action 'blocked' {throw 'NEVER'} -Admin
Assert ($script:Actions[-1].Status -eq 'BLOQUEADO') 'admin gate blocks action'
Run-Action 'cancelled' {throw 'NEVER'} -Warning 'confirm'
Assert ($script:Actions[-1].Status -eq 'CANCELADO') 'cancel gate blocks action'
Run-Action 'success' {'Test output'}
Assert ($script:Actions[-1].Status -eq 'CONCLUIDO') 'successful action logged'
Run-Action 'failure' {throw 'Expected error'}
Assert ($script:Actions[-1].Status -eq 'FALHA') 'exception logged as failure'
Run-Action 'native failure' {Invoke-Native $script:ShellExe @('-NoProfile','-Command','exit 7')}
Assert ($script:Actions[-1].Status -eq 'FALHA' -and $script:Actions[-1].Detalhe -like '*codigo 7*') 'nonzero native exit is failure'
Run-Action 'native success' {Invoke-Native $script:ShellExe @('-NoProfile','-Command','exit 0')}
Assert ($script:Actions[-1].Status -eq 'CONCLUIDO') 'zero native exit is completion'
Run-Action 'native missing' {Invoke-Native 'LP_COMMAND_DOES_NOT_EXIST'}
Assert ($script:Actions[-1].Status -eq 'FALHA') 'missing native command handled'
$csv=Import-Csv -LiteralPath (Join-Path $script:Session 'Historico.csv') -Delimiter ';'
Assert ($csv[0].Chamado -eq "'=TEST") 'CSV formula prefix escaped'
$metadata=Get-Content (Join-Path $script:Session 'Atendimento.json') -Raw | ConvertFrom-Json
Assert ($metadata.Chamado -eq '=TEST') 'JSON retains original ticket'
function Get-CimInstance {param($ClassName,$Filter) [pscustomobject]@{Caption='Test';Version='1';Size=100GB;FreeSpace=25GB;TotalPhysicalMemory=8GB;Name='Demo'}}
function Get-NetIPConfiguration {param([switch]$Detailed) 'TEST-NETWORK'}
function Get-DnsClientServerAddress { [pscustomobject]@{InterfaceAlias='Ethernet';AddressFamily=2;ServerAddresses='1.1.1.1'} }
function Get-Service { 'Test service' }
function Get-HotFix { throw 'Simulated unavailable section' }
function Get-WinEvent {param($FilterHashtable,$MaxEvents,$ErrorAction,$ErrorVariable) @()}
Run-Action 'diagnostic' { Write-Diagnostic }
Assert ($script:Actions[-1].Status -eq 'PARCIAL') 'partial diagnostic is not reported as full success'
$html=Get-ChildItem $script:Session -Filter '*.html' | Select-Object -First 1 | Get-Content -Raw
Assert ($html.Contains('&lt;img onerror=alert(1)&gt;') -and -not $html.Contains('<img onerror')) 'HTML escapes user symptom'
Assert ($html.Contains('&lt;script&gt;') -and -not $html.Contains('<script>x')) 'HTML escapes technician name'
Assert ($html.Contains('Simulated unavailable section')) 'diagnostic records unavailable section'
$script:Closed=$true; Save-Session
$metadata=Get-Content (Join-Path $script:Session 'Atendimento.json') -Raw | ConvertFrom-Json
Assert ($metadata.Encerrado -eq $true) 'session closure persisted'
$bat=[IO.File]::ReadAllText((Join-Path (Split-Path $PSScriptRoot) 'LP_Support_v2.0.bat'))
$m="`r`n#<LP_SUPPORT_POWERSHELL>`r`n"
$payload=$bat.Substring($bat.IndexOf($m)+$m.Length)
Assert ($payload.StartsWith('# LP Support 2.0')) 'BAT extracts exactly the payload'
$env:LP_SUPPORT_FILE="C:\Tools\O'Brien & Team\LP_Support_v2.0.bat"
$script:SourceFile=$env:LP_SUPPORT_FILE
$script:CapturedCommand=$null
function Confirm-Change { return $true }
function Start-Process {param($FilePath,$Verb,$ArgumentList) $script:CapturedCommand=$ArgumentList }
Start-Elevated
$encoded=$script:CapturedCommand.Split(' ')[-1]
$decoded=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
$e=$null;$t=$null
[void][System.Management.Automation.Language.Parser]::ParseInput($decoded,[ref]$t,[ref]$e)
Assert ($e.Count -eq 0 -and $decoded.Contains("O''Brien & Team")) 'elevation bootstrap parses with apostrophe and spaces in file path'

foreach($a in $ast.FindAll({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst]},$true)) {
    if ($a.Left.Extent.Text -in @('$script:RegistryTargets','$network','$printers','$system','$toolsMenu','$advanced')) { . ([scriptblock]::Create($a.Extent.Text)) }
}
Assert (($network.Count+$printers.Count+$system.Count+$toolsMenu.Count+$advanced.Count) -eq 35) 'all 35 submenu actions instantiate'
$script:Reg=@{}
function Test-Path {param($LiteralPath) if($LiteralPath -like 'HKLM:*'){return $script:Reg.ContainsKey($LiteralPath)}; Microsoft.PowerShell.Management\Test-Path -LiteralPath $LiteralPath}
function New-Item {param($Path,$ItemType,[switch]$Force) if($Path -like 'HKLM:*'){$script:Reg[$Path]=@{};return}; Microsoft.PowerShell.Management\New-Item @PSBoundParameters}
function Get-Item {param($LiteralPath)
 if($LiteralPath -like 'HKLM:*'){
  $obj=[pscustomobject]@{Values=$script:Reg[$LiteralPath]}
  $obj|Add-Member ScriptMethod GetValueNames {return @($this.Values.Keys)}
  $obj|Add-Member ScriptMethod GetValue {param($n)return $this.Values[$n]}
  $obj|Add-Member ScriptMethod GetValueKind {param($n)return 'DWord'}
  return $obj
 }; Microsoft.PowerShell.Management\Get-Item -LiteralPath $LiteralPath
}
function New-ItemProperty {param($LiteralPath,$Name,$PropertyType,$Value,[switch]$Force) $script:Reg[$LiteralPath][$Name]=$Value}
function Get-ItemProperty {param($LiteralPath,$Name) [pscustomobject]@{$Name=$script:Reg[$LiteralPath][$Name]}}
function Remove-ItemProperty {param($LiteralPath,$Name) $script:Reg[$LiteralPath].Remove($Name)}
function Read-Host {param($Prompt) return '1'}
$env:COMPUTERNAME='LP-TEST'
Set-PrintCompatibility 'Privacy'
Assert ($script:Reg[$script:RegistryTargets.Privacy.Path]['RpcAuthnLevelPrivacyEnabled'] -eq 0) 'compatibility writes expected value'
Restore-PrintValue
Assert (-not $script:Reg[$script:RegistryTargets.Privacy.Path].ContainsKey('RpcAuthnLevelPrivacyEnabled')) 'rollback removes previously absent value'
$script:Reg[$script:RegistryTargets.Privacy.Path]['RpcAuthnLevelPrivacyEnabled']=1
$script:Reg[$script:RegistryTargets.Privacy.Path]['OtherSetting']=42
Set-PrintCompatibility 'Privacy'
Restore-PrintValue
Assert ($script:Reg[$script:RegistryTargets.Privacy.Path]['RpcAuthnLevelPrivacyEnabled'] -eq 1) 'rollback restores existing DWORD'
Assert ($script:Reg[$script:RegistryTargets.Privacy.Path]['OtherSetting'] -eq 42) 'rollback preserves unrelated settings'

Write-Host 'ALL CHECKS PASSED (Windows operations mocked). Test files:'
Write-Host $script:Session
