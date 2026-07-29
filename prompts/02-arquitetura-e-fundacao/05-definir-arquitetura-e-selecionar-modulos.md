# Definir a arquitetura e aplicar decisões de módulos

## Objetivo

Depois de os requisitos estarem aprovados, transforma `[REQUISITOS_APROVADOS]` numa arquitetura implementável para o projeto derivado de `BoilerPlateAdvance`. Por omissão, produz apenas a decisão arquitetural e os ADRs. Só altera módulos quando `[MODO]=aplicar`, existe `[ARQUITETURA_APROVADA]` e o lote `[DECISOES_A_APLICAR]` está explicitamente identificado.

## Gate obrigatório da etapa anterior

Antes de analisar ou propor arquitetura:

1. lê `PRODUCT_DEFINITION.md` e `IMPLEMENTATION_STATUS.md`;
2. confirma que o documento está `aprovado`, a decisão do Gate A é `GO` e corresponde à versão atual;
3. confirma que DOR-01 a DOR-12 têm estado `passou`, evidência e nenhuma contradição material;
4. confirma que os prompts 01–04 estão concluídos e que o próximo lote autorizado é o prompt 05.
5. executa `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProductDefinitionGate.ps1` e exige exit code 0.

Se qualquer condição falhar, se o script estiver ausente ou se o comando terminar com outro exit code, não cries ADRs, não escolhas módulos e não completes a definição em falta por inferência. Atualiza apenas o bloqueio e termina com estado `bloqueado`, indicando o prompt 01, 02, 03 ou 04 ao qual o processo deve regressar.

## Entradas e modos

- Obrigatórias para decidir: `[REQUISITOS_APROVADOS]` e restrições técnicas/operacionais conhecidas.
- Obrigatórias para aplicar: `[ARQUITETURA_APROVADA]`, `[DECISOES_A_APLICAR]` e `[MODO]=aplicar`.
- `decidir` — modo predefinido e apenas de leitura sobre código/configuração, exceto documentação/ADRs.
- `aplicar` — executa um único lote coerente de decisões já aprovadas.

Se as entradas de aplicação não estiverem completas, termina depois da proposta e marca as decisões como `aguarda aprovação`; não removas ou atives módulos.

## Critérios de sucesso

- Topologia, fronteiras, dependências, dados e trust boundaries estão documentados.
- Cada módulo de `MODULES.md` tem decisão, motivo, configuração, testes e impacto.
- Requisitos não funcionais têm critérios mensuráveis ou questões pendentes.
- Decisões estruturais relevantes ficam em ADRs curtos.
- A arquitetura evita frameworks e serviços sem requisito concreto.
- No modo `aplicar`, cada alteração corresponde a uma decisão aprovada e mantém build/testes verdes.

## Processo

1. Lê `AGENTS.md`, requisitos, `README.md`, `MODULES.md`, projetos, packages, configuração, CI e documentação da base.
2. Confirma superfícies ativas: `Client.Ssr`, `Client.Web`, `Client.Core`, `Client.Maui`, `Server.Api` e testes, adaptando nomes reais.
3. Mapeia atores, jornadas, dados, integrações, disponibilidade, segurança, privacidade, performance, escala, operação e restrições.
4. Produz:

| Capacidade | Decisão | Requisito | Projetos/configuração | Dependências | Validação | Consequência |
|---|---|---|---|---|---|---|

5. Classifica cada capacidade como `manter`, `remover`, `adiar` ou `decisão em falta`.

## Regras de decisão

- Mantém por defeito a fundação necessária à solução: API/OpenAPI/ProblemDetails, SSR público, Web/PWA, EF Core/migrations, Identity, configuração validada, health, rate limiting, headers, logging e resiliência.
- Mantém MAUI apenas se existir requisito nativo.
- Ativa providers externos, push, SMS, Azure SignalR, Azure Monitor/OTLP ou Sentry apenas com caso de uso, configuração e smoke test.
- Trata Hangfire, SignalR, attachments, OData, diagnósticos avançados e MAUI como capacidades acopladas: uma remoção deve cobrir código, configuração, packages, endpoints, recursos e testes.
- Não copies credenciais nem inventes infraestrutura.

## Fase 1 — Decisão arquitetural

Atualiza apenas documentação/ADRs dentro do âmbito. Apresenta diagrama textual da topologia, matriz de módulos, fluxos de dados, NFRs, riscos, decisões pendentes e sequência de implementação. Para perante uma decisão estrutural irreversível sem requisito suficiente.

## Fase 2 — Aplicação opcional

Executa apenas quando os pré-requisitos do modo `aplicar` estiverem cumpridos:

1. Confirma que cada item de `[DECISOES_A_APLICAR]` existe na arquitetura aprovada.
2. Aplica uma capacidade de cada vez, incluindo código, configuração, packages, endpoints, recursos, documentação e testes associados.
3. Compila e testa após cada capacidade; se falhar, corrige dentro do lote ou repõe apenas a alteração desse lote sem tocar em trabalho pré-existente.
4. Não implementes funcionalidades de negócio nem avances automaticamente para decisões seguintes.

## Validação e conclusão

Confirma no repositório cada projeto, package, serviço e workflow mencionado. Revê contradições entre requisitos, ADRs e base. Classifica o resultado como `decisão pronta`, `aplicação concluída`, `parcial` ou `bloqueado`, sempre com evidência.

## Entrega

Apresenta modo executado, topologia, matriz de módulos, ADRs, decisões pendentes e sequência recomendada. No modo `aplicar`, acrescenta decisões aplicadas, ficheiros, comandos/resultados, comportamento preservado e próximo lote ainda não executado.

## Referências oficiais

- https://learn.microsoft.com/azure/architecture/guide/
- https://learn.microsoft.com/azure/well-architected/architect-role/fundamentals
- https://c4model.com/
