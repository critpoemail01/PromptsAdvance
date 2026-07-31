# Baseline profissional de produto, UX e UI

Esta baseline materializa o Gate G04 de [QUALITY_GATES.md](QUALITY_GATES.md). Uma decisão visual só pode ser propagada depois de satisfazer ambos os documentos com evidência da versão atual.

Validação mecânica antes de G04:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProductQualityGate.ps1
```

Este artefacto transforma o benchmark e os requisitos da aplicação em critérios mínimos aprovados e persistentes. É criado durante os prompts 1–4, confirmado antes do prompt 13 e atualizado apenas quando uma decisão de produto, evidência de utilizadores ou alteração material de plataforma justificar a mudança.

Não uses este template como uma checklist genérica. Substitui `A preencher` por critérios específicos do produto e liga cada decisão a requisitos, investigação, dados ou referências registadas. Um critério crítico sem evidência impede propagar a direção visual ou aprovar a release.

## Identificação

| Campo | Valor | Estado | Fonte/aprovação |
|---|---|---|---|
| Produto | A preencher | pendente | — |
| Versão da baseline | A preencher | pendente | — |
| Jornadas/superfícies abrangidas | A preencher | pendente | Requisitos |
| Público e contexto de uso | A preencher | pendente | Descoberta |
| Owner de produto | A preencher | pendente | — |
| Revisor de Product Design/UX | A preencher | pendente | — |
| Revisor de engenharia/frontend | A preencher | pendente | — |
| Data da aprovação | A preencher | pendente | — |

## Benchmark aprovado

| Referência | Tipo/fonte/data | Jornada comparável | Padrão observado | Problema que resolve | Evidência/limite | Adaptação aprovada | O que não copiar | Licença |
|---|---|---|---|---|---|---|---|---|
| A preencher | A preencher | A preencher | A preencher | A preencher | A preencher | A preencher | A preencher | A preencher |

Inclui normalmente aplicações profissionais comparáveis, um produto adjacente, um design system oficial e uma referência premium relevante. Popularidade, preço ou preferência estética não constituem evidência suficiente.

## Princípios de experiência

| ID | Princípio específico do produto | Problema/requisito | Comportamento observável | Métrica ou critério | Anti-padrão |
|---|---|---|---|---|---|
| XP-01 | A preencher | A preencher | A preencher | A preencher | A preencher |

Regista entre cinco e dez princípios coerentes. Resolve conflitos entre referências; não combines automaticamente “as melhores partes” de produtos diferentes.

## Rubrica mínima profissional

Classificações permitidas: `passou`, `falhou`, `bloqueado`, `não aplicável`. Um `não aplicável` exige justificação. Os itens marcados como críticos bloqueiam a propagação do layout e a release.

| Dimensão | Criticidade | Critério mínimo específico | Evidência exigida | Estado |
|---|---|---|---|---|
| Adequação ao domínio | crítica | Linguagem visual, conteúdo, densidade e interação correspondem ao trabalho real; não existe “template look” ou UI genérica de IA | Jornada renderizada + crítica | pendente |
| Arquitetura de informação | crítica | Navegação e hierarquia permitem localizar e concluir as tarefas Must sem caminhos ambíguos | Teste de tarefa + mapa | pendente |
| Eficiência operacional | crítica | Ações primárias, pesquisa, filtros, tabelas/formulários e atalhos usam controlos adequados ao tipo de dado | Cenários e métricas | pendente |
| Estados e recuperação | crítica | Loading, vazio, erro, sucesso, offline, sem permissão, sessão expirada e conteúdo extremo estão tratados quando aplicáveis | Testes + capturas | pendente |
| Mobile Web/PWA | crítica quando aplicável | Não é apenas desktop reduzido: navegação, ações alcançáveis, densidade, formulários, filtros e tabelas são repensados para toque e uso com uma mão | Mobile real + tarefas | pendente |
| Experiência nativa | crítica quando aplicável | MAUI respeita navegação, safe areas, back, ciclo de vida, permissões e convenções da plataforma | Dispositivo/emulador | pendente |
| Acessibilidade | crítica | Critérios WCAG/nativos definidos passam nos checks automáticos contínuos e na avaliação manual da jornada | Relatórios automáticos + manual | pendente |
| Consistência visual | alta | Tokens, grelha, tipografia, espaçamento, ícones e componentes formam um sistema coerente | Catálogo + diff visual | pendente |
| Conteúdo e confiança | alta | Texto é factual, claro, localizável, sem dark patterns, claims inventados ou informação legal não aprovada | Revisão de conteúdo | pendente |
| Performance e estabilidade | alta | Orçamentos da jornada são cumpridos sem layout shift ou degradação percetível não aceite | Métricas antes/depois | pendente |

## Primeira vertical slice

| Campo | Valor/evidência | Estado |
|---|---|---|
| Requisitos Must cobertos | A preencher | pendente |
| Dados/backend reais usados | A preencher | pendente |
| Atores e permissões exercitados | A preencher | pendente |
| Estados de erro/recuperação exercitados | A preencher | pendente |
| Superfícies e viewports | A preencher | pendente |
| Crítica Product Design/UX | A preencher | pendente |
| Revisão de engenharia/frontend | A preencher | pendente |
| Decisão: propagar, corrigir ou rejeitar | A preencher | pendente |

A revisão deve identificar o revisor ou tarefa separada, critérios aplicados, findings por severidade e decisões. Uma persona simulada pelo implementador não conta como opinião profissional independente.

## Teste de usabilidade

Para a principal jornada e para decisões de alto risco, executa teste de usabilidade antes de propagar o layout. Se participantes não puderem ser recrutados, regista `bloqueado` ou uma exceção explicitamente aceite com owner, prazo e risco; não declares que a usabilidade foi validada.

| Tarefa | Perfil/participantes | Métricas | Resultado observado | Finding/severidade | Correção/reteste |
|---|---|---|---|---|---|
| A preencher | A preencher | A preencher | A preencher | A preencher | A preencher |

Métricas possíveis: conclusão, erros, pedidos de ajuda, passos, tempo, confiança e recuperação. Não transformes uma amostra pequena em prova estatística global.

## Regressão visual

| Superfície/componente | Estado | Viewport/tema | Baseline aprovada | Ambiente CI | Resultado | Aprovador da alteração |
|---|---|---|---|---|---|---|
| A preencher | A preencher | A preencher | A preencher | A preencher | pendente | A preencher |

Mantém snapshots apenas para componentes e estados suficientemente estáveis. Gera e compara no mesmo sistema, versão de browser, fontes e configuração. Uma alteração de baseline exige diff revisto, razão ligada a requisito e aprovação explícita; nunca atualizes snapshots apenas para tornar a CI verde.

## Findings e exceções

| ID | Severidade | Finding/critério | Evidência | Owner | Prazo | Estado/decisão |
|---|---|---|---|---|---|---|
| QLT-001 | A preencher | A preencher | A preencher | A preencher | A preencher | aberto |

## Decisão

| Gate | Resultado | Evidência | Aprovador |
|---|---|---|---|
| Direção pronta para primeira slice | pendente | — | — |
| Primeira slice pronta para propagação | pendente | — | — |
| Baseline pronta para release | pendente | — | — |
