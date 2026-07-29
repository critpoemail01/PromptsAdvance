# Executar uma auditoria de qualidade baseada em risco

## Objetivo

Audita a qualidade da aplicação derivada de `BoilerPlateAdvance` dentro de `[JORNADAS_CRITICAS]`, `[SUPERFICIES_E_PLATAFORMAS]`, `[AMBIENTE_AUTORIZADO]` e `[ORCAMENTO_DE_TESTE]`. Encontra defeitos reproduzíveis e produz evidência acionável. O modo predefinido é diagnóstico; corrige apenas itens incluídos literalmente em `[AUTORIZAÇÃO_DE_CORREÇÃO]`.

## Entradas e limites

- Define jornadas, atores, superfícies, browsers/dispositivos e ambiente.
- Define o orçamento: tempo máximo, carga permitida, serviços que podem ser chamados e profundidade de cobertura.
- Define dados/contas descartáveis e efeitos externos proibidos.
- Se uma entrada material faltar, testa apenas o que for seguro e observável, marca a cobertura como parcial e não expande o âmbito por iniciativa própria.
- Não substitui as auditorias especializadas de segurança, performance, acessibilidade, PWA, SSR, SEO, cache ou resiliência; usa os resultados dessas tarefas quando existirem.

## Critérios de sucesso

- Todas as jornadas e plataformas selecionadas têm resultado ou bloqueio fundamentado.
- Cada defeito tem passos, esperado, observado, evidência e severidade.
- A conclusão distingue falha do produto, limitação do ambiente e zona não testada.
- Correções autorizadas são pequenas, têm teste de regressão e não alteram contratos ou arquitetura.
- A execução termina ao atingir o orçamento ou a matriz definida.

## Planeamento

1. Lê instruções, arquitetura, CI e testes existentes.
2. Confirma superfícies ativas e ambientes autorizados.
3. Cria uma matriz de risco apenas para o âmbito selecionado, por jornada, impacto, probabilidade, dados/permissões e plataforma.
4. Prioriza: autenticação/recuperação, autorização, fluxos de negócio, integridade, pagamentos quando existentes, site público/SSR, erros e atualização PWA.
5. Para jornadas visíveis, lê o benchmark e os princípios aprovados no `PRODUCT_EXCELLENCE.md`; avalia a implementação contra esses critérios, não por gosto pessoal nem por semelhança pixel a pixel.

## Estratégia

- Testes unitários para invariantes e lógica pura.
- Integração para API, Identity, EF/migrations, configuração e dependências substituídas.
- HTTP para SSR, status, headers, health e metadata.
- Browser/E2E para jornadas críticas e regressões visuais/interativas.
- Avaliação manual para acessibilidade; ferramentas automáticas não provam conformidade WCAG.

Valida happy paths e também: dados vazios/limite/inválidos, 401/403/404/409/429/500, repetição, concorrência, timeouts, rede lenta/offline, sessão expirada, deep links, mobile/tablet/desktop, teclado e idiomas/temas existentes.

## Regras

Usa dados isolados e descartáveis. Credenciais entram por variáveis de ambiente (`[TEST_USER_EMAIL]`, `[TEST_USER_PASSWORD]`) e nunca ficam em ficheiros/logs. Não uses produção, não envies emails/notificações, não faças compras e não cliques em anúncios reais.

No Playwright, usa isolamento, locators acessíveis, web-first assertions e traces em falha; evita sleeps fixos. Se não estiver instalado, não o adiciones sem justificar uma estratégia E2E duradoura.

Antes de corrigir, confirma que o defeito está incluído em `[AUTORIZAÇÃO_DE_CORREÇÃO]`, que a causa é inequívoca e que a alteração não muda produto, dados, API ou arquitetura. Caso contrário, limita-te ao diagnóstico e a uma proposta.

## Execução técnica

Executa os comandos do repositório: locked restore, build `*.Web.slnf` e testes Microsoft.Testing.Platform. Não passes `--logger`, `--report-trx` ou `-clp`. Compila MAUI só quando aplicável/workload disponível. Não escondas testes flaky por retries ilimitados.

## Entrega

Apresenta orçamento consumido, cobertura e ambiente, matriz de resultados, desvios aos princípios de experiência, defeitos com passos/esperado/observado/evidência, severidade, causa provável, correções efetuadas, comandos/resultados, testes flaky e riscos não cobertos. Não uses “sem bugs”; limita conclusões ao âmbito executado.

## Referências oficiais

- https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro
- https://playwright.dev/docs/best-practices
- https://playwright.dev/docs/browser-contexts
- https://www.w3.org/WAI/test-evaluate/
- https://owasp.org/www-project-application-security-verification-standard/
