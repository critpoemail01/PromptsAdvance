# Aprovação do piloto do catálogo

Este artefacto é bloqueante para o Gate G03. Só pode ser alterado para
`approved` depois de executar os 15 cenários de `PROMPT_EVALUATION.md` sobre a
mesma versão do catálogo e obter avaliação humana e revisão separada.

| Campo | Valor |
|---|---|
| Catalog version | 2026-07-29.11 |
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
