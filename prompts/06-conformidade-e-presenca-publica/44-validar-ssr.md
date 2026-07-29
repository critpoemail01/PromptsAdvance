# Auditar e validar o site público em static SSR

## Objetivo

Audita e valida o projeto público derivado de `Client.Ssr`. Prova que as rotas elegíveis devolvem HTML inicial útil, metadata correta e respostas HTTP robustas sem depender da execução de JavaScript. Por omissão, apenas diagnostica; corrige somente defeitos pequenos incluídos em `[AUTORIZACAO_DE_CORRECAO_SSR]`.

## Limite arquitetural

Nesta base, `Client.Ssr` é um site público autónomo em static SSR, separado de `Client.Web` (WASM/PWA autenticada). Não o transformes numa Blazor Web App interativa, não atives render modes globais e não mistures autenticação/estado da app sem uma decisão arquitetural explícita. Confirma a implementação real antes de alterar.

## Auditoria

1. Lê instruções, configuração e testes existentes, incluindo `PublicSiteSsrTests`.
2. Inventaria rotas por código, navegação, sitemap e testes:

| Rota | Status | HTML essencial | Metadata | Indexação | JS necessário | Evidência |
|---|---|---|---|---|---|---|

3. Regista baseline de HTML bruto, headers, redirects, 404/500, consola e layout.
4. Separa defeitos SSR de requisitos de negócio ausentes.

## Correções

Executa esta secção apenas para itens autorizados e cuja causa esteja demonstrada. Não redesenhes layouts, reescrevas conteúdo legal/SEO nem transformes a arquitetura; encaminha esses trabalhos para os prompts 13, 14, 40, 42 ou 43.

- Mantém título, heading principal, conteúdo, links e feedback essencial no HTML recebido.
- Corrige canonical, idioma, robots, sitemap, Open Graph/JSON-LD apenas com dados reais.
- Mantém indexação desativada até existir conteúdo final e URL HTTPS canónica configurada.
- Evita APIs de browser durante renderização no servidor e JavaScript para conteúdo essencial.
- Garante que erros e dados vazios produzem respostas/estados úteis, sem revelar segredos ou dados privados.
- Preserva a separação de hosts e contratos da API.

## Validação reproduzível

1. Faz pedidos HTTP diretos sem browser e guarda status, headers e excertos verificáveis do corpo.
2. Abre rotas num contexto com JavaScript desativado e confirma a experiência estática esperada.
3. Repete com JavaScript para comportamentos progressivos.
4. Testa deep links, refresh, 404, conteúdo vazio/long, rede lenta/falhada e 360×800, 768×1024, 1440×900.
5. Regista `console.error`, exceções, 4xx/5xx inesperados, pedidos duplicados e screenshots relevantes.
6. Usa Playwright existente. Se não estiver instalado, não o adiciones automaticamente: reforça testes HTTP/integração e usa o browser; propõe uma suite E2E separada apenas se o benefício justificar a nova dependência.
7. Executa restore/build/test do `*.Web.slnf` com Microsoft.Testing.Platform.

## Critérios de conclusão

Todas as rotas inventariadas têm resultado e evidência; conteúdo público essencial existe no HTML bruto; status/metadata/indexação estão coerentes; não há erros inesperados nos cenários executados; limitações estão identificadas. Não declares “SSR totalmente correto” fora da matriz testada.

## Entrega

Apresenta âmbito, matriz antes/depois ou baseline de auditoria, causas, correções autorizadas, itens encaminhados para prompts especializados, pedidos HTTP de prova, comandos/resultados, screenshots/traces e riscos residuais.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/components/render-modes?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/blazor/components/rendering?view=aspnetcore-10.0
- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- https://playwright.dev/docs/best-practices
