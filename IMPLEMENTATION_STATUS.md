# Estado de implementação

Este ficheiro é a fonte de verdade operacional entre tarefas do Codex. Copia-o para a raiz da aplicação criada e atualiza-o no final de cada prompt. Não guardes segredos, dados pessoais nem credenciais.

## Estado atual

| Campo | Valor |
|---|---|
| Produto | A preencher |
| Repositório | A preencher |
| Remote GitHub | A preencher |
| Branch principal | A preencher |
| Commit-base | A preencher |
| Candidate SHA | A preencher |
| Digest do artefacto | A preencher |
| Etapa atual | 01 — preparação e definição |
| Último prompt concluído | Nenhum |
| Estado global | bloqueado |
| Motivo | Contexto da aplicação e destino ainda não confirmados |
| Atualizado em | A preencher |
| Atualizado por | A preencher |

Estados permitidos: `não iniciado`, `em curso`, `parcial`, `bloqueado`, `concluído` e `não aplicável`.

## Gates

| Gate | Estado | Evidência | Bloqueios |
|---|---|---|---|
| A — definição do produto | não iniciado | `PRODUCT_DEFINITION.md` pendente | Concluir prompts 01–04, DOR-01 a DOR-12 e aprovação do responsável de produto |
| B — criação/adoção da aplicação | bloqueado | — | Gate A `GO`, modo da iniciativa, arquitetura, módulos, threat model e caminhos |
| C — implementação | bloqueado | — | Aplicação, Git/GitHub baseline, comandos, baseline profissional e avaliação piloto |
| D — prontidão de release | bloqueado | — | CI, SLI/SLO, operação, documentação, candidata, aceitação e revisão independente |
| E — produção/operação contínua | bloqueado | — | Ambiente, autorização, release, verificações pós-release e owners operacionais |

Um gate só fica `concluído` quando todas as condições do `README.md` tiverem evidência. Aprovação verbal genérica não substitui alvos, requisitos ou autorizações concretas.

## Gate A — Definition of Ready para a etapa 2

Esta tabela replica o estado resumido de `PRODUCT_DEFINITION.md`; esse documento conserva a evidência detalhada. O prompt 05 fica bloqueado enquanto alguma linha não tiver `passou`.

| Critério | Estado | Evidência/bloqueio |
|---|---|---|
| DOR-01 — problema específico e comprovado | pendente | — |
| DOR-02 — público, segmento, contexto e job to be done | pendente | — |
| DOR-03 — procura, alternativas, acesso e diferenciação | pendente | — |
| DOR-04 — nome de trabalho aprovado e triado | pendente | — |
| DOR-05 — jornada, aplicações/páginas, MVP e exclusões | pendente | — |
| DOR-06 — requisitos e contratos `APP/PAGE` verificáveis | pendente | — |
| DOR-07 — NFR materiais mensuráveis | pendente | — |
| DOR-08 — métricas, meta e critério de continuar/parar | pendente | — |
| DOR-09 — orçamento, prazo, competências e viabilidade | pendente | — |
| DOR-10 — nenhuma decisão material em aberto | pendente | — |
| DOR-11 — prompts 01–04 concluídos com evidência | pendente | — |
| DOR-12 — aprovação explícita do responsável de produto | pendente | — |

Decisão atual do Gate A: `PENDENTE`. Apenas o prompt 04 pode alterá-la para `GO`, `REWORK` ou `NO-GO`.

```text
GATE_A_DECISION: PENDENTE
```

## Progresso dos prompts

| Prompt | Aplicável | Estado | Requisitos/decisões | Evidência | Bloqueios |
|---|---|---|---|---|---|
| 01-descobrir-nova-ideia-de-app | sim | não iniciado | — | — | — |

Acrescenta uma linha quando um prompt entra no plano. Não marques prompts opcionais como aplicáveis até a arquitetura ou os requisitos selecionarem o módulo.

## Requisitos

| ID | APP/PAGE/operação | Prioridade | Resumo | Critérios de aceitação | Estado | Evidência |
|---|---|---|---|---|---|---|
| A preencher | A preencher | Must/Should/Could | A preencher | A preencher | não iniciado | — |

## Fatias verticais

Mantém esta tabela alinhada com `LIFECYCLE_STATE.json.slices`. Não reutilizes
IDs nem apagues fatias concluídas.

| Slice ID | Tipo/superfície | APP/PAGE/operação | Requisitos | Critérios de aceitação observáveis | Fora do âmbito | Estado | Evidência |
|---|---|---|---|---|---|---|---|
| A preencher | page/feature; ssr/web/maui | A preencher | A preencher | A preencher | A preencher | não iniciado | — |

## Decisões

| ID | Decisão | Estado | Owner | Fonte | Impacto |
|---|---|---|---|---|---|
| DEC-001 | A preencher | pendente | A preencher | A preencher | A preencher |

## Validação executada

| Data | Âmbito | Comando ou verificação | Resultado | Evidência/limitações |
|---|---|---|---|---|
| A preencher | A preencher | A preencher | passou/falhou/não executado | A preencher |

Regista comandos exatos e resultados observados. Nunca declares uma plataforma validada quando o workload, ambiente ou serviço necessário não estava disponível.

## Manifesto de evidência da candidata

| Campo | Valor/evidência | Estado |
|---|---|---|
| Base SHA | A preencher | pendente |
| Candidate SHA | A preencher | pendente |
| Artefacto e digest | A preencher | pendente |
| Pipeline/run e timestamps | A preencher | pendente |
| Ambiente e dados de teste | A preencher | pendente |
| Comandos e exit codes | A preencher | pendente |
| Relatórios de testes/segurança/acessibilidade/performance | A preencher | pendente |
| Baseline/diff visual aprovado | A preencher | pendente |
| UAT e usabilidade | A preencher | pendente |

## Revisões

| Data | Tipo | Base/candidata | Revisor/tarefa | Separação/contexto | Working tree read-only | Decisão | Findings/evidência |
|---|---|---|---|---|---|---|---|
| A preencher | design/engenharia/adversarial independente | A preencher | A preencher | A preencher | sim/não | GO/NO-GO/pendente | A preencher |

Uma correção invalida a aprovação da candidata anterior. Regista a nova SHA/digest e uma nova revisão independente.

## Operação contínua

| Workflow | Cadência/alvo | Última execução | Estado | Evidência | Owner/próxima ação |
|---|---|---|---|---|---|
| Pós-release 30 min/24 h/7 dias | Por release | — | não iniciado | — | A preencher |
| SLI/SLO/error budget | A preencher | — | não iniciado | — | A preencher |
| Triagem operacional diária | Diária | — | não iniciado | — | A preencher |
| RUM/Core Web Vitals | Contínua | — | não iniciado | — | A preencher |
| Bugs e feedback de suporte | A preencher | — | não iniciado | — | A preencher |
| Custos e anomalias | A preencher | — | não iniciado | — | A preencher |
| Vulnerabilidades contínuas | A preencher | — | não iniciado | — | A preencher |
| Métricas DORA | A preencher | — | não iniciado | — | A preencher |

## Bloqueios e riscos

| ID | Severidade | Descrição | Condição para desbloquear | Owner | Estado |
|---|---|---|---|---|---|
| BLK-001 | alta | Contexto da aplicação ainda não confirmado | Concluir as entradas do Gate A | A preencher | aberto |

## Próximo lote

| Campo | Valor |
|---|---|
| Objetivo | Concluir o Gate A |
| Prompt | `01-descobrir-nova-ideia-de-app.md` ou o primeiro prompt aplicável |
| Entradas necessárias | Ver `APP_CONTEXT.md` |
| Fora do âmbito | Implementação funcional, publicação e ações externas |
| Critério de conclusão | Evidência do gate registada neste ficheiro |

## Histórico

| Data | Alteração | Autor | Evidência |
|---|---|---|---|
| A preencher | Estado inicial criado | A preencher | — |
