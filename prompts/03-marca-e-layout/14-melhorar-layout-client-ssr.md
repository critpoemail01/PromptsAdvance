# Melhorar o layout do site público em Client.Ssr

## Objetivo

Melhora, dentro da `[VERTICAL_SLICE_ATUAL]`, a experiência pública em static SSR para `[PUBLICO_ALVO]` e `[OBJETIVOS_DA_AREA_PUBLICA]`. Trabalha sobre conteúdo, backend/contrato, estados e critérios reais já implementados para essa fatia. Preserva rotas, conteúdo útil, SEO, acessibilidade e identidade visual; não transformes a área pública numa aplicação dependente de JavaScript.

## Entradas

Usa `[CONTEUDO_PUBLICO_APROVADO]`, `[REFERENCIA_VISUAL_OU_BASELINE]`, `PRODUCT_QUALITY_BASELINE.md` e apenas as rotas da fatia atual. Se faltar conteúdo factual aprovado ou implementação funcional exercitável, bloqueia a propagação do padrão; conserva placeholders visíveis e não inventa claims, métricas, clientes ou benefícios.

## Critérios de sucesso

- A proposta de valor, navegação e chamadas à ação são claras nos primeiros ecrãs.
- O HTML inicial contém conteúdo e links relevantes sem depender de hidratação.
- O layout funciona por teclado, com zoom e nos viewports definidos.
- Estados de erro, conteúdo ausente e links externos estão tratados.
- Não existem regressões mensuráveis de performance, metadata ou indexabilidade.
- O resultado satisfaz a rubrica profissional, a linguagem visual própria do domínio e a revisão humana da primeira fatia.

## Processo

1. Lê requisitos, rotas públicas, analytics autorizada, componentes SSR e design tokens.
2. Aplica o `PRODUCT_EXCELLENCE.md`: compara sites públicos profissionais com proposta/jornada semelhante, um design system maduro e previews premium relevantes; documenta padrões adaptáveis e limites de licença.
3. Renderiza o estado atual em mobile e desktop. Regista problemas de hierarquia, conteúdo, responsividade, acessibilidade e desempenho com evidência.
4. Identifica páginas críticas: início, funcionalidades, preços quando aplicável, contacto, autenticação e páginas legais.
5. Propõe alterações ligadas a problemas observados e aos princípios aprovados; evita secções decorativas, “template look” ou texto inventado.

## Implementação

- Usa landmarks, headings, listas, links e formulários semanticamente corretos.
- Mantém a informação principal no HTML da resposta e progressive enhancement para interação opcional.
- Reutiliza tokens e componentes partilhados sem importar dependências exclusivas de WebAssembly ou MAUI.
- Otimiza imagens com dimensões, formatos e loading adequados; reserva espaço para evitar layout shift.
- Trata navegação ativa, skip link, foco, validação de formulários e feedback.
- Mantém conteúdo factual através de placeholders explícitos quando faltarem dados aprovados.
- Não adiciona trackers, cookies, embeds ou fontes externas sem rever privacidade, consentimento, segurança e impacto.

## Validação

Verifica HTML da resposta com JavaScript desativado, status HTTP, canonical/metadata existentes, links, teclado, contraste, zoom, mobile e desktop. Executa build/test, checks automáticos de acessibilidade, avaliação manual da jornada, inspeção de consola/rede e uma medição comparável de performance antes/depois. Compara snapshots aprovados de estado normal, loading, vazio, erro e conteúdo longo em ambiente reproduzível; alterações de baseline exigem `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`. Distingue problemas desta tarefa de SEO profundo ou área legal que pertençam a prompts posteriores.

## Entrega

Apresenta inputs/baseline, benchmark e padrões adotados, diagnóstico inicial, alterações por página, evidência visual e HTML, comandos/resultados, métricas comparáveis, placeholders/decisões de conteúdo, licenças e riscos ainda abertos.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/components/prerender?view=aspnetcore-10.0
- https://html.spec.whatwg.org/
- https://www.w3.org/WAI/ARIA/apg/
- https://web.dev/articles/vitals
