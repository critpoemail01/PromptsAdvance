# Criar testes Playwright para os requisitos de uma página

## Objetivo

Cria testes Playwright para `[ROTA_OU_ECRA]` contra `[REQUISITOS_DA_PAGINA]`, validando conteúdo, interação, estados, permissões e integração real com o backend. Aplica `TEST_STRATEGY_CONTRACT.md` e mantém o âmbito na página e nas transições diretamente necessárias.

## Cenários obrigatórios

Seleciona apenas os aplicáveis ao contrato e risco da página e justifica exclusões; a lista não obriga a fabricar estados que o produto não expõe:

- acesso anónimo, autorizado e proibido;
- loading, vazio, dados normais, conteúdo longo e erro recuperável;
- validação de campos, submissão, sucesso, conflito e repetição;
- navegação direta, refresh, back/forward e deep link;
- mobile e desktop, teclado, foco e nomes acessíveis;
- snapshots dos estados estáveis em mobile/desktop e temas suportados;
- sessão expirada, rede lenta/offline e os estados HTTP materialmente possíveis entre 401/403/404/409/429/500.
- quando aplicável, ajuda correta para a rota e `FNC`, idiomas, abertura/fecho do
  painel, foco, player simulado, fornecedor bloqueado e fallback textual.

## Processo

1. Lê o requisito, página, componentes, endpoint, autorização, testes existentes e infraestrutura Playwright.
2. Regista a matriz `critério → precondição → ação → resultado visível → efeito persistido`.
   Reconcilia-a com `quality/TEST_MATRIX.md`; lacunas de unitário, componente,
   integração/provider, contrato ou arquitetura regressam ao nível correto em
   vez de serem escondidas num E2E maior.
3. Prepara os dados por API/helper de teste em vez de construir toda a precondição pela UI.
4. Exercita pela UI apenas o comportamento que o utilizador realmente executa.

## Regras de implementação

- Usa locators acessíveis e únicos. Adiciona `data-testid` apenas quando não existir semântica estável.
- Afirma resultados visíveis e, quando material, o efeito persistido através da API/base descartável.
- Evita mockar a API que a página pretende validar. Substitui apenas fornecedores externos ou falhas impossíveis de provocar de forma segura.
- Usa web-first assertions; não usa sleeps fixos, dependência de ordem ou credenciais versionadas.
- Mantém cada teste independente, pequeno e diagnosticável.
- Não transforma a suite E2E num duplicado exaustivo de testes unitários.
- Executa checks automáticos de acessibilidade sem os tratar como substituto da avaliação manual da jornada.
- Em snapshots, fixa browser, viewport, fontes, locale, timezone, animações e dados. Publica o diff como artefacto e só altera a baseline com revisão explícita e `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`.

## Validação

Executa o ficheiro/classe focado, repete-o para detetar flakiness e executa a suite da feature. Confirma funcionamento nos browsers configurados e viewports exigidos. Inspeciona trace/vídeo/diff visual em falha, consola e pedidos inesperados. Confirma que uma diferença visual ou violação automática de acessibilidade bloqueia a pull request. Mede duração e elimina esperas desnecessárias sem enfraquecer assertions.

## Entrega

Apresenta matriz de critérios e níveis, cenários criados/excluídos e motivo, dados/fixtures, clock/seed/locale/timezone usados, locators relevantes, comandos/resultados, flakiness com owner/prazo, evidência de falhas corrigidas e limites de cobertura.

## Referências oficiais

- https://playwright.dev/docs/best-practices
- https://playwright.dev/dotnet/docs/browser-contexts
- https://playwright.dev/dotnet/docs/actionability
- https://playwright.dev/dotnet/docs/trace-viewer
- https://playwright.dev/docs/test-snapshots
- https://www.w3.org/WAI/test-evaluate/
