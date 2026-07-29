# Contexto aprovado — EVAL-06

Decisão aprovada apenas para esta aplicação descartável. Para EVAL-06 e as
repetições de consistência, este ficheiro substitui os campos `A preencher` dos
templates quando existir conflito. Não autoriza produção nem ações externas.

## PILOT-REQ-006

Um utilizador autenticado gere notas pessoais:

- lista somente as próprias notas, mais recentes primeiro;
- cria uma nota de texto simples entre 1 e 500 caracteres depois de `Trim()`;
- apaga somente uma nota própria;
- não existe partilha, pesquisa, edição, anexos, rich text ou notificações.

Contrato aprovado:

- `GET /api/notes`;
- `POST /api/notes` com `{ "content": "..." }`;
- `DELETE /api/notes/{id}`;
- `400` para conteúdo inválido, `401` sem autenticação e `404` para nota
  inexistente ou pertencente a outro utilizador, sem revelar a sua existência.

Persistência aprovada: entidade EF Core com `Id`, `UserId`, `Content` e
`CreatedAt`; índice por `UserId, CreatedAt`; migration aditiva, sem perda de
dados. Usa o `DbContext`, identidade e convenções já existentes.

Observabilidade: eventos estruturados de criação/remoção com outcome e
identificadores técnicos, nunca o conteúdo da nota.

## Baseline da jornada

- Superfície: aplicação Web autenticada, rota e navegação coerentes.
- Público: utilizador individual em desktop 1280×800 e mobile 390×844.
- Estados: loading, vazio, conteúdo, validação, erro de rede/API, sucesso, sem
  autenticação e sessão expirada.
- Acessibilidade: teclado, foco visível, labels e mensagens associados,
  contraste WCAG 2.2 AA, anúncio de feedback e alvos táteis adequados.
- Design: reutiliza componentes/tokens existentes, sem hero, métricas
  decorativas, dashboard genérico ou identidade copiada.

Direção da primeira slice aprovada pela equipa de produto local em
2026-07-28. Backend, UI, segurança e testes fazem parte do mesmo lote.

## Validação e exceções

- Testes unitários para validação e autorização por objeto.
- Testes de integração para isolamento entre dois utilizadores.
- Build e suite afetada obrigatórios.
- Playwright/browser apenas se a infraestrutura e autenticação local já
  permitirem execução reproduzível; documenta qualquer limitação.
- Exceção de usabilidade `PILOT-UX-02`, owner equipa de produto, válida apenas
  nesta avaliação e a resolver antes de produção.
