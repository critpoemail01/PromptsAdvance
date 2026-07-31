# Validar que a versão publicada atualiza corretamente

## Objetivo

Executa uma auditoria read-only de cache/versionamento em `[SSR_URL]`, `[WEB_URL]` e `[API_URL]`. Prova se instalações novas e clientes com cache anterior recebem um conjunto consistente de artefactos. Não publiques nem purgues caches sem autorização.

## Pré-condições

Regista versão/build esperada `[BUILD_ID]`, hora do deploy, ambiente, CDN e artefacto local opcional `[PUBLISH_DIR]`. Sem `[BUILD_ID]` ou outra prova inequívoca da versão esperada, recolhe baseline mas não classifica consistência como aprovada. Credenciais de teste entram por variáveis de ambiente.

## Matriz de cenários

Testa:

1. pedido HTTP sem cookies/cache;
2. browser/contexto novo;
3. perfil existente com service worker/cache anterior;
4. hard reload apenas como diagnóstico, não como solução;
5. múltiplas tabs;
6. online, offline e reconexão;
7. mobile e desktop;
8. origin direto versus CDN, se autorizado;
9. rollback ou versão anterior apenas em ambiente de teste.

## Evidência

Para HTML, service worker, manifestos, JS/CSS/WASM/assemblies e endpoints relevantes, recolhe:

- URL final, status, content type e redirects;
- `Cache-Control`, `ETag`, `Last-Modified`, `Age`, `Vary` e headers CDN;
- hash do conteúdo e referência a partir do HTML/manifesto;
- origem da resposta no DevTools (network, memory, disk, service worker);
- versão visível e estado do service worker (installing/waiting/active);
- erros de integridade, consola, 404/5xx e assets misturados.

Não assumes que `200`, refresh ou “parece atualizado” prova consistência. Compara hashes com o artefacto publicado quando disponível.

## Critérios

- assets fingerprinted são imutáveis e correspondem ao manifesto;
- entradas mutáveis revalidam e apontam para a build esperada;
- nenhuma sessão carrega assemblies/assets de builds incompatíveis;
- a PWA deteta atualização e mantém experiência offline coerente;
- API e clientes mantêm compatibilidade durante o rollout;
- CDN e origin convergem dentro do comportamento documentado.

## Entrega

Apresenta ambiente e build esperada/observada, matriz passada/falhada/não verificável, headers/hashes, screenshots de Application/Network, causa por camada, severidade e correções recomendadas. Se a correção exigir purge/deploy, remete para novo âmbito e autorização.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/progressive-web-app/?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/blazor/host-and-deploy/webassembly/bundle-caching-and-integrity-check-failures?view=aspnetcore-10.0
- https://developer.mozilla.org/docs/Web/HTTP/Reference/Headers/Cache-Control
- https://developers.cloudflare.com/cache/
