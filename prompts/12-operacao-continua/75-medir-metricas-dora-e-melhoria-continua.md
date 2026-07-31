# Medir métricas DORA e orientar melhoria contínua

## Objetivo

Calcula métricas DORA a partir de `[FONTE_METRICAS_DORA]` e usa-as para identificar restrições do sistema de entrega, sem transformar métricas de equipa em metas individuais ou incentivar manipulação.

## Métricas

- deployment frequency;
- lead time for changes;
- change fail rate;
- failed deployment recovery time;
- deployment rework rate.

Trata reliability, disponibilidade e cumprimento de SLOs como resultados
operacionais complementares, não como substitutos das cinco métricas de entrega.

## Processo

1. Define deployment, mudança, falha e recuperação para este produto.
2. Liga commits/PRs, pipelines, deploys, incidentes e rollbacks com IDs/timestamps consistentes.
3. Valida qualidade e cobertura dos dados; marca períodos incompletos.
4. Calcula tendências por produto/serviço e janela, preservando contexto de volume, risco e sazonalidade.
5. Faz análise sistémica de filas, lotes, testes, approvals, ambiente, rollback e dívida.
6. Escolhe uma melhoria pequena com hipótese e métrica de controlo; não otimiza uma métrica sacrificando qualidade/SLO.
7. Regista a melhoria como delta em `changes/CHG-####/PROPOSAL.md` segundo
   `CHANGE_CONTROL.md`. Não a promove a requisito nem altera a baseline antes da
   análise de impacto e aprovação.
8. Revê o resultado na cadência aprovada e regista aprendizagem.

## Critérios de sucesso

- Fórmulas e fontes são reproduzíveis.
- Métricas não são usadas para avaliar pessoas, comparar equipas sem contexto ou premiar deploys artificiais.
- Melhoria proposta tem owner, prazo, baseline e efeito esperado.
- Deployment rework rate usa uma definição explícita e não duplica change fail rate.
- Cada alteração material tem proposta, impacto, decisão e prompt/gate de reentrada.
- Qualidade, segurança, utilizadores e fiabilidade permanecem guardrails.

## Entrega

Apresenta definições, qualidade dos dados, métricas/tendências, principais restrições, hipótese de melhoria, owner/prazo e resultado das experiências anteriores.

## Referências

- https://dora.dev/guides/dora-metrics/
- https://dora.dev/capabilities/continuous-delivery/
