# Executar triagem operacional diária

## Objetivo

Produz uma triagem diária acionável para `[SERVICOS_E_JORNADAS_CRITICAS]`, agregando alertas, SLI/SLO, incidentes, deploys, jobs, integrações e bloqueios sem alterar produção por defeito.

## Processo

1. Confirma janela, timezone, serviços, dashboards e owners.
2. Recolhe alertas novos/ativos, burn rate, erros, latência, saturação, filas/jobs, falhas de providers, deploys recentes e tickets operacionais.
3. Deduplica sintomas do mesmo incidente e correlaciona-os com releases/configuração sem assumir causalidade.
4. Classifica `P0–P3`, impacto, evidência, owner, próximo passo e prazo.
5. Compara com o dia anterior: novo, agravado, estável, recuperado ou dados insuficientes.
6. Executa apenas consultas read-only. Correções e comunicação exigem `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]`.

## Critérios de sucesso

- Nenhum serviço crítico fica silenciosamente sem dados.
- Alertas ruidosos e lacunas de observabilidade geram ações próprias.
- Itens resolvidos têm evidência de recuperação; ausência de novo alerta não basta.
- O resultado cabe numa passagem operacional curta e liga aos detalhes.

## Entrega

Apresenta resumo executivo, tabela priorizada, SLO/error budget, mudanças/deploys correlacionados, lacunas de dados, ações/owners/prazos e estado geral `normal`, `atenção`, `incidente` ou `dados insuficientes`.

## Referências

- https://sre.google/sre-book/monitoring-distributed-systems/
- https://sre.google/sre-book/managing-incidents/

