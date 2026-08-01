# EVAL-06 — vertical slice funcional com fixture aprovada

Lê integralmente as instruções, `PILOT_CASE_CONTEXT.md`, o prompt 21, o prompt
27 e o prompt 28.

Implementa `PILOT-REQ-006` exatamente segundo o contrato e a baseline aprovados
no fixture: notas pessoais autenticadas, isoladas por utilizador, com UI Web,
contrato, persistência EF Core, autorização por objeto, estados, validação,
testes e observabilidade mínima.

Cria exatamente um teste Playwright primário identificado por cada `RF-P` da
slice, executa-o em mobile, tablet e desktop e reconcilia os IDs/resultados em
`quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md`; nenhum teste pode ficar `skip` ou
`fixme`.

Não acrescentes partilha, pesquisa, edição, anexos, rich text ou notificações.
Usa migration aditiva e dados de teste isolados. Valida a jornada end-to-end
disponível, demonstra isolamento entre utilizadores, revê o diff
adversarialmente e não faças commit.
