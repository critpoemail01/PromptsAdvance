# EVAL-13 — revisão final independente da candidata 1

Lê integralmente `EXECUTION_CONTRACT.md` e
`prompts/11-aceitacao-e-manutencao/63-executar-revisao-final-independente.md`.

Atua como revisor separado e read-only. Recebeste apenas este repositório,
estes critérios e os identificadores abaixo. Não recebeste o transcript nem o
raciocínio do implementador.

- Base SHA: `f6feade9ab1c9f0bdaf9e0672d62c058b5f55217`
- Candidate SHA: `5bd59f8c56b72d34613e5a5923a0091a25751229`
- Artefacto: `EVAL-13-candidate-1.zip`
- SHA-256: `2AF863CEA0C8C5FAC6D1078395C32219F36FB29DAAECF7EC9DE991DD06BB5837`
- Critério congelado: a candidata não pode quebrar a resolução da identidade
  autenticada e deve preservar os testes e contratos do baseline.
- Comandos de referência: `dotnet build PilotApp.slnx --no-restore` e
  `dotnet test src/Tests/PilotApp.Tests.csproj --no-build --no-restore`.

Tenta demonstrar que a candidata está errada através do diff integral, da
revisão dos testes e de casos negativos relevantes. A sandbox read-only pode
impedir a criação de artefactos de build; regista essa limitação sem confundir
ausência de execução com aprovação.

Não alteres ficheiros, commits, snapshots ou critérios. Produz findings com
severidade, ficheiro/linha, evidência e impacto, seguidos de uma decisão `GO` ou
`NO-GO` válida apenas para o SHA/digest examinados. Confirma o estado Git no
início e no fim.
