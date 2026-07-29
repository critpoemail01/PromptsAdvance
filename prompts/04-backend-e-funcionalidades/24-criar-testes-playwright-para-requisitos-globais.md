# Criar testes Playwright para requisitos globais

## Objetivo

Implementa testes UI end-to-end em Playwright para os requisitos globais `Must` de `[MATRIZ_DE_REQUISITOS]`. Reutiliza a infraestrutura de testes do projeto derivado de `BoilerPlateAdvance`, incluindo Microsoft.Testing.Platform, MSTest v4, `AppTestServer` e `Microsoft.Playwright.MSTest.v4`, quando continuarem presentes.

## Entradas

Define `[LOTE_DE_REQUISITOS]`, `[BROWSERS_E_VIEWPORTS]` e `[REPETICOES_ANTI_FLAKINESS]`. Testa apenas o lote concluído no prompt 23; se não houver lote, propõe cobertura e termina antes de criar uma suite genérica.

## Critérios de sucesso

- Cada teste está ligado a um requisito e a um risco que justifica E2E.
- As jornadas atravessam UI e backend reais com dados isolados e dependências externas substituídas.
- Perfis anónimo, autorizado, sem permissão e sessão expirada são cobertos quando aplicáveis.
- A suite é determinística, paralelizável e produz trace/vídeo/screenshot apenas com a política existente.
- Os testes focados passam localmente e a execução em CI fica configurada ou documentada.
- Estados visuais estáveis e acessibilidade têm checks reproduzíveis em cada pull request.

## Preparação

1. Lê requisitos, infraestrutura em `src/Tests`, `.runsettings`, exemplos `UITests`, CI e comandos do repositório.
2. Confirma URLs, projetos ativos e método de arranque; não cries uma segunda infraestrutura concorrente.
3. Converte requisitos em cenários e seleciona apenas os que precisam de browser. Mantém regras puras em testes unitários e contratos em integração.
4. Define uma matriz `requisito → cenário → perfil → dados → assertions → evidência`.

## Implementação

- Organiza testes por feature e comportamento observável, não por método interno.
- Cria dados únicos e descartáveis através das APIs/helpers de teste existentes; não depende da ordem nem de dados partilhados.
- Usa `GetByRole`, `GetByLabel`, `GetByText` e `GetByTestId` apenas quando necessário. Não usa seletores CSS frágeis.
- Usa assertions web-first e espera por estados observáveis; não usa `Task.Delay`, sleeps fixos ou polling manual sem limite.
- Cobre navegação global, autorização, validação, feedback, erro recuperável, refresh/deep link e responsividade essencial.
- Isola emails, pagamentos, push e outros efeitos externos com fakes/sandboxes locais já aprovados.
- Preserva paralelismo; se um teste exigir serialização, documenta a causa e o âmbito mínimo.
- Ativa trace, vídeo ou screenshot de acordo com a infraestrutura existente, preferencialmente em falha.
- Adiciona checks automáticos de acessibilidade às jornadas cobertas e mantém a avaliação manual dos fluxos críticos registada fora do teste automático.
- Para componentes/estados visualmente estáveis, cria snapshots aprovados em mobile/desktop, temas suportados e estados normal/loading/vazio/erro/conteúdo longo. Fixa browser, viewport, fontes, locale, timezone, animações e dados; mascara apenas valores genuinamente dinâmicos.
- Publica o diff visual como artefacto de pull request. Não atualiza baselines por conveniência: exige revisão explícita e `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`.

## Validação

Executa build e o subconjunto novo pelo comando Microsoft.Testing.Platform real do projeto; depois executa a suite afetada. Repete os novos testes pelo número definido, nos browsers/viewports exigidos, e confirma que passam individualmente e em conjunto. Provoca uma diferença visual controlada e uma violação de acessibilidade conhecida para provar que os gates falham, revertendo-as depois. Verifica artefactos de falha, tempo de execução e ausência de credenciais/dados pessoais.

## Entrega

Apresenta matriz de cobertura, ficheiros, dados/fixtures, comandos/resultados, duração, testes repetidos, flakiness encontrada, artefactos e requisitos não cobertos com justificação.

## Referências oficiais

- https://playwright.dev/docs/best-practices
- https://playwright.dev/dotnet/docs/locators
- https://playwright.dev/dotnet/docs/test-assertions
- https://playwright.dev/docs/test-snapshots
- https://www.w3.org/WAI/test-evaluate/
- https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro
