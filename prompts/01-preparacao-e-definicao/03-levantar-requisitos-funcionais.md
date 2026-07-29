# Especificar requisitos verificáveis por aplicação e página

## Resultado pedido

Transforma a oportunidade, o público, o problema, o nome de trabalho e o MVP
preliminar aprovados nos prompts 01 e 02 numa especificação de produto
versionada que elimine interpretações materiais incompatíveis.

No fim, produto, arquitetura, design, engenharia e QA devem conseguir responder,
com os mesmos IDs e fontes, a sete perguntas:

1. que resultado cada ator autorizado pode obter;
2. que comportamento observável o produto tem de fornecer;
3. que regras, dados, estados, permissões, integrações e qualidades condicionam
   esse comportamento;
4. em que aplicações o comportamento existe, é partilhado, diverge ou não se
   aplica, e porquê;
5. que páginas/ecrãs, rotas, estados e ações realizam cada passo da jornada;
6. como cada requisito será aceite e provado;
7. que dúvidas ainda impedem uma decisão responsável.

Esta é uma tarefa de descoberta e documentação. Não implementes código, não
escolhas arquitetura ou fornecedores e não decidas o Gate A.

## Pacote da tarefa

### Contexto obrigatório

Usa, por esta ordem:

1. os `AGENTS.md` ou `AGENTS.override.md` aplicáveis;
2. `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`, `APP_CONTEXT.md`,
   `IMPLEMENTATION_STATUS.md` e `PRODUCT_DEFINITION.md`;
3. o [contrato detalhado dos artefactos](03-contrato-detalhado-de-requisitos.txt),
   que deves ler integralmente antes de redigir requisitos;
4. `[FONTES_DE_REQUISITOS]` e as fontes explicitamente ligadas a partir delas;
5. numa iniciativa brownfield, código, configuração, testes, dados de operação
   autorizados e comportamento reproduzível, sempre classificados como
   `comportamento observado`, não como decisão de produto.

Descobre primeiro os caminhos e comandos reais com pesquisa local. Não assumas
que um ficheiro, módulo, role, integração ou comando existe por constar num
boilerplate, exemplo ou documento antigo.

### Artefactos obrigatórios

Cria ou atualiza, sem duplicar equivalentes:

- `requirements/REQUIREMENTS_SPECIFICATION.md`;
- `requirements/REQUIREMENTS_TRACEABILITY.md`;
- `requirements/APPLICATION_CATALOG.md`;
- `requirements/PAGE_CATALOG.md`;
- `PRODUCT_DEFINITION.md`;
- `IMPLEMENTATION_STATUS.md`.

Cria ainda um contrato em `requirements/applications/APP-<slug>.md` por
aplicação ativa e um contrato em `requirements/pages/PAGE-<slug>.md` por
página/ecrã em âmbito. Não cries ficheiros para aplicações ou páginas
hipotéticas; regista a decisão `não aplicável` ou a questão no índice.

Todos os artefactos de requisitos devem declarar versão, data, âmbito, fontes,
autores/revisores, owner de produto, estado e histórico de alterações. Se o
projeto já tiver equivalentes canónicos, usa-os e regista os seus caminhos.
Os dois catálogos são índices curtos; o detalhe por aplicação/página fica nos
ficheiros modulares para as etapas seguintes carregarem apenas o contexto da
fatia atual.

### Limites de autoridade

O pedido autoriza leitura, pesquisa, edição documental local e validação
não destrutiva dentro destes artefactos. Não autoriza:

- alterações de código, schema, infraestrutura ou configuração de runtime;
- criação ou alteração de contas, dados externos, remotes ou serviços;
- envio de mensagens, compras, pagamentos ou chamadas reais de integrações;
- aprovação de pressupostos, requisitos ou gates em nome de um stakeholder;
- recolha ou registo de segredos e dados pessoais reais.

Conserva o Gate A como `PENDENTE`. Só o prompt 04 pode produzir a decisão
`GO`, `REWORK` ou `NO-GO`.

## Pré-condições e triagem

Antes de escrever requisitos, confirma com evidência:

- prompts 01 e 02 concluídos;
- uma única oportunidade, público principal, problema, job to be done,
  proposta de valor, MVP preliminar e nome de trabalho aprovados;
- owner de produto, restrições materiais e fontes suficientes para decidir a
  jornada principal;
- âmbito e exclusões distinguíveis de ideias futuras.

Se houver várias hipóteses de produto incompatíveis, uma decisão material em
falta ou nenhuma fonte capaz de sustentar a jornada principal, não preenchas a
lacuna. Regista:

```text
Bloqueio -> IDs/decisões afetados -> evidência necessária
         -> owner -> prompt a repetir -> trabalho seguro preservado
```

Uma lacuna localizada não invalida todo o levantamento. Continua o trabalho
independente, mantém os itens afetados em `bloqueado` e nunca os promove a
`Must aprovado`.

## Protocolo de execução para o Codex

Mantém um plano curto por fases e avança autonomamente entre elas. Não pares para
pedir aprovação de passos locais já autorizados. Se uma resposta humana for
material, esgota primeiro as fontes disponíveis e apresenta uma única pergunta
agrupada com opções, impacto e recomendação; numa execução não interativa,
regista o bloqueio e conclui o trabalho seguro restante.

Em cada fase:

- começa pelo resultado que a fase tem de provar;
- lê apenas as fontes relevantes, mas lê por inteiro cada instrução ou contrato
  selecionado;
- atualiza os artefactos à medida que descobres evidência;
- regista decisões e racional breve, não raciocínio interno detalhado;
- não despejes templates vazios nem marques `não aplicável` sem justificação;
- preserva IDs existentes e nunca renumera requisitos para fechar lacunas.

### Fase 0 — enquadrar e medir a entrada

1. Resume objetivo, dentro/fora do âmbito, público, jornada principal,
   restrições, artefactos e critério de conclusão.
2. Cria a matriz de fontes definida no contrato detalhado.
3. Classifica cada fonte por autoridade, atualidade, cobertura, confiança e
   limitações.
4. Lista conflitos e decisões desconhecidas antes de gerar requisitos.
5. Define a cobertura esperada por jornada, capacidade, aplicação e
   página/ecrã, não uma quantidade arbitrária de requisitos.

Resultado da fase: um mapa de entrada que distingue factos, decisões aprovadas,
evidência observada, inferências e lacunas.

### Fase 1 — compreender domínio, atores, aplicações e resultado

1. Constrói o glossário operacional com termos proibidos ou ambíguos.
2. Identifica stakeholders, atores humanos/sistemas, objetivos, contexto,
   frequência e responsabilidade.
3. Modela objetos de negócio, eventos, estados, unidades, tempo, moedas,
   mercados e idiomas materiais.
4. Cria o mapa de capacidades e liga cada `Must` à jornada principal ou a uma
   obrigação bloqueante.
5. Define atores e permissões sem inferir roles, tenancy, ownership ou acesso
   administrativo.
6. Inventaria apenas as aplicações necessárias como `APP-###`, define a
   responsabilidade de cada uma e constrói a matriz
   `capacidade × aplicação`.

Resultado da fase: linguagem comum, fronteira do produto, atores, aplicações e
capacidades necessárias, com exclusões explícitas e sem assumir paridade entre
SSR, Web/PWA, MAUI, API, jobs ou integrações.

### Fase 2 — especificar uma jornada e as suas páginas de cada vez

Trabalha por ordem de prioridade. Para cada `JRN-###`:

1. descreve trigger, pré-condições, happy path, alternativas, falhas,
   recuperação, pós-condições e resultado mensurável;
2. atribui cada passo a uma `APP-###` e `PAGE-###`, ou identifica explicitamente
   a operação não visual de API/job/integração que o realiza;
3. atualiza o mapa de navegação/entrada/saída e cria o contrato detalhado de
   cada página/ecrã novo;
4. resolve por página dados, ações, formulários, permissões, estados,
   recuperação, responsive/adaptação, acessibilidade, conteúdo, telemetria e
   SEO quando aplicável;
5. deriva `FR-###` atómicos em pequenos lotes e liga-os a `APP/PAGE`;
6. valida o lote e a cobertura da jornada antes de passar à seguinte;
7. liga exclusões para impedir que reapareçam implicitamente.

Não tentes gerar todo o catálogo num único passe. Um requisito é atómico quando
um comportamento pode ser priorizado, implementado e testado sem esconder um
segundo comportamento normativo.

Resultado da fase: jornadas completas e requisitos funcionais ligados a atores,
aplicações, páginas, fontes, estados e resultados observáveis, sem passos nem
páginas órfãos.

### Fase 3 — fechar contratos transversais

Para cada requisito funcional e jornada, avalia explicitamente:

- `APP-###` e `PAGE-###`: aplicabilidade, contrato comum e divergências
  justificadas entre aplicações/páginas;
- `BR-###`: regras, cálculos, precedência, invariantes e máquinas de estado;
- `DATA-###`: semântica, classificação, qualidade, ownership, ciclo de vida,
  retenção, correção, exportação e eliminação;
- `PERM-###`: ação, objeto, âmbito, ownership, negação e auditoria;
- `INT-###`: fronteira externa, contrato observável, timeout, repetição,
  idempotência, falha, fallback e reconciliação;
- `NFR-###`: qualidade mensurável nas condições em que importa;
- `SEC-###`: segurança e privacidade conhecidas antes do threat model.

Usa `não aplicável` apenas com razão específica. Uma categoria ignorada não
equivale a uma categoria avaliada.

Resultado da fase: cada comportamento `Must` tem as condições transversais que
podem alterar a implementação ou o teste.

### Fase 4 — tornar a especificação executável

1. Escreve critérios `AC-<REQ>-##` com estado inicial, evento, resultado
   observável, efeito persistente e ausência de efeito indevido quando material.
2. Cobre caso principal, erro, fronteira de acesso, limite, repetição,
   concorrência, falha parcial e recuperação onde forem aplicáveis.
3. Indica a prova prevista: produto, unidade, integração, contrato, browser,
   acessibilidade, segurança, performance ou operação.
4. Completa a matriz bidirecional:

```text
fonte -> jornada/passo -> APP -> PAGE ou operação não visual -> requisito
      -> regra/dado/permissão/integração/qualidade -> aceitação
      -> prova prevista -> fatia vertical candidata
```

5. Propõe fatias verticais pequenas e utilizáveis. Para uma página, prepara o
   mapeamento `PAGE × APP/superfície -> 25 -> 13|15|17 -> 26`; para uma
   capacidade partilhada ou não visual, prepara `27 -> superfície aplicável
   -> 28`. Não seleciones a fatia no lifecycle nem antecipes arquitetura.

Resultado da fase: especificação navegável da necessidade até à prova e ao
primeiro corte de entrega.

### Fase 5 — revisão adversarial e correção

Executa uma segunda passagem separada da redação:

1. procura requisitos compostos, vagos, duplicados, contraditórios, órfãos,
   não necessários ou que impõem solução;
2. tenta construir duas implementações semanticamente incompatíveis que
   satisfaçam o mesmo requisito e critérios; se conseguires, corrige-os;
3. procura contraexemplos nos limites, estados inválidos, permissões por objeto,
   outro owner/tenant, conteúdo extremo, repetição, concorrência, timeout,
   dependência indisponível e sucesso parcial;
4. verifica unidades, inclusividade de limites, precisão, arredondamento,
   calendário, timezone, moeda e localização;
5. confirma que código, benchmark, mockup ou preferência não foram promovidos
   a requisito aprovado;
6. procura aplicações, páginas, passos, ações, estados e requisitos órfãos;
7. tenta executar cada página com utilizador anónimo/autorizado/negado,
   loading/vazio/erro/sucesso, conteúdo extremo, rede degradada, repetição e
   concorrência onde aplicável;
8. confirma que diferenças entre aplicações refletem uma necessidade de
   utilizador/plataforma aprovada, não conveniência técnica;
9. valida links, IDs, referências cruzadas e contagens do relatório de
   cobertura.

Resultado da fase: lacunas corrigidas ou expostas com IDs, impacto, owner e
evidência necessária.

### Fase 6 — consolidar e entregar

1. Atualiza os seis artefactos obrigatórios e os contratos modulares
   `APP/PAGE` aplicáveis.
2. Revê o diff documental e confirma que alterações não relacionadas ficaram
   intactas.
3. Executa os validadores documentais reais que existirem no repositório.
4. Regista comandos, exit codes e limitações; não inventes testes executados.
5. Produz uma entrega orientada à decisão, com conclusão primeiro.

## Regras de escrita dos requisitos

- Usa IDs estáveis do contrato detalhado e uma declaração normativa por item.
- Cada requisito, critério e passo de jornada aplicável identifica `APP-###` e
  `PAGE-###`, ou justifica explicitamente a sua natureza não visual.
- Escreve o que é necessário e observável; não prescrevas a solução.
- Usa termos do glossário, voz ativa e sujeito inequívoco.
- Substitui “rápido”, “seguro”, “intuitivo”, “robusto”, “adequado”,
  “escalável”, “em tempo real” e equivalentes por medida, limiar, condições e
  método de verificação.
- Declara tolerâncias, unidades, população, percentil e janela quando materiais.
- Se um valor ainda não tiver baseline, define como medi-lo, owner e prazo; não
  inventes a meta.
- Se duas fontes discordarem, mantém o conflito visível e não escolhas
  silenciosamente a opção mais comum.
- Separa sempre estado de evidência, estado de aprovação e evidência de
  implementação.
- Não assumes que a mesma capacidade existe em todas as aplicações nem que a
  mesma página tem comportamento idêntico em SSR, Web/PWA e MAUI.
- Não exposes passwords, tokens, connection strings, dados pessoais reais ou
  conteúdo privado em exemplos, logs ou screenshots.

## Estrutura mínima da especificação

`REQUIREMENTS_SPECIFICATION.md` deve permitir navegação nesta ordem:

1. controlo do documento, objetivo, âmbito e exclusões;
2. fontes, confiança, pressupostos e conflitos;
3. glossário e mapa de domínio;
4. mapa de capacidades;
5. inventário e fronteiras `APP`;
6. catálogo, navegação e cobertura `PAGE`;
7. atores e permissões;
8. jornadas ponta a ponta;
9. catálogos `FR`, `BR`, `DATA`, `PERM`, `INT`, `NFR` e `SEC`;
10. máquinas de estado, regras de cálculo e invariantes;
11. cenários de aceitação;
12. fatias verticais candidatas;
13. questões e decisões;
14. relatório de cobertura e estado de aprovação.

`REQUIREMENTS_TRACEABILITY.md` deve fornecer vistas por fonte, jornada,
aplicação, página, requisito, prova e fatia, além de identificar órfãos e
ligações quebradas.

`APPLICATION_CATALOG.md` e `PAGE_CATALOG.md` devem indexar contratos modulares,
estado, aprovação, dependências e cobertura sem duplicar o detalhe desses
ficheiros.

## Relatório de cobertura obrigatório

Apresenta contagens, IDs em falta e resultado `passou/falhou`, pelo menos para:

- fontes e objetivos `Must` cobertos;
- aplicações ativas com contrato `APP` completo;
- capacidades `Must` com aplicabilidade decidida em cada aplicação relevante;
- páginas/ecrãs em âmbito com contrato `PAGE` completo e entrada/saída
  navegável;
- passos das jornadas `Must` mapeados a `APP/PAGE` ou operação não visual;
- ações de página ligadas a `FR/PERM/DATA/AC`;
- estados aplicáveis por página decididos, com recuperação observável;
- divergências entre aplicações justificadas e contrato comum preservado;
- `Must` com fonte, aprovação e aceitação observável;
- jornadas com falha e recuperação;
- requisitos com dados e permissões avaliados;
- integrações com falha/reconciliação avaliadas;
- NFR/SEC materiais mensuráveis;
- critérios com prova prevista;
- páginas públicas com decisão de status HTTP, canonical, robots, metadata,
  sitemap e dados estruturados quando aplicável;
- páginas interativas com requisitos responsive/adaptive e acessibilidade;
- páginas com mutações com validação, autorização, prevenção de duplicação,
  concorrência, feedback e recuperação avaliados;
- cada `PAGE × APP` com implementação distinta mapeado à fatia/prompt
  downstream aplicável;
- ligações bidirecionais válidas;
- conflitos e questões bloqueantes em aberto.

Uma linha bloqueante que falhe impede o estado `concluído`.

## Critério de conclusão

Usa:

- `concluído` apenas quando todos os `Must` da versão estão aprovados pelo
  owner, a jornada principal é inequívoca, todas as aplicações e páginas em
  âmbito têm contratos completos, a rastreabilidade está completa, os critérios
  são observáveis, o relatório não tem falhas bloqueantes e a revisão identifica
  a versão atual;
- `parcial` quando existe especificação útil mas restam lacunas não bloqueantes;
- `bloqueado` quando falta uma decisão ou fonte material para aprovar um
  `Must`, indicando IDs, owner, evidência e prompt a repetir.

Não declares `GO`, não preenchas DOR-12 e não apresentes um pressuposto como
aprovação.

## Formato da entrega

Começa pela conclusão e inclui:

- estado honesto e razão;
- versão e caminhos dos artefactos;
- âmbito, exclusões, atores, jornadas e requisitos `Must`;
- inventário `APP`, catálogo `PAGE`, mapa de navegação e divergências entre
  aplicações;
- regras, dados, permissões, integrações e NFR/SEC materiais;
- fatias verticais candidatas;
- relatório de cobertura;
- conflitos, questões e decisões necessárias;
- fontes e limitações;
- comandos/validações executados e respetivos resultados;
- confirmação de que o Gate A permanece `PENDENTE`.

Omite introduções genéricas e repetição. Conserva toda a evidência, decisão,
ressalva e próximo passo necessários para revisão.

## Referências oficiais

- OpenAI, Codex best practices:
  https://learn.chatgpt.com/guides/best-practices
- OpenAI, Prompting:
  https://learn.chatgpt.com/docs/prompting
- OpenAI, Model guidance e prompting best practices:
  https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6
- OpenAI, AGENTS.md:
  https://learn.chatgpt.com/docs/agent-configuration/agents-md
- OpenAI, Execution Plans para Codex:
  https://developers.openai.com/cookbook/articles/codex_exec_plans
- ISO/IEC/IEEE 29148:2018, Requirements engineering:
  https://www.iso.org/standard/72089.html
- ISO/IEC 25010:2023, Product quality model:
  https://www.iso.org/standard/78176.html
- NASA, How to Write a Good Requirement:
  https://www.nasa.gov/reference/appendix-c-how-to-write-a-good-requirement/
- Cucumber, Gherkin Reference:
  https://cucumber.io/docs/gherkin/reference/
- RFC 8174, requirement levels:
  https://www.rfc-editor.org/rfc/rfc8174.html
- OWASP ASVS:
  https://owasp.org/www-project-application-security-verification-standard/
- W3C, WCAG 2.2:
  https://www.w3.org/TR/WCAG22/
- W3C, estrutura acessível da página:
  https://www.w3.org/WAI/tutorials/page-structure/
- W3C, conformidade em páginas completas e processos completos:
  https://www.w3.org/WAI/WCAG22/Understanding/conformance
- GOV.UK Design System, padrões por tarefa e tipo de página:
  https://design-system.service.gov.uk/patterns/
- OpenAPI Specification:
  https://spec.openapis.org/oas/latest.html
- Android, core/adaptive app quality:
  https://developer.android.com/develop/adaptive-apps/quality-guidelines/core-app-quality
- Apple Human Interface Guidelines:
  https://developer.apple.com/design/human-interface-guidelines/
- Google Search, crawling e indexação por página:
  https://developers.google.com/search/docs/crawling-indexing

## Sinais comunitários avaliados

Estes sinais ajudam a organizar contexto para o Codex, mas não substituem
normas, fontes de produto ou validação no projeto:

- OpenAI Developer Community, contexto modular repo-native:
  https://community.openai.com/t/a-repo-native-context-pattern-for-codex-agents-md-index-md-searchable-tags/1386068
- OpenAI Developer Community, práticas para ficheiros Markdown:
  https://community.openai.com/t/what-are-you-md-files-best-practices/1386098/2
