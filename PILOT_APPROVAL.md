# Aprovação do piloto do catálogo

Este artefacto é bloqueante para o Gate G03. Só pode ser alterado para
`approved` depois de executar os 15 cenários de `PROMPT_EVALUATION.md` sobre a
mesma versão do catálogo e obter avaliação humana e revisão separada.

| Campo | Valor |
|---|---|
| Catalog version | 2026-07-30.4 |
| Status | pending |
| Suite cases | pending |
| Critical failures | pending |
| Human evaluator | pending |
| Independent reviewer | pending |
| Evidence | pilot/PILOT-001-EXECUTION.md |
| Approved at | pending |

Motivo atual: o modo brownfield/path-based continue alterou materialmente o
orquestrador, a skill e o prompt 07. As versões 2026-07-29.2 a 2026-07-29.7
reforçaram o prompt 02 com verificação específica de `.com`, custo, evidência
OVHcloud/RDAP, benchmark de nomes reconhecidos com proteção contra imitações e
triagem fonética online contra nomes mecânicos, diversidade entre famílias de
naming, pesquisa de colisões nos componentes significativos e um gate
eliminatório contra neologismos opacos. A versão 2026-07-29.7 tornou o prompt
mais conciso e determinístico, acrescentou registo retomável, estados por
candidato, pesquisa em funil, revalidação final, defesa contra instruções
externas e EVAL-14. A versão 2026-07-29.8 reestruturou o prompt 03, acrescentou
um contrato verificável para pesquisa, requisitos, aplicações e páginas, e
introduziu EVAL-15 para pesquisa comparável/premium, inventário do boilerplate e
proteção contra promoção indevida de referências. As verificações direcionadas
não substituem a repetição dos 15 cenários, a avaliação humana e a revisão
separada nesta versão. A versão 2026-07-29.9 acrescentou relógio verificável,
licença oficial e reconciliação mecânica dos mapeamentos depois de EVAL-15-R1
detetar timestamps futuros e destinos BPP/BPR contraditórios. A versão
2026-07-29.10 tornou o prompt 03 autocontido após a remoção intencional do
contrato auxiliar e confirmou `C:\Work\BoilerPlateAdvance` como localização
canónica da base. Estas alterações materiais exigem repetir
EVAL-15 e a suite completa. A versão 2026-07-29.11 acrescentou a vista derivada
`DEVELOPER_REQUIREMENTS_CHECKLIST.md`, com requisitos organizados por página e
funcionalidade e paridade obrigatória com a especificação detalhada. A nova
saída e o oráculo associado exigem nova execução de EVAL-15 e dos 15 casos.
A versão 2026-07-30.1 tornou o prompt 01 uma descoberta zero-input orientada a
pesquisa online atual de procura, adoção, queixas, fragilidades e fragmentação.
Mercado, público, equipa, monetização, restrições, orçamento e prazo deixaram de
bloquear o arranque; orçamento e prazo transitam para o DOR-09 antes do Gate A.
Esta alteração do comportamento de descoberta exige repetir EVAL-01 e a suite
completa.
A versão 2026-07-30.2 acrescentou ao início do prompt 01 planeamento por etapas,
execução autónoma como objetivo único e validação adversarial com critérios
explícitos de separação para qualquer alegação de independência. EVAL-01 e a
suite completa devem ser repetidos.
A versão 2026-07-30.3 otimizou o prompt 01 para o Codex/GPT-5.6 com resultado e
critério de conclusão explícitos, routing e fallbacks de pesquisa, pontuação
ponderada reproduzível, análise de sensibilidade, stopping conditions e formato
de entrega orientado à decisão. A revisão separada passou a ser obrigatória para
o estado `concluído`; sem essa capacidade, o resultado permanece `parcial`.
O caso executável EVAL-01 foi alinhado com a descoberta zero-input e o oráculo
passou a limitar tracked, renames, untracked e commits aos dois artefactos
autorizados, incluindo alterações em ficheiros ignorados por Git através de
snapshots SHA-256 e novos objetos Git `commit`, mesmo após reset. Os bloqueios
antigos do prompt 07 ficaram cobertos pelo caso executável EVAL-11. EVAL-01 e a
suite completa devem ser repetidos. A lista das cinco aplicações passou também
a exigir uma explicação uniforme e objetiva de problema, solução, modelo de
negócio, novidade e razão comparativa para apostar.

A versão 2026-07-30.4 integrou um task ledger nativo no lifecycle: cada prompt
passa a ter uma tentativa estruturada com goals, verificações, autorrevisão
adversarial e findings. `record completed` deve falhar sem closeout da mesma
tentativa ou enquanto existir um finding aberto/bloqueado. EVAL-04, EVAL-11 e a
suite completa têm de ser repetidos numa cópia descartável; avaliação humana e
revisão separada continuam obrigatórias. O estado permanece `pending`.
