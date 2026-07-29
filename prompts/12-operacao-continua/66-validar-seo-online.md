# Validar SEO técnico num ambiente publicado

## Objetivo

Executa uma auditoria read-only de `[PUBLIC_BASE_URL]` e produz evidência por URL. Não publiques, não alteres DNS, não submetas URLs e não modifiques Search Console/IndexNow sem autorização explícita.

## Pré-condições

Confirma que o URL é o ambiente correto, HTTPS e autorizado. Regista data, região, user agent e se existe autenticação/CDN. Se o domínio não for fornecido, usa apenas o URL configurado no repositório e não adivinhes.

Define `[URLS_OU_AMOSTRA]`, limite de pedidos, concorrência e exclusões. Respeita robots e capacidade do ambiente; não expandas o crawl para subdomínios ou hosts externos sem os incluir explicitamente.

## Auditoria

1. Descobre URLs por navegação, sitemap e links internos; não faças crawling agressivo.
2. Para uma amostra representativa e páginas críticas, recolhe:
   - status, redirects, headers e `Content-Type`;
   - HTML bruto antes de JavaScript;
   - title, description, H1, canonical, robots meta/X-Robots;
   - `lang`, `hreflang`, Open Graph e JSON-LD;
   - links internos, imagens/alt e assets bloqueados;
   - sitemap/robots e referências a ambientes errados.
3. Confirma que páginas privadas, login, APIs e erros não são indexáveis.
4. Valida mobile e desktop, JavaScript desativado, 404/500 e Core Web Vitals de laboratório. Se houver dados de campo autorizados, separa-os claramente.
5. Verifica `ads.txt`/`app-ads.txt` apenas se o produto usar publicidade.

## Regras de evidência

Classifica cada problema por severidade, URLs afetadas, impacto e reprodução. Distingue:

- erro técnico confirmado;
- recomendação;
- resultado dependente do motor de pesquisa;
- limitação de acesso/ferramenta.

Uma resposta 200 de IndexNow prova receção, não indexação. Uma pontuação Lighthouse não garante ranking nem Core Web Vitals reais.

## Entrega

Apresenta âmbito, orçamento de crawl, resumo, matriz por URL, problemas priorizados, comandos/pedidos reproduzíveis com dados sensíveis redigidos, screenshots úteis e plano de correção. Compara com auditorias anteriores apenas quando os URLs e condições forem equivalentes.

## Referências oficiais

- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- https://search.google.com/test/rich-results
- https://web.dev/articles/vitals
- https://www.indexnow.org/documentation
