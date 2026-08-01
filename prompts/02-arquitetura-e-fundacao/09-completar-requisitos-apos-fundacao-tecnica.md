# Completar requisitos após observar a fundação técnica

## Objetivo

Repete de forma dirigida o método do prompt 03 para completar, corrigir e
reconciliar os requisitos com a aplicação e a fundação técnica agora
observáveis. Não recomeça a descoberta nem substitui silenciosamente decisões
aprovadas: parte dos artefactos existentes, regista apenas o delta comprovado e
preserva os IDs já atribuídos e a sua rastreabilidade.

Este passo ocorre depois dos prompts 07 e 08. Usa também a evidência dos prompts
05 e 06 quando tiverem sido selecionados.

## Entradas obrigatórias

- `PRODUCT_DEFINITION.md` e decisão atual do Gate G01;
- artefactos canónicos produzidos pelo prompt 03 em `requirements/`;
- `REQUIREMENTS_ENGINEERING_CONTRACT.md` e `TEST_STRATEGY_CONTRACT.md`;
- `IMPLEMENTATION_STATUS.md`, `APP_CONTEXT.md` e `HELP_AND_ACADEMY.md`;
- aplicação criada/adotada, comandos reais, projetos, módulos e superfícies
  confirmados pelos prompts 07 e 08;
- ADRs, threat model ou decisões técnicas existentes, quando aplicáveis;
- findings, lacunas e pressupostos deixados pelo prompt 03.

## Limites

- Lê integralmente o prompt 03 e reutiliza o seu contrato de IDs, evidência,
  aceitação, cobertura e paridade entre vistas.
- Não convertas uma limitação do boilerplate numa necessidade de produto.
- Não alteres arquitetura, providers, módulos ou comportamento executável nesta
  tarefa; devolve essas decisões ao prompt proprietário.
- Não apagues nem recicles IDs `APP/PAGE/FNC/REQ/AC/SLICE/HLP/VID/CRS`.
- Não promociones uma hipótese a `Must` apenas porque a implementação atual a
  sugere. Exige fonte, decisão e owner.
- Preserva alterações locais e não executes ações externas.

## Execução

1. Compara os artefactos do prompt 03 com a árvore real da aplicação, projetos,
   superfícies, módulos, comandos e contratos observados.
2. Classifica cada diferença como `correção factual`, `lacuna de requisito`,
   `hipótese`, `decisão técnica`, `dívida` ou `fora do âmbito`.
3. Atualiza os requisitos apenas quando a fonte e a autoridade forem
   suficientes; caso contrário, regista pergunta, owner e prompt proprietário.
4. Completa páginas, operações não visuais, dados, permissões, integrações,
   estados, recuperação, NFR, segurança, ajuda e critérios de aceitação que a
   fundação tornou concretos.
   Para regras materiais acrescenta tabelas de decisão/transição, exemplos e
   fronteiras; para NFR acrescenta estímulo, ambiente, resposta, medida e prova.
5. Reconcilia mecanicamente a especificação detalhada, contratos por aplicação
   e página, checklist do programador, `ALL_FUNCTIONALITIES.md`, catálogos e
   matrizes de cobertura, incluindo `REQUIREMENTS_QUALITY_MATRIX.md` e
   `quality/TEST_MATRIX.md` quando já existir.
   Repete exatamente o formato obrigatório
   `Projeto - PÁGINA|ECRÃ|ENDPOINT|OPERAÇÃO-NÃO-VISUAL - FUNCIONALIDADE -> ID | Quem | Onde | Quando | O quê`
   e percorre todas as superfícies e funcionalidades afetadas pelo delta, sem
   amostragem, resumos ou IDs repetidos.
6. Revê o delta adversarialmente: procura requisitos inventados a partir do
   código, IDs duplicados, páginas omitidas, contratos contraditórios e trabalho
   técnico apresentado como decisão de produto.

## Critério de conclusão

Conclui apenas quando:

- o delta entre requisitos e fundação técnica está classificado e rastreável;
- todas as alterações canónicas preservam IDs ou justificam novos IDs;
- as vistas derivadas estão em paridade com a fonte detalhada;
- o censo completo da fundação não contém página/ecrã, endpoint, operação,
  funcionalidade, ramo ou estado afetado sem cobertura ou lacuna explícita;
- decisões ainda materiais têm owner, evidência esperada e prompt proprietário;
- `IMPLEMENTATION_STATUS.md` regista resultado, evidência e trabalho restante.

Entrega primeiro uma síntese curta do que foi completado, corrigido e deixado
pendente. O detalhe permanece nos artefactos versionados do prompt 03.
