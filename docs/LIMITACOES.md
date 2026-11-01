# Limitações e cuidados de operação

- Versão em validação; sem homologação em produção ou garantia de compatibilidade com todas as edições do Windows.
- Não substitui análise técnica, autorização de mudança, backup do equipamento ou política da organização.
- Logs locais são editáveis; não são uma trilha de auditoria inviolável.
- Diagnóstico é uma coleta pontual e não certifica saúde, segurança ou ausência de falhas.
- Ping sem resposta pode resultar de bloqueio ICMP, não necessariamente falha de conexão. O teste TCP não comprova navegação autenticada nem funcionamento de proxy.
- Inventário de hotfixes é parcial. Alguns módulos, eventos ou dados podem estar indisponíveis por configuração ou permissão.
- Ferramentas abertas em outra janela não têm suas operações subsequentes registradas.
- A LP Support não solicita reinicialização automática. Instaladores externos executados pelo Winget podem ter comportamento próprio.
- Alterações legadas de impressão podem reduzir segurança ou contrariar políticas do ambiente. Use-as apenas como exceção tecnicamente justificada e autorizada, com plano de reversão.
- A restauração de Registro se limita aos dois valores de impressão conhecidos pela ferramenta; não apaga valores não relacionados nem restaura todo o sistema.
- A ferramenta não armazena senhas nem solicita credenciais fora do UAC do Windows.
- Não há integração implementada com plataformas ITSM, banco de dados central ou Power BI.

## Privacidade

Relatórios podem conter nomes de computador, usuário, domínio, IPs, números de série, eventos e nomes de documentos de impressão. Não publique arquivos reais de atendimento em issues, exemplos ou repositórios. Revise e remova esses dados antes de compartilhar evidências.

O `.gitignore` reduz o risco de inclusão acidental de arquivos com os nomes padrão, mas não é um filtro de segurança: revise os arquivos selecionados para cada publicação.

## Referências técnicas

- [Microsoft — alterações RPC para impressão](https://learn.microsoft.com/en-us/troubleshoot/windows-client/printing/windows-11-rpc-connection-updates-for-print)
- [Microsoft — proteção RPC de impressão, KB4599464](https://support.microsoft.com/en-us/servicing/os/windows-server/2020/12/managing-deployment-of-printer-rpc-binding-changes-for-cve-2021-1678-kb4599464)

Os ajustes são opções de compatibilidade para avaliação técnica, não recomendações de aplicação geral.
