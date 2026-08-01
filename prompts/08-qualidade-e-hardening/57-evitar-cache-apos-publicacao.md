# Garantir atualização segura após publicação sem desativar o cache

## Objetivo

Corrige a estratégia de versionamento, cache e deploy para que novas versões sejam detetadas e carregadas de forma consistente, preservando o desempenho e o suporte offline da PWA. Não uses `no-store` global nem desatives integrity checks para mascarar um deploy inconsistente.

## Contexto

O projeto separa `Client.Ssr`, `Client.Web` WASM/PWA e `Server.Api`, com bundles de publicação próprios. Pode existir CDN/purge no pipeline; confirma provider e configuração real antes de alterar. Este prompt prepara/corrige a estratégia; usa o prompt 53 para UX PWA/offline e o 68 para validação online.

## Diagnóstico

1. Reproduz o problema e identifica a camada: browser HTTP cache, service worker/Cache API, CDN/proxy, origin, deploy parcial ou versão da API.
2. Recolhe URL, headers (`Cache-Control`, `ETag`, `Last-Modified`, `Age`, `Vary`, CDN), service worker, cache names e hashes dos assets.
3. Compara artefacto publicado, origin e CDN. Um erro de integridade costuma indicar resposta/asset inconsistente; não remova a verificação.

## Estratégia

Define uma matriz por classe:

| Recurso | Exemplo | Versionado? | Política de cache | Invalidação |
|---|---|---|---|---|

Aplica, conforme a arquitetura:

- assets com fingerprint/hash: cache longo `public, max-age=..., immutable`;
- HTML de entrada, manifestos de versão e service worker: revalidação frequente, não cache imutável;
- `service-worker-assets.js`/equivalente: define a política a partir da implementação e documentação da versão usada; não imponhas `updateViaCache` sem confirmar o registo real do service worker;
- respostas autenticadas/API: política por sensibilidade e sem cache partilhado indevido;
- deploy atómico de cada bundle para evitar mistura de versões;
- quando existir CDN: purge seletivo de HTML/manifests/URLs mutáveis após deploy; evita “purge everything” salvo emergência;
- indicador de versão e UX de “nova versão disponível” com ativação segura, sem `skipWaiting` automático se quebrar consistência.

## Validação

Publica apenas num ambiente autorizado. Testa instalação limpa, utilizador existente, tab aberta durante deploy, múltiplas tabs, online/offline, CDN HIT/MISS e rollback. Verifica hashes/integridade, consola/rede e que assets antigos referenciados continuam disponíveis durante a janela necessária.

## Entrega

Apresenta topologia real de cache/CDN, causa raiz, matriz de cache, alterações no pipeline/código, prova antes/depois, comandos/resultados, estratégia de rollback, dependências dos prompts 53/68 e riscos.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/progressive-web-app/?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/blazor/host-and-deploy/webassembly/bundle-caching-and-integrity-check-failures?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/fundamentals/static-files?view=aspnetcore-10.0
- https://developer.mozilla.org/docs/Web/HTTP/Reference/Headers/Cache-Control
- https://developers.cloudflare.com/cache/how-to/purge-cache/purge-everything/
