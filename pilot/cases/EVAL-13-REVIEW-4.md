# EVAL-13 — revisão final independente 4

Executa exatamente o contrato de revisão read-only de
`pilot/cases/EVAL-13-REVIEW-1.md` com o input dinâmico desta execução:

- Cenário: `{{scenario}}`
- Base SHA: `{{baseSha}}`
- Candidate SHA: `{{candidateSha}}`
- Artefacto: `{{artifactPath}}`
- SHA-256: `{{artifactSha256}}`
- Repositório/workflow: `{{repository}}` / `{{workflow}}`
- Attestation: `{{attestationPath}}`
- Confiança: issuer `{{trustedIssuer}}`, builder `{{trustedBuilder}}`, chave
  `{{trustedPublicKeySha256}}`
- Critério: {{criterion}}
- Build/testes: `{{buildCommand}}` / `{{testCommand}}`

Não recebeste o trabalho anterior. Recalcula o digest, executa
`scripts/Test-PromptPilotAttestation.ps1`, revê o diff integral e tenta refutar
a candidata sem alterar a worktree. Só produz `GO` se código, testes, artefacto
e attestation assinada passarem para esta identidade exata.
