# Configurar CI/CD e ambientes de deployment

## Objetivo

Adapta os workflows existentes (`ci.yml`, `ci-maui.yml`, `cd-test.yml`, `cd-production.yml` e templates aplicáveis) ao projeto derivado, criando uma cadeia reprodutível, segura e auditável para `[AMBIENTES]`.

## Critérios de sucesso

- CI valida restore locked, build, testes e artefactos relevantes.
- Pull requests executam checks automáticos de acessibilidade, regressão visual dos estados estáveis e análise de segurança aplicáveis.
- O mesmo artefacto aprovado progride entre ambientes quando a plataforma o permite.
- A build produz SBOM e attestation de proveniência assinada; promoções
  verificam identidade, source SHA e digest antes de usar o artefacto.
- Ambientes têm proteção, responsáveis, approvals e secrets separados.
- Workflows usam permissões mínimas, actions imutáveis e OIDC quando suportado.
- Falha impede promoção e deixa evidência diagnosticável.
- A branch principal exige pull request, status checks, conversas resolvidas e revisão de outro autor/Code Owner conforme o risco.

## Processo

1. Lê workflows, documentação CI/CD do boilerplate, solution filters, testes, publicação e infraestrutura.
2. Confirma branches/tags, ambientes, runners, artefactos, providers e política de release.
3. Cria a matriz `evento → job → permissões → artefacto → ambiente → gate → rollback`.
4. Mantém etapas que continuam válidas; não reescreve tudo sem necessidade.
5. Confirma o remote GitHub criado no prompt 7, a branch principal, os owners e as capacidades do plano GitHub. Se uma proteção não estiver disponível, regista o controlo compensatório em vez de fingir enforcement.

## Implementação

- Usa versões de SDK/workloads explícitas e restore locked.
- Separa build/test, empacotamento, aprovação e deploy.
- Define `permissions` por job e fixa actions de terceiros por full SHA.
- Confirma o SHA completo na origem oficial e regista a versão/tag humana correspondente; uma tag sozinha não é referência imutável.
- Usa environment secrets/variables e OIDC; não imprime credenciais.
- Mantém produção protegida por regras e aprovação proporcionais ao risco.
- Publica resultados/artefactos úteis sem dados sensíveis.
- Gera a attestation apenas depois de fixar o artefacto final. Regista issuer,
  builder identity, workflow ref, source repository/SHA, predicate e digest;
  conserva a verificação como evidência de G07.
- Evita executar CD de produção em forks ou inputs não confiáveis.
- Inclui concurrency/cancelamento sem interromper deployment já iniciado de forma insegura.
- Executa em cada pull request os checks automáticos de acessibilidade das superfícies alteradas. Mantém a auditoria manual para jornadas críticas.
- Compara snapshots Playwright aprovados para componentes/estados estáveis em ambiente fixo: sistema, browser, fontes, timezone/locale e animações. Publica o diff visual como artefacto do pull request.
- Não atualiza baselines automaticamente. Uma alteração exige `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`, requisito associado e revisão do diff.
- Configura branch protection/ruleset para exigir os checks bloqueantes, revisão por alguém diferente do último autor e Code Owners nas áreas sensíveis quando existirem.
- Inclui dependency review, secret scanning/code scanning ou equivalentes disponíveis, sem transformar ausência de uma licença GitHub numa falsa garantia.
- Depois de a CI determinística estar estável, avalia opcionalmente
  `openai/codex-action` para revisão read-only de pull requests. Só o adiciona
  com `[AUTORIZAR_CODEX_ACTION]`, permissões mínimas, inputs do PR tratados como
  não confiáveis, ausência de secrets em eventos de forks e output meramente
  consultivo ou ligado a um check explicitamente aprovado. A action não
  substitui build, testes, Code Owners nem revisão humana exigida.

## Validação

Valida sintaxe e referências, executa localmente os comandos equivalentes e dispara CI numa alteração segura quando autorizado. Exercita falha de teste, finding de acessibilidade, regressão visual não aprovada, ausência de secret, attestation ausente/inválida ou de outro commit e promoção a ambiente não produtivo. Verifica que cada falha bloqueia merge/promoção e preserva artefactos de diagnóstico. Não faz deployment real de produção sem autorização explícita.

## Entrega

Apresenta matriz, workflows alterados, actions com SHA e versão de origem, permissões/secrets esperados sem valores, artefactos, checks de acessibilidade/visual/segurança, proteção da branch, revisões exigidas, comandos/runs e passos externos ainda necessários.

## Referências oficiais

- https://docs.github.com/actions/deployment/targeting-different-environments/managing-environments-for-deployment
- https://docs.github.com/actions/security-guides/security-hardening-for-github-actions
- https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- https://docs.github.com/actions/security-for-github-actions/using-artifact-attestations
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- https://playwright.dev/docs/test-snapshots
- https://www.w3.org/WAI/test-evaluate/
- https://github.com/openai/codex-action
