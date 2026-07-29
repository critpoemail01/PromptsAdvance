# Melhorar o layout da aplicação autenticada Client.Web

## Objetivo

Melhora, dentro da `[VERTICAL_SLICE_ATUAL]`, a experiência autenticada Blazor WebAssembly/PWA em `Client.Web` para a jornada selecionada, reutilizando `Client.Core` e preservando contratos, permissões e comportamento de negócio já implementados nessa fatia. Prioriza clareza operacional, feedback e recuperação em vez de elementos decorativos.

## Entradas e limites

Recebe `[JORNADAS_PRIORITARIAS]`, `[ATORES_E_PERMISSOES]`, `[VIEWPORTS_ALVO]`, `[ESTADOS_A_VALIDAR]`, a baseline aprovada e contas de teste por variáveis de ambiente. Exige backend, contratos, dados e autorização exercitáveis para a fatia. Se faltarem, audita e propõe o âmbito sem redesenhar a aplicação e termina `bloqueado` para implementação. Define métricas observáveis para os problemas visados, como conclusão da tarefa, erros, passos ou regressões de desempenho.

## Critérios de sucesso

- A arquitetura de informação e navegação tornam as tarefas prioritárias previsíveis.
- Cada jornada trata loading, vazio, erro, sucesso, offline, autorização e sessão expirada.
- O layout é responsivo, acessível e utilizável por teclado e toque.
- A UI não revela ações proibidas como substituto de autorização no servidor.
- O resultado é renderizado e validado em condições reais de rede e sessão.
- A densidade, grelha, hierarquia e controlos são deliberados para o domínio e não reproduzem um dashboard administrativo genérico.

## Descoberta

1. Confirma rotas, shell, menus, componentes partilhados, roles/permissões, PWA, temas e telemetria existente.
2. Executa as jornadas atuais com contas de teste representativas e regista fricção, inconsistências e falhas.
3. Mapeia `jornada → ecrãs → estados → permissões → API → componente`.
4. Aplica o `PRODUCT_EXCELLENCE.md` à jornada: compara aplicações profissionais autenticadas, design systems de produto e temas premium relevantes quanto a navegação, densidade, formulários, tabelas, feedback e recuperação.
5. Define princípios e âmbito; preserva elementos que já cumprem o design system e não introduzas o framework das referências.

## Implementação

- Melhora navegação global, breadcrumbs quando úteis, títulos e ações primárias.
- Usa padrões consistentes para filtros, pesquisa, tabelas/listas, formulários, confirmação e feedback.
- Evita modais desnecessários e perda de dados; protege ações irreversíveis com contexto e confirmação proporcionais.
- Mantém foco, labels, mensagens de validação, targets táteis e preferência por movimento reduzido.
- Trata latência, cancelamento, repetição e concorrência sem duplicar operações.
- Reutiliza `Client.Core` apenas para componentes realmente partilháveis; não força padrões web dentro de MAUI.
- Não adiciona analytics, notificações ou experiências de retenção fora do âmbito.

## Validação

Executa build/test e a jornada selecionada nos viewports alvo, com teclado, zoom, rede lenta/offline e sessão expirada quando aplicável. Executa checks automáticos de acessibilidade e avaliação manual proporcional. Verifica os estados HTTP relevantes, refresh/deep link, consola, pedidos duplicados, leaks de informação e layout shift. Usa locators acessíveis e assertions orientadas a estado. Compara snapshots aprovados de mobile/desktop, temas suportados e estados normal/loading/vazio/erro/conteúdo longo; qualquer baseline nova exige revisão humana e `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`.

## Entrega

Apresenta âmbito, baseline, matriz de benchmark e padrões adotados, jornadas melhoradas, estados cobertos, componentes alterados, evidência visual, métricas antes/depois quando mensuráveis, comandos/resultados, permissões testadas, licenças e lacunas encaminhadas para o prompt de conclusão ou PWA.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/blazor/?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/blazor/progressive-web-app/?view=aspnetcore-10.0
- https://www.w3.org/WAI/ARIA/apg/
