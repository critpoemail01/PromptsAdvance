# Contrato de estratégia e matriz de testes

Este contrato define como cada risco obtém uma prova adequada sem concentrar
toda a confiança em testes end-to-end. Aplica-se desde a primeira vertical
slice e é atualizado quando requisitos, arquitetura, providers ou riscos mudam.

## Artefactos obrigatórios

Mantém:

- `quality/TEST_STRATEGY.md` — ambientes, níveis, lanes de CI, dados, políticas
  de determinismo/flakiness, ferramentas e responsabilidades;
- `quality/TEST_MATRIX.md` — uma linha por requisito/risco material, atualizada
  em cada slice.
- `quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md` — censo de todos os `RF-P`,
  teste Playwright primário e resultados por resolução/plataforma.

## Matriz mínima

| Requisito/risco | Invariante/oráculo | Unitário | Componente | Integração/provider real | Contrato/compatibilidade | Playwright/teste nativo | Mobile | Tablet | Desktop | Visual | A11y | Performance/resiliência | Evidência |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

Usa `sim`, `não aplicável` com razão ou `bloqueado` com owner/prazo. Não marques
uma célula como coberta apenas porque outro nível executou uma jornada feliz.

## Cobertura Playwright obrigatória por requisito funcional

- Cada `RF-P` definido tem exatamente um teste Playwright primário identificável
  pelo próprio ID no título, tag/trait ou metadata. Um teste primário não pode
  substituir dois requisitos; cenários negativos ou critérios adicionais podem
  criar testes suplementares com o mesmo ID.
- Cada `RF-P` visível em Web/SSR executa o mesmo teste primário em três projetos
  determinísticos: `mobile`, `tablet` e `desktop`. Cada projeto regista viewport,
  browser/device, orientação, device scale factor quando relevante e resultado.
  Usa as resoluções aprovadas em `PRODUCT_QUALITY_BASELINE.md`; quando ainda não
  existirem, adota e regista provisoriamente `390×844`, `768×1024` e `1440×900`,
  respetivamente. Uma decisão posterior pode substituí-las, mas nunca pode
  reduzir as três classes nem usar a mesma resolução para representar duas.
- Cada `RF-P` de `Server.Api` ou operação não visual usa Playwright
  `APIRequestContext`/equivalente da stack para provar contrato, autorização,
  efeito e erro. Resoluções são `não aplicável` apenas quando não existe
  consumidor visual; quando existe, liga também aos testes do consumidor
  executados em mobile, tablet e desktop.
- Um `RF-P` exclusivamente nativo MAUI mantém a linha no censo e exige um teste
  UI nativo automatizado equivalente nas classes de largura/plataformas
  aprovadas. Playwright cobre a API/contrato partilhado ou a superfície Web
  equivalente, mas não é apresentado como prova de uma UI nativa que não
  controla.
- `quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md` usa:

| RF-P | APP/unidade | Teste primário/ficheiro | Oráculo | Mobile | Tablet | Desktop | API/nativo equivalente | Resultado/evidência |
|---|---|---|---|---|---|---|---|---|

- IDs ausentes, duplicados, testes sem execução, `skip`/`fixme`, projetos de
  viewport em falta ou resultado diferente não justificado impedem concluir o
  prompt, a slice e G05. Geração dinâmica só é aceite quando o relatório ainda
  apresenta um caso independente e diagnosticável por `RF-P` e projeto.

## Escolha do nível

- **Unitário/propriedades:** invariantes, cálculos, parsing, transições e lógica
  combinatória. Usa testes property-based ou mutation testing apenas quando a
  ferramenta já existir ou o risco justificar a adoção aprovada; conserva seed,
  mutantes sobreviventes e custo.
- **Componente:** estados e interação de UI/serviço isolados com contratos
  estáveis, incluindo acessibilidade básica.
- **Integração:** serialização, Identity, EF, migrations, filas, storage e
  configuração. Comportamento dependente de SQL/provider usa uma instância
  descartável do provider real; SQLite/InMemory não prova outro provider.
- **Contrato:** OpenAPI/eventos e consumers/providers. Executa diff de
  compatibilidade e testes de consumidor/provedor quando uma interface atravessa
  equipas, processos ou versões.
- **Arquitetura:** automatiza limites entre módulos/camadas quando uma referência
  proibida possa compilar e degradar o desenho.
- **Browser/nativo:** cada requisito funcional tem a prova primária acima;
  jornadas críticas acrescentam combinações ponta a ponta, integrações reais
  visíveis, autorização, efeitos persistidos, recuperação e regressão interativa.
- **Visual, acessibilidade, performance e resiliência:** gates próprios para
  riscos que testes funcionais não observam.

## Lanes de CI

| Lane | Objetivo | Conteúdo mínimo | Budget/política |
|---|---|---|---|
| Commit | feedback rápido | build, unitários, componentes e checks estáticos afetados | rápida e determinística |
| Pull request | integração e regressão | integração/provider, contrato, arquitetura, Playwright dos `RF-P` afetados em mobile/tablet/desktop, a11y e diff visual | bloqueia defeitos materiais |
| Nightly | amplitude | cross-browser/dispositivo, dados volumosos, concorrência, mutation/property quando adotados, performance e resiliência segura | findings com owner; sem esconder falhas |
| Release | candidata imutável | todos os `RF-P` reconciliados e verdes nos projetos aplicáveis, suite de risco, migrations, segurança, acessibilidade, performance, recuperação e smoke sobre o mesmo SHA/artefacto | fail-closed |

Não uses uma lane posterior para justificar ausência permanente de feedback
rápido no nível mais baixo adequado.

## Determinismo, dados e diagnóstico

- fixa ou regista clock, timezone, locale, cultura, random seed, browser,
  viewport, fontes, animações, versões e dados;
- cada teste cria recursos próprios e elimina apenas esses recursos;
- efeitos externos usam fake/sandbox autorizado, nunca contas ou produção reais;
- espera por estados observáveis com timeout explícito; não usa sleeps fixos;
- em falha conserva logs, trace, screenshot/diff, request/correlation ID e estado
  suficiente, redigindo segredos e dados pessoais;
- repete falhas de forma controlada para distinguir produto, ambiente e teste.

## Política de flakiness

Um teste flaky continua a ser uma falha. Pode ser colocado numa lane de
diagnóstico apenas com finding, owner, severidade, causa provável, prazo e
cobertura compensatória. São proibidos retries ilimitados, `skip`, sleeps
arbitrários e relaxamento de assertions/thresholds apenas para tornar CI verde.
Depois da correção, executa repetições com a mesma seed e com seeds variadas
quando o risco o justificar.

## Failure modes e robustez

Para cada jornada crítica mantém:

| Falha/modo | Causa | Efeito local | Efeito no utilizador/dados | Deteção | Prevenção/mitigação | Recuperação | Teste | Owner |
|---|---|---|---|---|---|---|---|---|

Prioriza por impacto, probabilidade e detetabilidade. Cobre timeout, resposta
inválida, indisponibilidade, repetição, concorrência, perda parcial, restart,
limites de capacidade e recuperação. Combina carga e fault injection apenas em
ambiente descartável autorizado, com hard stops, SLO/RTO/RPO aprovados e sem
efeitos externos reais.

## Conclusão honesta

Entrega cobertura Playwright/nativa por `RF-P` e por mobile/tablet/desktop,
além da cobertura por requisito/risco, comandos e exit codes, ambientes e
providers usados, mutações/falhas provocadas, artefactos, zonas não testadas,
flakiness e riscos residuais. Nunca uses “sem bugs” ou “cobertura total” fora do
âmbito e dos oráculos demonstrados.

## Referências oficiais

- https://playwright.dev/docs/test-projects
- https://playwright.dev/docs/api-testing
- https://playwright.dev/docs/api/class-apirequestcontext
- https://playwright.dev/docs/test-annotations
