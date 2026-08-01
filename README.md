# Processo profissional de desenvolvimento com Codex

Catálogo de prompts para criar, adotar, publicar e operar uma aplicação
Advance. O fluxo padrão é controlado pelo programador: executa um prompt,
apresenta o resultado e tudo o que falta implementar, e para. Só prepara outro
prompt depois de `próximo`, `repetir`, `corrigir` ou `ignorar e avançar`.

Iniciativas `greenfield` partem do `BoilerPlateAdvance`; iniciativas
`brownfield` ligam um processo isolado à aplicação existente sem copiar a base
por cima dela. Os 76 prompts ficam disponíveis como catálogo detalhado, mas não
formam uma cadeia automática nem obrigam a executar trabalho que não se aplica.

Este catálogo é deliberadamente opinativo para Advance/.NET, Bit, Blazor,
MAUI, GitHub e o boilerplate indicado. Não é um lifecycle universal para todas
as stacks; adaptações de plataforma exigem um perfil aprovado e novo piloto.

## Documentos obrigatórios

Mantém estes ficheiros na raiz deste workspace. No prompt 7, copia-os para o
novo repositório greenfield ou conserva-os no processo isolado brownfield,
adicionando-os à aplicação existente apenas num lote explícito e sem colisões:

- [START_HERE.md](START_HERE.md): entrada curta e comandos para iniciar/continuar;
- [PROCESS_MANIFEST.json](PROCESS_MANIFEST.json): etapas, prompts, dependências, routing e gates legíveis por máquina;
- [QUALITY_GATES.md](QUALITY_GATES.md): critérios profissionais de produto, arquitetura, layout, código, release e operação;
- [AGENTS.md](AGENTS.md): instruções duradouras carregadas pelo Codex;
- [EXECUTION_CONTRACT.md](EXECUTION_CONTRACT.md): planeamento, limites, validação adversarial e evidências;
- [CHANGE_CONTROL.md](CHANGE_CONTROL.md): deltas aprovados, análise de impacto,
  invalidação de gates e novos ciclos depois da release;
- [CLAUDE.md](CLAUDE.md): ponte mínima para Claude Code importar `AGENTS.md`;
- [PRODUCT_EXCELLENCE.md](PRODUCT_EXCELLENCE.md): benchmark, crítica profissional e critérios de produto/UX;
- [REQUIREMENTS_ENGINEERING_CONTRACT.md](REQUIREMENTS_ENGINEERING_CONTRACT.md):
  atomicidade, decisões/estados, NFR e rastreabilidade requisito-risco-teste;
- [PRODUCT_DEFINITION.md](PRODUCT_DEFINITION.md): definição e lacunas conhecidas do produto;
- `DISCOVERY_RESEARCH.md`: evidência detalhada criada pelo prompt 01; a resposta
  conversacional conserva apenas a síntese necessária à decisão;
- [PRODUCT_QUALITY_BASELINE.md](PRODUCT_QUALITY_BASELINE.md): baseline aprovada, rubrica visual e primeira fatia;
- [VISUAL_SLICE_CONTRACT.md](VISUAL_SLICE_CONTRACT.md): brief, alternativas de
  baixa fidelidade, decisão humana, responsividade, estados e evidência visual;
- [TEST_STRATEGY_CONTRACT.md](TEST_STRATEGY_CONTRACT.md): matriz de testes por
  risco, níveis, lanes de CI, determinismo, flakiness e failure modes;
- [HELP_AND_ACADEMY.md](HELP_AND_ACADEMY.md): protocolo opcional para inventário
  funcional, artigos bilingues como PT/EN, vídeos, ajuda contextual, cursos e publicação;
- [APP_CONTEXT.md](APP_CONTEXT.md): valores da aplicação, fontes, confiança e autorizações por execução;
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md): requisitos, candidata, evidências, bloqueios e operação;
- [LIFECYCLE_GATE_EVIDENCE.json](LIFECYCLE_GATE_EVIDENCE.json): evidência estruturada, identidades, candidata, attestation/proveniência, autorização e artefactos com SHA-256 para G06–G10;
- [PILOT_APPROVAL.md](PILOT_APPROVAL.md): avaliação do próprio catálogo; não bloqueia o desenvolvimento local da aplicação;
- [EVALUATION_IMPACT_MAP.json](EVALUATION_IMPACT_MAP.json): regressão dirigida por ficheiros alterados; a suite completa continua obrigatória para promoção a `stable`;
- [PROMPT_EVALUATION.md](PROMPT_EVALUATION.md): avaliação piloto executável do próprio processo.
- [pilot/README.md](pilot/README.md): runner, isolamento e casos reproduzíveis de `PILOT-001`.
- [pilot/PILOT-001-EXECUTION.md](pilot/PILOT-001-EXECUTION.md): resultados, SHAs, consistência, pontuação provisória e limitações da execução atual.

Valores entre `[COLCHETES]` são entradas. Resolve-os por `APP_CONTEXT.md`, código/configuração real e decisões aprovadas; não os envies literalmente nem inventes valores. Segredos entram apenas por variáveis de ambiente, User Secrets, OIDC ou cofre aprovado.

## Como começar uma nova aplicação

Usa [START_HERE.md](START_HERE.md) e as skills `$advance-app-start` e
`$advance-app-continue`. A primeira cria uma instância isolada e executa apenas
o prompt 01; a segunda executa apenas o prompt preparado e para no fim.

O catálogo é publicado primeiro como `candidate`. Projetos existentes só
recebem upgrade automático de uma versão `stable` cujo piloto esteja aprovado
para a mesma `catalogVersion`; uma candidata pode ser exercitada em instâncias
isoladas, mas nunca bloqueia silenciosamente uma aplicação existente.

Para que as skills apareçam em todos os projetos, instala o catálogo como um
plugin Codex, no mesmo modelo de um marketplace Git:

```text
codex plugin marketplace add critpoemail01/PromptsAdvance
codex plugin add advance-app@promptsadvance
```

Também é possível substituir o primeiro argumento pelo caminho absoluto de um
clone local. Reinicia o Codex e abre uma tarefa nova após a instalação. O
manifesto está em `plugins/advance-app/.codex-plugin/plugin.json` e o
marketplace em `.agents/plugins/marketplace.json`.

Para continuar ou adotar um projeto existente por caminho:

```text
Continua o projeto Advance em C:\Work\qqlcoisa
```

O comando subjacente `software-lifecycle.ps1 continue -ProjectPath <caminho>`
resolve uma instância existente ou cria uma instância brownfield isolada. Não
altera a árvore da aplicação, `.git`, histórico, alterações locais ou remotes
durante a inicialização. O prompt 07 executa a baseline de adoção; código
existente só satisfaz requisitos e gates quando houver evidência verificável.

Para executar a aplicação local basta pedir `corre a app`. A skill resolve o
prefixo e os projetos reais do repositório e mantém, em sessões separadas,
`<App>.Server.Api`, `<App>.Client.Ssr` e `<App>.Client.Web`; aceita
`<App>.Cliente.Web` apenas se esse for o nome realmente existente. A API fica
ready antes dos dois clientes, e a resposta apresenta as três URLs e o estado
de cada processo. Este pedido não avança prompts nem autoriza deploy/produção.

1. Cria uma tarefa por prompt.
2. Executa o prompt atual, valida-o e regista um resultado honesto.
3. Se ficar incompleto, lista concretamente o que falta implementar.
4. Para e aguarda a decisão do programador.
5. `próximo` avança; `repetir/corrigir` exige um objetivo; `ignorar e avançar`
   conserva as lacunas e a razão.
6. Numa aplicação existente, mostra histórico ou sobreposição antes de repetir.
7. Mantém autorizações externas, Git e produção como limites bloqueantes.

Para trabalho complexo ou ambíguo, usa Plan mode para refinar resultado, restrições, etapas e verificação; depois executa o plano. Para trabalho longo suportado pela interface, Goal mode pode manter a execução persistente. Nenhum modo amplia autorização para GitHub, produção, operações destrutivas ou custos.

Prompt inicial recomendado para uma aplicação nova:

```text
Usa $advance-app-start. Inicia uma nova iniciativa chamada "nome-da-iniciativa", com o responsável de produto indicado. Usa o BoilerPlateAdvance no caminho absoluto existente desta máquina, inicializa uma instância isolada e executa apenas o primeiro prompt. Não declares o Gate A concluído.
```

## Gates do processo

No fluxo padrão, estes gates são checklists de qualidade e prontidão. Uma falha
aparece no resultado e em `Falta para terminar`, mas não impede o programador de
pedir `próximo`. Só ações externas, destrutivas, financeiras, Git, lojas,
release e produção mantêm bloqueios de autorização obrigatórios.

### Gate A — definição do produto

Os prompts 1–4 constroem e auditam a definição. O Gate A considera a definição
pronta quando `PRODUCT_DEFINITION.md` estiver `aprovado`, a decisão for `GO`,
DOR-01 a DOR-12 tiverem `passou`, existir evidência direta do problema e teste
da solução com utilizadores representativos — ou exceção aprovada e limitada —
e os prompts 01–04 estiverem concluídos em `IMPLEMENTATION_STATUS.md`. Se faltar
qualquer critério, o prompt 04 decide `REWORK`, permanece ativo para recolher
evidência, viabilidade ou aprovação e só identifica um prompt anterior quando
a respetiva fonte canónica tiver realmente de ser alterada. Não envia
entrevistas, pilotos, orçamento ou equipa para o prompt 01 e mantém a etapa 2
bloqueada.

A passagem é também validada mecanicamente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProductDefinitionGate.ps1
```

Exit code 0 prova que o checklist passou; não aprova arquitetura, criação do
repositório ou qualquer ação externa. Outro resultado identifica trabalho em
falta e não força automaticamente a repetição do prompt.

### Gate B — criação ou adoção

Permite 7–8 quando o Gate A continua válido e nome, requisitos `Must`,
arquitetura, módulos, threat model, modo da iniciativa, origem/destino ou raiz
brownfield e identificadores estão aprovados. A criação/push GitHub requer
alvo, autenticação e autorização explícitos; a adoção preserva o Git existente.

### Gate C — implementação

Considera 9–56 prontos quando o repositório novo/adotado está ligado aos documentos
obrigatórios, possui baseline Git, comandos reais confirmados, primeira fatia
selecionada. `PILOT-001` avalia o catálogo e não bloqueia a implementação local
da aplicação.

A passagem é validada por
`scripts/Test-ImplementationReadinessGate.ps1`; texto livre em `GateEvidence`
não substitui `PILOT_APPROVAL.md` aprovado para a mesma `catalogVersion`.

O primeiro padrão visual só pode propagar depois de
`scripts/Test-ProductQualityGate.ps1` validar
`PRODUCT_QUALITY_BASELINE.md` e de G04 ter aprovação humana identificada.

### Gate D — candidata e release

Permite 57–65 quando CI/CD, SLI/SLO, observabilidade, backup/restore, rollback,
runbooks, documentação e owners estão comprovados. A candidata deve ter base
SHA, candidate SHA, digest e attestation de proveniência imutáveis. O prompt 65
executa aceitação e o 65 executa revisão separada, read-only, verificando issuer,
builder, source SHA e subject digest.

### Gate E — operação contínua

Permite o prompt 67 apenas quando os prompts 65 e 66 produziram `GO` para os mesmos identificadores e existe `[AUTORIZAR_RELEASE]`. Depois da publicação, permite 68–76 apenas sobre o ambiente exato, com acessos read-only e owners. Correções externas continuam a exigir `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]` ou outra autorização específica.

G08–G10 são validados por `scripts/Test-LifecycleGateEvidence.ps1`.
G09 passa **antes** de selecionar o prompt 67 e fixa ambiente, SHA, digest, attestation,
janela e identidade autorizadora. A conclusão do prompt 67 volta a validar no
mesmo ficheiro o ambiente/artefacto implantado, smoke tests, rollback e
critérios de aborto.

Um gate incompleto é comunicado sem ser transformado silenciosamente em
aprovação. O programador escolhe corrigir, repetir ou avançar com a lacuna
registada; autorizações de release não podem ser ignoradas.

## Mudanças depois de uma release

Feedback, métricas, findings e pedidos não alteram diretamente requisitos ou
baselines. Cria `changes/CHG-####/PROPOSAL.md` segundo `CHANGE_CONTROL.md`. Numa
instância concluída, uma proposta aprovada inicia novo ciclo com:

```powershell
.\software-lifecycle.ps1 cycle-start -ProcessRoot . `
  -ChangeId CHG-0001 -Evidence changes/CHG-0001/PROPOSAL.md
```

O estado e a evidência dos gates anteriores são arquivados e nenhum gate é
herdado automaticamente.

Validação estática do processo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-PromptProcess.ps1
```

Este comando verifica documentos, numeração, links, placeholders e contratos críticos. Não executa nem aprova `PILOT-001`.

O workflow `.github/workflows/process-validation.yml` executa a validação
estática e o lifecycle E2E em pull requests/push; a cópia descartável corre fora
de pull requests e numa cadência semanal.

O teste E2E do orquestrador verifica arranque, Gate A, transições automáticas,
bloqueio de `NextPrompt` arbitrário, G02/G03, seleção contextual de fatia e G04:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-SoftwareLifecycle.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-LifecycleMigration.ps1
```

Depois de alterar materialmente o catálogo, repete as duas verificações numa
cópia Git descartável e confirma que ela permanece limpa:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProcessInDisposableCopy.ps1
```

Este runner não executa nem aprova sozinho os 15 casos/human review de
`PILOT-001`.

Validação e navegação de uma instância:

```powershell
.\software-lifecycle.ps1 status -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 validate -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 next -ProcessRoot C:\Caminho\Processo
```

Para trabalho complexo, um prompt pode usar uma tentativa estruturada:

```powershell
.\software-lifecycle.ps1 work-start -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 checkpoint -ProcessRoot C:\Caminho\Processo `
  -GoalId GOAL-001 -CheckpointStatus completed `
  -Evidence "ficheiros e baseline inspecionados"
.\software-lifecycle.ps1 verify -ProcessRoot C:\Caminho\Processo `
  -VerificationKind command -VerifyCommand "comando real" `
  -VerifyExitCode 0 -VerifyEvidence "relatório ou output preservado"
.\software-lifecycle.ps1 finding-gate -ProcessRoot C:\Caminho\Processo
```

Quando o ledger estiver em uso, usa `finding-add` para cada problema aceite durante a revisão e
`finding-resolve` apenas depois da correção e de uma verificação com exit code
zero. No fluxo governado legado, o closeout pode ser obrigatório. No fluxo
padrão, `partial` e `blocked` conservam o resultado e `RemainingWork` sem prender
o programador ao mesmo prompt.

## Ciclo de implementação por fatias verticais

Depois dos prompts 9–13:

1. executa 21 para o backend mínimo e 22–24 apenas no âmbito necessário;
2. escolhe um requisito observável pequeno e aplica o Definition of Ready de
   `REQUIREMENTS_ENGINEERING_CONTRACT.md`;
3. executa 27 para uma página ou 29 para uma funcionalidade;
4. aplica 14, 16 ou 18 apenas à superfície dessa fatia, seguindo o brief e a
   direção escolhida de `VISUAL_SLICE_CONTRACT.md`;
5. executa 20 para reconciliar os requisitos com a experiência renderizada;
6. executa 28 para a página ou 30 para a funcionalidade e reconcilia a matriz
   de `TEST_STRATEGY_CONTRACT.md`;
7. valida UI, contrato, backend/dados, autorização, loading/vazio/erro/conteúdo
   longo, observabilidade, acessibilidade e snapshots;
8. submete a primeira fatia a crítica de design e engenharia e a validação de usabilidade;
9. corrige e repete os testes afetados;
10. atualiza `IMPLEMENTATION_STATUS.md` e seleciona a fatia seguinte.

Os prompts 25/26 tratam requisitos globais quando já existe base funcional suficiente. Os prompts 15/17/19 são gates de conclusão, não atividades iniciais. Não propagues um padrão visual antes de a primeira fatia real satisfazer `PRODUCT_QUALITY_BASELINE.md`.

## Regras de qualidade não negociáveis

- Pesquisa atual de aplicações profissionais comparáveis, design systems maduros, investigação UX e referências premium relevantes; popularidade ou preço são sinais, não prova de qualidade.
- Extrai princípios e critérios próprios do domínio. Não copies marcas, trade dress, texto, código ou assets sem licença.
- Evita dashboards genéricos: densidade, grelha, hierarquia, navegação, controlos e estados devem responder às tarefas reais.
- Mantém catálogo `componente → variantes → estados → plataformas → acessibilidade → baseline`.
- Executa acessibilidade desde a primeira fatia: checks automáticos em cada pull request aplicável e avaliação manual das jornadas críticas.
- Executa regressão visual reproduzível em mobile/desktop, temas suportados e estados normal/loading/vazio/erro/conteúdo longo. Publica o diff na pull request; só altera baselines mediante revisão e autorização explícitas.
- Mantém a matriz `requisito/risco → oráculo → nível → evidência`; usa provider
  real descartável quando a semântica depender dele e diffs de compatibilidade
  para contratos públicos.
- Trata flakiness como defeito com owner/prazo; não usa retries ilimitados,
  `skip`, sleeps ou thresholds relaxados para tornar a CI verde.
- Não declara “sem bugs”, conformidade total ou sucesso sem evidência. A revisão adversarial do próprio executor é obrigatória, mas só a tarefa/revisor separado do prompt 66 é independente.

## Ordem global dos prompts

### 1 — Preparação e definição

1. [Descobrir e validar uma oportunidade](prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md)
2. [Criar e validar o nome](prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md)
3. [Especificar requisitos por página/funcionalidade e checklist do programador](prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md)
4. [Fechar a definição e executar o Gate A](prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md)

### 2 — Arquitetura e fundação

5. [Definir arquitetura e módulos (opcional)](prompts/02-arquitetura-e-fundacao/Optional/05-definir-arquitetura-e-selecionar-modulos.md)
6. [Modelar ameaças e requisitos de segurança (opcional)](prompts/02-arquitetura-e-fundacao/Optional/06-modelar-ameacas-e-requisitos-de-seguranca.md)
7. [Criar ou adotar o projeto da iniciativa](prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md)
8. [Otimizar o projeto para Codex](prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md)
9. [Completar requisitos após observar a fundação técnica](prompts/02-arquitetura-e-fundacao/09-completar-requisitos-apos-fundacao-tecnica.md)
10. [Configurar ambientes, segredos e configuração (opcional)](prompts/02-arquitetura-e-fundacao/Optional/10-configurar-ambientes-segredos-e-configuracao.md)
11. [Definir contratos API e compatibilidade (opcional)](prompts/02-arquitetura-e-fundacao/Optional/11-definir-contratos-api-versionamento-e-compatibilidade.md)

### 3 — Fundação visual e gates de superfície

12. [Criar ícone e marca](prompts/03-marca-e-layout/12-criar-icone-e-marca.md)
13. [Criar fundação visual mínima](prompts/03-marca-e-layout/13-criar-layout-inicial.md)
14. [Melhorar a fatia em Client.Ssr](prompts/03-marca-e-layout/14-melhorar-layout-client-ssr.md)
15. [Concluir Client.Ssr após jornadas Must](prompts/03-marca-e-layout/15-concluir-layout-client-ssr.md)
16. [Melhorar a fatia em Client.Web](prompts/03-marca-e-layout/16-melhorar-layout-client-web.md)
17. [Concluir Client.Web após jornadas Must](prompts/03-marca-e-layout/17-concluir-layout-client-web.md)
18. [Melhorar a fatia em Client.Maui](prompts/03-marca-e-layout/18-melhorar-layout-client-maui.md)
19. [Concluir Client.Maui após jornadas Must](prompts/03-marca-e-layout/19-concluir-layout-client-maui.md)
20. [Completar requisitos após o refinamento visual](prompts/03-marca-e-layout/20-completar-requisitos-apos-refinamento-visual.md)

### 4 — Backend e funcionalidades

21. [Implementar backend inicial](prompts/04-backend-e-funcionalidades/21-criar-backend-inicial.md)
22. [Validar dados, migrations e integridade](prompts/04-backend-e-funcionalidades/22-validar-base-de-dados-migrations-e-integridade.md)
23. [Validar autenticação, autorização e MFA](prompts/04-backend-e-funcionalidades/23-validar-autenticacao-autorizacao-e-mfa.md)
24. [Validar contas e sessões](prompts/04-backend-e-funcionalidades/24-validar-ciclo-de-vida-de-contas-e-sessoes.md)
25. [Implementar requisitos globais](prompts/04-backend-e-funcionalidades/25-implementar-requisitos-globais.md)
26. [Testar requisitos globais com Playwright](prompts/04-backend-e-funcionalidades/26-criar-testes-playwright-para-requisitos-globais.md)
27. [Implementar requisitos de página](prompts/04-backend-e-funcionalidades/27-implementar-requisitos-de-pagina.md)
28. [Testar a página com Playwright](prompts/04-backend-e-funcionalidades/28-criar-testes-playwright-para-requisitos-de-pagina.md)
29. [Implementar funcionalidade específica](prompts/04-backend-e-funcionalidades/29-implementar-funcionalidades-especificas.md)
30. [Testar a funcionalidade com Playwright](prompts/04-backend-e-funcionalidades/30-criar-testes-playwright-para-funcionalidade-especifica.md)
31. [Criar emails transacionais](prompts/04-backend-e-funcionalidades/31-criar-emails-transacionais.md)
32. [Validar vantagem competitiva, layout, funcionalidades e fluxos](prompts/04-backend-e-funcionalidades/32-validar-vantagem-competitiva-layout-funcionalidades-e-fluxos.md)

Opcionais desta etapa: [33 faturação](prompts/04-backend-e-funcionalidades/Optional/33-implementar-faturacao.md), [34 localização](prompts/04-backend-e-funcionalidades/Optional/34-validar-localizacao-e-formatacao-cultural.md), [35 login externo](prompts/04-backend-e-funcionalidades/Optional/35-validar-login-com-fornecedores-externos.md), [36 passkeys](prompts/04-backend-e-funcionalidades/Optional/36-validar-webauthn-e-passkeys.md), [37 Hangfire](prompts/04-backend-e-funcionalidades/Optional/37-validar-jobs-hangfire.md), [38 SignalR](prompts/04-backend-e-funcionalidades/Optional/38-validar-signalr-e-tempo-real.md), [39 push/deep links](prompts/04-backend-e-funcionalidades/Optional/39-validar-push-notifications-e-deep-links.md) e [40 uploads](prompts/04-backend-e-funcionalidades/Optional/40-validar-uploads-imagens-e-armazenamento.md).

### 5 — Segurança e privacidade

41. [Privacidade operacional e direitos de dados — opcional](prompts/05-seguranca-e-privacidade/Optional/41-implementar-privacidade-operacional-e-direitos-de-dados.md)
42. [Auditar segurança com OWASP ASVS](prompts/05-seguranca-e-privacidade/42-auditar-seguranca-com-owasp-asvs.md)

### 6 — Conformidade e presença pública

43. [Implementar área legal](prompts/06-conformidade-e-presenca-publica/43-implementar-area-legal-ssr.md)
44. [Atualizar footer institucional](prompts/06-conformidade-e-presenca-publica/44-atualizar-footer-institucional-ssr.md)
45. [Implementar SEO SSR](prompts/06-conformidade-e-presenca-publica/45-implementar-seo-area-publica-ssr.md)
46. [Auditar acessibilidade WCAG](prompts/06-conformidade-e-presenca-publica/46-auditar-acessibilidade-wcag.md)
47. [Validar static SSR](prompts/06-conformidade-e-presenca-publica/47-validar-ssr.md)

### 7 — Monetização e crescimento — opcionais

48. [Publicidade](prompts/07-monetizacao-e-crescimento/Optional/48-implementar-publicidade.md)
49. [Retenção](prompts/07-monetizacao-e-crescimento/Optional/49-implementar-retencao-de-utilizadores.md)
50. [Fidelização](prompts/07-monetizacao-e-crescimento/Optional/50-fidelizar-utilizadores.md)

### 8 — Qualidade e hardening

51. [Observabilidade e alertas](prompts/08-qualidade-e-hardening/51-implementar-observabilidade-e-alertas.md)
52. [Performance, carga e estabilidade](prompts/08-qualidade-e-hardening/52-testar-performance-e-carga.md)
53. [PWA, instalação, offline e atualização](prompts/08-qualidade-e-hardening/53-validar-pwa-instalacao-offline-e-atualizacao.md)
54. [Resiliência e recuperação de falhas](prompts/08-qualidade-e-hardening/54-testar-resiliencia-e-recuperacao-de-falhas.md)
55. [Auditoria geral baseada em risco](prompts/08-qualidade-e-hardening/55-testar-aplicacao-geral.md)
56. [Dependências, licenças e supply chain](prompts/08-qualidade-e-hardening/56-auditar-dependencias-licencas-e-supply-chain.md)
57. [Preparar estratégia de cache](prompts/08-qualidade-e-hardening/57-evitar-cache-apos-publicacao.md)

### 9 — Entrega e distribuição

58. [Configurar CI/CD e ambientes](prompts/09-entrega-e-distribuicao/58-configurar-ci-cd-e-ambientes-de-deploy.md)
59. [Infraestrutura como código — opcional](prompts/09-entrega-e-distribuicao/Optional/59-provisionar-infraestrutura-como-codigo.md)
60. [Preparar MAUI para lojas — opcional](prompts/09-entrega-e-distribuicao/Optional/60-preparar-maui-para-distribuicao-nas-stores.md)

### 10 — Operação e recuperação

61. [Definir SLI, SLO e error budget](prompts/10-operacao-e-recuperacao/61-definir-sli-slo-e-error-budget.md)
62. [Implementar backup, restore e disaster recovery](prompts/10-operacao-e-recuperacao/62-implementar-backup-restore-e-disaster-recovery.md)
63. [Criar runbook de incidentes e operação](prompts/10-operacao-e-recuperacao/63-criar-runbook-de-incidentes-e-operacao.md)

### 11 — Aceitação, revisão e release

64. [Concluir documentação e manutenção](prompts/11-aceitacao-e-manutencao/64-concluir-documentacao-e-plano-de-manutencao.md)
65. [Executar aceitação final](prompts/11-aceitacao-e-manutencao/65-executar-aceitacao-final-e-checklist-de-release.md)
66. [Executar revisão final independente](prompts/11-aceitacao-e-manutencao/66-executar-revisao-final-independente.md)
67. [Publicar com migrations, smoke tests e rollback](prompts/11-aceitacao-e-manutencao/67-publicar-com-migrations-smoke-tests-e-rollback.md)

### 12 — Operação contínua

68. [Validar cache da versão publicada](prompts/12-operacao-continua/68-validar-cache-da-versao-publicada.md)
69. [Validar SEO online](prompts/12-operacao-continua/69-validar-seo-online.md)
70. [Verificar pós-release a 30m, 24h e 7d](prompts/12-operacao-continua/70-verificar-pos-release-30m-24h-7d.md)
71. [Executar triagem operacional diária](prompts/12-operacao-continua/71-executar-triagem-operacional-diaria.md)
72. [Monitorizar Core Web Vitals com RUM](prompts/12-operacao-continua/72-monitorizar-core-web-vitals-rum.md)
73. [Triar bugs e feedback de suporte](prompts/12-operacao-continua/73-triar-bugs-e-feedback-de-suporte.md)
74. [Monitorizar custos e anomalias](prompts/12-operacao-continua/74-monitorizar-custos-e-anomalias.md)
75. [Auditar vulnerabilidades continuamente](prompts/12-operacao-continua/75-auditar-vulnerabilidades-continuas.md)
76. [Medir DORA e melhoria contínua](prompts/12-operacao-continua/76-medir-metricas-dora-e-melhoria-continua.md)

## Módulos não previstos

Se a arquitetura aprovar outro módulo, cria um prompt `Optional` na etapa proprietária antes da aceitação final. Inclui aplicabilidade, critérios, threat model, configuração sem segredos, implementação, testes, observabilidade, falhas/recuperação, operação e condições de conclusão.

## Referências principais

- [OpenAI — Codex best practices](https://learn.chatgpt.com/guides/best-practices)
- [OpenAI — avaliação de prompts](https://developers.openai.com/api/docs/guides/evaluation-best-practices)
- [OpenAI — frontend prompting](https://developers.openai.com/api/docs/guides/frontend-prompt)
- [GitHub CLI — criar repositórios](https://cli.github.com/manual/gh_repo_create)
- [Playwright — visual comparisons](https://playwright.dev/docs/test-snapshots)
- [W3C — avaliar acessibilidade](https://www.w3.org/WAI/test-evaluate/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [Google — Core Web Vitals e RUM](https://web.dev/articles/vitals)
- [DORA — métricas de desempenho de entrega](https://dora.dev/guides/dora-metrics/)
