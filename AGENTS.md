# Instruções do projeto para o Codex

## Leitura obrigatória

Antes de executar qualquer tarefa:

1. Quando `LIFECYCLE_STATE.json` existir, usa a skill `advance-app-continue`, executa `software-lifecycle.ps1 status` e `validate`, e trabalha apenas no prompt atual preparado em `NEXT_TASK.md`.
   Quando o pedido for `Continua o projeto Advance em <caminho>` e o caminho
   ainda não tiver lifecycle, usa `software-lifecycle.ps1 continue
   -ProjectPath <caminho>` para criar uma instância brownfield isolada; não
   executes `start` dentro da aplicação nem copies o boilerplate por cima.
2. Numa instância, usa a secção `Required context` de `NEXT_TASK.md` como
   routing auditável e lê integralmente os documentos aí listados; os hashes
   confirmam a versão usada. No catálogo canónico ou sem task packet, lê
   integralmente o [EXECUTION_CONTRACT.md](EXECUTION_CONTRACT.md) e aplica-o
   como contrato comum. Não carregues recursivamente todos os documentos apenas
   por estarem ligados: abre os adicionais quando o prompt, uma decisão em falta
   ou a superfície alterada os tornar materiais.
3. Se a tarefa afetar produto, requisitos, marca, conteúdo, UI, UX, jornadas, emails, monetização ou retenção, o task packet deve incluir e o executor lê integralmente o [PRODUCT_EXCELLENCE.md](PRODUCT_EXCELLENCE.md).
   Para requisitos inclui [REQUIREMENTS_ENGINEERING_CONTRACT.md](REQUIREMENTS_ENGINEERING_CONTRACT.md); para experiências visíveis inclui [VISUAL_SLICE_CONTRACT.md](VISUAL_SLICE_CONTRACT.md); para implementação, validação, hardening ou CI inclui [TEST_STRATEGY_CONTRACT.md](TEST_STRATEGY_CONTRACT.md).
4. Antes de uma tarefa da etapa 2 ou posterior, lê o [PRODUCT_DEFINITION.md](PRODUCT_DEFINITION.md) e executa `scripts/Test-ProductDefinitionGate.ps1` quando aplicável. Trata uma falha como diagnóstico e comunica o que falta; não bloqueies um `próximo` explícito salvo quando a lacuna tornar o objetivo tecnicamente impossível ou inseguro.
5. Antes de avaliar arquitetura, UI, implementação, hardening, release ou operação, lê [QUALITY_GATES.md](QUALITY_GATES.md) e usa o gate correspondente como checklist de qualidade.
   Para G06–G10, atualiza e valida `LIFECYCLE_GATE_EVIDENCE.json`; texto livre em `GateEvidence` não substitui identidades, hashes, candidata, autorização ou artefactos exigidos.
6. Para tarefas de produto ou experiência posteriores à descoberta, lê também o [PRODUCT_QUALITY_BASELINE.md](PRODUCT_QUALITY_BASELINE.md) e usa a versão aprovada como gate mensurável.
   Quando ajuda contextual, vídeos de utilização ou Academia estiverem em
   âmbito, lê também [HELP_AND_ACADEMY.md](HELP_AND_ACADEMY.md) e aplica a matriz,
   o perfil de produção, os limites de publicação e a Definition of Done.
7. Lê o `APP_CONTEXT.md` quando existir e resolve apenas os valores necessários ao prompt atual.
8. Lê o `IMPLEMENTATION_STATUS.md` quando existir para conhecer decisões, evidências, bloqueios e trabalho já concluído.
9. Depois de alterar materialmente este processo, lê e executa a avaliação aplicável de `PROMPT_EVALUATION.md` numa cópia descartável. O piloto avalia o catálogo; não bloqueia o desenvolvimento local de uma aplicação.
10. Lê os `AGENTS.md` ou `AGENTS.override.md` mais próximos dos ficheiros afetados. Regras locais mais específicas complementam estas instruções.
11. Usa `CHANGE_CONTROL.md` para baselines de release aprovadas e comportamento
    já lançado. Durante o desenvolvimento normal, atualiza a fonte canónica e a
    rastreabilidade sem obrigar um novo ciclo formal.

Se `EXECUTION_CONTRACT.md` estiver ausente, não inicies alterações. Aplica o mesmo comportamento a uma tarefa de produto/experiência se `PRODUCT_EXCELLENCE.md` estiver ausente. Para outros documentos em falta, não inventes conteúdo: regista a lacuna no resultado e bloqueia apenas quando ela impedir execução segura/verificável ou uma ação externa/release.

## Regras duradouras

- Usa código, configuração executada, testes, documentação aprovada e decisões registadas como fontes de verdade.
- Trata valores entre `[COLCHETES]` como entradas a resolver, não como texto decorativo.
- Executa um único lote coerente por tarefa e mantém alterações fora do âmbito intactas.
- Executa exatamente um prompt por tarefa. No fim, regista o resultado, resume
  o que foi alcançado, lista tudo o que falta implementar e para. Só prepara
  outro prompt depois de `próximo`, `repetir`, `corrigir` ou `ignorar e avançar`.
- Preserva alterações locais e distingue falhas introduzidas pela tarefa de falhas preexistentes.
- Não coloques segredos, credenciais, dados pessoais ou configuração privada em prompts, código, logs ou documentação versionada.
- Não inventes comandos. Descobre e usa os comandos reais do repositório.
- Quando o programador pedir `corre a app`, `run the app` ou equivalente,
  inicia em desenvolvimento local os três projetos executáveis reais com os
  sufixos `Server.Api`, `Client.Ssr` e `Client.Web` (`Cliente.Web` apenas se
  esse nome existir). Mantém-nos em sessões persistentes separadas, confirma a
  readiness e URLs dos três e não avança o lifecycle. Não substituas projetos
  em falta nem mates globalmente processos `dotnet`.
- Não executes ações externas, destrutivas, financeiras ou de produção sem alvo e autorização explícitos.
- Não uses nomes de modos da interface como substituto de um plano, critérios de conclusão ou autorizações concretas.
- Mantém as validações específicas no prompt da tarefa; não copies para cada prompt o contrato comum inteiro.
- Em experiências visíveis, pesquisa padrões atuais de produtos profissionais comparáveis e adapta-os sem copiar identidade, código ou assets.
- Implementa funcionalidades em cortes verticais pequenos e completos. Não concluas antecipadamente todos os layouts contra dados, permissões ou erros simulados quando a jornada real ainda não existe.
- Em alterações de UI, mantém acessibilidade automatizada contínua e regressão visual dos componentes/estados estáveis; baselines só mudam com revisão explícita.
- Criar repositórios remotos, adicionar ou substituir `origin`, fazer commit/push e alterar regras do GitHub são ações externas: exige alvo exato e autorização explícita, verifica conflitos e nunca uses `force push`.
- A candidata de produção exige revisão final independente, read-only e sobre commit/artefacto imutável. O revisor não corrige a própria candidata; findings regressam ao implementador e uma nova candidata exige nova revisão.
- Quando existir uma instância do lifecycle, não alteres estados diretamente. Usa `record`, `advance`, `request` e `repeat`.
- Antes de repetir um prompt ou aplicá-lo a uma aplicação existente, mostra o
  histórico/evidência ou a sobreposição detetada, confirma se é para repetir e
  exige o objetivo concreto da repetição.
- Usa o task ledger, checkpoints e findings quando forem úteis para trabalho
  complexo; não são um bloqueio obrigatório do desenvolvimento normal.

## Documentação específica da aplicação

Na aplicação derivada, mantém neste ficheiro apenas informação curta e comprovada:

- mapa dos projetos ativos e respetivas responsabilidades;
- comandos reais de restore, build, execução e testes;
- convenções do repositório e documentos a consultar por tipo de tarefa;
- exclusões de pesquisa para artefactos gerados, builds e caches;
- limites técnicos que se aplicam a todas as alterações.

Coloca explicações extensas nos documentos próprios e liga-as a partir daqui, indicando quando devem ser lidas.
