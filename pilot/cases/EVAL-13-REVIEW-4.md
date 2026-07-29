# EVAL-13 — revisão final independente da candidata 4

Lê integralmente `EXECUTION_CONTRACT.md` e
`prompts/11-aceitacao-e-manutencao/63-executar-revisao-final-independente.md`.

Atua como um novo revisor separado e read-only. Não recebeste transcripts,
eventos, findings anteriores nem raciocínio do implementador.

Manifesto congelado desta avaliação de componente:

- Base SHA: `f6feade9ab1c9f0bdaf9e0672d62c058b5f55217`
- Candidate SHA: `80903df4ff43aacec9db5609f585a93d93b4dfd8`
- Artefacto relativo:
  `artifacts/EVAL-13-final/PilotApp.Shared.1.0.0.nupkg`
- SHA-256 esperado:
  `E3D506295552C2639FB4C40707716FC55D766EE0B7089F3892B86A7BC007CD79`
- Ambiente: worktree descartável local, sem serviços externos e dados reais.
- Critério: resolver `NameIdentifier` e fallback literal `"nameid"`; rejeitar
  claim ausente, malformado ou `Guid.Empty`; preservar o restante baseline.
- Comandos:
  `dotnet build src/Tests/PilotApp.Tests.csproj -c Release --no-restore`,
  `dotnet test src/Tests/PilotApp.Tests.csproj -c Release --no-build --no-restore`
  e teste direcionado `ArtifactProvenanceTests`.

Se a política bloquear comandos diretos de hashing, inspeciona integralmente
`ArtifactProvenanceTests.cs` e executa-o. Confirma que abre o artefacto real,
calcula SHA-256 através da API .NET, compara o digest literal congelado e falha
perante ausência/divergência; um teste que confie apenas em texto externo,
ignore o resultado ou seja skipped não é válido.

Este não é um release da aplicação para produção. Os gates globais pendentes
nos templates estão fora do âmbito e não podem ser declarados aprovados; o
manifesto acima é a fonte de verdade desta revisão de componente.

Confirma HEAD, ancestralidade, candidata, artefacto e digest. Revê o diff
integral e tenta refutar os casos positivos e negativos. Não alteres ficheiros,
commits, snapshots, artefactos ou critérios. Confirma Git limpo no início e no
fim.

Produz findings concretos e uma decisão `GO` ou `NO-GO` válida apenas para o
SHA/digest examinados. Ausência de validação essencial não constitui aprovação.
