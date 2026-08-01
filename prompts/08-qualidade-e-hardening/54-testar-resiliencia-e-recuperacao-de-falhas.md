# Testar resiliência e recuperação de falhas

## Objetivo

Valida como a aplicação reage e recupera de falhas transitórias e persistentes em `[DEPENDENCIAS_CRITICAS]`, incluindo rede, base de dados, fornecedores, jobs, SignalR e armazenamento quando ativos. Aplica `TEST_STRATEGY_CONTRACT.md`.

## Autoridade para fault injection

Usa `[AMBIENTE_DESCARTAVEL_AUTORIZADO]` e define dependências, intensidade, duração e hard stops. Sem alvo comprovadamente não produtivo ou sem autorização para interromper a dependência, limita-te a testes com fakes/proxies locais e à proposta do exercício.

## Critérios de sucesso

- Timeouts, retries e circuit breakers têm limites coerentes com a operação.
- Operações não idempotentes não são duplicadas por retry.
- O utilizador recebe estado seguro e acionável, sem stack traces ou falsos sucessos.
- A aplicação recupera depois de a dependência voltar.
- Telemetria distingue falha transitória, esgotamento, degradação e recuperação.

## Preparação

1. Inventaria `HttpClient`, políticas de resiliência, transações, jobs, health, queues e fornecedores.
2. Mapeia `dependência → operação → timeout → retry → idempotência → fallback → sinal`.
3. Define falhas controladas e ambiente descartável; não provoca falhas em produção.
4. Usa objetivos/SLOs aprovados; não inventa tempos de indisponibilidade tolerados.
5. Cria uma análise de failure modes por jornada/dependência com causa, efeito
   local e no utilizador/dados, deteção, mitigação, recuperação, teste e owner;
   prioriza por impacto, probabilidade e detetabilidade.

## Execução

- Testa timeout, reset de ligação, 429/5xx, DNS/host indisponível, base bloqueada, storage indisponível e exporter em falha conforme aplicável.
- Valida exponential backoff/jitter e limites; evita retries em cascata.
- Testa cancelamento do utilizador e shutdown.
- Confirma atomicidade ou compensação quando a falha ocorre entre passos.
- Reinicia serviço/processo e verifica recuperação de jobs e estado persistido.
- Mede latência, número de tentativas, carga adicional e tempo de recuperação.
- Quando autorizado e seguro, combina a falha prioritária com carga realista
  para observar cascatas e recuperação; aplica hard stops e não chama serviços
  externos reais.

## Validação

Executa testes automatizados e pelo menos um exercício integrado de falha/recuperação em ambiente não produtivo. Confirma logs/traces/métricas sem dados sensíveis e alertas acionáveis. Adiciona testes de regressão para defeitos encontrados.

## Entrega

Apresenta ambiente/autoridade, matriz de dependências/falhas, experiências e hard stops, resultados, correções, métricas, cenários não executados e riscos residuais.

## Referências oficiais

- https://learn.microsoft.com/dotnet/core/resilience/
- https://learn.microsoft.com/azure/well-architected/reliability/testing-strategy
- https://learn.microsoft.com/azure/architecture/patterns/retry
- https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker
