# EVAL-06 — vertical slice funcional completa

Lê integralmente as instruções, o prompt 21, o prompt 27 e o prompt 28.

Implementa `PILOT-REQ-006`: uma fatia vertical pequena de notas pessoais
autenticadas. Um utilizador autenticado pode listar as próprias notas, criar
uma nota curta e apagar apenas uma nota própria. Decompõe a funcionalidade em
`RF-P` atómicos e cria exatamente um teste Playwright primário identificado por
cada `RF-P`, executado em projetos mobile, tablet e desktop e reconciliado em
`quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md`. Inclui contrato, persistência EF
Core, autorização por objeto, UI Web, loading/vazio/erro/sucesso, validação,
testes unitários/integração e observabilidade mínima. Não acrescentes partilha,
pesquisa, anexos ou notificações.

Usa migration compatível e dados de teste isolados. Valida a jornada end-to-end disponível, revê o diff adversarialmente e não faças commit.
