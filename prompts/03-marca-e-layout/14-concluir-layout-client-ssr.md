# Concluir e validar o layout de Client.Ssr

## Objetivo

Depois de todas as jornadas públicas `Must` terem sido implementadas por fatias verticais, fecha as lacunas do layout público SSR contra `[MATRIZ_DE_REQUISITOS_PUBLICOS]` e entrega uma versão pronta para as auditorias especializadas de conteúdo legal, SEO, acessibilidade e SSR. Corrige apenas problemas comprovados; não redesenhes novamente sem uma regressão ou requisito por cumprir.

## Pré-requisito

A matriz deve provar que todas as jornadas públicas `Must` passaram pelas respetivas implementações e testes de vertical slice, e identificar rotas, estados, conteúdo aprovado e viewports alvo. Se alguma jornada `Must` ainda não estiver funcionalmente integrada, termina `bloqueado`; se faltar conteúdo material, usa `bloqueado por conteúdo` e não substitui a lacuna por texto inventado.

## Critérios de conclusão

- Todas as rotas públicas no âmbito têm estados e conteúdo definidos.
- Header, navegação, footer e chamadas à ação são consistentes.
- O conteúdo essencial aparece no HTML inicial e os links são navegáveis.
- Mobile, tablet, desktop, teclado, zoom e temas suportados passam.
- Não permanecem placeholders acidentais, links quebrados, overflow ou erros de consola.

## Execução

1. Constrói uma matriz `rota × requisito × viewport × estado × resultado × evidência`.
2. Compara implementação, requisitos, design system, princípios aprovados no benchmark do `PRODUCT_EXCELLENCE.md` e comportamento renderizado.
3. Testa primeira visita, navegação direta, refresh, 404/erro, conteúdo longo, localização suportada e rede lenta.
4. Corrige por ordem: bloqueios funcionais, acessibilidade, responsividade, legibilidade, consistência e acabamento.
5. Remove CSS/componentes órfãos apenas depois de confirmar que não são usados por outra superfície.
6. Mantém alterações pequenas e revê o diff para impedir mudanças de negócio, tracking ou dependências não autorizadas.

## Validação obrigatória

Executa restore/build/test adequados, checks automáticos de acessibilidade, pedidos HTTP às rotas críticas e inspeção visual/manual em browser real. Verifica source HTML, status, headings, landmarks, foco, formulários, imagens, consola, rede e links internos/externos. A regressão visual é obrigatória para mobile/desktop, temas suportados e estados estáveis; uma diferença falha até ser corrigida ou aprovada explicitamente por `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`, com revisão do diff visual.

## Entrega

Apresenta a matriz final por rota/estado/viewport, problemas corrigidos, evidências, comandos/resultados e lista explícita de itens encaminhados para SEO, WCAG, área legal ou validação SSR. Usa `bloqueado` ou `não verificável` quando faltar ambiente ou conteúdo; não declares sucesso por inspeção de código apenas.

## Referências oficiais

- https://www.w3.org/WAI/test-evaluate/
- https://html.spec.whatwg.org/
- https://web.dev/articles/vitals
