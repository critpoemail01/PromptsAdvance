# Criar testes Playwright para os requisitos de uma página

## Objetivo

Cria um teste Playwright primário independente para cada `RF-P` de
`[ROTA_OU_ECRA]` em `[REQUISITOS_DA_PAGINA]`, validando conteúdo, interação,
estados, permissões e integração real com o backend. Executa cada requisito Web
nos projetos `mobile`, `tablet` e `desktop`. Aplica
`TEST_STRATEGY_CONTRACT.md` e mantém o âmbito na página e nas transições
diretamente necessárias.

## Cenários obrigatórios

Seleciona apenas os aplicáveis ao contrato e risco da página e justifica exclusões; a lista não obriga a fabricar estados que o produto não expõe:

- acesso anónimo, autorizado e proibido;
- loading, vazio, dados normais, conteúdo longo e erro recuperável;
- validação de campos, submissão, sucesso, conflito e repetição;
- navegação direta, refresh, back/forward e deep link;
- mobile, tablet e desktop, teclado, foco, toque e nomes acessíveis;
- snapshots dos estados estáveis em mobile/tablet/desktop e temas suportados;
- sessão expirada, rede lenta/offline e os estados HTTP materialmente possíveis entre 401/403/404/409/429/500.
- quando aplicável, ajuda correta para a rota e `FNC`, idiomas, abertura/fecho do
  painel, foco, player simulado, fornecedor bloqueado e fallback textual.

## Processo

1. Lê o requisito, página, componentes, endpoint, autorização, testes existentes e infraestrutura Playwright.
2. Regista a matriz `RF-P → teste Playwright primário → critério → precondição → ação → resultado visível → efeito persistido → mobile/tablet/desktop`.
   Reconcilia-a com `quality/TEST_MATRIX.md`; lacunas de unitário, componente,
   integração/provider, contrato ou arquitetura regressam ao nível correto em
   vez de serem escondidas num E2E maior.
3. Prepara os dados por API/helper de teste em vez de construir toda a precondição pela UI.
4. Exercita pela UI apenas o comportamento que o utilizador realmente executa.
5. Atualiza `quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md` e falha perante `RF-P`
   omitido, teste primário duplicado/ausente ou projeto de viewport não executado.

## Regras de implementação

- Usa locators acessíveis e únicos. Adiciona `data-testid` apenas quando não existir semântica estável.
- Afirma resultados visíveis e, quando material, o efeito persistido através da API/base descartável.
- Evita mockar a API que a página pretende validar. Substitui apenas fornecedores externos ou falhas impossíveis de provocar de forma segura.
- Usa web-first assertions; não usa sleeps fixos, dependência de ordem ou credenciais versionadas.
- Mantém cada teste independente, pequeno e diagnosticável.
- Inclui o `RF-P` no título/tag/trait/metadata de exatamente um teste primário;
  não agrega vários `RF-P` num único teste. Mantém combinações internas no
  nível unitário adequado, mas não elimina a prova funcional primária.
- Executa checks automáticos de acessibilidade sem os tratar como substituto da avaliação manual da jornada.
- Em snapshots, fixa browser, viewport, fontes, locale, timezone, animações e dados. Publica o diff como artefacto e só altera a baseline com revisão explícita e `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`.

## Validação

Executa o ficheiro/classe focado nos três projetos `mobile`, `tablet` e
`desktop`, repete-o para detetar flakiness e executa a suite da feature. Produz
um relatório reconciliado que demonstre um resultado por `RF-P × projeto`.
Confirma as resoluções exatas aprovadas ou os defaults `390×844`, `768×1024` e
`1440×900`; não testes apenas a largura nem reutilizes uma viewport entre classes.
Inspeciona trace/vídeo/diff visual em falha, consola e pedidos inesperados.
Confirma que requisito ausente/falhado, diferença visual ou violação automática
de acessibilidade bloqueia a pull request. Mede duração e elimina esperas
desnecessárias sem enfraquecer assertions.

## Entrega

Apresenta a matriz completa `RF-P → teste → mobile/tablet/desktop → resultado`,
critérios e níveis, cenários suplementares/excluídos e motivo, dados/fixtures,
clock/seed/locale/timezone usados, locators relevantes, comandos/resultados,
flakiness com owner/prazo, evidência de falhas corrigidas e limites de cobertura.

## Referências oficiais

- https://playwright.dev/docs/best-practices
- https://playwright.dev/dotnet/docs/browser-contexts
- https://playwright.dev/dotnet/docs/actionability
- https://playwright.dev/dotnet/docs/trace-viewer
- https://playwright.dev/docs/test-snapshots
- https://playwright.dev/docs/test-projects
- https://www.w3.org/WAI/test-evaluate/
