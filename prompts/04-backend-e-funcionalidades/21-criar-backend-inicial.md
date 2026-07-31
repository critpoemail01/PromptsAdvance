# Implementar o backend inicial do produto

## Objetivo

Implementa `[PRIMEIRO_CORTE_VERTICAL]` a partir de `[REQUISITOS_DO_PRODUTO]`, reutilizando a fundação existente no projeto derivado de `BoilerPlateAdvance`. Entrega domínio, persistência, API, autorização e testes para um único fluxo utilizável; não substituas a infraestrutura madura da base nem avances para o backlog seguinte.

## Entradas e limite

O corte deve indicar IDs de requisitos, ator, trigger, resultado observável e exclusões. Se `[PRIMEIRO_CORTE_VERTICAL]` não estiver identificado, propõe o menor corte que atravesse API, domínio e persistência e termina antes de editar. Não incluas mais de um agregado/capacidade principal, salvo dependência técnica inseparável.

## Preparação

1. Lê `AGENTS.md`, `README.md`, `MODULES.md`, projetos `Server.Api`, `Server.Shared`, `Shared` e `Tests`.
2. Confirma módulos mantidos/removidos, provider EF atual, migrations, Identity, roles/policies, OpenAPI/Scalar, ProblemDetails, rate limiting, Hangfire, SignalR e health checks.
3. Confirma que o corte fornecido é pequeno e completa-o com casos de uso, invariantes, atores, permissões, erros e critérios de aceitação.
4. Se faltarem decisões de negócio irreversíveis, documenta-as e implementa apenas uma fundação reversível.

## Implementação

1. Modela entidades e value objects sem acoplar DTOs públicos à persistência.
2. Cria migrations EF Core mínimas e reversíveis. Não uses `EnsureCreated`; não apliques migrations automaticamente em produção.
3. Implementa endpoints/serviços com validação, cancelamento, logging estruturado e `ProblemDetails`.
4. Aplica autenticação e autorização no servidor, incluindo acesso por objeto e função. Não confies em IDs, roles ou preços enviados pelo cliente.
5. Usa transações apenas nos limites que exigem atomicidade e torna comandos externos/idempotentes quando repetição for possível.
6. Evita overfetching, mass assignment, N+1, enumeração de contas e consumo ilimitado de recursos.
7. Reutiliza rate limiting, telemetry, health e background jobs existentes. Só ativa módulos opcionais se o caso de uso os exigir.
8. Mantém segredos em User Secrets/variáveis de ambiente/cofre. Usa placeholders `[DB_CONNECTION]`, `[PROVIDER_KEY]`; nunca escrevas valores reais em `appsettings*.json`.
9. Atualiza OpenAPI, documentação e dados de desenvolvimento seguros.

## Testes e validação

Cria testes unitários para invariantes e integração para happy path, validação, 401, 403, not found, conflito/idempotência e rollback. Testa migrations numa base descartável. Executa:

```text
dotnet restore <Projeto>.Web.slnf --locked-mode
dotnet build <Projeto>.Web.slnf --no-restore --nologo -v:q
dotnet test --project src/Tests/<Projeto>.Tests.csproj --no-build --no-restore -v:q --no-progress --no-ansi
```

Adapta nomes. Não uses argumentos VSTest incompatíveis. Não executes migrações, emails, pagamentos ou integrações reais em produção.

## Entrega

Apresenta corte vertical implementado, IDs cumpridos, exclusões, decisões/invariantes, endpoints e autorização, migration, ficheiros, testes/resultados, configuração necessária sem segredos e próximo corte proposto sem o executar.

## Referências oficiais

- https://learn.microsoft.com/ef/core/managing-schemas/migrations/applying
- https://learn.microsoft.com/aspnet/core/security/app-secrets?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/fundamentals/error-handling-api?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/performance/rate-limit?view=aspnetcore-10.0
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/
