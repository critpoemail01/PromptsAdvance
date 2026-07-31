# Implementar SEO técnico e conteúdo indexável na área pública

## Objetivo

Implementa SEO apenas no site público `Client.Ssr`, com HTML static SSR, metadata coerente e indexação segura. Não tornes a app autenticada `Client.Web` indexável.

## Entrada bloqueante

Exige `[PUBLIC_BASE_URL_HTTPS_APROVADO]` para gerar canonical, sitemap, `hreflang` e metadata absoluta. Não o deduzas de localhost, headers de preview ou nomes do repositório. Sem este valor, mantém `noindex` e prepara a implementação sem ativar indexação.

## Preparação

1. Confirma rotas públicas, idiomas, URL HTTPS canónica, configuração SEO, sitemap, robots, IndexNow e testes existentes.
2. Cria uma matriz por rota:

| URL canónica | Intenção | Idioma | Title/H1 | Description | Indexável? | Schema | Evidência |
|---|---|---|---|---|---|---|---|

3. Mantém `noindex`/indexação desativada enquanto existirem placeholders, conteúdo incompleto ou URL canónica não configurada.

## Implementação

- Conteúdo principal, title e headings devem existir no HTML inicial.
- Gera titles/descriptions únicos, canonical absoluto HTTPS e status/redirects corretos.
- Para idiomas, usa URLs estáveis e `hreflang` recíproco, incluindo `x-default` quando apropriado. Não forces redirects pela língua do browser que impeçam utilizador/crawler de escolher.
- Gera `sitemap.xml` apenas com URLs canónicas indexáveis e `robots.txt` coerente. `robots.txt` não é mecanismo de segurança.
- Implementa Open Graph/social metadata e JSON-LD apenas para tipos/propriedades reais; valida contra Schema.org/Google.
- Evita páginas doorway, keyword stuffing, conteúdo duplicado ou promessas não suportadas.
- Otimiza semântica, links internos, imagens, fontes, LCP/CLS/INP e acessibilidade.
- Configura IndexNow apenas se já fizer parte da base; guarda a chave corretamente e não submete URLs de preview/staging.

## Validação

Testa HTML bruto, status/headers, canonical/hreflang, robots, sitemap, JSON-LD, 404 e páginas `noindex`. Usa Lighthouse apenas como medição de laboratório; não o presentes como dados reais de utilizador. Executa testes SSR e build/test do `*.Web.slnf`.

## Critérios

Nenhuma rota privada aparece em sitemap/canonical público; não há canonicals para host local; metadata corresponde ao conteúdo visível; indexação só é ativada com decisão explícita e configuração de produção válida.

## Entrega

Apresenta base URL usada, matriz, ficheiros, alterações, validações, estado de indexação e passos externos ainda necessários (Search Console/Bing), sem os executar.

## Referências oficiais

- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- https://developers.google.com/search/docs/specialty/international/localized-versions
- https://schema.org/
- https://www.indexnow.org/documentation
