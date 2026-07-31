# Aprovação do piloto do catálogo

Este artefacto é bloqueante para o Gate G03. Só pode ser alterado para
`approved` depois de executar os 15 cenários de `PROMPT_EVALUATION.md` sobre a
mesma versão do catálogo e obter avaliação humana e revisão separada.

| Campo | Valor |
|---|---|
| Catalog version | 2026-07-31.4 |
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
A versão 2026-07-30.5 acrescenta `ALL_FUNCTIONALITIES.md`, com o formato
obrigatório `Projeto/APP -> PAGE -> FUNCIONALIDADE ->
ID | Quem | Onde | Quando | O quê`, decomposição sem quota fixa de todos os
ramos/interações/efeitos e paridade mecânica com a especificação, contratos
PAGE, checklist e rastreabilidade. O prompt 04 passa a bloquear o Gate A perante
omissões, IDs divergentes ou linhas genéricas. Esta alteração material exige
nova execução de EVAL-15 e da suite completa.

A versão 2026-07-30.6 separa os pontos de entrada em `$advance-app-start` para
criar uma aplicação e `$advance-app-continue` para continuar ou adotar uma
instância. O inicializador, o orquestrador, a documentação e os testes passam a
copiar e exigir `.agents/skills/advance-app-continue`. A validação estrutural
numa cópia descartável não substitui a suite piloto completa, a avaliação
humana nem a revisão separada; o estado permanece `pending`.

A versão 2026-07-30.7 acrescenta investigação direta de problema/solução ao
Gate A, change control com ciclos arquivados, attestations assinadas nos gates
G07–G09, as cinco métricas DORA atuais, CI do próprio catálogo e ponte
`CLAUDE.md`. Estas alterações são materiais: exigem repetir EVAL-01, EVAL-03,
EVAL-04, EVAL-11, EVAL-13, EVAL-15 e depois a suite completa. Avaliação humana
e revisão separada continuam obrigatórias; o estado permanece `pending`.

A versão 2026-07-30.8 conclui a separação dos pontos de entrada declarada na
versão 2026-07-30.6: adiciona a skill local `$advance-app-start` para criar uma
instância greenfield e executar apenas o prompt 01, remove a inicialização da
skill `$advance-app-continue` e acrescenta oráculos estruturais que exigem as
duas skills e impedem a regressão de responsabilidades. A validação estrutural
e a repetição numa cópia descartável não substituem a suite piloto completa,
a avaliação humana nem a revisão separada; o estado permanece `pending`.

A versão 2026-07-30.9 empacota os dois pontos de entrada no plugin instalável
`advance-app`, publicado pelo marketplace `promptsadvance`, para que apareçam em
qualquer projeto Codex. As skills globais resolvem deterministicamente a fonte
canónica no checkout do marketplace, num clone configurado ou num caminho
explícito, sem pesquisa ilimitada do filesystem. O manifesto, as políticas de
instalação, o resolver e a delegação para as skills canónicas têm oráculos
estruturais próprios. A suite piloto completa, a avaliação humana e a revisão
separada permanecem obrigatórias; o estado continua `pending`.

A versão 2026-07-30.10 torna a validação do catálogo portável para checkouts
Windows limpos: fixa LF no artefacto cujo SHA-256 é validado por G06–G10 e
cria um `BoilerPlateAdvance` mínimo e descartável apenas quando os testes E2E
não encontram a base irmã real. Os testes conservam as proteções de paths e
eliminam apenas fixtures temporárias com prefixos verificados. Esta correção
faz a validação estática, o lifecycle E2E e a cópia descartável passarem sem
dependências fora do checkout, mas não executa nem aprova os 15 casos do piloto.
A avaliação humana e a revisão separada permanecem pendentes.

A versão 2026-07-31.1 integra no contrato comum e no prompt 08 um routing
explícito para documentação atual de APIs/SDKs, automação de browser e contexto
GitHub. Context7 ou documentação oficial preservam biblioteca, versão e fonte;
`playwright-cli` é uma capacidade pessoal do Codex e não uma dependência de
produção; o connector GitHub ou `gh` começam em read-only e mantêm escritas
sujeitas a alvo e autorização explícitos. O prompt proíbe configuração
silenciosa de MCPs/plugins/hooks, segredos versionados e um segundo lifecycle
concorrente. A validação estrutural desta integração não substitui os 15 casos,
a avaliação humana nem a revisão separada; o estado permanece `pending`.

A versão 2026-07-31.2 remove caminhos Windows fixos dos prompts ativos e faz o
runner descartável excluir explicitamente os metadados `.git` da origem antes
de criar a candidata isolada. Esta correção de portabilidade exige repetir os
casos afetados e a suite completa; não fornece a avaliação humana nem a revisão
separada exigidas. O estado permanece `pending`.

A versão 2026-07-31.3 introduz um contrato comum de respostas orientadas
primeiro à decisão para os 73 prompts: conclusão no início, até três razões e
riscos, opções comparáveis, prova curta e uma única próxima ação. O prompt 01
passa a conservar pesquisa, fontes e cálculos em `DISCOVERY_RESEARCH.md` e a
mostrar ao programador apenas uma tabela curta das cinco hipóteses, a recomendação
e respostas rápidas. O caso EVAL-01 e o oráculo exigem agora essa separação e os
três artefactos duráveis. Esta alteração material exige repetir EVAL-01 e a suite
completa, com avaliação humana e revisão separada; o estado permanece `pending`.

A versão 2026-07-31.4 acrescenta o percurso opcional de ajuda contextual,
conteúdo bilingue, vídeos e Academia. `HELP_AND_ACADEMY.md` define inventário
por `APP/PAGE/FNC`, IDs `HLP/VID/CRS`, perfil de produção, primeira unidade
vertical, privacidade/acessibilidade, fallback e publicação externa autorizada.
Os prompts 03–07, 09–10, 23–28, 31, 38–39, 43, 52 e 61–62 aplicam os checkpoints
correspondentes. EVAL-15 passa a exigir a matriz e a rejeitar provider, upload
ou IDs externos inventados. Esta alteração material exige repetir EVAL-15 e a
suite completa, com avaliação humana e revisão separada; o estado permanece
`pending`.
