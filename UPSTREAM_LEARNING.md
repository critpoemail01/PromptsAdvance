# Aprendizagem upstream do AdvanceAppFlow

Este contrato aplica-se depois de corrigir um defeito, regressão, configuração
incorreta ou fragilidade numa aplicação criada, adotada ou continuada com o
AdvanceAppFlow. O objetivo é impedir recorrência sem transformar o catálogo
numa cópia da lógica de negócio de uma aplicação.

## Sequência obrigatória

1. Corrige primeiro a aplicação e valida o comportamento afetado com o menor
   conjunto de testes que prova o resultado e o caso negativo relevante.
2. Antes da entrega, executa uma revisão de recorrência e classifica a causa:
   - `advanceappflow_systemic`: o erro foi causado ou permitido por um prompt,
     contrato, skill/plugin, script de lifecycle, teste, default ou artefacto
     copiado pelo AdvanceAppFlow;
   - `boilerplate_systemic`: o erro vem do boilerplate/template partilhado;
   - `application_specific`: depende apenas do domínio, configuração, dados,
     integração, ambiente ou decisão específica desta aplicação;
   - `unknown`: a evidência ainda não permite atribuir a causa.
3. Regista na entrega a classificação, a causa comprovada, a evidência e o
   estado da aprendizagem upstream. Não uses apenas “corrigido” como causa.

## Quando corrigir o catálogo

Para `advanceappflow_systemic`, corrige no mesmo workflow o clone canónico
local do AdvanceAppFlow e acrescenta uma regressão que falhava antes e passa
depois. Atualiza a fonte mais pequena e autoritativa: prompt, contrato,
manifesto, skill/plugin, lifecycle, fixture ou teste. Não copies o patch da
aplicação literalmente quando uma regra, default, gerador ou oráculo mais
geral elimina a classe de erro.

Para `boilerplate_systemic`, corrige o boilerplate apenas quando esse
repositório estiver explicitamente em âmbito e a alteração local estiver
autorizada. Independentemente disso, acrescenta ao AdvanceAppFlow uma
verificação, regra de adoção ou teste que detete versões afetadas antes de a
mesma falha chegar a outra aplicação.

Para `application_specific`, não alteres o catálogo. Regista em uma frase por
que a correção não é reutilizável. Para `unknown`, preserva reprodução e
evidência, marca a aprendizagem como pendente e não inventes uma generalização.

## Resolver e proteger o upstream

Quando a entrada for a skill global, resolve primeiro o catálogo usado pela
aplicação. Para procurar um clone de desenvolvimento apropriado para a
correção, usa também:

```powershell
pwsh -NoProfile -File <plugin>/scripts/Resolve-AdvanceCatalog.ps1 `
  -PreferDevelopmentClone
```

Um alvo upstream editável deve ser um clone Git local identificável como
`AdvanceAppFlow`, conter este contrato e não ser apenas o checkout/cache
instalado do marketplace. Antes de alterar:

- inspeciona `git status --short`, branch, remote e diff relevante;
- preserva todas as alterações existentes e não mistura trabalho concorrente;
- confirma que a causa aponta para uma fonte canónica do catálogo;
- não edita `LIFECYCLE_STATE.json` à mão e não altera o estado da aplicação para
  simular uma correção do processo.

Se o clone estiver ausente, não for inequivocamente o canónico, estiver num
cache instalado, ou a alteração colidir com trabalho existente, não o
sobrescrevas. Cria ou atualiza na aplicação
`reports/ADVANCEAPPFLOW_UPSTREAM_FEEDBACK.md` com:

- versão do catálogo e artefacto afetado;
- sintoma e reprodução mínima;
- causa e classificação, separando facto de hipótese;
- correção aplicada na aplicação, já anonimizada;
- correção generalizada proposta;
- teste/oráculo que impediria a recorrência;
- motivo concreto pelo qual a integração upstream ficou pendente.

## Evidência mínima e privacidade

Uma aprendizagem upstream válida contém sintoma, reprodução, causa raiz,
versão/artefacto afetado, correção generalizada e oráculo de regressão. Inclui
um caso negativo quando permissões, erros, ausência de dados, offline,
responsividade ou concorrência forem materiais.

Nunca copies para o AdvanceAppFlow segredos, dados pessoais, dados de cliente,
nomes internos, URLs privadas, código proprietário de domínio ou caminhos
específicos da aplicação. Minimiza e anonimiza a fixture até conservar apenas a
classe de erro. Uma correção reutilizável deve funcionar para uma segunda
aplicação fictícia com outro nome e outro domínio.

## Validação e autorizações

Depois de uma alteração upstream:

1. executa o teste de regressão novo e a avaliação dirigida pelo
   `EVALUATION_IMPACT_MAP.json`;
2. valida numa cópia descartável quando a mudança for material ao processo;
3. incrementa `catalogVersion` e mantém piloto/canal coerentes quando o contrato
   do processo mudar;
4. atualiza a tool Advance pelo workflow oficial do próprio catálogo.

A autorização duradoura para aprender localmente não autoriza commit, push,
PR, alteração de remote, publicação, produção ou outra ação externa. Sem essa
autorização, deixa o diff upstream validado localmente e informa-o. A
aprendizagem upstream nunca deve esconder nem atrasar a entrega da correção já
validada na aplicação; se não puder ser integrada com segurança, entrega a
aplicação e assinala o relatório pendente.

## Definition of Done

Uma correção numa aplicação Advance só está completamente reportada quando:

- a aplicação está corrigida e existe evidência verificável;
- a causa foi classificada;
- uma causa sistémica produziu uma correção generalizada e regressão no
  AdvanceAppFlow, ou um relatório pendente com motivo concreto;
- uma causa específica não contaminou o catálogo;
- a resposta distingue claramente `Aplicação` e `Aprendizagem AdvanceAppFlow`.
