# Definir contratos API, versionamento e compatibilidade

## Objetivo

Define e implementa as convenções de API necessárias ao âmbito `[API_SCOPE]` e a `[JORNADAS_E_CONSUMIDORES]`, preservando compatibilidade entre `Server.Api`, SSR, Web/PWA, MAUI e integrações autorizadas. Trata uma família coerente de recursos/endpoints por execução.

## Entradas e limites

- `[API_SCOPE]`: recursos, endpoints ou contrato a alterar.
- `[JORNADAS_E_CONSUMIDORES]`: consumidores, versões mínimas e cadência de atualização.
- `[POLITICA_DE_COMPATIBILIDADE]`: janela de suporte/depreciação, quando já aprovada.

Se consumidores ou âmbito não estiverem identificados, inventaria e propõe convenções sem alterar contratos. Uma breaking change, remoção ou mudança de semântica exige aprovação explícita e plano de migração antes da edição.

## Critérios de sucesso

- OpenAPI representa pedidos, respostas, erros, autenticação e exemplos sem dados sensíveis.
- DTOs públicos não expõem diretamente entidades de persistência.
- Status codes e `ProblemDetails` são consistentes e testados.
- Paginação, filtros, ordenação, concorrência e idempotência têm regras explícitas quando aplicáveis.
- Existe política objetiva para mudanças compatíveis e breaking changes.

## Processo

1. Inventaria endpoints, OpenAPI/Scalar, DTOs, clientes gerados/manuais, OData quando ativo e testes de contrato.
2. Identifica consumidores, cadência de atualização, versões mínimas e necessidade real de versionamento.
3. Regista inconsistências e propõe uma convenção mínima para o âmbito antes de editar.
4. Cria a matriz `operação → consumidor → contrato → erros → autorização → idempotência → compatibilidade`.

## Implementação

- Usa recursos e verbos HTTP de forma previsível.
- Valida inputs no limite da API e devolve erros seguros e acionáveis.
- Distingue 400, 401, 403, 404, 409, 412, 422 e 429 apenas quando o significado é real no produto.
- Evita overposting, mass assignment e exposição de campos internos.
- Define limites de página, cursores/tokens ou offsets conforme o caso e ordenação determinística.
- Usa tokens de concorrência e idempotency keys em operações cujo replay pode causar dano.
- Não adiciona versionamento por antecipação. Se necessário, documenta suporte, depreciação e migração.
- Atualiza clientes e testes em conjunto; não quebra MAUI ou integrações existentes sem decisão explícita.
- Não normalizes endpoints fora de `[API_SCOPE]`; regista inconsistências adjacentes para outro lote.

## Validação

Gera/valida OpenAPI, executa testes de integração e contratos para happy path, validação, autorização, not found, conflito, limite e repetição. Compara o contrato anterior quando existir e classifica cada diferença.

## Entrega

Apresenta âmbito, convenções, matriz, endpoints/DTOs alterados, diferenças compatíveis ou breaking, aprovação associada, política de evolução, testes/resultados e consumidores ainda por atualizar.

## Referências oficiais

- https://learn.microsoft.com/azure/architecture/best-practices/api-design
- https://learn.microsoft.com/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/fundamentals/error-handling-api?view=aspnetcore-10.0
- https://www.rfc-editor.org/rfc/rfc9457
