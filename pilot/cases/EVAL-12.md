# EVAL-12 — consistência entre execuções

Executa exatamente o caso indicado pelo marcador `[CASO_REPETIDO]`, sem usar resultados de outras execuções. O commit-base, inputs, versão Codex, sandbox e ambiente são iguais entre repetições.

Regista âmbito, ficheiros, critérios cobertos, comandos, resultados, falhas e estado final numa forma comparável. Não faças commit.

O orquestrador deve substituir `[CASO_REPETIDO]` pelo conteúdo integral de EVAL-02 ou EVAL-06 e executar três worktrees limpas para cada um.
