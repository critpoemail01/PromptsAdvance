# Começar ou continuar uma aplicação Advance

Este é o ponto de entrada do processo. Não copies prompts manualmente nem
executes os 73 de uma vez.

## Continuar um projeto por caminho

Para uma aplicação existente ou uma iniciativa já inicializada, abre
`PromptsAdvance` no Codex e envia apenas:

```text
Continua o projeto Advance em C:\Work\qqlcoisa
```

A skill resolve o caminho através de:

```powershell
.\software-lifecycle.ps1 continue -ProjectPath "C:\Work\qqlcoisa"
```

Se já existir um lifecycle associado, valida-o e prepara o prompt atual. Se não
existir, cria uma instância `brownfield` isolada em
`..\SoftwareProcesses\<nome-do-projeto>`, regista a raiz da aplicação e a
baseline Git não sensível e prepara o prompt 01. A aplicação existente, `.git`,
histórico, alterações locais e remotes não são modificados durante esta adoção.
Se esse destino cair dentro do mesmo repositório Git da aplicação, o comando
bloqueia e exige `-ProcessRoot` fora da árvore Git.

Para separar explicitamente a adoção da continuação:

```powershell
.\software-lifecycle.ps1 adopt `
  -ProjectPath C:\Work\qqlcoisa `
  -Name qqlcoisa `
  -Owner "Nome do responsável"
```

O responsável pode ficar pendente quando não foi fornecido; deve ser resolvido
no prompt 01 antes do Gate G01.

## Opção recomendada — Codex

### Instalar globalmente como plugin

Para disponibilizar `Advance App` em todos os projetos Codex, instala este
repositório como marketplace e depois instala o plugin:

```text
codex plugin marketplace add critpoemail01/PromptsAdvance
codex plugin add advance-app@promptsadvance
```

Para testar um clone local antes de publicar:

```text
codex plugin marketplace add /caminho/absoluto/PromptsAdvance
codex plugin add advance-app@promptsadvance
```

Reinicia o Codex e abre uma tarefa nova. O plugin disponibiliza
`$advance-app-start` e `$advance-app-continue` em qualquer projeto. O catálogo
é resolvido a partir do checkout do marketplace, de `PROMPTS_ADVANCE_ROOT`, de
um clone convencional ou de um caminho explícito.

### Usar a partir do catálogo

Abre esta pasta no Codex e envia:

```text
Usa $advance-app-start.
Inicia uma nova iniciativa chamada "nome-da-iniciativa".
O responsável de produto é "nome-do-responsável".
Usa o `BoilerPlateAdvance` em `/caminho/absoluto/BoilerPlateAdvance`.
Inicializa o processo e executa apenas o primeiro prompt.
```

O Codex cria uma instância isolada do processo, apresenta o caminho, prepara `NEXT_TASK.md`, executa apenas o prompt 01 e para no primeiro gate ou decisão material.

Para continuar mais tarde:

```text
Usa $advance-app-continue e continua a iniciativa em "CAMINHO_DA_INSTANCIA".
Valida o estado, executa apenas o próximo trabalho autorizado e apresenta evidências.
```

Se a instância já terminou e existe uma mudança material, cria e aprova primeiro
`changes/CHG-####/PROPOSAL.md` segundo `CHANGE_CONTROL.md`; depois usa
`software-lifecycle.ps1 cycle-start`. Não edites o estado concluído diretamente.

## Opção por PowerShell

Na raiz deste catálogo:

```powershell
.\software-lifecycle.ps1 start `
  -Name nome-da-iniciativa `
  -Owner "Nome do responsável"
```

Por omissão, a instância é criada em `../SoftwareProcesses/nome-da-iniciativa`
e usa a pasta irmã `../BoilerPlateAdvance`, resolvida para um caminho absoluto.
Para outro destino ou boilerplate:

```powershell
.\software-lifecycle.ps1 start `
  -Name nome-da-iniciativa `
  -Owner "Nome do responsável" `
  -ProcessRoot C:\Caminho\Processos\nome-da-iniciativa `
  -BoilerplatePath C:\Caminho\BoilerPlateAdvance
```

Comandos seguintes:

```powershell
.\software-lifecycle.ps1 status -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 validate -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 next -ProcessRoot C:\Caminho\Processo
```

O comando `next` cria ou atualiza `NEXT_TASK.md`. Abre uma tarefa Codex na instância e envia:

```text
Usa $advance-app-continue e executa integralmente NEXT_TASK.md.
```

`NEXT_TASK.md` exige uma tentativa estruturada antes da execução. O Codex usa:

```powershell
.\software-lifecycle.ps1 work-start -ProcessRoot C:\Caminho\Processo
```

Depois regista goals, verificações e findings através de `checkpoint`, `verify`,
`finding-add`, `finding-resolve` e `finding-gate`. A conclusão não avança
enquanto a tentativa atual não passar o closeout. Para trabalho parcial ou
bloqueado, o resultado é registado honestamente e uma nova tentativa retoma o
mesmo prompt.

Quando o estado indicar `waiting_decision`, a skill escolhe o próximo lote com
`software-lifecycle.ps1 select`, registando a vertical slice e a evidência. Não
edites `currentPrompt` manualmente.

Uma fatia exige sempre IDs de requisitos, critérios de aceitação observáveis e
exclusões explícitas. O estado preserva todas as fatias em `slices`; uma nova
seleção nunca apaga o histórico da anterior.

As transições lineares são automáticas. O comando `status` separa progresso
obrigatório, opcionais selecionados e decisões opcionais pendentes, mostra a
etapa/gates e imprime o próximo comando ou as opções permitidas. `NextPrompt`
não pode ser usado para saltar trabalho.

Para uma capacidade opcional comprovadamente fora do âmbito:

```powershell
.\software-lifecycle.ps1 decide -ProcessRoot C:\Caminho\Processo `
  -PromptId 30 -Result not_applicable `
  -Evidence "PRODUCT_DEFINITION.md: decisão CAP-030"
```

Quando todos os pré-requisitos estiverem concluídos, um gate que ocorre entre
prompts pode ser registado sem editar o estado:

```powershell
.\software-lifecycle.ps1 gate -ProcessRoot C:\Caminho\Processo `
  -GateId G05 -GateDecision passed `
  -GateEvidence "requirements/traceability.md; reports/must-journeys" `
  -ApprovedBy "Responsável identificado"
```

## O que acontece automaticamente

- criação de uma instância isolada e autocontida;
- registo dos 73 prompts e identificação dos opcionais;
- estado legível por máquina em `LIFECYCLE_STATE.json`;
- seleção do prompt atual e geração do respetivo pacote;
- validação da estrutura e do Gate A;
- bloqueio do Gate G03 enquanto `PILOT_APPROVAL.md` não provar 15/15 na versão
  atual, sem falhas críticas e com avaliação humana/revisão separada;
- validação mecânica do Gate G04 através de baseline, benchmark, rubrica
  crítica, usabilidade, acessibilidade e regressão visual;
- validação estruturada de G06–G10 através de
  `LIFECYCLE_GATE_EVIDENCE.json`, identidades e artefactos com SHA-256;
- autorização G09 antes da seleção do prompt 64 e validação pós-deploy contra
  o mesmo ambiente, candidata e digest;
- escrita atómica do estado com revisão e bloqueio de atualizações concorrentes;
- bloqueio de saltos de etapa ou conclusões sem evidência;
- atualização do progresso e preparação do próximo trabalho;
- aplicação dos gates profissionais de produto, arquitetura, UI/UX, código, segurança, release e operação.

## O que nunca é autoaprovado

- decisões materiais de produto;
- aprovação humana do layout e usabilidade;
- termos jurídicos, preços, retenção e tratamento de dados;
- criação/push GitHub sem alvo e autorização;
- alterações destrutivas ou financeiras;
- publicação em produção;
- alteração de baselines visuais;
- revisão final independente.

“Automatizado” significa que o processo descobre, prepara, executa, valida, regista e encaminha o trabalho seguro. Não significa remover decisões humanas onde a evidência exige julgamento ou autorização.
