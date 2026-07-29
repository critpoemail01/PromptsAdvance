# Verificar a release após 30 minutos, 24 horas e 7 dias

## Objetivo

Compara a release `[VERSAO_CANDIDATA]` com a baseline anterior em checkpoints de 30 minutos, 24 horas e 7 dias, usando produção apenas em modo observação. Deteta regressões rápidas, lentas e dependentes do comportamento real antes de encerrar a release.

## Entradas

Exige ambiente, release/candidate SHA, janela de comparação, SLI/SLO, dashboards, journeys seguras, owners e critérios de rollback/escalation. Observar está autorizado apenas quando o acesso já existir; qualquer correção, rollback, mudança de tráfego ou comunicação externa exige `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]`.

## Checkpoints

| Momento | Verificações mínimas |
|---|---|
| 30 min | versão servida, health, erros, latência, saturação, migrations/jobs, cache/service worker, smoke seguro, alertas e rollback triggers |
| 24 h | SLI/SLO e burn rate, volume representativo, integrações, filas, emails/push sandbox quando aplicável, feedback/suporte, custos e segurança |
| 7 dias | tendência, coortes/funcionalidade, Core Web Vitals RUM, retenção/uso sem causalidade inventada, incidentes, custos, vulnerabilidades e dívida criada |

## Processo e validação

1. Congela queries e baseline antes da comparação.
2. Segmenta por versão, plataforma, browser/dispositivo, região e jornada quando houver volume suficiente.
3. Distingue correlação temporal de causalidade; compara deploys e mudanças externas concorrentes.
4. Executa apenas smoke tests sem efeitos reais.
5. Em cada checkpoint produz `saudável`, `degradado`, `incidente` ou `dados insuficientes`, com evidência e owner.
6. Não encerra a release enquanto um checkpoint obrigatório estiver pendente; agenda automaticamente os seguintes apenas depois de o workflow estar estável e autorizado.

## Entrega

Apresenta release/SHA, checkpoints executados, métricas versus baseline/SLO, alertas/incidentes, feedback, custos, decisão, ações autorizadas executadas, ações propostas e evidência para encerrar ou manter monitorização reforçada.

## Referências

- https://learn.microsoft.com/azure/well-architected/operational-excellence/safe-deployments
- https://sre.google/workbook/canarying-releases/

