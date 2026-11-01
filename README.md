# LP Support

**Central de suporte técnico para Windows · Projeto de Leonardo Polato**

Diagnósticos, manutenção e documentação de atendimentos em uma ferramenta portátil, com inicialização por arquivo `.bat` e rotinas em PowerShell.

**Versão 2.0 — em validação.** A sintaxe e a lógica foram verificadas com testes e simulações. Os comandos de manutenção ainda precisam ser validados em Windows real. Não é uma versão homologada para produção.

## O problema

Atendimentos de suporte frequentemente exigem alternar entre comandos, ferramentas do Windows e anotações. A LP Support reúne essas atividades em menus e registra o contexto e o resultado das operações, facilitando a revisão do atendimento.

## Funcionalidades

| Área | Recursos |
| --- | --- |
| Rede | Configuração IP, testes por etapas, DNS, DHCP, rotas e Winsock |
| Impressoras | Inventário, consulta e reinício do spooler, trabalhos de impressão |
| Sistema | SFC, DISM, políticas, informações do Windows e espaço em disco |
| Ferramentas | Acesso a consoles e ferramentas administrativas do Windows |
| Diagnóstico | Relatórios em HTML e TXT, com identificação do atendimento |
| Histórico | Eventos em JSONL e CSV; contexto do chamado em JSON |
| Controles | Verificação de administrador e confirmação de alterações |
| Compatibilidade | Ajustes avançados de impressão com backup e restauração dos valores envolvidos |

São **35 opções nos submenus**, além das opções de diagnóstico, histórico, guia e encerramento no menu principal.

## Começar

1. Baixe o projeto pelo botão **Code → Download ZIP** e extraia o conteúdo.
2. Leia o [guia de uso](docs/GUIA_DE_USO.md) e as [limitações](docs/LIMITACOES.md).
3. Em um Windows de testes, abra `LP_Support_v2.0.bat` com dois cliques.
4. Informe chamado, técnico e sintoma. Os campos são opcionais.
5. Comece pela opção **5 — Gerar diagnóstico**.
6. Use **H** para o guia e **0** para registrar a validação e encerrar.

A opção **A** solicita uma nova sessão como administrador. Ela não eleva a sessão atual nem mescla os históricos. Se outra conta for utilizada, os arquivos ficam no perfil dessa conta.

### Requisitos previstos

- Windows 10 ou 11, com Windows PowerShell 5.1 e ferramentas correspondentes disponíveis.
- Administrador para operações que alteram componentes protegidos.
- Winget apenas para as opções de aplicativos; sua ausência é tratada como indisponibilidade.
- Internet apenas quando a operação selecionada precisar dela, como teste externo de rede, atualização ou reparo via Windows Update.

A disponibilidade das funções depende da edição, configuração e políticas do equipamento. Não há instalação automática de dependências.

## Dados do atendimento

Os arquivos são gravados em `%LOCALAPPDATA%\LP Support\Atendimentos\`, em uma pasta diferente por sessão.

| Arquivo | Conteúdo |
| --- | --- |
| `Atendimento.json` | Identificação, sintoma, validação e pendências |
| `Auditoria.jsonl` | Eventos de início, resultado e erro |
| `Historico.csv` | Eventos para análise em Excel ou Power BI; separador `;` |
| `NNN_Saida.txt` | Saída individual de cada operação |
| `Diagnostico_*.html` / `.txt` | Coleta do equipamento quando solicitada |
| `Registro_*.clixml` | Estado anterior dos valores de impressão alterados |

O CSV é uma base de eventos; ainda não há dashboard Power BI ou integração com ServiceNow. A organização de chamado, diagnóstico, tratamento e validação se inspira em práticas de gestão de serviços, sem alegação de certificação ITIL.

## Arquitetura

O `.bat` contém o código-fonte PowerShell após o marcador `#<LP_SUPPORT_POWERSHELL>`. O inicializador lê o próprio arquivo e executa esse conteúdo em memória. Não baixa código remoto. O parâmetro de política usado no processo PowerShell não altera permanentemente a política da máquina; políticas corporativas ainda podem impedir a execução.

Não há envio automático de logs. Comandos de rede, Windows Update e Winget podem acessar serviços externos quando escolhidos. Ferramentas abertas em outras janelas têm somente sua abertura registrada; as ações feitas nelas não são auditadas.

## Qualidade e estágio atual

- Sintaxe e extração do conteúdo PowerShell verificadas.
- Testes de bloqueio por privilégio, cancelamento, resultados e erros.
- Testes de exportação, escape de dados em HTML/CSV e diagnóstico parcial.
- Restauração de Registro testada com simulações, incluindo preservação de valores não relacionados.
- **Pendente:** validação dos comandos nativos, inicialização por CMD e elevação UAC em Windows real.

Consulte [VALIDACAO.md](docs/VALIDACAO.md) e [CHANGELOG.md](CHANGELOG.md). Capturas reais serão adicionadas após a validação em Windows; este repositório não apresenta simulações como telas reais.

## Autoria e evolução

**Leonardo Polato** — concepção, requisitos e direcionamento do projeto a partir da experiência em suporte técnico. Desenvolvimento e revisão do código com apoio de inteligência artificial.

Próximos passos: validar em Windows, registrar resultados, incluir capturas sem dados sensíveis e explorar indicadores de atendimentos no Power BI. Essas evoluções ainda não estão implementadas.

## Licenciamento

A licença de distribuição ainda será definida pelo autor. Nenhuma licença de código aberto é concedida por este pacote. A publicação do código não deve ser apresentada como um registro legal da marca LP Support.
