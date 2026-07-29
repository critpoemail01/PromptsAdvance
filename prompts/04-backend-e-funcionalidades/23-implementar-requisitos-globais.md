# Implementar um conjunto global de requisitos por fases

## Objetivo

Implementa um único lote coerente de requisitos `Must` de `[MATRIZ_DE_REQUISITOS]` que atravessam várias áreas da aplicação. O lote é `[LOTE_DE_REQUISITOS]` e deve produzir um resultado utilizável, verificável e reversível; não implementes automaticamente o backlog restante.

## Entradas e limite do lote

- `[MATRIZ_DE_REQUISITOS]` com IDs, fontes, prioridades, dependências e critérios de aceitação.
- `[LOTE_DE_REQUISITOS]` com uma única capacidade transversal e, por omissão, no máximo três requisitos `Must`.
- `[DECISOES_APROVADAS]` para contratos, dados, permissões, retenção ou cobrança afetados.

Se o lote não for fornecido, propõe o menor corte vertical elegível e termina antes de editar. Se exceder uma capacidade coerente, divide-o e executa apenas a primeira parte explicitamente aprovada.

## Critérios de sucesso

- Cada requisito do lote tem critério observável e evidência.
- Dependências necessárias estão concluídas ou incluídas no lote.
- Alterações de UI, API, domínio, dados, autorização e observabilidade mantêm rastreabilidade.
- Build e testes afetados passam sem enfraquecer baselines.
- Requisitos fora do lote permanecem classificados e não são alterados.

## Preparação

1. Confirma os requisitos, respetivas fontes, dependências e critérios de aceitação.
2. Lê a arquitetura do derivado de `BoilerPlateAdvance` e preserva alterações locais.
3. Se o lote alterar jornadas ou UI, aplica o `PRODUCT_EXCELLENCE.md` e liga cada padrão adotado a um requisito e critério observável.
4. Cria um plano apenas para o lote e uma matriz `requisito → projeto → ficheiros → testes → risco`.
5. Para perante requisitos contraditórios, alterações destrutivas de dados, contratos públicos incompatíveis ou decisões de produto sem resposta. Para lacunas menores, declara pressupostos reversíveis.

## Implementação

- Mantém `Client.Ssr` público/static SSR separado de `Client.Web` WASM/PWA.
- Coloca UI/serviços partilháveis em `Client.Core`, lógica/regra no servidor e contratos nos projetos partilhados adequados.
- Aplica autorização no servidor e por objeto/função, não apenas na UI.
- Usa migrations EF Core e transações/idempotência nos limites corretos.
- Reutiliza módulos existentes; não ativa Hangfire, SignalR, attachments, OData, telemetry, push ou MAUI se não forem necessários.
- Mantém segredos fora do repositório e configurações por ambiente validadas.
- Implementa uma fase do lote de cada vez, executa testes direcionados e atualiza a matriz antes de avançar.
- Não aproveites o contexto para corrigir requisitos adjacentes; regista-os como backlog.

## Qualidade e testes

Para cada requisito, cobre happy path, validação, autorização, erro/recuperação e observabilidade. Inclui acessibilidade e estados de UI. Executa build/test pelo `*.Web.slnf` e Microsoft.Testing.Platform; compila MAUI apenas quando alterado e o workload existir. Não alteres baselines ou desatives testes para os fazer passar.

## Critérios de conclusão

Um requisito só fica `cumprido` quando o critério passa com evidência. Usa `parcial` ou `bloqueado` quando apropriado. Revê regressões transversais, migrations, API e diff final. Termina depois deste lote e propõe o seguinte sem o executar. Não declares “todos os requisitos implementados” fora da matriz.

## Entrega

Apresenta lote e fases executadas, matriz final, decisões, migrations/contratos, ficheiros, comandos/resultados, requisitos não tocados, próximo lote proposto e riscos.

## Referências

- https://learn.microsoft.com/ef/core/managing-schemas/migrations/applying
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- https://www.w3.org/TR/WCAG22/
