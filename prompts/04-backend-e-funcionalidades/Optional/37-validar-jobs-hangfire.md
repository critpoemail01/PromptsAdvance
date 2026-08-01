# Validar jobs Hangfire e processamento em background

## Aplicabilidade

Executa quando Hangfire ou outro processamento persistente em background for mantido.

## Objetivo

Garante que `[JOBS_CRITICOS]` são idempotentes, observáveis, recuperáveis e seguros em múltiplas instâncias, assumindo entrega/processamento `at least once`. Não prometas semântica exactly-once.

## Critérios de sucesso

- Cada job tem trigger, payload mínimo, proprietário, retries, timeout e política de falha.
- Reexecução não duplica emails, pagamentos, notificações ou alterações de dados.
- Dashboard e endpoints operacionais estão autenticados/autorizados.
- Falhas e backlog geram sinais acionáveis.
- Deploy e shutdown não perdem trabalho confirmado.

## Processo

1. Inventaria enqueue/schedule, handlers, armazenamento, recorrência, dashboard, filas e telemetria.
2. Classifica jobs por criticidade, duração, idempotência, dependências e dados sensíveis.
3. Define limites transacionais entre alteração de dados e publicação do trabalho.
4. Evita serializar entidades, tokens ou payloads grandes.

## Implementação e validação

- Usa identificadores e DTOs versionáveis, cancellation e scopes corretos.
- Torna side effects idempotentes e usa deduplicação/outbox quando o requisito o justificar.
- Usa locks apenas para coordenação; não os trates como substituto de idempotência, deduplicação ou transações corretas.
- Define retries limitados com backoff e destino operacional para falhas finais.
- Protege dashboard, filtra argumentos/logs e controla retenção.
- Testa sucesso, retry transitório, falha permanente, duplicação, concorrência, restart e indisponibilidade de dependência.
- Mede duração, fila e throughput básicos; executa build/test.

## Entrega

Apresenta catálogo de jobs, semântica de entrega, chaves/estratégia de idempotência, políticas, ficheiros, testes/resultados, métricas/alertas, falhas finais e procedimentos operacionais.

## Referências oficiais

- https://docs.hangfire.io/en/latest/background-methods/index.html
- https://docs.hangfire.io/en/latest/background-processing/dealing-with-exceptions.html
- https://learn.microsoft.com/dotnet/core/extensions/scoped-service
