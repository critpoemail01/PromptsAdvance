# Criar a fundação visual e o layout partilhado

## Objetivo

Cria a fundação visual mínima da aplicação `[NOME_PRODUTO]` a partir de `[REQUISITOS_DE_PRODUTO]`, `[IDENTIDADE_VISUAL]`, `[REFERENCIAS_VISUAIS]` e da baseline aprovada em `PRODUCT_QUALITY_BASELINE.md`. Limita esta tarefa a tokens, primitivas, componentes transversais essenciais, catálogo inicial de componentes/estados e shells mínimos necessários à primeira `[VERTICAL_SLICE_ATUAL]`. Não completes antecipadamente páginas ou jornadas sem dados, permissões e comportamento reais.

## Critérios de sucesso

- Existe uma linguagem visual coerente para cor, tipografia, espaçamento, elevação, movimento, ícones e estados.
- Os componentes partilhados têm variantes e estados documentados, acessíveis e responsivos.
- SSR, Web e MAUI reutilizam `Client.Core` quando tecnicamente adequado, mantendo diferenças de plataforma intencionais.
- Loading, vazio, erro, sucesso, offline, disabled e focus são tratados.
- A alteração compila, é renderizada e inspecionada nos viewports e temas relevantes.
- Nenhuma página de negócio é redesenhada além do necessário para provar a fundação.
- A linguagem visual é específica do domínio e evita a aparência genérica de dashboard/template de IA.
- A primeira fatia tem critérios e referências visuais aprovados antes de o padrão ser propagado.

## Descoberta

1. Lê `AGENTS.md`, requisitos, rotas, `MODULES.md`, identidade visual, tokens, componentes e layouts existentes.
2. Confirma os projetos e superfícies realmente ativos; não assumes os nomes originais do boilerplate.
3. Executa o benchmark do `PRODUCT_EXCELLENCE.md` para a primeira superfície ativa e regista os resultados em `PRODUCT_QUALITY_BASELINE.md`. Extrai princípios, padrões próprios do domínio e limites explícitos contra a aparência genérica.
4. Inventaria o que deve ser preservado, melhorado, substituído ou removido. Não elimines comportamento, acessibilidade ou componentes usados apenas por parecerem antigos.
5. Cria uma matriz `elemento → proprietário → plataformas → estados → evidência`.
6. Se as referências visuais forem externas, usa-as como direção, não como licença para copiar assets, texto ou trade dress.

## Implementação

1. Define tokens semânticos, incluindo superfícies, texto, bordas, estados, foco e contraste. Evita cores literais repetidas.
2. Estabelece uma escala tipográfica e de espaçamento previsível, breakpoints justificados e largura máxima de conteúdo.
3. Implementa primitivas e componentes transversais necessários: botões, links, campos, feedback, cards, diálogos, navegação e skeletons.
4. Mantém HTML semântico, ordem de foco, nomes acessíveis, contraste e preferência por movimento reduzido.
5. Define apenas a estrutura base dos shells:
   - público SSR: conteúdo indexável, navegação simples e desempenho;
   - Web/PWA: navegação de produto, densidade e estados autenticados;
   - MAUI: safe areas, input tátil e convenções nativas.
6. Preserva o design system e packages existentes quando satisfazem o requisito. Não introduzas outro framework visual sem necessidade demonstrada.
7. Remove código antigo apenas depois de confirmar referências, cobertura e equivalência funcional.
8. Implementa apenas os componentes e estados necessários à primeira vertical slice real. Uma página de demonstração isolada não substitui a validação da jornada com backend, dados, autorização e estados reais.
9. Mantém um catálogo rastreável `componente → variantes → estados → plataformas → acessibilidade → snapshot aprovado`; não propagues um padrão antes da revisão humana da primeira fatia.

## Validação

Executa restore/build/test aplicáveis. Arranca as superfícies alteradas, renderiza-as e inspeciona pelo menos mobile e desktop, tema claro/escuro quando suportados, zoom e teclado. Captura referências aprovadas para loading, vazio, erro, conteúdo longo e estado normal num ambiente reproduzível; configura comparação visual em CI para os estados estáveis sem atualizar baselines automaticamente. Executa checks automáticos de acessibilidade e avaliação manual proporcional. Verifica clipping, overflow, layout shift, estados incompletos, consola e erros de rede. Corrige regressões observadas antes de concluir.

## Entrega

Apresenta baseline aprovada, benchmark e princípios adotados, fundação visual, catálogo inicial, decisões e componentes, primeira vertical slice abrangida, mapa de reutilização por plataforma, ficheiros alterados, capturas/snapshots, checks de acessibilidade, comandos/resultados, revisão humana e comportamento preservado.

## Referências oficiais

- https://www.w3.org/TR/WCAG22/
- https://learn.microsoft.com/aspnet/core/blazor/components/?view=aspnetcore-10.0
- https://learn.microsoft.com/dotnet/maui/user-interface/layouts/?view=net-maui-10.0
- https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6
