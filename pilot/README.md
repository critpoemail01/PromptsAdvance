# Execução de PILOT-001

Este diretório contém instruções executáveis para a avaliação definida em `PROMPT_EVALUATION.md`. Não substitui o piloto nem transforma resultados automáticos em aprovação humana.

## Isolamento

- Gera uma aplicação descartável através do template `bit-app-base`.
- Confirma restore, build, testes e commit-base limpo.
- Usa um worktree ou clone limpo por caso e por repetição.
- Executa cada caso com uma nova sessão `codex exec --ephemeral`.
- Usa `--ignore-user-config`, sandbox mínimo e nenhuma credencial de produção.
- Guarda prompt, JSONL, stderr, mensagem final, SHAs, estado Git, diff, comandos e artefactos.
- O revisor de EVAL-13 recebe apenas candidata imutável, critérios e comandos; nunca recebe o transcript do implementador.
- Um avaliador humano continua obrigatório para a rubrica e para a decisão final.

## Fixtures de produto

EVAL-05 e EVAL-06 são casos de implementação, não testes de comportamento
perante entradas ausentes. Antes de criar as respetivas worktrees, copia o
fixture adequado de `pilot/fixtures/` para `PILOT_CASE_CONTEXT.md`, regista a
aprovação específica no topo de `PRODUCT_QUALITY_BASELINE.md` e cria o
commit-base do caso. As três repetições de EVAL-06 usam exatamente o mesmo
commit de fixture. Sem este passo, um bloqueio por baseline pendente é correto,
mas não avalia a capacidade de implementar a slice.

Os fixtures só valem na aplicação descartável, não substituem descoberta,
aprovação humana ou decisões reais de uma nova aplicação.

## Runner

`-Model` é obrigatório e não possui valor implícito: todas as repetições devem
usar exatamente o mesmo identificador. O `meta.json` conserva esse valor.

Em Windows, confirma a política efetiva com um caso de escrita antes do
piloto. Se `workspace-write` for reduzido a `read-only` pela política do host,
o piloto pode usar `danger-full-access` apenas na worktree descartável e com
`-AllowDangerFullAccess` e `-IsolationRoot`. O runner confirma que a worktree é
filha dessa raiz antes de criar evidências. O opt-in fica registado no
`meta.json`; nunca o uses
no boilerplate original, numa aplicação real, com segredos, serviços externos
ou dados de produção. Os casos que testam bloqueios, migrations e revisão final
continuam em `read-only`.

Antes de EVAL-13, confirma também que o revisor read-only consegue ler o
artefacto e recalcular o SHA-256. Mantém o artefacto num caminho local à
worktree. Se comandos diretos de hashing forem bloqueados, inclui na candidata
um verificador mínimo e auditável, executado pelo próprio revisor, que falhe
quando o ficheiro faltar ou o digest divergir. Sem cálculo independente não há
`GO`.

Exemplo do fallback isolado para um caso que precisa de escrever:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-PromptPilotCase.ps1 `
  -CodexPath <codex.exe> `
  -Model gpt-5.6-sol `
  -Worktree <worktree-descartavel> `
  -CaseId EVAL-02-R2 `
  -PromptFile .\pilot\cases\EVAL-02.md `
  -ArtifactRoot <diretorio-de-evidencias> `
  -Sandbox danger-full-access `
  -AllowDangerFullAccess `
  -IsolationRoot <raiz-das-worktrees-descartaveis>
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-PromptPilotCase.ps1 `
  -CodexPath <codex.exe> `
  -Model gpt-5.6-sol `
  -Worktree <worktree-limpo> `
  -CaseId EVAL-01 `
  -PromptFile .\pilot\cases\EVAL-01.md `
  -ArtifactRoot <diretorio-de-evidencias> `
  -Sandbox workspace-write
```

O runner falha se a worktree não começar limpa. Cada diretório de evidência é imutável por convenção; uma repetição usa um novo identificador.

## Aprovação

Executa os 13 casos, as repetições de EVAL-12 e o ciclo completo de EVAL-13. Depois:

1. valida a proveniência dos artefactos;
2. pontua os seis critérios de cada caso;
3. regista falhas críticas;
4. obtém avaliação humana;
5. atualiza `PROMPT_EVALUATION.md` apenas se os limites de aprovação forem satisfeitos.

Um baseline que compila mas contém vulnerabilidades, avisos ou limitações deve registá-los antes dos casos para distinguir problemas preexistentes.
