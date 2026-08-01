# Gates profissionais de qualidade

Este documento define o mínimo observável para avaliar a prontidão. No fluxo
padrão, G01–G08 e G10 são checklists consultivas: uma lacuna é reportada, não
força a repetição nem impede um `próximo` explícito. Autorizações externas e G09
release/produção continuam bloqueantes.

Estados permitidos: `passou`, `falhou`, `não verificável` e `não aplicável com justificação`. Um critério bloqueante só passa com evidência ligada à versão atual.

## G01 — Definição do produto

Validador: `scripts/Test-ProductDefinitionGate.ps1`.

- problema, público, job to be done e jornada principal concretos;
- procura, alternativas, acesso ao público e diferenciação sustentados;
- evidência direta do problema e teste da solução com utilizadores
  representativos, ou exceção aprovada com risco, owner, prazo e plano;
- MVP, exclusões, orçamento, prazo e métrica de decisão;
- requisitos `Must` da release com resultado, fonte, prioridade, aceitação,
  owner e slice candidata; a primeira slice e contratos transversais de alto
  risco estão totalmente refinados;
- `REQUIREMENTS_ENGINEERING_CONTRACT.md` aplicado: obrigações atómicas,
  tabelas de decisão/transição para regras materiais, exemplos/fronteiras,
  cenários NFR mensuráveis e matriz `requisito -> risco -> oráculo -> teste`;
- especificação canónica e vistas derivadas em paridade para o detalhe já
  aprovado; nenhuma linha genérica finge que uma slice futura está pronta;
- cada slice posterior passa um Definition of Ready no prompt 27/29, atualiza a
  fonte canónica e reconcilia checklist e `ALL_FUNCTIONALITIES.md` antes de código;
- quando ajuda contextual/Academia estiver em âmbito, existe matriz
  `APP/PAGE/FNC -> artigo -> vídeo -> ajuda -> curso`, idiomas, owners,
  publicação externa e critérios de aceitação segundo `HELP_AND_ACADEMY.md`;
- aprovação explícita da versão pelo responsável de produto.

## G02 — Arquitetura e fundação

Artefactos mínimos:

- contexto e containers C4; componentes apenas onde acrescentem valor;
- ADRs para decisões estruturais e respetivos trade-offs;
- fronteiras, dependências permitidas e ownership de dados;
- contratos API, compatibilidade, erros e idempotência;
- threat model, trust boundaries, autenticação e autorização;
- estratégia de configuração, segredos e ambientes;
- avaliação proporcional de fiabilidade, segurança, custo, operação e performance;
- módulos mantidos/removidos/adiados ligados a requisitos;
- arquitetura de ajuda/Academia, resolução contextual, fallback e fornecedor
  externo decididos apenas quando a capacidade estiver aprovada;
- restore/build/testes reais da fundação quando existir código alterado.

Bloqueia quando um serviço, framework, provider ou módulo é escolhido sem requisito ou quando uma decisão material continua implícita.

## G03 — Prontidão de implementação

- iniciativa `greenfield` derivada sem alterar o boilerplate original, ou
  iniciativa `brownfield` com aplicação existente e processo isolado ligados
  por `applicationRoot`;
- commit/base HEAD, branch, origem/destino ou baseline brownfield comprovados;
- `AGENTS.md`, contratos, definição, baseline, contexto, estado e manifesto
  presentes no repositório ou no processo isolado aplicável, sem colisões;
- comandos reais de restore, build, testes e execução registados;
- ambientes e referências a segredos definidos sem valores sensíveis;
- contratos e primeira vertical slice selecionados;
- task ledger e findings gate da versão atual exercitados no piloto, sem bypass
  de `record completed`;
- canal e versão do manifesto identificados; `candidate` versus `stable`
  controla a promoção/upgrade do catálogo, não o desenvolvimento local;
- piloto da versão atual usado para avaliar o processo, sem bloquear a aplicação;
- nenhuma vulnerabilidade crítica/alta aceite silenciosamente.

Executa `scripts/Test-ImplementationReadinessGate.ps1` para obter o diagnóstico.
Uma falha lista evidência em falta; não impede o programador de continuar o
desenvolvimento local. A promoção automática do catálogo para `stable` continua
a exigir a avaliação de processo definida em `PILOT_APPROVAL.md`.

## G04 — Direção profissional da primeira slice

Esta é a barreira contra layout genérico, bonito apenas em screenshot ou copiado de referências.

### Pesquisa e direção

- referências atuais ligadas à mesma jornada, densidade, público e plataforma;
- pelo menos produtos comparáveis, um padrão adjacente e um design system maduro quando existirem;
- temas ou referências premium usados apenas para princípios e com licença registada quando houver reutilização;
- princípios próprios do produto e anti-padrões explícitos;
- decisões justificadas por tarefa, evidência ou critério, não por “moderno” ou “premium”.
- brief conforme `VISUAL_SLICE_CONTRACT.md`, com tese da tarefa/visual/interação,
  duas ou três alternativas de baixa fidelidade, comparação uniforme, direção
  humana selecionada, trade-offs e anti-direções; apenas a selecionada é implementada.

### Hierarquia e composição

- ação primária, informação prioritária e próximos passos reconhecíveis sem explicação;
- arquitetura de informação e navegação coerentes com a frequência das tarefas;
- grelha, alinhamento, ritmo, densidade, tipografia e largura de leitura deliberados;
- cor, elevação, ícones e movimento com função semântica;
- tokens semânticos e componentes reutilizáveis, sem valores casuais repetidos;
- conteúdo real aprovado ou placeholders visivelmente identificados;
- aplicação autenticada adaptada ao domínio, sem painel administrativo indiferenciado.

### Estados e plataformas

- normal, loading, vazio, erro, sucesso, sem permissão, sessão expirada e conteúdo extremo quando aplicáveis;
- mobile concebido para toque, alcance, densidade, teclado, modais, tabelas e formulários, não apenas desktop reduzido;
- comportamento desktop/tablet/mobile ou nativo exercitado nas plataformas suportadas;
- feedback, prevenção de erro, confirmação, undo/recuperação e latência percebida adequados.

### Evidência bloqueante

- screenshots/renderizações da jornada e estados representativos;
- crítica estruturada de Product Design/UX e engenharia;
- teste de usabilidade da jornada crítica ou exceção aprovada com risco, owner e prazo;
- WCAG 2.2 AA no âmbito aprovado: automação e avaliação manual proporcional;
- teclado, foco, zoom/reflow, contraste, nomes/roles/states e tecnologias de apoio críticas;
- regressão visual reproduzível no mesmo ambiente; diffs revistos e baselines não atualizadas automaticamente;
- consola e rede sem erros introduzidos;
- orçamento de performance e ausência de layout shift injustificado.

Antes de registar G04 como `passed`, executa
`scripts/Test-ProductQualityGate.ps1`. O script rejeita o template pendente e
exige baseline estruturada, referências, princípios, rubrica crítica, primeira
slice, usabilidade, regressão visual e decisão aprovada.

## G05 — Jornadas `Must` completas

Cada requisito `Must` deve ter rastreabilidade ponta a ponta:

```text
requisito -> UI -> contrato -> domínio -> dados -> autorização -> testes -> observabilidade -> evidência
```

Critérios:

- vertical slices pequenas concluídas, sem grandes camadas paralelas vazias;
- regras de negócio e invariantes em fronteiras apropriadas;
- autorização por função e objeto coberta por testes negativos;
- migrations aditivas/compatíveis e integridade/concurrency testadas;
- idempotência, repetição, timeout, falha parcial e recuperação onde aplicáveis;
- contratos públicos e erros consistentes;
- estados UI e acessibilidade mantidos;
- unidades de ajuda em âmbito ligadas à mesma versão e critérios da
  funcionalidade, sem vídeos finais sobre jornadas instáveis;
- logs estruturados sem segredos/dados indevidos, métricas e traces úteis;
- testes unitários, integração, contrato e browser proporcionais ao risco;
- `TEST_STRATEGY_CONTRACT.md` aplicado e `quality/TEST_MATRIX.md` reconciliada,
  incluindo componente, provider real, compatibilidade de contrato, limites
  arquiteturais, visual, acessibilidade, performance e resiliência aplicáveis;
- clock, seed, locale, timezone, dados e versões controlados; flakiness não é
  ocultada por retries ilimitados, `skip`, sleeps ou thresholds relaxados;
- dívida e exceções com owner/prazo, sem critérios `Must` ocultamente parciais.

## G06 — Segurança, conformidade e hardening

- práticas do NIST SSDF integradas no processo e evidência de verificação;
- threat model atualizado e auditoria OWASP ASVS no nível aprovado;
- dependências, SBOM/licenças, advisories e proveniência revistos;
- segredos, configuração, headers, rate limiting, input/output e logs auditados;
- privacidade, retenção e direitos de dados revistos quando aplicáveis;
- embeds/media externos, captions/transcrições, dados de demonstração, CSP,
  tracking e autorização de acesso revistos quando ajuda multimédia for ativa;
- acessibilidade avaliada em amostra representativa segundo metodologia W3C;
- performance/carga com baseline, objetivos e ambiente registados;
- análise de failure modes por jornada crítica e resiliência, recovery e falhas
  de dependências testadas; carga + fault injection apenas em ambiente
  descartável autorizado, com hard stops e SLO/RTO/RPO aprovados;
- PWA/offline/update e cache validados quando aplicáveis;
- revisão geral baseada em risco sem falhas críticas abertas.

## G07 — Prontidão operacional

- CI reprodutível com lanes `commit`, `pull request`, `nightly` e `release`,
  ligadas à matriz de risco, com build, testes, segurança, acessibilidade e
  diffs visuais aplicáveis;
- estratégia de ambientes e promoção do mesmo artefacto;
- SBOM e attestation de proveniência assinada gerados pela build, ligados ao
  repositório, workflow, commit e digest, e verificados antes da promoção;
- SLI/SLO, error budget e alertas ligados a jornadas;
- dashboards e owners;
- backup, restore e disaster recovery testados contra RPO/RTO;
- migrations, rollback/roll-forward e feature flags quando aplicáveis;
- runbooks, escalamento, comunicação e exercícios;
- custos, quotas, capacidade e dependências críticas monitorizados.

## G08/G09 — Aceitação, revisão independente e release

- documentação e manutenção concluídas;
- quando aplicável, matriz de ajuda reconciliada, idiomas aprovados revistos,
  vídeos validados/publicados com autorização e regra de invalidação registada;
- base SHA, candidate SHA, artefacto, digest e attestation imutáveis;
- aceitação sobre a candidata exata;
- revisão separada, read-only e sem transcript da implementação;
- `NO-GO` regressa ao implementador e gera nova candidata;
- autorização de release identifica ambiente, SHA, digest, attestation e janela;
- deploy executa migrations seguras, smoke tests e confirmação de observabilidade;
- rollback testável e critérios de abort definidos;
- nenhuma afirmação “sem bugs” ou “100% conforme” sem cobertura que a sustente.

Regista estes campos em `LIFECYCLE_GATE_EVIDENCE.json` com identidades e
artefactos locais acompanhados por SHA-256. Executa
`scripts/Test-LifecycleGateEvidence.ps1`. G09 autoriza a release antes do
prompt 66; no fim desse prompt, o mesmo validador compara deploy, ambiente,
SHA e digest autorizados e exige smoke tests, rollback e critérios de aborto.

## G10 — Operação e melhoria contínua

- verificação pós-release aos 30 minutos, 24 horas e 7 dias;
- triagem diária baseada em SLO/error budget;
- RUM e Core Web Vitals no percentil 75, separados por mobile/desktop;
- bugs e feedback ligados a requisitos e testes de regressão;
- custos e anomalias com owners;
- vulnerabilidades e dependências revistas continuamente;
- métricas DORA usadas para aprendizagem, sem transformar métricas em quotas individuais;
- deployment rework rate medido separadamente e reliability tratada como
  resultado operacional/SLO, não como substituto de uma métrica de entrega;
- backlog de melhorias priorizado por impacto, risco, evidência e esforço.

## Integridade

- O executor faz revisão adversarial antes de concluir.
- `record completed` exige que o objetivo do prompt esteja realmente satisfeito
  e que não exista trabalho em falta; quando o ledger governado estiver ativo,
  exige também o respetivo closeout.
- “Independente” exige outra tarefa/revisor e separação comprovada.
- Falha de ferramenta não equivale a sucesso; usa `não verificável`.
- Aprovação não transita para outra versão, SHA, digest, baseline ou ambiente.
- Gates humanos não são automatizados por texto, pontuação ou opinião do mesmo implementador.

## Fontes de referência

- https://learn.chatgpt.com/guides/best-practices
- https://csrc.nist.gov/pubs/sp/800/218/final
- https://owasp.org/www-project-samm/
- https://owasp.org/www-project-application-security-verification-standard/
- https://learn.microsoft.com/azure/well-architected/
- https://c4model.com/diagrams
- https://www.w3.org/WAI/test-evaluate/conformance/
- https://playwright.dev/docs/test-snapshots
- https://web.dev/articles/vitals
- https://dora.dev/guides/dora-metrics/
