# Contexto central da aplicação

Este ficheiro reúne os dados não sensíveis usados para resolver os valores entre `[COLCHETES]` nos prompts. Deve ser copiado para a raiz da aplicação derivada de `BoilerPlateAdvance` e atualizado a partir do código, configuração, requisitos e decisões aprovadas.

## Regras de utilização

1. Antes de executar um prompt, extrai todos os placeholders nele existentes.
2. Resolve-os pela seguinte ordem de precedência:
   1. decisão explícita e aprovada do responsável pelo produto;
   2. valor `confirmado` neste ficheiro;
   3. requisitos, ADRs e matrizes aprovadas;
   4. código e configuração efetivamente executados;
   5. documentação do projeto;
   6. inferência reversível, sempre identificada como tal.
3. Se duas fontes materiais divergirem, não escolhas silenciosamente: regista o conflito e usa `bloqueado`.
4. Nunca guardes passwords, tokens, connection strings, certificados privados, recovery codes ou chaves neste ficheiro. Guarda apenas o nome da variável de ambiente ou referência ao cofre.
5. Não infiras decisões de produção, legais, financeiras, de retenção, identidade externa ou publicação apenas a partir do código.
6. Atualiza a fonte, o estado e a data sempre que um valor mudar.

Estados permitidos:

- `confirmado` — comprovado por uma fonte aprovada;
- `inferido` — deduzido de evidência, mas ainda não aprovado;
- `pendente` — necessita de decisão ou informação;
- `não aplicável` — não faz parte do produto;
- `bloqueado` — existe conflito ou ausência que impede avançar.

## Preenchimento mínimo por gate

Não transformes todos os campos pendentes em bloqueio antecipado. Resolve apenas os dados materiais para o gate atual e mantém o restante explicitamente `pendente` ou `não aplicável`.

| Gate/condição | Antes de | Campos mínimos confirmados |
|---|---|---|
| Entrada autónoma da descoberta | Prompt 01 | origem do boilerplate e acesso a pesquisa online; mercado, público, modelo, equipa, orçamento, prazo e restrições podem permanecer pendentes |
| Fecho da definição | Prompts 02–04 | oportunidade selecionada, responsável, mercados/limites relevantes, público, requisitos, orçamento, prazo, competências e decisões materiais exigidas pelo Gate A |
| A — definição do produto | Prompts 5–6 | `PRODUCT_DEFINITION.md` aprovado, decisão `GO`, DOR-01 a DOR-12 passados com evidência e prompts 01–04 concluídos |
| B — criação/adoção | Prompts 7–8 | Gate A válido, modo greenfield/brownfield, nomes técnico/público, requisitos `Must`, arquitetura, plataformas, módulos, threat model, origem/destino ou raiz existente, identificadores aplicáveis e destino GitHub quando autorizado |
| C — implementação | Prompts 9–56 | repositório/commit-base, comandos reais, piloto aprovado, baseline profissional, ambientes, vertical slice atual e critérios de aceitação |
| D — prontidão de release | Prompts 57–65 | CI, SLI/SLO, observabilidade, backup/DR, runbooks, documentação, candidata imutável, aceitação e revisão independente |
| E — produção e operação contínua | Prompts 66–75 | ambiente/artefacto alvo, owners, rollback, autorização externa/produção, monitorização pós-release e cadências operacionais |

O estado global do processo fica em `IMPLEMENTATION_STATUS.md`. Uma decisão material não confirmada bloqueia apenas o prompt que dela depende, salvo quando comprometer a segurança ou a validade de todas as etapas seguintes.

## Metadados deste contexto

| Campo | Valor | Estado | Fonte | Atualizado em |
|---|---|---|---|---|
| Produto/repositório | A preencher | pendente | — | — |
| Modo da iniciativa | `greenfield` ou `brownfield` | pendente | `software-lifecycle.ps1` | — |
| Commit ou versão de referência | A preencher | pendente | — | — |
| Responsável pelo contexto | A preencher | pendente | — | — |
| Última revisão completa | A preencher | pendente | — | — |

## Gate de definição do produto

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Artefacto de definição | `PRODUCT_DEFINITION.md` | pendente | Prompts 01–04 |
| Versão da definição | A preencher | pendente | `PRODUCT_DEFINITION.md` |
| Estado do documento | rascunho | pendente | `PRODUCT_DEFINITION.md` |
| Decisão do Gate A | PENDENTE | pendente | Prompt 04 |
| Evidência DOR-01 a DOR-12 | A preencher | pendente | `PRODUCT_DEFINITION.md` |
| Responsável/aprovador | A preencher | pendente | Decisão de produto |
| Data e evidência da aprovação | A preencher | pendente | Registo aprovado |

O Codex não pode resolver estes campos por inferência numa tarefa da etapa 2. Se o gate não estiver comprovado, deve manter o estado `bloqueado` e regressar ao prompt da etapa 1 indicado pelo finding.

## Identidade e posicionamento

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Nome técnico | A preencher | pendente | — |
| Nome público da aplicação | A preencher | pendente | — |
| Nome legal da entidade | A preencher | pendente | — |
| Nome comercial | A preencher | pendente | — |
| Descrição curta do produto | A preencher | pendente | — |
| Proposta de valor | A preencher | pendente | — |
| Posicionamento | A preencher | pendente | — |
| Público principal | A preencher | pendente | — |
| Segmentos secundários | A preencher | pendente | — |
| Atributos da marca | A preencher | pendente | — |
| Identificador reverso MAUI | A preencher | pendente | — |

Aliases resolvidos por esta secção:

- `[NOME_TECNICO]`
- `[NOME_PRODUTO]`, `[NOME_DA_APP]`, `[PRODUTO]`
- `[DESCRIÇÃO_DA_APP]`
- `[PROPOSTA_DE_VALOR]`
- `[POSICIONAMENTO]`
- `[PÚBLICO]`, `[PUBLICO_ALVO]`, `[PRODUTO/PÚBLICO]`, `[SEGMENTO]`
- `[ATRIBUTOS]`
- `[ENTIDADE]`, `[NOME_LEGAL]`, `[NOME_COMERCIAL]`
- `[IDENTIFICADOR_INVERSO]`

## Mercado e modelo de negócio

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Mercado principal | A preencher | pendente | — |
| Mercados adicionais | A preencher | pendente | — |
| Culturas/idiomas suportados | A preencher | pendente | — |
| Modelo de receita | A preencher | pendente | — |
| Plano de monetização aprovado | A preencher | pendente | — |
| Orçamento de implementação | A preencher | pendente | — |
| Custo máximo anual do domínio `.com` (valor, moeda e impostos) | A preencher | pendente | — |
| Prazo ou fase alvo | A preencher | pendente | — |
| Competências/recursos disponíveis | A preencher | pendente | — |
| Restrições de negócio | A preencher | pendente | — |

Aliases:

- `[MERCADO]`, `[MERCADO_ATUAL]`, `[MERCADO_PRIMARIO]`
- `[MERCADOS]`, `[MERCADOS_ALVO]`
- `[CULTURAS_SUPORTADAS]`
- `[MODELO]`
- `[PLANO_DE_MONETIZAÇÃO]`
- `[ORÇAMENTO]`, `[PRAZO]`, `[COMPETÊNCIAS]`, `[RESTRIÇÕES]`
- `[CUSTO_MAXIMO_ANUAL_DOMINIO]`

## Arquitetura e superfícies

Confirma estes valores no projeto derivado. São expectativas do `BoilerPlateAdvance`, não decisões automáticas para todas as aplicações.

| Capacidade/superfície | Caminho ou implementação | Estado | Fonte |
|---|---|---|---|
| Site público static SSR | `Client.Ssr` esperado | inferido | BoilerPlateAdvance |
| Aplicação autenticada Web/PWA | `Client.Web` esperado | inferido | BoilerPlateAdvance |
| UI/serviços partilhados | `Client.Core` esperado | inferido | BoilerPlateAdvance |
| Cliente nativo | `Client.Maui` quando aplicável | pendente | Decisão de arquitetura |
| API | `Server.Api` esperado | inferido | BoilerPlateAdvance |
| Projetos partilhados | A confirmar | pendente | Repositório |
| Projeto de testes | A confirmar | pendente | Repositório |
| Provider da base de dados | EF Core/SQLite esperado | inferido | BoilerPlateAdvance |
| Background jobs | A confirmar | pendente | Repositório/MODULES.md |
| Tempo real | A confirmar | pendente | Repositório/MODULES.md |
| Uploads/storage | A confirmar | pendente | Repositório/MODULES.md |
| Push notifications | A confirmar | pendente | Repositório/MODULES.md |
| Telemetria | OpenTelemetry esperado | inferido | BoilerPlateAdvance |

| Campo arquitetural | Valor | Estado | Fonte |
|---|---|---|---|
| Arquitetura aprovada/ADR | A preencher | pendente | — |
| Diagrama e fluxos de dados | A preencher | pendente | — |
| Plataformas ativas | A preencher | pendente | — |
| Plataformas MAUI | A preencher | pendente | — |
| Plataforma MAUI principal | A preencher | pendente | — |
| Módulos a manter | A preencher | pendente | — |
| Módulos a remover | A preencher | pendente | — |
| Decisões arquiteturais ainda pendentes | A preencher | pendente | — |

Aliases:

- `[ARQUITETURA_APROVADA]`, `[ARQUITETURA_E_JORNADAS]`
- `[SSR, WEB_PWA, MAUI]`
- `[SUPERFICIES_E_PLATAFORMAS]`
- `[PLATAFORMAS_MAUI]`, `[PLATAFORMA_PRIMARIA]`, `[PLATAFORMA_PRINCIPAL]`
- `[DECISAO_DE_MODULOS]`, `[DECISOES_APROVADAS]`, `[DECISOES_A_APLICAR]`

## Caminhos e comandos comprovados

| Finalidade | Valor real | Estado | Fonte |
|---|---|---|---|
| Raiz do BoilerPlateAdvance | A preencher | pendente | `software-lifecycle.ps1` regista o caminho absoluto validado |
| Raiz da aplicação | A preencher | pendente | Sistema de ficheiros |
| Solution filter Web | A preencher | pendente | Repositório |
| Projeto de testes | A preencher | pendente | Repositório |
| Comando de restore | A preencher | pendente | CI/AGENTS.md |
| Comando de build | A preencher | pendente | CI/AGENTS.md |
| Comando de testes | A preencher | pendente | CI/AGENTS.md |
| Comando de execução API | A preencher | pendente | Repositório |
| Comando de execução SSR | A preencher | pendente | Repositório |
| Comando de execução Web | A preencher | pendente | Repositório |
| Diretório de publicação | A preencher | pendente | Pipeline |

Aliases:

- `[MODO_INICIATIVA]`
- `[PASTA_ORIGEM_BOILERPLATE]`
- `[PASTA_DESTINO]`, `[RAIZ_APLICACAO_EXISTENTE]`
- `[PUBLISH_DIR]`

## Git e GitHub

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| GitHub owner | `critpoemail01` | confirmado | Decisão do responsável |
| Nome do repositório GitHub | A preencher | pendente | Nome técnico/decisão |
| Visibilidade GitHub | `private` por defeito | inferido | Política conservadora |
| Branch principal | `main` por defeito | inferido | Git/GitHub |
| Nome do remote | `origin` por defeito | inferido | Git |
| URL esperada do remote | A preencher | pendente | GitHub |
| Commit-base local/remoto | A preencher | pendente | Git |

Aliases:

- `[GITHUB_OWNER]`
- `[GITHUB_REPOSITORY]`
- `[GITHUB_VISIBILITY]`
- `[GITHUB_DEFAULT_BRANCH]`
- `[GIT_REMOTE_NAME]`
- `[GITHUB_REMOTE_URL]`

Estes campos definem o destino esperado, mas não autorizam a ação externa. A criação do repositório, o primeiro `push`, alterações de visibilidade, branch protection e regras de merge exigem as autorizações específicas da execução.

## Requisitos e jornadas

| Campo | Valor ou caminho para artefacto | Estado | Fonte |
|---|---|---|---|
| Fontes de requisitos | A preencher | pendente | — |
| Especificação detalhada para desenvolvimento | A preencher | pendente | `requirements/REQUIREMENTS_SPECIFICATION.md` |
| Checklist legível do programador | A preencher | pendente | `requirements/DEVELOPER_REQUIREMENTS_CHECKLIST.md` |
| Ficheiro único de todas as funcionalidades | A preencher | pendente | `requirements/ALL_FUNCTIONALITIES.md` |
| Matriz de requisitos | A preencher | pendente | — |
| Catálogo de aplicações | A preencher | pendente | `requirements/APPLICATION_CATALOG.md` |
| Contratos por aplicação | A preencher | pendente | `requirements/applications/` |
| Catálogo de páginas/ecrãs | A preencher | pendente | `requirements/PAGE_CATALOG.md` |
| Contratos por página/ecrã | A preencher | pendente | `requirements/pages/` |
| Mapa de navegação e passos | A preencher | pendente | Prompt 03 |
| Matriz de estados por página | A preencher | pendente | Prompt 03 |
| Matriz aplicação × capacidade | A preencher | pendente | Prompt 03 |
| Requisitos aprovados | A preencher | pendente | — |
| Requisitos do produto | A preencher | pendente | — |
| Matriz pública SSR | A preencher | pendente | — |
| Matriz Web/PWA | A preencher | pendente | — |
| Matriz MAUI | A preencher | pendente | — |
| Jornadas prioritárias | A preencher | pendente | — |
| Jornadas críticas | A preencher | pendente | — |
| Atores e permissões | A preencher | pendente | — |
| Primeiro corte vertical | A preencher | pendente | — |
| Vertical slice atual | A preencher | pendente | `IMPLEMENTATION_STATUS.md` |

Aliases:

- `[FONTES_DE_REQUISITOS]`
- `[ESPECIFICAÇÃO_OU_BACKLOG]`, `[ESPECIFICACAO_DETALHADA]`
- `[CHECKLIST_REQUISITOS_PROGRAMADOR]`, `[DEVELOPER_REQUIREMENTS_CHECKLIST]`
- `[FICHEIRO_UNICO_FUNCIONALIDADES]`, `[ALL_FUNCTIONALITIES]`
- `[MATRIZ_DE_REQUISITOS]`
- `[CATALOGO_DE_APLICACOES]`, `[CONTRATOS_POR_APLICACAO]`
- `[CATALOGO_DE_PAGINAS]`, `[CONTRATOS_POR_PAGINA]`
- `[MAPA_DE_NAVEGACAO]`, `[MAPA_DE_PASSOS]`
- `[MATRIZ_DE_ESTADOS_POR_PAGINA]`, `[MATRIZ_APLICACAO_CAPACIDADE]`
- `[REQUISITOS_APROVADOS]`, `[REQUISITOS_DE_PRODUTO]`, `[REQUISITOS_DO_PRODUTO]`
- `[MATRIZ_DE_REQUISITOS_PUBLICOS]`, `[MATRIZ_DE_REQUISITOS_WEB]`, `[MATRIZ_DE_REQUISITOS_MAUI]`
- `[JORNADAS_PRIORITARIAS]`, `[JORNADAS_CRITICAS]`, `[JORNADAS_E_ESTADOS_CRITICOS]`
- `[JORNADAS_E_CONSUMIDORES]`
- `[ATORES]`, `[ATORES_E_PERMISSOES]`, `[PERFIS_DE_AUTORIZACAO]`
- `[PRIMEIRO_CORTE_VERTICAL]`
- `[VERTICAL_SLICE_ATUAL]`

## UX, marca e conteúdo

| Campo | Valor ou caminho | Estado | Fonte |
|---|---|---|---|
| Identidade visual aprovada | A preencher | pendente | — |
| Referências visuais autorizadas | A preencher | pendente | — |
| Aplicações profissionais de referência | A preencher | pendente | Pesquisa de produto |
| Princípios de experiência aprovados | A preencher | pendente | Benchmark/decisão |
| Temas, UI kits ou investigação premium autorizados | A preencher | pendente | Licença/compra |
| Evidência e localização das licenças | A preencher | pendente | Registo de licenças |
| Baseline visual | A preencher | pendente | — |
| Baseline profissional de produto/UX/UI | `PRODUCT_QUALITY_BASELINE.md` | pendente | Benchmark/aprovação |
| Estratégia mobile Web/PWA | A preencher | pendente | Produto/UX |
| Catálogo de componentes e estados | A preencher | pendente | Design system |
| Plano/resultados de usabilidade | A preencher | pendente | Investigação com utilizadores |
| Evidência direta do problema e solução | A preencher | pendente | `requirements/USER_RESEARCH_EVIDENCE.md` |
| Exceção de investigação aprovada | A preencher | pendente | Gate A/owner de produto |
| Baselines de regressão visual | A preencher | pendente | Testes/CI |
| Revisor Product Design/UX | A preencher | pendente | Aprovação |
| Revisor de engenharia/frontend | A preencher | pendente | Aprovação |
| Conteúdo público aprovado | A preencher | pendente | — |
| Objetivos da área pública | A preencher | pendente | — |
| Viewports alvo | A preencher | pendente | — |
| Estados obrigatórios de UI | A preencher | pendente | — |
| Browsers/dispositivos suportados | A preencher | pendente | — |
| Clientes de email alvo | A preencher | pendente | — |

Aliases:

- `[IDENTIDADE_VISUAL]`
- `[REFERENCIAS_VISUAIS]`, `[REFERENCIA_VISUAL_OU_BASELINE]`
- `[REFERENCIAS_DE_PRODUTO]`, `[APLICACOES_DE_REFERENCIA]`
- `[PRINCIPIOS_DE_EXPERIENCIA]`, `[PADRAO_DE_QUALIDADE_VISUAL]`
- `[TEMAS_PREMIUM_AUTORIZADOS]`, `[EVIDENCIA_DE_LICENCA]`
- `[CONTEUDO_PUBLICO_APROVADO]`
- `[OBJETIVOS_DA_AREA_PUBLICA]`
- `[VIEWPORTS_ALVO]`, `[ESTADOS_A_VALIDAR]`
- `[BROWSERS_E_DISPOSITIVOS]`, `[BROWSERS_E_VIEWPORTS]`, `[BROWSERS_PLATAFORMAS_E_VERSOES]`
- `[CLIENTES_EMAIL_ALVO]`
- `[PRODUCT_QUALITY_BASELINE]`
- `[ESTRATEGIA_MOBILE_WEB]`
- `[CATALOGO_DE_COMPONENTES_E_ESTADOS]`
- `[PLANO_E_RESULTADOS_DE_USABILIDADE]`
- `[EVIDENCIA_DE_INVESTIGACAO_COM_UTILIZADORES]`
- `[EXCECAO_DE_INVESTIGACAO_APROVADA]`
- `[BASELINES_DE_REGRESSAO_VISUAL]`
- `[REVISOR_PRODUCT_DESIGN]`, `[REVISOR_ENGENHARIA_FRONTEND]`

## Contas, autenticação e autorização

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Modelo de conta | A preencher | pendente | — |
| Aquisição de conta | A preencher | pendente | — |
| Perfis/roles/permissions | A preencher | pendente | — |
| MFA ativo | A preencher | pendente | — |
| Passkeys/WebAuthn ativo | A preencher | pendente | — |
| Fornecedores de login selecionados | A preencher | pendente | — |
| Fornecedor de login atual | A preencher | pendente | — |
| Domínios, RP ID e origins | A preencher | pendente | — |

Aliases:

- `[MODELO_DE_CONTA]`
- `[MODELO_DE_AQUISICAO_DE_CONTA]`
- `[FORNECEDORES_SELECIONADOS]`, `[FORNECEDOR_ATUAL]`
- `[DOMINIOS_E_CLIENTES]`

## Dados, privacidade e conteúdo legal

| Campo | Valor ou caminho | Estado | Fonte |
|---|---|---|---|
| Inventário de dados | A preencher | pendente | — |
| Matriz de dados e retenção aprovada | A preencher | pendente | — |
| Matriz de retenção/eliminação | A preencher | pendente | — |
| Matriz de privacidade aprovada | A preencher | pendente | — |
| Conteúdo legal aprovado | A preencher | pendente | — |
| Nome/NIF/morada da entidade | A preencher | pendente | — |
| Email de suporte | A preencher | pendente | — |
| Email de privacidade | A preencher | pendente | — |
| Redes sociais validadas | A preencher | pendente | — |
| Responsável pela revisão jurídica | A preencher | pendente | Entidade/DPO/jurista |

Aliases:

- `[INVENTARIO_DE_DADOS]`
- `[MATRIZ_APROVADA_DE_DADOS_E_RETENCAO]`
- `[MATRIZ_APROVADA_DE_RETENCAO_E_ELIMINACAO]`
- `[MATRIZ_DE_PRIVACIDADE_APROVADA]`
- `[CONTEUDO_LEGAL_APROVADO]`
- `[NIF/REGISTO]`, `[MORADA]`
- `[EMAIL_SUPORTE]`, `[EMAIL_PRIVACIDADE]`, `[REDES_VALIDAS]`
- `[RESPONSAVEL_REVISAO_JURIDICA]`

## Integrações e capacidades condicionais

| Capacidade | Provider/canal atual | Estado | Fonte |
|---|---|---|---|
| Faturação/pagamentos | A preencher | pendente | — |
| Integração contabilística/SAP | A preencher | pendente | — |
| Publicidade | A preencher | pendente | — |
| Emails transacionais | A preencher | pendente | — |
| Push notifications | A preencher | pendente | — |
| SignalR/tempo real | A preencher | pendente | — |
| Jobs críticos | A preencher | pendente | — |
| Uploads e tipos de ficheiro | A preencher | pendente | — |
| Telemetria | A preencher | pendente | — |
| Cloud provider | A preencher | pendente | — |
| Ferramenta IaC | A preencher | pendente | — |
| Plataformas/lojas | A preencher | pendente | — |

Aliases:

- `[PROVIDER]`, `[PROVEDOR]`
- `[SUPERFICIE_ATUAL]`
- `[REQUISITOS_DE_FATURAÇÃO]`, `[SIM/NÃO]`
- `[CANAL_ATUAL]`, `[WEB_PUSH_APNS_FIREBASE]`
- `[CASOS_DE_USO_TEMPO_REAL]`
- `[JOBS_CRITICOS]`
- `[EVENTOS]`
- `[TIPOS_DE_FICHEIRO]`
- `[DESTINO_DE_TELEMETRIA]`
- `[CLOUD_PROVIDER]`, `[FERRAMENTA_IAC]`, `[RECURSOS_EXTERNOS]`
- `[PLATAFORMAS_E_LOJAS]`, `[PLATAFORMA_ATUAL]`, `[LOJA_ATUAL]`

## Ambientes e endpoints

| Campo | Valor não sensível | Estado | Fonte |
|---|---|---|---|
| Ambientes existentes | A preencher | pendente | — |
| Ambiente local autorizado | A preencher | pendente | — |
| Ambiente de teste autorizado | A preencher | pendente | — |
| Ambiente descartável para fault injection | A preencher | pendente | — |
| URL pública canónica HTTPS | A preencher | pendente | — |
| URL SSR | A preencher | pendente | — |
| URL Web/PWA | A preencher | pendente | — |
| URL API | A preencher | pendente | — |
| Alvo isolado de restore | A preencher | pendente | — |

Aliases:

- `[AMBIENTES]`
- `[AMBIENTE_AUTORIZADO]`
- `[AMBIENTE_DESCARTAVEL_AUTORIZADO]`
- `[PUBLIC_BASE_URL]`, `[PUBLIC_BASE_URL_HTTPS_APROVADO]`
- `[SSR_URL]`, `[WEB_URL]`, `[API_URL]`
- `[ALVO_ISOLADO_DE_RESTORE]`

`[AMBIENTE_ALVO]` deve ser confirmado novamente em cada execução de publicação; o valor deste ficheiro não constitui autorização.

## Qualidade, segurança e operação

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Versão ASVS | `5.0.0` a confirmar na execução | inferido | OWASP |
| Nível ASVS | A preencher | pendente | Threat model |
| Âmbito ASVS | A preencher | pendente | Threat model |
| Nível WCAG | `WCAG 2.2 AA` a confirmar na execução | inferido | Requisitos/W3C |
| Cenários críticos de performance | A preencher | pendente | Requisitos |
| Carga esperada | A preencher | pendente | Requisitos/SLO |
| Objetivos de performance | A preencher | pendente | Requisitos/SLO |
| Dependências críticas | A preencher | pendente | Arquitetura |
| Dados e serviços críticos | A preencher | pendente | Arquitetura/DR |
| Serviços e jornadas operacionais | A preencher | pendente | Arquitetura/SLO |
| RPO | A preencher | pendente | Decisão operacional |
| RTO | A preencher | pendente | Decisão operacional |
| SLI por jornada/serviço | A preencher | pendente | Produto/operação |
| SLO por jornada/serviço | A preencher | pendente | Produto/operação |
| Política de error budget | A preencher | pendente | Operação |
| Fonte de RUM/Core Web Vitals | A preencher | pendente | Observabilidade |
| Cadência de triagem operacional | A preencher | pendente | Operação |
| Canais de bugs/feedback de suporte | A preencher | pendente | Suporte/produto |
| Orçamentos e limites de custo | A preencher | pendente | FinOps/negócio |
| Cadência de vulnerabilidades contínuas | A preencher | pendente | Segurança |
| Fonte e cadência de métricas DORA | A preencher | pendente | Engenharia |

Aliases:

- `[VERSAO_ASVS]`, `[NIVEL_ASVS]`, `[AMBITO_ASVS]`
- `[NIVEL_WCAG]`
- `[CENARIOS_CRITICOS]`, `[CARGA_ESPERADA]`, `[OBJETIVOS_DE_PERFORMANCE]`
- `[DEPENDENCIAS_CRITICAS]`
- `[DADOS_E_SERVICOS_CRITICOS]`
- `[SERVICOS_E_JORNADAS_CRITICAS]`
- `[SLIS]`, `[SLOS]`, `[POLITICA_DE_ERROR_BUDGET]`
- `[FONTE_RUM]`, `[CADENCIA_TRIAGEM_OPERACIONAL]`
- `[CANAIS_DE_BUGS_E_FEEDBACK]`, `[ORCAMENTOS_DE_CUSTO]`
- `[CADENCIA_VULNERABILIDADES]`, `[FONTE_METRICAS_DORA]`

## Estado de implementação e release

| Campo | Valor | Estado | Fonte |
|---|---|---|---|
| Versão candidata | A preencher | pendente | Pipeline/release |
| Build ID esperado | A preencher | pendente | Pipeline |
| Base SHA da candidata | A preencher | pendente | Git |
| Candidate SHA | A preencher | pendente | Git |
| Digest do artefacto | A preencher | pendente | Pipeline |
| Attestation/proveniência da build | A preencher | pendente | Pipeline de build |
| Issuer e builder identity da attestation | A preencher | pendente | Verificação da attestation |
| Revisor/tarefa independente | A preencher | pendente | Revisão final |
| Evidência de separação da revisão | A preencher | pendente | Revisão final |
| Decisão da revisão independente | A preencher | pendente | Revisão final |
| Requisitos concluídos | A preencher | pendente | `IMPLEMENTATION_STATUS.md` |
| Bloqueios atuais | A preencher | pendente | `IMPLEMENTATION_STATUS.md` |
| Próximo lote recomendado | A preencher | pendente | `IMPLEMENTATION_STATUS.md` |
| Política de compatibilidade | A preencher | pendente | ADR/API |
| Política de atualização | A preencher | pendente | Dependências |

Aliases:

- `[VERSAO_CANDIDATA]`
- `[BUILD_ID]`
- `[BASE_SHA]`, `[CANDIDATE_SHA]`, `[ARTIFACT_PATH]`, `[ARTIFACT_DIGEST]`
- `[ATTESTATION_PATH]`, `[ATTESTATION_DIGEST]`, `[ATTESTATION_ISSUER]`, `[BUILDER_IDENTITY]`
- `[REVISOR_INDEPENDENTE]`, `[EVIDENCIA_DE_SEPARACAO]`, `[DECISAO_REVISAO_INDEPENDENTE]`
- `[POLITICA_DE_COMPATIBILIDADE]`
- `[POLITICA_DE_ATUALIZACAO]`

## Entradas que pertencem a cada execução

Estes valores não devem ficar implicitamente aprovados neste ficheiro. O prompt atual deve recebê-los ou resolvê-los com uma confirmação específica:

| Entrada | Regra |
|---|---|
| `[MODO]` | Definido pelo objetivo da tarefa; usa o modo seguro predefinido quando ausente. |
| `[LOTE_DE_REQUISITOS]` | Um único lote coerente escolhido a partir do estado atual. |
| `[LOTE_DE_ATUALIZACAO_APROVADO]` | Lista exata de dependências autorizadas. |
| `[API_SCOPE]` | Família concreta de endpoints/recursos desta execução. |
| `[ROTA]`, `[ROTA_OU_ECRA]` | `PAGE-###`, rota/ecrã e `APP-###` em âmbito. |
| `[FUNCIONALIDADE]` | Uma única capacidade. |
| `[IDS_OU_DESCRIÇÃO]`, `[REQUISITOS_DA_PAGINA]` | IDs estáveis `APP/PAGE/JRN/FR/AC` selecionados. |
| `[CRITERIOS_DE_ACEITACAO]`, `[CRITÉRIOS_DE_ACEITAÇÃO]` | Critérios observáveis do lote atual. |
| `[FORA_DO_AMBITO]` | Exclusões explícitas da tarefa. |
| `[AUTORIZACAO_DE_CORRECAO]`, `[AUTORIZAÇÃO_DE_CORREÇÃO]` | Defeitos concretos que podem ser alterados. |
| `[AUTORIZACAO_DE_CORRECAO_SSR]` | Correções SSR concretas autorizadas. |
| `[ORCAMENTO_DE_TESTE]` | Tempo, carga, serviços e profundidade permitidos. |
| `[REPETICOES_ANTI_FLAKINESS]` | Número de repetições definido para a suite atual. |
| `[CASO_REPETIDO]` | Conteúdo integral do caso EVAL-02 ou EVAL-06 usado numa repetição isolada de EVAL-12. |
| `[URLS_OU_AMOSTRA]` | Allowlist e orçamento do crawl. |
| `[OWNER_DO_EXPERIMENTO]` | Pessoa/função responsável pelo experimento. |
| `[AMBIENTE_ALVO]` | Alvo exato, confirmado imediatamente antes da ação externa. |
| `[AUTORIZAR_CRIACAO_GITHUB_E_PUSH_INICIAL]` | Autorização explícita para criar exatamente `[GITHUB_OWNER]/[GITHUB_REPOSITORY]`, adicionar `origin`, criar o commit-base e fazer o primeiro `push`. |
| `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]` | Baselines e diffs visuais concretos cuja alteração foi revista e aprovada. |
| `[AUTORIZAR_FERRAMENTAS_LAYOUT]` | Lista nominal das ferramentas de layout autorizadas, respetivo âmbito pessoal/projeto, origem, versão e permissões; vazio significa pesquisar e propor sem instalar. |
| `[AUTORIZAR_CONFIG_CODEX_PROJETO]` | Chaves e valores não sensíveis exatos autorizados para `.codex/config.toml`; vazio significa propor sem persistir. |
| `[AUTORIZAR_CODEX_ACTION]` | Workflow/repositório exatos, permissões e comportamento de check autorizados para integrar `openai/codex-action`; vazio significa não alterar a CI. |
| `[EXCECAO_DE_USABILIDADE_APROVADA]` | Risco, owner, prazo e aprovador quando um teste de usabilidade obrigatório não puder ser executado. |
| `[AUTORIZAR_RELEASE]` | Ambiente, candidate SHA, digest e janela exatos autorizados para publicação. |
| `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]` | Ações externas concretas permitidas durante triagem/monitorização; observar e reportar não implica autorização para alterar produção. |

## Referências a segredos

Guarda apenas os nomes das variáveis ou referências ao cofre:

| Placeholder | Referência permitida | Valor neste ficheiro |
|---|---|---|
| `[TEST_USER_EMAIL]` | Nome da variável de ambiente, por exemplo `TEST_USER_EMAIL` | Nunca guardar o email real |
| `[TEST_USER_PASSWORD]` | Nome da variável de ambiente, por exemplo `TEST_USER_PASSWORD` | Nunca guardar a password |
| `[DB_CONNECTION]` | Nome da variável/opção ou URI do secret no cofre | Nunca guardar a connection string |
| `[PROVIDER_KEY]` | Nome da variável/opção ou URI do secret no cofre | Nunca guardar a chave |

## Decisões pendentes

| ID | Decisão | Porque é necessária | Opções | Owner | Prazo | Bloqueia |
|---|---|---|---|---|---|---|
| DEC-001 | A preencher | A preencher | A preencher | A preencher | A preencher | A preencher |

## Conflitos encontrados

| Campo | Fonte A | Fonte B | Impacto | Decisão necessária | Estado |
|---|---|---|---|---|---|
| A preencher | A preencher | A preencher | A preencher | A preencher | pendente |

## Matriz de resolução antes de cada prompt

O Codex deve apresentar esta tabela antes de implementar:

| Placeholder | Valor resolvido | Fonte | Confiança | Estado/ação |
|---|---|---|---|---|
| A preencher | A preencher | A preencher | alta/média/baixa | confirmado/inferido/bloqueado |

Só avança quando todas as entradas materiais do prompt estiverem `confirmado` ou quando o próprio prompt permitir explicitamente um pressuposto reversível.
