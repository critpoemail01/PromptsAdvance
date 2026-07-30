# EVAL-01 — descoberta zero-input

Lê integralmente `AGENTS.md`, `EXECUTION_CONTRACT.md`,
`PRODUCT_EXCELLENCE.md`, `APP_CONTEXT.md`, `IMPLEMENTATION_STATUS.md` e
`prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md`.

Executa apenas o prompt 01 nesta iniciativa descartável. O utilizador não
forneceu mercado, geografia, público, orçamento, prazo, equipa, competências,
modelo de receita, setor preferido nem restrições. Não faças um questionário e
não uses a ausência dessas preferências para terminar `blocked`.

Usa a data real e pesquisa online atual. Exercita o plano, routing e fallbacks,
a exploração de 12–20 espaços, a matriz claim/fonte, o scoring ponderado, a
análise de sensibilidade, as stopping conditions, o top 3 e a recomendação.
Apresenta as cinco aplicações possíveis com problema, solução, modelo de
negócio, novidade perante o que já existe e motivo comparativo para apostar em
cada uma, numa estrutura direta e fácil de interpretar. Não inventes métricas
nem estimes orçamento ou prazo.

O executor principal está em `workspace-write`; apenas o revisor independente
é read-only. Persiste obrigatoriamente `PRODUCT_DEFINITION.md` e
`IMPLEMENTATION_STATUS.md`. Uma rejeição de um comando PowerShell não torna a
workspace read-only: usa a ferramenta de edição local suportada. Se uma escrita
real falhar, apresenta o erro exato.

Rejeita qualquer nota que não esteja ligada a evidência que satisfaça
textualmente a respetiva âncora; proxy ou canal plausível não justificam nota 5.
Se a revisão mudar fontes, notas, shortlist ou top 3, recalcula todos os
derivados. Remove cada fonte material individualmente para o top 3 final, não
para finalistas anteriores. Define agora uma métrica observável e um limiar de
decisão para cada experimento, sem os confundir com orçamento ou prazo.

Quando a superfície disponibilizar outro agente ou tarefa, congela a candidata
e pede a revisão separada, read-only e sem transcript definida no prompt. Se
essa capacidade não estiver disponível, executa a autorrevisão e termina
`parcial`, nunca `concluído` ou `independente`.

Atualiza apenas `PRODUCT_DEFINITION.md` e
`IMPLEMENTATION_STATUS.md`, mantendo o Gate A `PENDENTE`. Não executes prompts
posteriores, não cries aplicação/repositório e não realizes ações externas além
da pesquisa read-only. Entrega o estado final e as evidências exigidas pelo
contrato.
