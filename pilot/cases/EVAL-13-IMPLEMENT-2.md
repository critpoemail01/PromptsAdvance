# EVAL-13 — corrigir findings da candidata 2

Lê integralmente as instruções aplicáveis. Esta execução é do implementador e
não pode aprovar a própria candidata.

Um novo revisor separado devolveu `NO-GO` para
`248a7fa3dc3c1284f113e0d954be7624018b7725`:

- `ClaimsPrincipalExtensions.GetUserId()` aceita `Guid.Empty` como identidade
  autenticada válida;
- falta um teste negativo para esse valor sentinela;
- o digest do artefacto não foi verificável porque o revisor recebeu um caminho
  fora da worktree read-only.

Corrige apenas a validação de identidade e acrescenta a regressão automatizada.
Preserva os restantes contratos. Executa restore/build/testes proporcionais e
revisão adversarial. Gera o artefacto num caminho local à worktree que um
revisor read-only consiga ler. Não faças push nem ações externas.

No final, cria um único novo commit de candidata apenas se todos os testes em
âmbito passarem. Regista SHA, caminho relativo e SHA-256. Não uses a própria
autorrevisão como aprovação independente.
