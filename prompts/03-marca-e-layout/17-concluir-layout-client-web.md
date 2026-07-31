# Concluir e validar o layout de Client.Web

## Objetivo

Depois de todas as jornadas Web/PWA `Must` terem sido implementadas e testadas por fatias verticais, conclui a UI autenticada contra `[MATRIZ_DE_REQUISITOS_WEB]`, eliminando inconsistências e regressões antes da validação PWA global. Não introduzas novas funcionalidades de produto para “preencher” ecrãs.

## Pré-requisito

A matriz deve provar que todas as jornadas `Must` passaram pelas respetivas implementações e testes de vertical slice, e indicar estados, `[PERFIS_DE_AUTORIZACAO]` e `[VIEWPORTS_ALVO]`. Se uma jornada não estiver integrada, termina `bloqueado`. Se não existirem contas de teste para um perfil, não simules evidência: marca essa célula como `não verificável`.

## Critérios de conclusão

- Rotas e jornadas no âmbito têm navegação, estados, permissões e feedback completos.
- Componentes equivalentes usam padrões, tokens e linguagem consistentes.
- Deep links, refresh, sessão expirada, erros e offline degradam de forma segura.
- Não existem placeholders acidentais, ações sem resultado, scroll traps ou erros de consola.
- As evidências cobrem viewports, teclado, temas e perfis de autorização relevantes.

## Execução

1. Cria a matriz `jornada × estado × role/permissão × viewport × resultado`.
2. Confirma que os princípios do benchmark do `PRODUCT_EXCELLENCE.md` estão rastreados a requisitos e evidência, sem semelhança indevida com uma única referência.
3. Testa fluxos críticos do início ao fim com dados isolados e contas de teste.
4. Corrige primeiro bloqueios, perda de dados, autorização, acessibilidade, responsividade e só depois acabamento.
5. Confirma consistência de shell, navegação, formulários, listas, feedback e diálogos.
6. Verifica que a UI não depende de sleeps, refresh manual ou ordem acidental de pedidos.
7. Remove estilos/componentes órfãos apenas com pesquisa de referências e build verde.

## Validação obrigatória

Executa restore/build/test, arranque local e browser real. Valida mobile/tablet/desktop, teclado, zoom, temas, rede lenta/offline, 401/403/409/429/500, múltiplos separadores e atualização de página. Executa Playwright focado, checks automáticos de acessibilidade e avaliação manual das jornadas críticas. A regressão visual é obrigatória nos estados estáveis; preserva a baseline em CI e não escondas diferenças ou flakiness com retries ilimitados.

## Entrega

Apresenta matriz por jornada/perfil/viewport, conformidade com os princípios do benchmark e evidências, correções, comandos/resultados, regressões verificadas e itens explicitamente deixados para validação PWA, segurança ou performance. Não declares conclusão quando estados obrigatórios não foram exercitados.

## Referências oficiais

- https://playwright.dev/docs/best-practices
- https://learn.microsoft.com/aspnet/core/blazor/progressive-web-app/?view=aspnetcore-10.0
- https://www.w3.org/WAI/test-evaluate/
