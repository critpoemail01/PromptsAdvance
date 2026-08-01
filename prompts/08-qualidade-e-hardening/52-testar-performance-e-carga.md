# Testar performance, carga e estabilidade

## Objetivo

Mede e melhora a performance da aplicação sob carga realista, usando `[AMBIENTE_AUTORIZADO]`, `[CENARIOS_CRITICOS]`, `[CARGA_ESPERADA]`, `[OBJETIVOS_DE_PERFORMANCE]` e `TEST_STRATEGY_CONTRACT.md`. Produz um baseline reproduzível, identifica gargalos com telemetria e prova as melhorias sem alterar comportamento, consistência ou segurança.

## Critérios de sucesso

- Os cenários, workload, ambiente, dados e objetivos estão explícitos e reproduzíveis.
- Existem resultados de latência por percentis, throughput, erros e recursos, não apenas médias.
- Cada otimização está ligada a evidência de um gargalo e é comparada com o mesmo teste de baseline.
- A aplicação mantém integridade e recupera após carga extrema.
- Os limites de capacidade, riscos e partes não testadas ficam documentados.

## Preparação

1. Lê requisitos, arquitetura, deployment, cache, rate limiting, observabilidade, base de dados, integrações e testes existentes.
2. Não uses produção sem autorização explícita. Prefere um ambiente isolado semelhante a produção, dados sintéticos e integrações simuladas/sandbox.
3. Confirma objetivos mensuráveis por cenário: utilizadores/requests concorrentes, duração, p50/p95/p99, throughput, error rate e recursos máximos.
4. Define o modelo de carga: distribuição de jornadas, think time, ramp-up/down, tamanhos de payload, cache quente/fria e utilizadores/dados distintos.
5. Regista versões, configuração Release, capacidade do host, região/rede, estado da base e release da aplicação.
6. Define antes de executar hard stops para taxa de erro, latência, CPU/memória, custo, duração e impacto nas dependências. Se faltarem limites seguros, executa apenas uma validação mínima dos scripts.
7. Liga os cenários à análise de failure modes e à `quality/TEST_MATRIX.md`.
   Só combina carga e fault injection num ambiente descartável explicitamente
   autorizado, com hard stops e SLO/RTO/RPO aprovados.

## Plano de testes

Seleciona apenas os testes que respondem ao risco:

- baseline de um utilizador e cold/warm start;
- load test na carga normal e de pico esperada;
- stress test para encontrar o ponto de saturação e comportamento de degradação;
- spike test para aumentos súbitos;
- soak test para fugas, acumulação de filas e degradação prolongada;
- testes específicos de endpoints, SSR, API, jobs, SignalR ou uploads quando ativos.

Reutiliza a ferramenta existente. Se não houver nenhuma, escolhe uma opção mantida e isolada no repositório apenas se o benefício justificar a dependência; não cries serviços pagos ou recursos cloud sem autorização.

## Execução e diagnóstico

1. Compila e executa em Release/Production-like, com logging representativo e sem debugger.
2. Faz uma execução curta de validação antes da carga para provar scripts, dados, autenticação e assertions.
3. Durante o teste recolhe:
   - latência p50/p95/p99 e máximo;
   - throughput, concorrência e taxa/tipos de erro;
   - CPU, memória, GC, thread pool, exceções e sockets;
   - queries, ligações, locks, tempo EF/base de dados;
   - cache hit/miss, filas/jobs e dependências externas.
4. Inclui assertions funcionais; uma resposta rápida mas errada não é sucesso.
5. Respeita rate limits e limites do ambiente. Para stress, aumenta carga gradualmente e define condições de paragem para proteger sistemas.
6. Diagnostica primeiro. Procura queries/índices, N+1, bloqueios síncronos, alocações, serialização, payloads, chamadas repetidas, cache, pool starvation e dependências lentas.
7. Aplica a menor correção comprovada. Não relaxes validação, autorização, consistência, durabilidade ou rate limiting para melhorar números.
8. Repete o mesmo workload várias vezes e compara distribuições, não uma única execução favorável.

## Validação

1. Compara baseline e resultado com a mesma versão de script, dados e capacidade.
2. Executa testes funcionais/regressão após cada alteração.
3. Confirma ausência de erros silenciosos, dados duplicados/perdidos e filas não drenadas.
4. Depois do stress/soak, valida recuperação de latência, recursos, health e processamento pendente.
5. Se os resultados variarem por rede, vizinhança do host ou warm-up, assinala e repete em condições controladas.
6. Não apresenta estimativas de capacidade para além da faixa realmente medida.

## Limites

Não ataques endpoints públicos, serviços de terceiros, emails, SMS, pagamentos ou anúncios reais. Não uses credenciais/dados pessoais. Não desatives controlos de segurança. Custos, aumento de escala, alterações de infraestrutura e testes destrutivos exigem autorização.

## Entrega

Apresenta configuração, hard stops e ocorrências, scripts, tabela por cenário com p50/p95/p99/throughput/erros/recursos, gráficos ou artefactos existentes, gargalos e evidência, alterações e comparação antes/depois, ponto de saturação, recuperação e recomendações priorizadas.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/test/load-tests?view=aspnetcore-10.0
- https://learn.microsoft.com/azure/well-architected/performance-efficiency/performance-test
- https://learn.microsoft.com/dotnet/core/diagnostics/dotnet-counters
- https://learn.microsoft.com/aspnet/core/performance/rate-limit?view=aspnetcore-10.0
- https://learn.microsoft.com/ef/core/performance/efficient-querying
