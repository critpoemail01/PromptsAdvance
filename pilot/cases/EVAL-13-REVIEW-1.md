# EVAL-13 — revisão final independente 1

Lê integralmente `EXECUTION_CONTRACT.md` e
`prompts/11-aceitacao-e-manutencao/65-executar-revisao-final-independente.md`.

Atua como revisor separado e read-only. Não recebeste transcripts, eventos,
findings anteriores nem raciocínio do implementador. O input abaixo foi
renderizado pelo runner a partir de `input.json` e é válido apenas para esta
revisão:

- Cenário de proveniência: `{{scenario}}`
- Base SHA: `{{baseSha}}`
- Candidate SHA: `{{candidateSha}}`
- Artefacto relativo: `{{artifactPath}}`
- SHA-256 do artefacto: `{{artifactSha256}}`
- Repositório: `{{repository}}`
- Workflow: `{{workflow}}`
- Attestation relativa ou `absent`: `{{attestationPath}}`
- Issuer autorizado: `{{trustedIssuer}}`
- Builder autorizado: `{{trustedBuilder}}`
- SHA-256 da chave pública autorizada: `{{trustedPublicKeySha256}}`
- Critério congelado: {{criterion}}
- Build: `{{buildCommand}}`
- Testes: `{{testCommand}}`

Confirma HEAD, ancestralidade, artefacto e digest. Se existir attestation,
executa `scripts/Test-PromptPilotAttestation.ps1` com os valores congelados e
inspeciona a assinatura RSA-PSS, o artefacto, repositório, workflow, candidata,
issuer, builder e chave. Attestation ausente, alterada, não autorizada ou de
outro commit exige `NO-GO`, mesmo que o código pareça correto.

Tenta refutar a candidata pelo diff integral, testes e casos negativos. Não
alteres ficheiros, commits, artefactos, snapshots ou critérios. Confirma Git
limpo no início e no fim. Produz findings concretos e `GO`/`NO-GO` válido
apenas para o SHA, digest e attestation examinados. Termina com uma única linha
`Decision: GO` ou `Decision: NO-GO`.
