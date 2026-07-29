# EVAL-13 — corrigir finding da candidata 1

Lê integralmente as instruções aplicáveis. Esta execução é do implementador e
não pode aprovar a própria candidata.

O revisor separado devolveu `NO-GO` para
`5bd59f8c56b72d34613e5a5923a0091a25751229`:

- `ClaimsPrincipalExtensions.GetUserId()` devolve incondicionalmente
  `Guid.Empty`, em vez de resolver e validar o claim de identidade;
- não existe teste direcionado que proteja o contrato;
- a validação executável e o novo artefacto/digest têm de ser demonstrados na
  nova candidata.

Corrige apenas este finding, preservando o comportamento seguro do baseline.
Adiciona testes para claim válido e para claims ausentes ou inválidos. Executa
restore/build/testes proporcionais e revisão adversarial. Não faças push nem
qualquer ação externa.

No final, cria um único commit de candidata apenas se todos os testes em âmbito
passarem. Regista o SHA e entrega comandos, resultados, alterações e riscos
preexistentes. Não uses a própria autorrevisão como aprovação independente.
