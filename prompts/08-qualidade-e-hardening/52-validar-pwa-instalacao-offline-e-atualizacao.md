# Validar PWA, instalação, offline e atualização

## Objetivo

Audita e corrige a experiência PWA de `Client.Web` para `[BROWSERS_E_DISPOSITIVOS]`, focando manifest, instalação, modo standalone, comportamento offline, dados/operações pendentes e atualização vista pelo utilizador. A política HTTP/CDN de publicação pertence ao prompt 56 e a sua validação online ao prompt 67.

## Critérios de sucesso

- O manifest é válido e usa identidade, ícones, scope e start URL corretos.
- Instalação e arranque standalone funcionam nos ambientes suportados.
- A estratégia offline distingue shell público, dados sensíveis e ações que exigem rede.
- Novas versões são detetadas e aplicadas sem misturar assets incompatíveis.
- Falha de rede/storage/service worker tem recuperação compreensível.

## Processo

1. Lê service worker, manifest, estratégia do prompt 56 e resultados online do prompt 67 quando já existirem, configuração de publicação e documentação de force update do boilerplate.
2. Inventaria recursos precache/runtime, requests autenticados, IndexedDB/local storage e dados sensíveis.
3. Define a matriz `recurso/jornada → online → offline → cache → invalidação → recuperação`.
4. Confirma requisitos de instalação e offline por plataforma; não promete suporte universal.

## Implementação

- Mantém scope, paths e base URL coerentes em subpaths/domínios.
- Respeita a matriz de cache aprovada; não redesenha headers/CDN neste prompt e não guarda indiscriminadamente respostas autenticadas.
- Define UX para primeira visita offline, perda de ligação, operações pendentes e reconexão.
- Se existir fila/sync, torna operações idempotentes, visíveis e canceláveis; evita conflitos silenciosos.
- Coordena versões entre separadores e apresenta atualização quando necessário, preservando trabalho não submetido.
- Limpa caches obsoletos com segurança e mantém um caminho de recuperação.

## Validação

Testa instalação limpa, standalone, primeira visita, visita repetida offline, rede lenta, API indisponível, sessão expirada, versão nova com separadores abertos, storage cheio/limpo e uninstall/reinstall quando possível. Inspeciona Application/Cache/Network, consola e conteúdo sensível. Executa build/test e auditoria automatizada apenas como evidência complementar.

## Entrega

Apresenta matriz de instalação/offline/sync/atualização, ficheiros, browsers/dispositivos, testes/resultados, evidência de atualização, dados que nunca ficam offline e questões encaminhadas para os prompts 56/67.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/progressive-web-app/?view=aspnetcore-10.0
- https://developer.mozilla.org/docs/Web/Progressive_web_apps
- https://w3c.github.io/manifest/
- https://w3c.github.io/ServiceWorker/
