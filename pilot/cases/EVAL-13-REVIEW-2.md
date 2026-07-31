# EVAL-13 — revisão final independente 2

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

Não recebeste o trabalho anterior. Recalcula o digest e executa
`scripts/Test-PromptPilotAttestation.ps1`. Revê e tenta refutar a candidata sem
alterar a worktree. Attestation inválida ou validação essencial ausente produz
`NO-GO`. Entrega findings e decisão apenas para esta identidade imutável.
