# EVAL-13 — corrigir findings da candidata 3

Executa o contrato de implementador de `pilot/cases/EVAL-13-IMPLEMENT.md`.

- Candidata rejeitada: `{{candidateSha}}`
- Findings separados: {{findings}}
- Build/testes: `{{buildCommand}}` / `{{testCommand}}`

Não aproves a própria candidata. Corrige apenas o âmbito aceite, valida e cria
um único novo commit limpo, sem push. A proveniência final é produzida por um
builder isolado e revista numa nova tarefa read-only.
