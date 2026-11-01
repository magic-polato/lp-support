# Guia de uso — LP Support 2.0

## Primeiro atendimento

Abra o arquivo `.bat` em um computador Windows de testes. Registre o número do chamado, seu nome e o sintoma observado. O nome padrão é Leonardo Polato; altere-o quando outro técnico executar o atendimento.

Gere um diagnóstico no menu principal antes de aplicar reparos. Em seguida, escolha a categoria apropriada. As opções permanecem no submenu depois da execução; `0` retorna ao menu principal.

## Interpretar os resultados

- **INICIADO:** execução solicitada, ainda sem resultado final.
- **CONCLUIDO:** rotina terminou sem erro detectado; não significa que o incidente foi resolvido.
- **PARCIAL:** diagnóstico com alguma seção indisponível.
- **FALHA:** erro ou código de saída não aceito; consultar a saída gravada.
- **BLOQUEADO:** privilégio de administrador ausente.
- **CANCELADO:** confirmação não concedida pelo técnico.

Uma sessão interrompida pode conter eventos INICIADO sem conclusão. Registre o resultado técnico no encerramento e confirme o funcionamento com o usuário.

## Administrador

A opção A abre uma nova janela mediante UAC. O atendimento original permanece separado. Consultas podem funcionar sem elevação; reparos protegidos são bloqueados sem administrador. Nunca use uma conta diferente sem autorização do responsável pelo equipamento.

## Relatórios

A opção 7 abre a pasta da sessão. Abra o relatório HTML no navegador; utilize a impressão do navegador para salvar PDF, se necessário. A ferramenta não gera PDF diretamente.

Para Power BI, importe `Historico.csv` com delimitador ponto e vírgula e codificação UTF-8. Cada linha representa um evento, não um chamado inteiro. Conte sessões distintas se desejar contar atendimentos; não some linhas como se fossem chamados.

## Ações de manutenção

Leia a explicação exibida e digite SIM apenas quando a ação corresponder ao diagnóstico. Liberar DHCP pode cortar o acesso remoto. Winsock pode exigir reinicialização posterior. SFC/DISM podem demorar. A limpeza usa a interface do próprio Windows, onde o técnico escolhe os itens.

As opções avançadas de impressão alteram somente valores específicos. Elas não corrigem universalmente um código de erro. O ajuste legado de privacidade RPC reduz proteção e exige avaliação do ambiente. Prefira investigar conectividade, atualizações e drivers antes de recorrer à compatibilidade legada.

## Restaurar ajustes de impressão

No menu avançado, escolha a opção 9 e selecione o backup correspondente à alteração que pretende desfazer. Confira o arquivo e o valor antes de confirmar. Quando houver várias alterações do mesmo valor, reverta na ordem inversa das alterações desejadas. A restauração usa backups deste perfil e computador; não é um backup completo do Registro.

## Encerramento

Use 0 no menu principal. Descreva resultado, validação do usuário e pendências. Fechar a janela abruptamente não registra encerramento. Os arquivos já gravados permanecem na pasta.
