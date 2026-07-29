# Definir SLI, SLO e error budget

## Objetivo

Define indicadores e objetivos operacionais para `[SERVICOS_E_JORNADAS_CRITICAS]`, usando `[SLIS]`, `[SLOS]` e `[POLITICA_DE_ERROR_BUDGET]` quando já existirem. Liga fiabilidade técnica ao impacto real nas jornadas e cria regras objetivas para release, investimento em estabilidade e resposta a degradação.

## Entradas

Exige jornadas/serviços, população de eventos válidos, janela, fontes de telemetria, owners e criticidade. Não inventes metas a partir de valores “típicos”. Se ainda não houver dados, propõe uma baseline temporária identificada e define o período de medição antes da aprovação.

## Critérios de sucesso

- Cada jornada crítica tem SLI mensurável a partir de telemetria comprovada.
- SLO, janela e população de eventos são explícitos e evitam médias enganadoras.
- O error budget tem cálculo, owner e ações graduais antes de esgotar.
- Alertas distinguem sintomas com impacto de causas diagnósticas.
- Metas de produto, performance, disponibilidade e integridade não se contradizem.

## Processo

1. Lê requisitos, arquitetura, observabilidade, dependências, métricas de negócio e histórico disponível.
2. Cria a matriz:

| Jornada/serviço | Evento bom/total | Fonte/query | Janela | SLO | Error budget | Burn-rate/alerta | Owner |
|---|---|---|---|---|---|---|---|

3. Inclui, quando material, disponibilidade, latência por percentil, correção/integridade, frescura, conclusão da tarefa e dependências externas.
4. Define exclusões limitadas e justificadas; manutenção ou tráfego inválido não podem ser usados para esconder falhas.
5. Liga consumo do budget a ações: investigação, congelamento de risco, redução de cadência, trabalho de fiabilidade e decisão executiva documentada.

## Validação

Executa queries contra dados de teste ou histórico autorizado, confirma unidades, labels, cardinalidade, timezone e eventos sem telemetria. Simula períodos bons, degradação rápida e lenta e esgotamento do budget. Verifica que os alertas são acionáveis e que o cálculo pode ser reproduzido.

## Limites

Não altera produção nem cria alertas/recursos externos sem autorização. Não define “100%” por defeito nem classifica ausência de telemetria como sucesso. Uma exceção ao SLO exige impacto, compensação, owner, prazo e aprovação.

## Entrega

Apresenta matriz, fórmulas/queries, fontes, dashboards/alertas criados ou propostos, simulações, owners, política de error budget, limitações dos dados e data da primeira revisão.

## Referências oficiais

- https://sre.google/sre-book/service-level-objectives/
- https://sre.google/workbook/implementing-slos/
- https://opentelemetry.io/docs/concepts/observability-primer/

