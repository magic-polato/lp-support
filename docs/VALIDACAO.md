# Validação

## Testes automatizados de lógica

Execute na raiz do projeto:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Logic.ps1
```

Em um ambiente com PowerShell 7, o executável pode ser `pwsh`.

O teste extrai e analisa o conteúdo do BAT, carrega apenas as definições de funções, cria arquivos temporários sintéticos e substitui consultas Windows e operações de Registro por simulações. Os comandos nativos utilizados no teste são subprocessos PowerShell que encerram com códigos controlados. O teste não executa SFC, DISM, alterações de rede nem grava no Registro real.

Verificações: sintaxe, extração do BAT, 35 opções, bloqueio administrativo, cancelamento, saída e falha de processo, comando ausente, CSV, JSON, escape HTML, coleta parcial, encerramento, montagem de elevação e restauração de valores de Registro com preservação de dados não relacionados.

## Evidência disponível

Os testes de lógica passaram em PowerShell 7.4.6 sobre Linux. Isso não comprova execução de comandos Windows nem compatibilidade completa com Windows PowerShell 5.1. Os testes devem ser repetidos no ambiente alvo.

## Plano de teste manual — pendente

Utilize uma máquina virtual ou equipamento de laboratório com possibilidade de recuperação.

| Cenário | Resultado esperado | Estado |
| --- | --- | --- |
| Abrir BAT em caminho com espaços | Menu inicial e cadastro acessíveis | Pendente |
| Consultar sem administrador | Consultas disponíveis, ações protegidas bloqueadas | Pendente |
| Solicitar administrador / cancelar UAC | Nova sessão quando autorizado; cancelamento tratado | Pendente |
| Gerar diagnóstico | HTML/TXT legíveis, falhas parciais identificadas | Pendente |
| Encerrar atendimento | JSON e CSV com validação e pendências | Pendente |
| Teste de rede | Resultados de cada etapa, sem inferir falha apenas por ICMP | Pendente |
| Reiniciar spooler em laboratório | Serviço em execução e impressão validada | Pendente |
| Aplicar e reverter compatibilidade | Backup anterior e restauração do valor exato | Pendente |
| Winget indisponível | Falha informativa, sem instalação automática | Pendente |
| SFC/DISM em laboratório | Saída registrada e códigos tratados | Pendente |

Registre versão/build do Windows, versão do PowerShell, privilégio, cenário, resultado observado e evidência sanitizada. Não marque um item como aprovado apenas porque a rotina exibiu CONCLUIDO.
