# Implementar backup, restauro e disaster recovery

## Objetivo

Define e valida recuperação para `[DADOS_E_SERVICOS_CRITICOS]` com RPO/RTO aprovados. Inclui base de dados, storage, configuração operacional, chaves necessárias e dependências externas; um backup não conta como válido sem teste de restauro.

## Autoridade e alvo de teste

Exige `[ALVO_ISOLADO_DE_RESTORE]` identificado e descartável. Criar storage, cofres, replicação, recursos externos ou custos exige autorização explícita. Se o alvo isolado ou as chaves de recuperação não estiverem disponíveis, prepara scripts/runbook e termina como `bloqueado para exercício`; nunca restaures por cima de produção ou de dados partilhados.

## Critérios de sucesso

- Cada dataset tem RPO, RTO, método, frequência, retenção, cifragem e proprietário.
- Backups são isolados, monitorizados e protegidos contra alteração/eliminação indevida.
- Existe restauro documentado e testado num ambiente isolado.
- Integridade funcional, não apenas presença de ficheiros, é verificada.
- O plano cobre perda parcial, corrupção, credenciais/chaves e indisponibilidade regional quando aplicável.

## Processo

1. Inventaria SQLite/outro provider, blobs/attachments, Data Protection, configurações e providers.
2. Define dependências e ordem de restauro.
3. Cria a matriz:

| Ativo | RPO | RTO | Backup | Retenção/local | Cifragem/chaves | Teste | Proprietário |
|---|---|---|---|---|---|---|---|

4. Para SQLite, usa API de online backup ou mecanismo consistente; não copies cegamente uma base ativa.

## Implementação e exercício

- Automatiza backups idempotentes com verificação, retenção e alertas.
- Separa credenciais/chaves do backup e garante que também têm recuperação segura.
- Evita guardar backups apenas no mesmo host/conta de falha.
- Confirma novamente que o destino não é produção/partilhado e restaura nesse alvo isolado; verifica integridade, migrations, contagens/invariantes e uma jornada crítica.
- Mede tempo real e compara com RTO/RPO.
- Não substitui produção nem elimina backups durante o exercício.

## Entrega

Apresenta matriz, autoridade usada, alvo isolado, recursos/custos criados ou apenas propostos, scripts/configuração, exercício, tempos, evidência de integridade, lacunas, runbook e data do próximo teste.

## Referências oficiais

- https://learn.microsoft.com/dotnet/standard/data/sqlite/backup
- https://learn.microsoft.com/azure/well-architected/design-guides/disaster-recovery
- https://learn.microsoft.com/azure/reliability/reliability-guidance-overview
