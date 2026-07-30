# Processo profissional de desenvolvimento com Codex

Coleção de 73 prompts autónomos para criar, adotar, publicar e operar uma
aplicação Advance. Iniciativas `greenfield` são derivadas do
`BoilerPlateAdvance`; iniciativas `brownfield` ligam um processo isolado a uma
aplicação existente sem copiar a base sobre ela. A ordem global é obrigatória
para os gates, mas a implementação do produto é iterativa: depois da fundação,
cada lote é uma pequena fatia vertical funcional, não uma fase extensa de
layout ou backend isolado.

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
- [PRODUCT_DEFINITION.md](PRODUCT_DEFINITION.md): definição aprovada e gate bloqueante entre as etapas 1 e 2;
- [PRODUCT_QUALITY_BASELINE.md](PRODUCT_QUALITY_BASELINE.md): baseline aprovada, rubrica visual e primeira fatia;
- [APP_CONTEXT.md](APP_CONTEXT.md): valores da aplicação, fontes, confiança e autorizações por execução;
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md): requisitos, candidata, evidências, bloqueios e operação;
- [LIFECYCLE_GATE_EVIDENCE.json](LIFECYCLE_GATE_EVIDENCE.json): evidência estruturada, identidades, candidata, attestation/proveniência, autorização e artefactos com SHA-256 para G06–G10;
- [PILOT_APPROVAL.md](PILOT_APPROVAL.md): decisão bloqueante do piloto para a versão exata do catálogo;
- [PROMPT_EVALUATION.md](PROMPT_EVALUATION.md): avaliação piloto executável do próprio processo.
- [pilot/README.md](pilot/README.md): runner, isolamento e casos reproduzíveis de `PILOT-001`.
- [pilot/PILOT-001-EXECUTION.md](pilot/PILOT-001-EXECUTION.md): resultados, SHAs, consistência, pontuação provisória e limitações da execução atual.

Valores entre `[COLCHETES]` são entradas. Resolve-os por `APP_CONTEXT.md`, código/configuração real e decisões aprovadas; não os envies literalmente nem inventes valores. Segredos entram apenas por variáveis de ambiente, User Secrets, OIDC ou cofre aprovado.

## Como começar uma nova aplicação

Usa preferencialmente [START_HERE.md](START_HERE.md) e as skills `$advance-app-start` e `$advance-app-continue`. A primeira cria uma instância isolada; a segunda valida o estado e executa apenas o próximo prompt autorizado.

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

1. Cria uma tarefa por prompt; não juntes os 73 prompts num único pedido.
2. Executa 1–4 no workspace de preparação. Os prompts constroem progressivamente [PRODUCT_DEFINITION.md](PRODUCT_DEFINITION.md), mas só o prompt 04 pode fechar o Gate A.
3. Não executes o prompt 05 enquanto `PRODUCT_DEFINITION.md` não estiver `aprovado`, com decisão `GO`, DOR-01 a DOR-12 em `passou` e evidência da aprovação do responsável de produto.
4. Executa 5–6 para definir arquitetura, módulos e threat model. Se a etapa 1 estiver incompleta, estes prompts devem terminar `bloqueado`, sem preencher as lacunas por inferência.
5. No prompt 7, cria a aplicação numa pasta nova quando o modo for `greenfield`
   ou captura a baseline/gaps do repositório existente quando for `brownfield`.
   A adoção preserva Git e remotes. Apenas no modo greenfield, e quando
   `[AUTORIZAR_CRIACAO_GITHUB_E_PUSH_INICIAL]` estiver explicitamente aprovado,
   cria o repositório remoto autorizado, configura `origin` e confirma os SHAs.
6. Executa o prompt 8 sobre o repositório novo ou adotado, usando a raiz
   registada no lifecycle.
7. Executa integralmente o piloto de [PROMPT_EVALUATION.md](PROMPT_EVALUATION.md) numa cópia Git descartável. Revisão documental não substitui este teste.
8. Completa 9–12 e seleciona a primeira `[VERTICAL_SLICE_ATUAL]`.
9. Implementa a fatia com backend mínimo e um dos pares 25/26 ou 27/28; aplica apenas o prompt visual 13, 15 ou 17 da superfície usada.
10. Faz revisão humana de design e engenharia, valida usabilidade, acessibilidade e regressão visual da primeira fatia antes de propagar padrões.
11. Repete o ciclo até todas as jornadas `Must` passarem. Só então executa 14, 16 ou 18 para fechar globalmente as superfícies aplicáveis.
12. Conclui hardening, preparação operacional, documentação, aceitação e revisão independente. O prompt 64 só publica a candidata com o mesmo SHA/digest/attestation aprovado e com autorização de release explícita.
13. Depois da publicação, executa 65–73 nas respetivas cadências.

Para trabalho complexo ou ambíguo, usa Plan mode para refinar resultado, restrições, etapas e verificação; depois executa o plano. Para trabalho longo suportado pela interface, Goal mode pode manter a execução persistente. Nenhum modo amplia autorização para GitHub, produção, operações destrutivas ou custos.

Prompt inicial recomendado para uma aplicação nova:

```text
Usa $advance-app-start. Inicia uma nova iniciativa chamada "nome-da-iniciativa", com o responsável de produto indicado. Usa o BoilerPlateAdvance em C:\Work\BoilerPlateAdvance, inicializa uma instância isolada e executa apenas o primeiro prompt. Não declares o Gate A concluído.
```

## Gates do processo

### Gate A — definição do produto

Os prompts 1–4 constroem e auditam a definição. O Gate A só permite iniciar o
prompt 05 quando `PRODUCT_DEFINITION.md` estiver `aprovado`, a decisão for `GO`,
DOR-01 a DOR-12 tiverem `passou`, existir evidência direta do problema e teste
da solução com utilizadores representativos — ou exceção aprovada e limitada —
e os prompts 01–04 estiverem concluídos em `IMPLEMENTATION_STATUS.md`. Se faltar
qualquer critério, o prompt 04 decide `REWORK`, identifica o prompt a repetir e
mantém a etapa 2 bloqueada.

A passagem é também validada mecanicamente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProductDefinitionGate.ps1
```

Exit code 0 autoriza apenas o início da etapa 2; não aprova arquitetura, criação do repositório ou qualquer ação externa. Qualquer outro resultado mantém o processo bloqueado.

### Gate B — criação ou adoção

Permite 7–8 quando o Gate A continua válido e nome, requisitos `Must`,
arquitetura, módulos, threat model, modo da iniciativa, origem/destino ou raiz
brownfield e identificadores estão aprovados. A criação/push GitHub requer
alvo, autenticação e autorização explícitos; a adoção preserva o Git existente.

### Gate C — implementação

Permite 9–54 quando o repositório novo/adotado está ligado aos documentos
obrigatórios, possui baseline Git, comandos reais confirmados, primeira fatia
selecionada e piloto sem falhas críticas. `PILOT-001` pendente bloqueia este
gate.

A passagem é validada por
`scripts/Test-ImplementationReadinessGate.ps1`; texto livre em `GateEvidence`
não substitui `PILOT_APPROVAL.md` aprovado para a mesma `catalogVersion`.

O primeiro padrão visual só pode propagar depois de
`scripts/Test-ProductQualityGate.ps1` validar
`PRODUCT_QUALITY_BASELINE.md` e de G04 ter aprovação humana identificada.

### Gate D — candidata e release

Permite 55–63 quando CI/CD, SLI/SLO, observabilidade, backup/restore, rollback,
runbooks, documentação e owners estão comprovados. A candidata deve ter base
SHA, candidate SHA, digest e attestation de proveniência imutáveis. O prompt 62
executa aceitação e o 63 executa revisão separada, read-only, verificando issuer,
builder, source SHA e subject digest.

### Gate E — operação contínua

Permite o prompt 64 apenas quando os prompts 62 e 63 produziram `GO` para os mesmos identificadores e existe `[AUTORIZAR_RELEASE]`. Depois da publicação, permite 65–73 apenas sobre o ambiente exato, com acessos read-only e owners. Correções externas continuam a exigir `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]` ou outra autorização específica.

G08–G10 são validados por `scripts/Test-LifecycleGateEvidence.ps1`.
G09 passa **antes** de selecionar o prompt 64 e fixa ambiente, SHA, digest, attestation,
janela e identidade autorizadora. A conclusão do prompt 64 volta a validar no
mesmo ficheiro o ambiente/artefacto implantado, smoke tests, rollback e
critérios de aborto.

Um gate incompleto termina `bloqueado`; não se transforma silenciosamente num pressuposto ou exceção.

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

Cada prompt usa uma tentativa estruturada no próprio lifecycle:

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

Usa `finding-add` para cada problema aceite durante a revisão e
`finding-resolve` apenas depois da correção e de uma verificação com exit code
zero. `record completed` falha sem goals concluídos, verificação, autorrevisão
adversarial ou enquanto existir um finding aberto/bloqueado. `partial` e
`blocked` continuam disponíveis para conservar um resultado honesto.

## Ciclo de implementação por fatias verticais

Depois dos prompts 9–12:

1. executa 19 para o backend mínimo e 20–22 apenas no âmbito necessário;
2. escolhe um requisito observável pequeno;
3. executa 25 e 26 para uma página, ou 27 e 28 para uma funcionalidade;
4. aplica 13, 15 ou 17 apenas à superfície dessa fatia;
5. valida UI, contrato, backend/dados, autorização, loading/vazio/erro/conteúdo longo, observabilidade, acessibilidade e snapshots;
6. submete a primeira fatia a crítica de design e engenharia e a validação de usabilidade;
7. corrige e repete os testes afetados;
8. atualiza `IMPLEMENTATION_STATUS.md` e seleciona a fatia seguinte.

Os prompts 23/24 tratam requisitos globais quando já existe base funcional suficiente. Os prompts 14/16/18 são gates de conclusão, não atividades iniciais. Não propagues um padrão visual antes de a primeira fatia real satisfazer `PRODUCT_QUALITY_BASELINE.md`.

## Regras de qualidade não negociáveis

- Pesquisa atual de aplicações profissionais comparáveis, design systems maduros, investigação UX e referências premium relevantes; popularidade ou preço são sinais, não prova de qualidade.
- Extrai princípios e critérios próprios do domínio. Não copies marcas, trade dress, texto, código ou assets sem licença.
- Evita dashboards genéricos: densidade, grelha, hierarquia, navegação, controlos e estados devem responder às tarefas reais.
- Mantém catálogo `componente → variantes → estados → plataformas → acessibilidade → baseline`.
- Executa acessibilidade desde a primeira fatia: checks automáticos em cada pull request aplicável e avaliação manual das jornadas críticas.
- Executa regressão visual reproduzível em mobile/desktop, temas suportados e estados normal/loading/vazio/erro/conteúdo longo. Publica o diff na pull request; só altera baselines mediante revisão e autorização explícitas.
- Não declara “sem bugs”, conformidade total ou sucesso sem evidência. A revisão adversarial do próprio executor é obrigatória, mas só a tarefa/revisor separado do prompt 63 é independente.

## Ordem global dos prompts

### 1 — Preparação e definição

1. [Descobrir e validar uma oportunidade](prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md)
2. [Criar e validar o nome](prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md)
3. [Especificar requisitos por página/funcionalidade e checklist do programador](prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md)
4. [Fechar a definição e executar o Gate A](prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md)

### 2 — Arquitetura e fundação

5. [Definir arquitetura e módulos](prompts/02-arquitetura-e-fundacao/05-definir-arquitetura-e-selecionar-modulos.md)
6. [Modelar ameaças e requisitos de segurança](prompts/02-arquitetura-e-fundacao/06-modelar-ameacas-e-requisitos-de-seguranca.md)
7. [Criar ou adotar o projeto da iniciativa](prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md)
8. [Otimizar o projeto para Codex](prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md)
9. [Configurar ambientes, segredos e configuração](prompts/02-arquitetura-e-fundacao/09-configurar-ambientes-segredos-e-configuracao.md)
10. [Definir contratos API e compatibilidade](prompts/02-arquitetura-e-fundacao/10-definir-contratos-api-versionamento-e-compatibilidade.md)

### 3 — Fundação visual e gates de superfície

11. [Criar ícone e marca](prompts/03-marca-e-layout/11-criar-icone-e-marca.md)
12. [Criar fundação visual mínima](prompts/03-marca-e-layout/12-criar-layout-inicial.md)
13. [Melhorar a fatia em Client.Ssr](prompts/03-marca-e-layout/13-melhorar-layout-client-ssr.md)
14. [Concluir Client.Ssr após jornadas Must](prompts/03-marca-e-layout/14-concluir-layout-client-ssr.md)
15. [Melhorar a fatia em Client.Web](prompts/03-marca-e-layout/15-melhorar-layout-client-web.md)
16. [Concluir Client.Web após jornadas Must](prompts/03-marca-e-layout/16-concluir-layout-client-web.md)
17. [Melhorar a fatia em Client.Maui](prompts/03-marca-e-layout/17-melhorar-layout-client-maui.md)
18. [Concluir Client.Maui após jornadas Must](prompts/03-marca-e-layout/18-concluir-layout-client-maui.md)

### 4 — Backend e funcionalidades

19. [Implementar backend inicial](prompts/04-backend-e-funcionalidades/19-criar-backend-inicial.md)
20. [Validar dados, migrations e integridade](prompts/04-backend-e-funcionalidades/20-validar-base-de-dados-migrations-e-integridade.md)
21. [Validar autenticação, autorização e MFA](prompts/04-backend-e-funcionalidades/21-validar-autenticacao-autorizacao-e-mfa.md)
22. [Validar contas e sessões](prompts/04-backend-e-funcionalidades/22-validar-ciclo-de-vida-de-contas-e-sessoes.md)
23. [Implementar requisitos globais](prompts/04-backend-e-funcionalidades/23-implementar-requisitos-globais.md)
24. [Testar requisitos globais com Playwright](prompts/04-backend-e-funcionalidades/24-criar-testes-playwright-para-requisitos-globais.md)
25. [Implementar requisitos de página](prompts/04-backend-e-funcionalidades/25-implementar-requisitos-de-pagina.md)
26. [Testar a página com Playwright](prompts/04-backend-e-funcionalidades/26-criar-testes-playwright-para-requisitos-de-pagina.md)
27. [Implementar funcionalidade específica](prompts/04-backend-e-funcionalidades/27-implementar-funcionalidades-especificas.md)
28. [Testar a funcionalidade com Playwright](prompts/04-backend-e-funcionalidades/28-criar-testes-playwright-para-funcionalidade-especifica.md)
29. [Criar emails transacionais](prompts/04-backend-e-funcionalidades/29-criar-emails-transacionais.md)

Opcionais desta etapa: [30 faturação](prompts/04-backend-e-funcionalidades/Optional/30-implementar-faturacao.md), [31 localização](prompts/04-backend-e-funcionalidades/Optional/31-validar-localizacao-e-formatacao-cultural.md), [32 login externo](prompts/04-backend-e-funcionalidades/Optional/32-validar-login-com-fornecedores-externos.md), [33 passkeys](prompts/04-backend-e-funcionalidades/Optional/33-validar-webauthn-e-passkeys.md), [34 Hangfire](prompts/04-backend-e-funcionalidades/Optional/34-validar-jobs-hangfire.md), [35 SignalR](prompts/04-backend-e-funcionalidades/Optional/35-validar-signalr-e-tempo-real.md), [36 push/deep links](prompts/04-backend-e-funcionalidades/Optional/36-validar-push-notifications-e-deep-links.md) e [37 uploads](prompts/04-backend-e-funcionalidades/Optional/37-validar-uploads-imagens-e-armazenamento.md).

### 5 — Segurança e privacidade

38. [Privacidade operacional e direitos de dados — opcional](prompts/05-seguranca-e-privacidade/Optional/38-implementar-privacidade-operacional-e-direitos-de-dados.md)
39. [Auditar segurança com OWASP ASVS](prompts/05-seguranca-e-privacidade/39-auditar-seguranca-com-owasp-asvs.md)

### 6 — Conformidade e presença pública

40. [Implementar área legal](prompts/06-conformidade-e-presenca-publica/40-implementar-area-legal-ssr.md)
41. [Atualizar footer institucional](prompts/06-conformidade-e-presenca-publica/41-atualizar-footer-institucional-ssr.md)
42. [Implementar SEO SSR](prompts/06-conformidade-e-presenca-publica/42-implementar-seo-area-publica-ssr.md)
43. [Auditar acessibilidade WCAG](prompts/06-conformidade-e-presenca-publica/43-auditar-acessibilidade-wcag.md)
44. [Validar static SSR](prompts/06-conformidade-e-presenca-publica/44-validar-ssr.md)

### 7 — Monetização e crescimento — opcionais

45. [Publicidade](prompts/07-monetizacao-e-crescimento/Optional/45-implementar-publicidade.md)
46. [Retenção](prompts/07-monetizacao-e-crescimento/Optional/46-implementar-retencao-de-utilizadores.md)
47. [Fidelização](prompts/07-monetizacao-e-crescimento/Optional/47-fidelizar-utilizadores.md)

### 8 — Qualidade e hardening

48. [Observabilidade e alertas](prompts/08-qualidade-e-hardening/48-implementar-observabilidade-e-alertas.md)
49. [Performance, carga e estabilidade](prompts/08-qualidade-e-hardening/49-testar-performance-e-carga.md)
50. [PWA, instalação, offline e atualização](prompts/08-qualidade-e-hardening/50-validar-pwa-instalacao-offline-e-atualizacao.md)
51. [Resiliência e recuperação de falhas](prompts/08-qualidade-e-hardening/51-testar-resiliencia-e-recuperacao-de-falhas.md)
52. [Auditoria geral baseada em risco](prompts/08-qualidade-e-hardening/52-testar-aplicacao-geral.md)
53. [Dependências, licenças e supply chain](prompts/08-qualidade-e-hardening/53-auditar-dependencias-licencas-e-supply-chain.md)
54. [Preparar estratégia de cache](prompts/08-qualidade-e-hardening/54-evitar-cache-apos-publicacao.md)

### 9 — Entrega e distribuição

55. [Configurar CI/CD e ambientes](prompts/09-entrega-e-distribuicao/55-configurar-ci-cd-e-ambientes-de-deploy.md)
56. [Infraestrutura como código — opcional](prompts/09-entrega-e-distribuicao/Optional/56-provisionar-infraestrutura-como-codigo.md)
57. [Preparar MAUI para lojas — opcional](prompts/09-entrega-e-distribuicao/Optional/57-preparar-maui-para-distribuicao-nas-stores.md)

### 10 — Operação e recuperação

58. [Definir SLI, SLO e error budget](prompts/10-operacao-e-recuperacao/58-definir-sli-slo-e-error-budget.md)
59. [Implementar backup, restore e disaster recovery](prompts/10-operacao-e-recuperacao/59-implementar-backup-restore-e-disaster-recovery.md)
60. [Criar runbook de incidentes e operação](prompts/10-operacao-e-recuperacao/60-criar-runbook-de-incidentes-e-operacao.md)

### 11 — Aceitação, revisão e release

61. [Concluir documentação e manutenção](prompts/11-aceitacao-e-manutencao/61-concluir-documentacao-e-plano-de-manutencao.md)
62. [Executar aceitação final](prompts/11-aceitacao-e-manutencao/62-executar-aceitacao-final-e-checklist-de-release.md)
63. [Executar revisão final independente](prompts/11-aceitacao-e-manutencao/63-executar-revisao-final-independente.md)
64. [Publicar com migrations, smoke tests e rollback](prompts/11-aceitacao-e-manutencao/64-publicar-com-migrations-smoke-tests-e-rollback.md)

### 12 — Operação contínua

65. [Validar cache da versão publicada](prompts/12-operacao-continua/65-validar-cache-da-versao-publicada.md)
66. [Validar SEO online](prompts/12-operacao-continua/66-validar-seo-online.md)
67. [Verificar pós-release a 30m, 24h e 7d](prompts/12-operacao-continua/67-verificar-pos-release-30m-24h-7d.md)
68. [Executar triagem operacional diária](prompts/12-operacao-continua/68-executar-triagem-operacional-diaria.md)
69. [Monitorizar Core Web Vitals com RUM](prompts/12-operacao-continua/69-monitorizar-core-web-vitals-rum.md)
70. [Triar bugs e feedback de suporte](prompts/12-operacao-continua/70-triar-bugs-e-feedback-de-suporte.md)
71. [Monitorizar custos e anomalias](prompts/12-operacao-continua/71-monitorizar-custos-e-anomalias.md)
72. [Auditar vulnerabilidades continuamente](prompts/12-operacao-continua/72-auditar-vulnerabilidades-continuas.md)
73. [Medir DORA e melhoria contínua](prompts/12-operacao-continua/73-medir-metricas-dora-e-melhoria-continua.md)

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
