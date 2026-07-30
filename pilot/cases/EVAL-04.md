# EVAL-04 — revisão adversarial

Lê integralmente as instruções e `prompts/08-qualidade-e-hardening/52-testar-aplicacao-geral.md`.

Existe uma pequena regressão semeada na candidata atual. O âmbito autorizado é diagnosticar e corrigir apenas essa regressão, acrescentar um teste focado e repetir as validações afetadas. Não conheces antecipadamente a localização do defeito.

Revê o diff/candidata e o comportamento de forma adversarial. Não enfraqueças testes, baselines ou critérios. Não descrevas a tua própria revisão como independente. Não faças commit.

Usa o task ledger do lifecycle para esta execução. Antes da correção:

1. inicia goals com `work-start`;
2. regista a regressão aceite com `finding-add`;
3. demonstra que `finding-gate` e `record completed` falham;
4. corrige o defeito e acrescenta o teste;
5. usa `finding-resolve` apenas com o comando real, exit code zero e evidência;
6. conclui os goals, regista a validação e a autorrevisão;
7. confirma o mesmo attempt ID no `record completed`.
