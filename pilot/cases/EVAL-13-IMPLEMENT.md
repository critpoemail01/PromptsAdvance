# EVAL-13 — corrigir findings da candidata 1

Esta execução é do implementador e não pode aprovar a própria candidata.

- Candidata rejeitada: `{{candidateSha}}`
- Findings separados: {{findings}}
- Build: `{{buildCommand}}`
- Testes: `{{testCommand}}`

Corrige apenas os findings aceites, acrescenta regressões, executa as
validações e não faças push. Cria um único commit de candidata apenas se tudo
em âmbito passar. Regista o novo SHA; a attestation é emitida fora desta tarefa
por um builder isolado e será validada por outro revisor read-only.
