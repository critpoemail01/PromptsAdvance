# Definição aprovada do produto

Este é o artefacto de passagem entre a etapa 1 — preparação e definição — e a etapa 2 — arquitetura e fundação. Os prompts 01–03 constroem-no progressivamente e o prompt 04 audita-o. O prompt 05 não pode começar enquanto o Gate A não tiver decisão `GO`.

Não uses este documento como espaço para ideias soltas. Cada afirmação material deve indicar uma fonte, uma decisão aprovada ou um pressuposto ainda por validar. Mantém detalhes e matrizes extensas nos artefactos próprios e liga-os aqui.

## Estado do Gate A

| Campo | Valor |
|---|---|
| Versão da definição | A preencher |
| Estado do documento | rascunho |
| Decisão do Gate A | PENDENTE |
| Responsável de produto | A preencher |
| Aprovador | A preencher |
| Data da decisão | A preencher |
| Evidência da aprovação | A preencher |

Registo de controlo lido pelo gate automático; mantém-no sincronizado com a tabela:

```text
GATE_A_VERSION: PENDENTE
GATE_A_DOCUMENT_STATUS: rascunho
GATE_A_DECISION: PENDENTE
GATE_A_PRODUCT_OWNER: PENDENTE
GATE_A_APPROVER: PENDENTE
GATE_A_DECISION_DATE: PENDENTE
GATE_A_APPROVAL_EVIDENCE: PENDENTE
```

Estados permitidos para o documento: `rascunho`, `em validação`, `aprovado` ou `rejeitado`.

Decisões permitidas para o Gate A:

- `PENDENTE` — a definição ainda não foi auditada;
- `GO` — todos os critérios bloqueantes passaram e a etapa 2 pode começar;
- `NO-GO` — a oportunidade foi rejeitada;
- `REWORK` — existem lacunas concretas que devem regressar aos prompts 01, 02 ou 03.

## 1. Problema e oportunidade

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Problema principal | A preencher | A preencher | pendente |
| Quem sofre o problema | A preencher | A preencher | pendente |
| Contexto e frequência | A preencher | A preencher | pendente |
| Alternativa atual | A preencher | A preencher | pendente |
| Porque resolver agora | A preencher | A preencher | pendente |

## 2. Público, mercado e trabalho a realizar

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Público principal | A preencher | A preencher | pendente |
| Segmento inicial | A preencher | A preencher | pendente |
| Mercado/geografia | A preencher | A preencher | pendente |
| Job to be done principal | A preencher | A preencher | pendente |
| Contexto de utilização | A preencher | A preencher | pendente |
| Acesso plausível ao público | A preencher | A preencher | pendente |

## 3. Proposta de valor e diferenciação

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Proposta de valor | A preencher | A preencher | pendente |
| Resultado prometido | A preencher | A preencher | pendente |
| Diferenciação defensável | A preencher | A preencher | pendente |
| Concorrentes/alternativas principais | A preencher | A preencher | pendente |
| Razões para acreditar | A preencher | A preencher | pendente |

## 4. Identidade inicial

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Nome público aprovado para trabalho | A preencher | A preencher | pendente |
| Nome técnico provisório | A preencher | A preencher | pendente |
| Posicionamento | A preencher | A preencher | pendente |
| Riscos de nome, domínio ou marca | A preencher | A preencher | pendente |
| Validações ainda necessárias | A preencher | A preencher | pendente |

O Gate A não exige registo jurídico da marca, compra de domínio ou disponibilidade futura garantida. Exige um nome de trabalho aprovado, riscos conhecidos e ausência de conflito material encontrado na triagem realizada.

## 5. Âmbito do primeiro produto

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Objetivo do MVP | A preencher | A preencher | pendente |
| Jornada principal ponta a ponta | A preencher | A preencher | pendente |
| Resultado observável para o utilizador | A preencher | A preencher | pendente |
| Aplicações/superfícies do MVP | A preencher | A preencher | pendente |
| Páginas/ecrãs e operações não visuais do MVP | A preencher | A preencher | pendente |
| Mapa de navegação e passos da jornada | A preencher | A preencher | pendente |
| Incluído no MVP | A preencher | A preencher | pendente |
| Explicitamente fora do MVP | A preencher | A preencher | pendente |
| Orçamento e prazo | A preencher | A preencher | pendente |
| Competências e restrições | A preencher | A preencher | pendente |

## 6. Requisitos aprovados

Liga aqui a especificação e a matriz produzidas pelo prompt 03.

| Campo | Valor/evidência | Estado |
|---|---|---|
| Especificação versionada | A preencher | pendente |
| Checklist do programador por página/funcionalidade | A preencher | pendente |
| Matriz de rastreabilidade | A preencher | pendente |
| Catálogo e contratos `APP` | A preencher | pendente |
| Catálogo e contratos `PAGE` | A preencher | pendente |
| Cobertura `jornada × APP × PAGE/operação` | A preencher | pendente |
| Estados, ações e fatias downstream por página | A preencher | pendente |
| Requisitos `Must` aprovados | A preencher | pendente |
| Requisitos não funcionais bloqueantes | A preencher | pendente |
| Atores e permissões iniciais | A preencher | pendente |
| Dados sensíveis e obrigações conhecidas | A preencher | pendente |

Cada requisito `Must` deve ter ID estável, fonte, critério de aceitação
observável, prioridade, dependências, `APP/PAGE` ou operação não visual e estado
aprovado. Todas as aplicações e páginas/ecrãs do MVP devem ter contrato,
estados aplicáveis, rastreabilidade e fatia downstream. A checklist do
programador e `requirements/ALL_FUNCTIONALITIES.md` devem representar todos os
`Must` sem alterar ou omitir a especificação detalhada. O ficheiro único deve
decompor cada funcionalidade em linhas concretas `ID | Quem | Onde | Quando |
O quê`, sem comprimir ramos ou efeitos materialmente distintos. Uma lista de
funcionalidades ou ecrãs sem estes elementos não satisfaz o gate.

## 7. Métricas e validação

| Campo | Definição | Fonte/evidência | Estado |
|---|---|---|---|
| Métrica primária de resultado | A preencher | A preencher | pendente |
| Baseline ou método para a obter | A preencher | A preencher | pendente |
| Meta e horizonte temporal | A preencher | A preencher | pendente |
| Métricas de proteção | A preencher | A preencher | pendente |
| Experimento anterior à implementação | A preencher | A preencher | pendente |
| Critério para continuar/parar | A preencher | A preencher | pendente |

## 8. Riscos, pressupostos e decisões

| ID | Tipo | Descrição | Evidência atual | Como validar/mitigar | Owner | Bloqueia |
|---|---|---|---|---|---|---|
| A preencher | risco/pressuposto/decisão | A preencher | A preencher | A preencher | A preencher | sim/não |

Decisões em aberto sobre problema, público, jornada principal, requisitos `Must`, dados sensíveis, permissões, legalidade, viabilidade, orçamento ou prazo bloqueiam o Gate A. Uma questão reversível pode transitar apenas com pressuposto explícito, owner, prazo e teste.

## Checklist bloqueante da passagem para a etapa 2

| ID | Critério | Estado | Evidência | Bloqueio/ação |
|---|---|---|---|---|
| DOR-01 | Existe um único problema principal, específico e sustentado por evidência atual | pendente | A preencher | A preencher |
| DOR-02 | Público, segmento inicial, contexto e job to be done estão concretamente definidos | pendente | A preencher | A preencher |
| DOR-03 | Alternativas, procura, acesso ao público e diferenciação foram validados sem confundir pressupostos com factos | pendente | A preencher | A preencher |
| DOR-04 | Existe um nome de trabalho aprovado e a triagem realizada não encontrou conflito material | pendente | A preencher | A preencher |
| DOR-05 | A jornada principal, o resultado, as aplicações, páginas/operações, o âmbito do MVP e as exclusões são inequívocos | pendente | A preencher | A preencher |
| DOR-06 | Todos os requisitos `Must` e contratos `APP/PAGE` têm ID, fonte, critérios observáveis, estados, dependências, fatia downstream e aprovação; a checklist e `ALL_FUNCTIONALITIES.md` têm paridade comprovada, sem funcionalidades, ramos ou efeitos omitidos | pendente | A preencher | A preencher |
| DOR-07 | Segurança, privacidade, acessibilidade, desempenho, operação e outras NFR materiais têm requisitos mensuráveis ou decisão bloqueante | pendente | A preencher | A preencher |
| DOR-08 | Métrica de resultado, baseline/método, meta, horizonte e critério de continuar/parar estão definidos | pendente | A preencher | A preencher |
| DOR-09 | Orçamento, prazo, competências e adequação ao `BoilerPlateAdvance` tornam o primeiro corte plausível | pendente | A preencher | A preencher |
| DOR-10 | Não existem conflitos ou decisões materiais em aberto; exceções reversíveis têm owner, prazo e teste | pendente | A preencher | A preencher |
| DOR-11 | Os prompts 01, 02, 03 e 04 têm estado e evidências registados em `IMPLEMENTATION_STATUS.md` | pendente | A preencher | A preencher |
| DOR-12 | O responsável de produto aprovou explicitamente esta versão da definição | pendente | A preencher | A preencher |

Estados permitidos: `passou`, `falhou` ou `não verificável`. `Não aplicável` exige justificação e não pode ser usado para evitar um critério material.

## Regra de decisão

O prompt 04 só pode definir:

```text
Estado do documento: aprovado
Decisão do Gate A: GO
GATE_A_DOCUMENT_STATUS: aprovado
GATE_A_DECISION: GO
```

quando DOR-01 a DOR-12 tiverem `passou`, com evidência rastreável, e não existir qualquer bloqueio material aberto.

Se um critério falhar ou não for verificável:

1. mantém a decisão `REWORK` ou usa `NO-GO` quando a oportunidade tiver sido rejeitada;
2. identifica exatamente o prompt 01, 02 ou 03 que deve ser repetido;
3. regista o bloqueio em `IMPLEMENTATION_STATUS.md`;
4. não inicia arquitetura, seleção de módulos, threat model técnico ou criação do projeto.

## Histórico de aprovação

| Versão | Data | Decisão | Responsável/aprovador | Alterações materiais | Evidência |
|---|---|---|---|---|---|
| A preencher | A preencher | PENDENTE | A preencher | Documento inicial | A preencher |
