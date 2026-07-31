# Executar aceitação final e checklist de release

## Objetivo

Determina objetivamente se a candidata imutável `[VERSAO_CANDIDATA]`, identificada por `[BASE_SHA]`, `[CANDIDATE_SHA]` e `[ARTIFACT_DIGEST]`, está apta a seguir para revisão final independente. Rastreia requisitos, riscos, testes, segurança, experiência, operação e aprovações até evidência verificável. Esta tarefa não é a revisão independente e não publica.

## Critérios de sucesso

- Todos os requisitos `Must` têm estado e evidência.
- Jornadas críticas passam em ambiente representativo.
- O quality gate do `PRODUCT_EXCELLENCE.md` passa para as superfícies visíveis, com benchmark, estados e evidência renderizada.
- A baseline de `PRODUCT_QUALITY_BASELINE.md`, regressão visual, acessibilidade contínua e usabilidade das jornadas críticas passam sem exceção silenciosa.
- Vulnerabilidades, migrações, performance, acessibilidade, PWA e operação têm gates definidos.
- SLI/SLO, error budget, observabilidade, operação pós-release e rollback têm owners e condições mensuráveis.
- Bloqueios e riscos aceites têm owner e decisão.
- O resultado é `GO`, `NO-GO` ou `GO condicionado`, com fundamento.

## Processo

1. Congela o âmbito da candidata e prova base SHA, candidate SHA, digest do artefacto, configuração e proveniência dos relatórios. Um novo commit ou artefacto invalida a decisão.
2. Reúne requisitos, benchmark/princípios e baseline de produto, revisão de design/engenharia da primeira fatia, estudos de usabilidade, diffs visuais, matriz de testes, threat model, ASVS, WCAG, performance, CI/CD, SLI/SLO, DR e runbooks.
3. Cria:

| Gate | Critério | Evidência | Resultado | Owner | Bloqueio/aceitação |
|---|---|---|---|---|---|

4. Antes de executar, classifica cada gate como `bloqueante` ou `passível de exceção` e define quem pode aceitar a exceção. Segurança crítica, integridade de dados e impossibilidade de rollback não se tornam dispensáveis por omissão.
5. Executa UAT com scripts para os atores e jornadas prioritárias usando dados de teste.
6. Reexecuta apenas validações necessárias à candidata; não aceita relatórios obsoletos sem confirmar aplicabilidade.
7. Confirma que checks automáticos de acessibilidade e regressão visual correram em cada pull request aplicável, que a avaliação manual cobriu jornadas críticas e que nenhuma baseline foi alterada sem revisão explícita.
8. Exige evidência de usabilidade das jornadas principais/críticas. Se a execução for materialmente impossível, só aceita `[EXCECAO_DE_USABILIDADE_APROVADA]` com risco, owner, prazo e compensação; sem isso, produz `NO-GO`.

## Gates mínimos

- build/test/Playwright;
- migrations e compatibilidade;
- autenticação/autorização e segurança;
- dependências, supply chain e licenças de temas/assets incorporados;
- privacidade/legal quando aplicável;
- acessibilidade e SSR/SEO;
- excelência de produto/UX/UI, conteúdo, consistência visual e estados das jornadas;
- regressão visual reproduzível, catálogo de componentes/estados e ausência de UI genérica;
- usabilidade observada das jornadas principais/críticas;
- performance/resiliência;
- PWA/cache ou MAUI/distribuição;
- observabilidade, alertas, backup/restauro e incidentes;
- SLI/SLO/error budget, pós-release 30m/24h/7d e triagem operacional contínua;
- release notes, suporte, custos, vulnerabilidades contínuas, DORA e rollback.
- quando aplicável, matriz `APP/PAGE/FNC/HLP/VID/CRS` reconciliada, vídeos na
  versão correta, idiomas revistos, captions/transcrição, privacidade, links/embed,
  fallback, pesquisa, permissões, curso/progresso e autorização de publicação.

## Regras

Não baixa critérios, ignora testes, reclassifica `Must` ou aceita vulnerabilidades em nome do prazo. Uma exceção exige risco, compensação, owner, prazo e aprovação. Distingue falha do produto de bloqueio do ambiente.

## Entrega

Apresenta decisão, base/candidate SHA, digest, classificação dos gates, matriz, UAT/usabilidade, regressão visual, acessibilidade, comandos/resultados, bloqueios, exceções com autoridade/expiração, riscos aceites, condições e próximos passos. Atualiza o manifesto de `IMPLEMENTATION_STATUS.md`. Um `GO` significa apenas “apto para o prompt 63” e não autorização de publicação.

## Referências oficiais

- https://learn.microsoft.com/azure/well-architected/operational-excellence/safe-deployments
- https://owasp.org/www-project-application-security-verification-standard/
- https://www.w3.org/WAI/test-evaluate/
