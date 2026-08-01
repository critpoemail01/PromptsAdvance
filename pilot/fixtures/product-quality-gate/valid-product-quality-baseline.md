# Valid product quality baseline fixture

## Identificação

| Campo | Valor | Estado | Fonte/aprovação |
|---|---|---|---|
| Produto | Fixture Operations | confirmado | PD-001 |
| Versão da baseline | 1.0.0 | aprovado | commit fixture-sha |
| Jornadas/superfícies abrangidas | FR-001 no Web | confirmado | traceability.md |
| Público e contexto de uso | Operadores em desktop e mobile | confirmado | research.md |
| Owner de produto | Fixture Owner | aprovado | approval/owner.md |
| Revisor de Product Design/UX | Fixture UX Reviewer | aprovado | reviews/ux.md |
| Revisor de engenharia/frontend | Fixture Engineering Reviewer | aprovado | reviews/frontend.md |
| Contrato visual aplicado | VISUAL_SLICE_CONTRACT.md | confirmado | design/slices/SLICE-001-VISUAL_BRIEF.md |
| Data da aprovação | 2026-07-28 | confirmado | approval/g04.md |

## Benchmark aprovado

| Referência | Tipo/fonte/data | Jornada comparável | Padrão observado | Problema que resolve | Evidência/limite | Adaptação aprovada | O que não copiar | Licença |
|---|---|---|---|---|---|---|---|---|
| Product A | Produto comparável, 2026-07-20 | Triagem operacional | Fila priorizada | Reduz procura | research/a.md | Prioridade explícita | Identidade visual | Apenas observação |
| Product B | Produto adjacente, 2026-07-20 | Resolução de caso | Painel contextual | Evita navegação | research/b.md | Contexto persistente | Estrutura proprietária | Apenas observação |
| Design System C | Sistema oficial, 2026-07-20 | Formulários densos | Tokens semânticos | Mantém consistência | research/c.md | Estados de foco | Componentes copiados | Licença registada |

## Princípios de experiência

| ID | Princípio específico do produto | Problema/requisito | Comportamento observável | Métrica ou critério | Anti-padrão |
|---|---|---|---|---|---|
| XP-01 | Prioridade antes de detalhe | FR-001 | A próxima ação surge primeiro | tarefa concluída | cartões decorativos |
| XP-02 | Contexto persistente | FR-001 | caso mantém contexto | sem retorno à lista | navegação em ziguezague |
| XP-03 | Erros recuperáveis | REL-001 | ação falhada pode repetir | recuperação testada | erro sem ação |
| XP-04 | Densidade ajustável | UX-001 | operador escolhe densidade | sem truncar dados | espaços arbitrários |
| XP-05 | Teclado eficiente | A11Y-001 | fluxo principal é navegável | teste de teclado passa | foco invisível |

## Rubrica mínima profissional

| Dimensão | Criticidade | Critério mínimo específico | Evidência exigida | Estado |
|---|---|---|---|---|
| Adequação ao domínio | crítica | linguagem de operações | reviews/ux.md | passou |
| Arquitetura de informação | crítica | tarefas Must localizáveis | tests/tasks.md | passou |
| Eficiência operacional | crítica | controlos adequados | tests/efficiency.md | passou |
| Estados e recuperação | crítica | oito estados exercitados | tests/states.md | passou |
| Mobile Web/PWA | crítica quando aplicável | uso por toque validado | tests/mobile.md | passou |
| Experiência nativa | crítica quando aplicável | Web não inclui MAUI neste âmbito | Justificação aprovada em approval/scope.md | não aplicável |
| Acessibilidade | crítica | WCAG no âmbito aprovado | reports/a11y.md | passou |
| Consistência visual | alta | tokens e grelha coerentes | reports/visual.md | passou |
| Conteúdo e confiança | alta | conteúdo aprovado | reviews/content.md | passou |
| Performance e estabilidade | alta | orçamento cumprido | reports/performance.md | passou |

## Primeira vertical slice

| Campo | Valor/evidência | Estado |
|---|---|---|
| Requisitos Must cobertos | FR-001 | passou |
| Brief da slice | design/slices/SLICE-001-VISUAL_BRIEF.md | passou |
| Tese da tarefa/visual/interação | resolver a fila com hierarquia operacional | passou |
| Alternativas de baixa fidelidade comparadas | design/alternatives/SLICE-001.md | passou |
| Direção selecionada, revisor e trade-offs | reviews/direction.md | passou |
| Anti-direções rejeitadas | design/anti-directions.md | passou |
| Matriz responsiva e de estados | design/responsive-state-matrix.md | passou |
| Dados/backend reais usados | tests/integration.md | passou |
| Atores e permissões exercitados | tests/authz.md | passou |
| Estados de erro/recuperação exercitados | tests/states.md | passou |
| Superfícies e viewports | reports/viewports.md | passou |
| Crítica Product Design/UX | reviews/ux.md | passou |
| Revisão de engenharia/frontend | reviews/frontend.md | passou |
| Decisão: propagar, corrigir ou rejeitar | propagar em approval/g04.md | passou |

## Teste de usabilidade

| Tarefa | Perfil/participantes | Métricas | Resultado observado | Finding/severidade | Correção/reteste |
|---|---|---|---|---|---|
| Resolver caso FR-001 | três operadores fixture | conclusão e erros | três conclusões | nenhum bloqueante | reteste passou |

## Regressão visual

| Superfície/componente | Estado | Viewport/tema | Baseline aprovada | Ambiente CI | Resultado | Aprovador da alteração |
|---|---|---|---|---|---|---|
| Fila Web | normal, erro, vazio | 390 e 1440, claro/escuro | snapshots/fixture | CI Playwright 1 | passou | Fixture UX Reviewer |

## Findings e exceções

| ID | Severidade | Finding/critério | Evidência | Owner | Prazo | Estado/decisão |
|---|---|---|---|---|---|---|
| QLT-NONE | baixa | Sem findings abertos | reviews/combined.md | Fixture Owner | 2026-07-28 | fechado |

## Decisão

| Gate | Resultado | Evidência | Aprovador |
|---|---|---|---|
| Direção pronta para primeira slice | passou | approval/direction.md | Fixture UX Reviewer |
| Primeira slice pronta para propagação | passou | approval/g04.md | Fixture Owner |
| Baseline pronta para release | passou | approval/release.md | Fixture Owner |
