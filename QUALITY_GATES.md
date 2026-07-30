# Gates profissionais de qualidade

Este documento define o mínimo observável para o processo declarar que uma aplicação está pronta para a etapa seguinte. Complementa os prompts; não substitui os critérios específicos, `PRODUCT_DEFINITION.md`, `PRODUCT_QUALITY_BASELINE.md` ou a evidência executável.

Estados permitidos: `passou`, `falhou`, `não verificável` e `não aplicável com justificação`. Um critério bloqueante só passa com evidência ligada à versão atual.

## G01 — Definição do produto

Validador: `scripts/Test-ProductDefinitionGate.ps1`.

- problema, público, job to be done e jornada principal concretos;
- procura, alternativas, acesso ao público e diferenciação sustentados;
- MVP, exclusões, orçamento, prazo e métrica de decisão;
- requisitos `Must` aprovados, singulares e verificáveis;
- especificação detalhada e checklist legível do programador em paridade por
  página, funcionalidade, requisito e critério de aceitação;
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
- piloto da versão atual sem falha crítica e com avaliação exigida;
- nenhuma vulnerabilidade crítica/alta aceite silenciosamente.

Executa `scripts/Test-ImplementationReadinessGate.ps1`. O gate permanece
bloqueado se `PILOT_APPROVAL.md` não indicar 15/15 na mesma `catalogVersion`,
zero falhas críticas, avaliação humana e revisor separado.

## G04 — Direção profissional da primeira slice

Esta é a barreira contra layout genérico, bonito apenas em screenshot ou copiado de referências.

### Pesquisa e direção

- referências atuais ligadas à mesma jornada, densidade, público e plataforma;
- pelo menos produtos comparáveis, um padrão adjacente e um design system maduro quando existirem;
- temas ou referências premium usados apenas para princípios e com licença registada quando houver reutilização;
- princípios próprios do produto e anti-padrões explícitos;
- decisões justificadas por tarefa, evidência ou critério, não por “moderno” ou “premium”.

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
- logs estruturados sem segredos/dados indevidos, métricas e traces úteis;
- testes unitários, integração, contrato e browser proporcionais ao risco;
- dívida e exceções com owner/prazo, sem critérios `Must` ocultamente parciais.

## G06 — Segurança, conformidade e hardening

- práticas do NIST SSDF integradas no processo e evidência de verificação;
- threat model atualizado e auditoria OWASP ASVS no nível aprovado;
- dependências, SBOM/licenças, advisories e proveniência revistos;
- segredos, configuração, headers, rate limiting, input/output e logs auditados;
- privacidade, retenção e direitos de dados revistos quando aplicáveis;
- acessibilidade avaliada em amostra representativa segundo metodologia W3C;
- performance/carga com baseline, objetivos e ambiente registados;
- resiliência, recovery e falhas de dependências testadas;
- PWA/offline/update e cache validados quando aplicáveis;
- revisão geral baseada em risco sem falhas críticas abertas.

## G07 — Prontidão operacional

- CI reprodutível com build, testes, segurança, acessibilidade e diffs visuais aplicáveis;
- estratégia de ambientes e promoção do mesmo artefacto;
- SLI/SLO, error budget e alertas ligados a jornadas;
- dashboards e owners;
- backup, restore e disaster recovery testados contra RPO/RTO;
- migrations, rollback/roll-forward e feature flags quando aplicáveis;
- runbooks, escalamento, comunicação e exercícios;
- custos, quotas, capacidade e dependências críticas monitorizados.

## G08/G09 — Aceitação, revisão independente e release

- documentação e manutenção concluídas;
- base SHA, candidate SHA, artefacto e digest imutáveis;
- aceitação sobre a candidata exata;
- revisão separada, read-only e sem transcript da implementação;
- `NO-GO` regressa ao implementador e gera nova candidata;
- autorização de release identifica ambiente, SHA, digest e janela;
- deploy executa migrations seguras, smoke tests e confirmação de observabilidade;
- rollback testável e critérios de abort definidos;
- nenhuma afirmação “sem bugs” ou “100% conforme” sem cobertura que a sustente.

Regista estes campos em `LIFECYCLE_GATE_EVIDENCE.json` com identidades e
artefactos locais acompanhados por SHA-256. Executa
`scripts/Test-LifecycleGateEvidence.ps1`. G09 autoriza a release antes do
prompt 64; no fim desse prompt, o mesmo validador compara deploy, ambiente,
SHA e digest autorizados e exige smoke tests, rollback e critérios de aborto.

## G10 — Operação e melhoria contínua

- verificação pós-release aos 30 minutos, 24 horas e 7 dias;
- triagem diária baseada em SLO/error budget;
- RUM e Core Web Vitals no percentil 75, separados por mobile/desktop;
- bugs e feedback ligados a requisitos e testes de regressão;
- custos e anomalias com owners;
- vulnerabilidades e dependências revistas continuamente;
- métricas DORA usadas para aprendizagem, sem transformar métricas em quotas individuais;
- backlog de melhorias priorizado por impacto, risco, evidência e esforço.

## Integridade

- O executor faz revisão adversarial antes de concluir.
- `record completed` exige objetivos concluídos, verificação observável,
  autorrevisão adversarial registada e zero findings `open`/`blocked` na mesma
  tentativa.
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
