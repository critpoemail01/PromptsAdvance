# Instruções do projeto para o Codex

## Leitura obrigatória

Antes de executar qualquer tarefa:

1. Quando `LIFECYCLE_STATE.json` existir, usa a skill `advance-app-continue`, executa `software-lifecycle.ps1 status` e `validate`, e trabalha apenas no prompt atual preparado em `NEXT_TASK.md`.
   Quando o pedido for `Continua o projeto Advance em <caminho>` e o caminho
   ainda não tiver lifecycle, usa `software-lifecycle.ps1 continue
   -ProjectPath <caminho>` para criar uma instância brownfield isolada; não
   executes `start` dentro da aplicação nem copies o boilerplate por cima.
2. Lê integralmente o [EXECUTION_CONTRACT.md](EXECUTION_CONTRACT.md) e aplica-o como contrato comum de planeamento, autonomia, validação adversarial e entrega.
3. Se a tarefa afetar produto, requisitos, marca, conteúdo, UI, UX, jornadas, emails, monetização ou retenção, lê integralmente o [PRODUCT_EXCELLENCE.md](PRODUCT_EXCELLENCE.md).
4. Antes de qualquer tarefa da etapa 2 ou posterior, lê o [PRODUCT_DEFINITION.md](PRODUCT_DEFINITION.md) e executa `scripts/Test-ProductDefinitionGate.ps1`. Só prossegue se o comando terminar com exit code 0, confirmando documento `aprovado`, Gate A `GO`, DOR-01 a DOR-12 e prompts 01–04 concluídos com evidência. Se falhar ou estiver ausente, não preenchas a lacuna dentro da tarefa seguinte: termina `bloqueado` e remete para o prompt 01, 02, 03 ou 04 aplicável.
5. Antes de aprovar arquitetura, UI, implementação, hardening, release ou operação, lê [QUALITY_GATES.md](QUALITY_GATES.md) e aplica o gate correspondente do [PROCESS_MANIFEST.json](PROCESS_MANIFEST.json).
   Para G06–G10, atualiza e valida `LIFECYCLE_GATE_EVIDENCE.json`; texto livre em `GateEvidence` não substitui identidades, hashes, candidata, autorização ou artefactos exigidos.
6. Para tarefas de produto ou experiência posteriores à descoberta, lê também o [PRODUCT_QUALITY_BASELINE.md](PRODUCT_QUALITY_BASELINE.md) e usa a versão aprovada como gate mensurável.
   Quando ajuda contextual, vídeos de utilização ou Academia estiverem em
   âmbito, lê também [HELP_AND_ACADEMY.md](HELP_AND_ACADEMY.md) e aplica a matriz,
   o perfil de produção, os limites de publicação e a Definition of Done.
7. Lê o `APP_CONTEXT.md` quando existir e resolve apenas os valores necessários ao prompt atual.
8. Lê o `IMPLEMENTATION_STATUS.md` quando existir para conhecer decisões, evidências, bloqueios e trabalho já concluído.
9. Antes de concluir o Gate G03 ou depois de alterar materialmente este processo, lê e executa o `PROMPT_EVALUATION.md` numa cópia descartável. Exige `PILOT_APPROVAL.md` aprovado para a mesma `catalogVersion` e executa `scripts/Test-ImplementationReadinessGate.ps1`; uma revisão estática não aprova o piloto.
10. Lê os `AGENTS.md` ou `AGENTS.override.md` mais próximos dos ficheiros afetados. Regras locais mais específicas complementam estas instruções.
11. Depois de existir uma definição aprovada, lê `CHANGE_CONTROL.md` antes de
    alterar requisitos, arquitetura, contratos, baselines, segurança, operação
    ou comportamento lançado. Numa instância concluída, inicia um novo ciclo
    apenas com `software-lifecycle.ps1 cycle-start` e proposta `CHG` aprovada.

Se `EXECUTION_CONTRACT.md` estiver ausente, não inicies alterações: limita-te a identificar a falta e termina como `bloqueado`. Aplica o mesmo comportamento a uma tarefa de produto/experiência se `PRODUCT_EXCELLENCE.md` estiver ausente. A etapa 2 e todas as posteriores ficam bloqueadas se `PRODUCT_DEFINITION.md` estiver ausente, incompleto ou sem `GO`. Depois da descoberta, uma tarefa que altere uma experiência crítica fica igualmente bloqueada se `PRODUCT_QUALITY_BASELINE.md` estiver ausente ou sem critérios aprovados para essa superfície. Se outro ficheiro referenciado estiver ausente, não inventes o seu conteúdo; prossegue apenas quando a tarefa continuar segura e verificável.

## Regras duradouras

- Usa código, configuração executada, testes, documentação aprovada e decisões registadas como fontes de verdade.
- Trata valores entre `[COLCHETES]` como entradas a resolver, não como texto decorativo.
- Executa um único lote coerente por tarefa e mantém alterações fora do âmbito intactas.
- Preserva alterações locais e distingue falhas introduzidas pela tarefa de falhas preexistentes.
- Não coloques segredos, credenciais, dados pessoais ou configuração privada em prompts, código, logs ou documentação versionada.
- Não inventes comandos. Descobre e usa os comandos reais do repositório.
- Não executes ações externas, destrutivas, financeiras ou de produção sem alvo e autorização explícitos.
- Não uses nomes de modos da interface como substituto de um plano, critérios de conclusão ou autorizações concretas.
- Mantém as validações específicas no prompt da tarefa; não copies para cada prompt o contrato comum inteiro.
- Em experiências visíveis, pesquisa padrões atuais de produtos profissionais comparáveis e adapta-os sem copiar identidade, código ou assets.
- Implementa funcionalidades em cortes verticais pequenos e completos. Não concluas antecipadamente todos os layouts contra dados, permissões ou erros simulados quando a jornada real ainda não existe.
- Em alterações de UI, mantém acessibilidade automatizada contínua e regressão visual dos componentes/estados estáveis; baselines só mudam com revisão explícita.
- Criar repositórios remotos, adicionar ou substituir `origin`, fazer commit/push e alterar regras do GitHub são ações externas: exige alvo exato e autorização explícita, verifica conflitos e nunca uses `force push`.
- A candidata de produção exige revisão final independente, read-only e sobre commit/artefacto imutável. O revisor não corrige a própria candidata; findings regressam ao implementador e uma nova candidata exige nova revisão.
- Quando existir uma instância do lifecycle, não alteres `currentPrompt`, gates ou estados diretamente para contornar validações. Regista cada resultado com `software-lifecycle.ps1 record` e evidência durável. Deixa as transições determinísticas ao orquestrador e usa `select` apenas nas decisões permitidas por `status`.
- Feedback, métricas e findings não alteram diretamente a fonte canónica:
  captura o delta e aplica o workflow de `CHANGE_CONTROL.md`.
- Em cada prompt de uma instância, inicia o task ledger com
  `software-lifecycle.ps1 work-start`, checkpointa goals e verificações, regista
  findings aceites e fecha-os com evidência. `record completed` só é válido
  depois do closeout da mesma tentativa e com zero findings abertos/bloqueados.

## Documentação específica da aplicação

Na aplicação derivada, mantém neste ficheiro apenas informação curta e comprovada:

- mapa dos projetos ativos e respetivas responsabilidades;
- comandos reais de restore, build, execução e testes;
- convenções do repositório e documentos a consultar por tipo de tarefa;
- exclusões de pesquisa para artefactos gerados, builds e caches;
- limites técnicos que se aplicam a todas as alterações.

Coloca explicações extensas nos documentos próprios e liga-as a partir daqui, indicando quando devem ser lidas.
