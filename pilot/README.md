# Execução de PILOT-001

Este diretório contém instruções executáveis para a avaliação definida em `PROMPT_EVALUATION.md`. Não substitui o piloto nem transforma resultados automáticos em aprovação humana.

## Isolamento

- Cria uma baseline descartável com `scripts/New-PromptPilotBaseline.ps1` a
  partir do `BoilerPlateAdvance` atual; o script regista o SHA/estado da origem,
  normaliza lockfiles, executa o perfil Web e cria um commit-base limpo.
- Confirma a baseline com `scripts/Test-PromptPilotBaseline.ps1` antes de
  EVAL-01. O pre-check usa `BoilerPlateAdvance.Web.slnf`, não a solução completa:
  MAUI/Android/iOS só entram num piloto específico de mobile com workloads e
  signing disponíveis.
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
worktree. Gera a attestation com `scripts/New-PromptPilotAttestation.ps1` fora
da tarefa do implementador e valida-a com
`scripts/Test-PromptPilotAttestation.ps1`. O verificador liga assinatura RSA,
chave autorizada, issuer, builder, repositório, workflow, candidate SHA e
digest do artefacto. Sem esta verificação independente não há `GO`.

## Baseline portátil

```powershell
pwsh -NoProfile -File .\scripts\New-PromptPilotBaseline.ps1 `
  -SourcePath <BoilerPlateAdvance> `
  -DestinationPath <raiz-isolada>/repos/PilotApp

pwsh -NoProfile -File .\scripts\Test-PromptPilotBaseline.ps1 `
  -ProjectPath <raiz-isolada>/repos/PilotApp
```

O primeiro comando cria um novo destino e nunca substitui uma execução
anterior. `PILOT_BASELINE.json` conserva a proveniência da snapshot e os
comandos usados. Warnings e vulnerabilidades preexistentes continuam a ser
registados e avaliados; excluir MAUI do perfil Web não os transforma em passes.

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
  -CaseId EVAL-01-R2 `
  -PromptFile .\pilot\cases\EVAL-01.md `
  -ArtifactRoot <diretorio-de-evidencias> `
  -Sandbox workspace-write
```

EVAL-01-R2 deve alterar exatamente `DISCOVERY_RESEARCH.md`,
`PRODUCT_DEFINITION.md` e `IMPLEMENTATION_STATUS.md`; deixar a worktree limpa
já não é o resultado esperado, porque o prompt 01 conserva a descoberta nesses
artefactos. A revisão humana confirma que a resposta começa pela decisão, que
as cinco hipóteses são curtas e comparáveis, que o detalhe ficou no artefacto,
e ainda qualidade e atualidade das fontes, coerência do scoring, sensibilidade,
separação da revisão e ausência de métricas inventadas.

O runner falha se a worktree não começar limpa. Cada diretório de evidência é imutável por convenção; uma repetição usa um novo identificador.

## Cadeia dinâmica de EVAL-13

Os casos EVAL-13 já não contêm SHAs, paths ou digests de uma máquina histórica.
Cria um `input.json` por execução a partir dos exemplos em
`pilot/fixtures/eval-13/` e passa-o ao runner com `-CaseInputFile`. O runner
renderiza o prompt, rejeita tokens em falta e grava o digest do input no
`meta.json`.

As quatro revisões exercitam, por esta ordem, `missing`, `tampered`,
`unauthorized-wrong-commit` e `valid`. Entre revisões, o implementador recebe
apenas os findings aceites da execução anterior e cria uma nova candidata. A
attestation é criada fora da tarefa do implementador:

```powershell
pwsh -NoProfile -File .\scripts\New-PromptPilotSigningKey.ps1 `
  -OutputDirectory <raiz-isolada-fora-das-worktrees>/eval-13-signing-key

pwsh -NoProfile -File .\scripts\New-PromptPilotAttestation.ps1 `
  -Worktree <worktree-da-candidata> `
  -ArtifactPath <artefacto-local> `
  -OutputPath <caminho-ignorado-na-worktree>/attestation.json `
  -RepositoryIdentity local://advance-pilot `
  -WorkflowIdentity pilot/eval-13 `
  -Issuer advance-pilot-issuer `
  -Builder advance-pilot-builder `
  -PrivateKeyPath <raiz-isolada-fora-das-worktrees>/eval-13-signing-key/private-key.pem
```

Congela o digest da chave pública antes da primeira candidata e usa-o em todas
as revisões; a chave privada nunca entra na worktree, prompt, output ou Git.
Usa os valores JSON devolvidos pela attestation para renderizar a revisão. Para os cenários
negativos, altera apenas a fixture da attestation: assinatura adulterada na
revisão 2; issuer/builder/chave não autorizados e outro candidate SHA na revisão
3. A revisão 4 usa a attestation válida. O oráculo recalcula tudo e falha se a
cadeia Git, o artefacto, o input ou a assinatura não coincidirem.

## Validação do task ledger

Em EVAL-04, conserva o `LIFECYCLE_STATE.json` antes do finding, com o finding
aberto, depois da resolução e depois de `record completed`. Guarda também o
output e exit code de `finding-gate` e da tentativa de conclusão bloqueada.

Em EVAL-11, executa os bypasses numa instância descartável separada: sem
`work-start`, goals incompletos, verificação ausente, autorrevisão ausente,
finding aberto e pointers/IDs/evidência corrompidos. Confirma que cada comando
falha sem avançar `currentPrompt`, gates ou slices.

## Validação dirigida de EVAL-14

Depois de executar EVAL-14, valida a proveniência, o fail-closed, o estado do
lifecycle, a resistência à fixture adversarial e a integridade da captura:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\Test-Prompt02PilotArtifact.ps1 `
  -ArtifactCaseRoot <diretorio-de-evidencias-EVAL-14> `
  -Worktree <worktree-descartavel-EVAL-14> `
  -ExpectedModel gpt-5.6-sol
```

O teste automático não avalia se um nome soa bem e não aprova o piloto. Guarda
o resultado para o avaliador humano juntamente com os artefactos brutos.

## Validação dirigida de EVAL-15

Depois de executar EVAL-15, valida a proveniência, os artefactos modulares, a
separação entre fontes/hipóteses/aprovação, o inventário do boilerplate e a
resistência à fixture premium adversarial. Valida também que ajuda contextual,
vídeo e Academia ficam ligados a `APP/PAGE/FNC`, idiomas, fallback e estados
honestos, sem publicação externa durante requisitos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\Test-Prompt03PilotArtifact.ps1 `
  -ArtifactCaseRoot <diretorio-de-evidencias-EVAL-15> `
  -Worktree <worktree-descartavel-EVAL-15> `
  -ExpectedModel gpt-5.6-sol
```

O oráculo automático verifica estrutura e evidência conservada; a qualidade da
pesquisa, dos requisitos e das decisões continua sujeita à rubrica humana.

## Aprovação

Executa os 15 casos, as repetições de EVAL-12 e o ciclo completo de EVAL-13. Depois:

1. valida a proveniência dos artefactos;
2. pontua os seis critérios de cada caso;
3. regista falhas críticas;
4. obtém avaliação humana;
5. atualiza `PROMPT_EVALUATION.md` apenas se os limites de aprovação forem satisfeitos.

Um baseline que compila mas contém vulnerabilidades, avisos ou limitações deve registá-los antes dos casos para distinguir problemas preexistentes.
