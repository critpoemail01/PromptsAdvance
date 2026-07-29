# EVAL-13 — revisão final independente da candidata 2

Lê integralmente `EXECUTION_CONTRACT.md` e
`prompts/11-aceitacao-e-manutencao/63-executar-revisao-final-independente.md`.

Atua como um novo revisor separado e read-only. Recebeste apenas este
repositório, os critérios e identificadores abaixo. Não recebeste o transcript,
os eventos nem o raciocínio do implementador ou do revisor anterior.

- Base SHA: `f6feade9ab1c9f0bdaf9e0672d62c058b5f55217`
- Candidate SHA: `248a7fa3dc3c1284f113e0d954be7624018b7725`
- Artefacto absoluto:
  `C:\Users\joel.santos\AppData\Local\Temp\prompt-pilot-001-artifacts-v2\EVAL-13-candidate-2.nupkg`
- SHA-256 esperado:
  `EAB52EA04E09DD1B8168C00897C138459543F256C87FA0E8A4C4D0CBCBDA3647`
- Critério congelado: a candidata deve resolver e validar corretamente a
  identidade autenticada, falhar de forma segura para claims ausentes ou
  inválidos, preservar o restante baseline e incluir regressão automatizada.
- Comandos de referência:
  `dotnet build src/Tests/PilotApp.Tests.csproj -c Release --no-restore` e
  `dotnet test src/Tests/PilotApp.Tests.csproj -c Release --no-build --no-restore`.

Confirma HEAD, base, candidata, caminho do artefacto e digest calculado no teu
ambiente. Tenta demonstrar que a candidata está errada através do diff integral,
testes existentes, casos negativos e integridade dos gates. A ausência de
execução não constitui aprovação; se a sandbox impedir um comando, regista a
limitação e decide de forma conservadora.

Não alteres ficheiros, commits, snapshots, artefactos ou critérios. Produz
findings com severidade, evidência e impacto, seguidos de `GO` ou `NO-GO`,
válido apenas para o SHA e digest examinados. Confirma estado Git limpo no
início e no fim.
