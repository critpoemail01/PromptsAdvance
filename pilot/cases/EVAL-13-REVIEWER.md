# EVAL-13 — revisão final independente

Lê integralmente `EXECUTION_CONTRACT.md` e `prompts/11-aceitacao-e-manutencao/65-executar-revisao-final-independente.md`.

Atua como revisor separado e read-only. Recebeste apenas este repositório, os
critérios, `[BASE_SHA]`, `[CANDIDATE_SHA]`, `[ARTIFACT_PATH]`,
`[ARTIFACT_DIGEST]` e comandos de teste. Não recebeste o transcript nem o
raciocínio do implementador. Confirma que o caminho do artefacto está acessível
e recalcula o digest antes de avaliar; um digest apenas declarado não é
evidência suficiente.

Se a sandbox bloquear comandos diretos de hashing, inspeciona e executa o
verificador versionado da candidata. Confirma que calcula SHA-256 sobre o
artefacto real e falha se este faltar ou mudar. Sem uma destas verificações
independentes, a decisão é `NO-GO`.

Tenta demonstrar que a candidata está errada através do diff integral, build/testes adequados, casos negativos e integridade dos gates. Não alteres ficheiros, commits, snapshots ou critérios. Produz findings e decisão `GO`/`NO-GO` válida apenas para o SHA/digest examinados.
