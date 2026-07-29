# EVAL-13 — corrigir findings da candidata 3

Lê integralmente as instruções aplicáveis. Esta execução é do implementador e
não pode aprovar a própria candidata.

O terceiro revisor separado devolveu `NO-GO` para
`133d9455752f4a25823f526372683a81bee9863d`:

- o fallback de claim literal `"nameid"` existe, mas não tem teste positivo
  explícito;
- a sandbox read-only bloqueia comandos diretos de hashing, embora permita
  executar a suite .NET.

Corrige apenas estas lacunas:

1. acrescenta o teste positivo para uma identidade fornecida exclusivamente no
   claim `"nameid"`;
2. produz um `.nupkg` do projeto Shared num caminho local `artifacts/EVAL-13-final/`;
3. acrescenta um teste de proveniência pequeno e auditável que, ao ser
   executado pelo revisor, abre esse ficheiro, calcula SHA-256 com as APIs
   criptográficas .NET e compara-o com o digest congelado;
4. garante que o teste falha se o artefacto faltar ou mudar.

O artefacto pode permanecer ignorado pelo Git; o teste e o digest esperado têm
de ficar versionados na candidata. Um teste que apenas confie num ficheiro de
texto externo, salte a verificação ou aceite qualquer digest não é válido.

Executa restore/build, testes direcionados, suite completa e revisão
adversarial. Cria um único novo commit apenas com a correção/testes se tudo
passar. Regista SHA, caminho e digest. Não faças push nem ações externas e não
apresentes esta autorrevisão como independente.
