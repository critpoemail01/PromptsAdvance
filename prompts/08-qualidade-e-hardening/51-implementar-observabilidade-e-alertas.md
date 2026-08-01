# Implementar observabilidade e alertas operacionais

## Objetivo

Implementa observabilidade contínua e acionável para a aplicação derivada de `BoilerPlateAdvance`, cobrindo logs, métricas, traces distribuídos, health probes, dashboards e alertas. Reutiliza a infraestrutura OpenTelemetry existente e configura `[DESTINO_DE_TELEMETRIA]` sem acoplar o domínio a um fornecedor nem expor dados pessoais ou segredos.

## Autoridade externa

Configurar ficheiros e exportação local está dentro do âmbito. Criar workspaces, projetos, sinks, dashboards, alertas pagos ou destinos externos exige provider, ambiente, orçamento/retenção e autorização explícita; sem isso, entrega queries/especificações e valida com destino local.

## Critérios de sucesso

- Uma jornada crítica pode ser seguida do cliente/API às dependências através de correlação e traces.
- Existem métricas técnicas e de negócio suficientes para detetar indisponibilidade, erros e degradação.
- Readiness e liveness representam estados diferentes e não revelam detalhes sensíveis.
- Cada alerta é acionável: tem condição, janela, severidade, proprietário, destino, recuperação e runbook.
- A aplicação continua funcional quando exportadores opcionais estão desconfigurados ou temporariamente indisponíveis.

## Preparação

1. Lê `AGENTS.md`, `MODULES.md`, configuração, logging, OpenTelemetry, Azure Monitor/OTLP/Sentry, health checks, resiliência HTTP, Hangfire/SignalR quando ativos e infraestrutura de deployment.
2. Confirma ambientes, topologia, destinos autorizados, limites de custo/retenção e jornadas/SLOs críticos.
3. Regista a matriz:

| Serviço/jornada | Sinal | Instrumentação | Atributos/correlação | Exportação | Dashboard/alerta |
|---|---|---|---|---|---|

4. Mede o baseline e identifica lacunas antes de adicionar instrumentação.

## Implementação

1. Normaliza atributos de recurso: service name, versão/release, environment e instance, sem cardinalidade ilimitada.
2. Reutiliza instrumentação de ASP.NET Core, `HttpClient`, runtime e EF Core. Adiciona `ActivitySource`, `Meter` e logging estruturado próprio apenas nos limites de negócio que precisam de diagnóstico.
3. Propaga correlation/trace context entre HTTP, jobs, SignalR e integrações ativas. Não uses IDs pessoais como chaves de correlação expostas.
4. Mantém logs estruturados com níveis coerentes, event IDs quando úteis e exceções uma única vez no nível responsável. Evita duplicação, payloads completos e mensagens impossíveis de agregar.
5. Recolhe métricas para taxa de pedidos, erros, latência, saturação, filas/jobs, dependências e resultados de jornadas críticas. Controla cardinalidade de tags.
6. Separa:
   - liveness: o processo consegue continuar;
   - readiness: a instância está pronta para receber tráfego e dependências essenciais cumprem o necessário.
7. Mantém respostas públicas de health mínimas. Detalhes operacionais ficam protegidos.
8. Filtra passwords, tokens, cookies, connection strings, corpos sensíveis, dados pessoais e parâmetros de alta cardinalidade antes da exportação.
9. Define sampling e retenção com base em volume, custo e capacidade de diagnóstico. Preserva erros e traces críticos sem assumir recolha integral.
10. Configura exportadores por ambiente e apenas quando as respetivas opções existem. Não adiciones credenciais nem tornes Azure Monitor, OTLP ou Sentry obrigatórios no desenvolvimento local.

## Alertas e operação

1. Define SLOs/SLIs ou, se ainda não existirem, propõe valores para aprovação em vez de inventar compromissos.
2. Cria alertas para indisponibilidade, taxa de erro, latência, saturação, falha de jobs/dependências e ausência inesperada de telemetria, evitando alertar por eventos transitórios isolados.
3. Cada alerta deve conter contexto útil, link para dashboard/query, release/ambiente, proprietário e ação inicial.
4. Usa infraestrutura como código quando o repositório já a suporta. Se não houver provider ou autorização externa, entrega especificações e ficheiros locais sem criar recursos cloud.
5. Evita alert storms, duplicação e notificações sem ação. Define resolução automática e janelas de manutenção quando aplicável.

## Validação

1. Executa localmente uma jornada bem-sucedida e falhas controladas de API, base de dados e dependência substituída.
2. Confirma correlação entre logs/traces, métricas esperadas, status de health e ausência de dados sensíveis.
3. Testa o arranque sem configuração de exportação e a falha temporária do exporter.
4. Valida pelo menos uma condição de alerta em ambiente não produtivo, quando houver infraestrutura autorizada; caso contrário valida a query/regra com dados de teste.
5. Mede overhead básico e volume de telemetria.
6. Executa build e testes afetados.

## Entrega

Apresenta a matriz de observabilidade, instrumentação e configuração criadas, recursos externos criados ou apenas especificados, dashboards/queries, catálogo de alertas, testes/resultados, amostra de correlação sem dados sensíveis, custos/volume estimáveis e lacunas operacionais.

## Referências oficiais

- https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel
- https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-10.0
- https://learn.microsoft.com/azure/azure-monitor/alerts/best-practices-alerts
- https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-filter
- https://opentelemetry.io/docs/concepts/observability-primer/
