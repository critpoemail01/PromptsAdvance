# Criar ou adotar o projeto da iniciativa

## Objetivo

Depois de aprovados os requisitos, a arquitetura, os módulos e o threat model,
prepara o repositório da iniciativa segundo `[MODO_INICIATIVA]`:

- `greenfield`: cria em `[PASTA_DESTINO]` uma aplicação funcional derivada de
  `[PASTA_ORIGEM_BOILERPLATE]`;
- `brownfield`: adota a aplicação existente em
  `[RAIZ_APLICACAO_EXISTENTE]`, preservando código, histórico Git, remotes e
  alterações locais, e estabelece uma baseline verificável antes de qualquer
  modernização.

Nos dois modos, usa `[NOME_TECNICO]` e `[NOME_PRODUTO]`, mantém apenas
plataformas/capacidades aprovadas e entrega evidência reproduzível de restore,
build e testes. Uma adoção não declara o comportamento existente correto nem
concluído sem o verificar.

## Dados obrigatórios

- Modo da iniciativa: `[MODO_INICIATIVA]` (`greenfield` ou `brownfield`)
- Pasta de origem: `[PASTA_ORIGEM_BOILERPLATE]`
- Localização canónica da origem nesta workspace:
  `C:\Work\BoilerPlateAdvance`
- Pasta de destino nova: `[PASTA_DESTINO]`, quando `greenfield`
- Raiz da aplicação existente: `[RAIZ_APLICACAO_EXISTENTE]`, quando `brownfield`
- Nome técnico válido para assemblies/namespaces: `[NOME_TECNICO]`
- Nome apresentado ao utilizador: `[NOME_PRODUTO]`
- Identificador reverso para MAUI, quando aplicável: `[IDENTIFICADOR_INVERSO]`
- Plataformas ativas: `[SSR, WEB_PWA, MAUI]`
- Módulos a manter/remover: `[DECISAO_DE_MODULOS]`
- GitHub owner/repositório: `[GITHUB_OWNER]/[GITHUB_REPOSITORY]`, apenas para
  criação greenfield autorizada
- Visibilidade, branch e remote: `[GITHUB_VISIBILITY]`,
  `[GITHUB_DEFAULT_BRANCH]`, `[GIT_REMOTE_NAME]`, apenas para criação
  greenfield autorizada
- Autorização externa: `[AUTORIZAR_CRIACAO_GITHUB_E_PUSH_INICIAL]`, apenas
  quando a ação externa é pedida

Em `greenfield`, usa `private`, `main` e `origin` apenas como defaults
conservadores quando não colidirem com uma política confirmada. Não inventes
owner, nome do repositório ou autorização. A autorização deve nomear exatamente
o destino e abranger criação do repositório, commit-base e primeiro `push`;
caso contrário conclui apenas a parte local e termina `bloqueado para
sincronização GitHub`.

Em `brownfield`, o repositório, branch, histórico e remotes existentes são
fontes de verdade. Não cries/substituas `origin`, não reescrevas histórico, não
faças commit/push e não mudes visibilidade ou regras sem uma autorização
separada que nomeie a ação e o alvo exatos.

## Critérios de sucesso

- `[MODO_INICIATIVA]`, raiz da aplicação, raiz do processo e baseline Git estão
  registados no estado e no contexto sem segredos.
- A origem e o `BoilerPlateAdvance` permanecem inalterados.
- Soluções, projetos, assemblies, namespaces, testes e documentação refletem
  apenas mudanças aprovadas para o modo selecionado.
- Não existem segredos, artefactos de build, caches, configuração local privada ou histórico Git copiados.
- O `AGENTS.md` aplicável referencia `EXECUTION_CONTRACT.md` e
  `PRODUCT_EXCELLENCE.md` sem duplicar os protocolos.
- `PROCESS_MANIFEST.json`, `QUALITY_GATES.md`, `PRODUCT_DEFINITION.md`, `PRODUCT_QUALITY_BASELINE.md`, `PILOT_APPROVAL.md`, `LIFECYCLE_GATE_EVIDENCE.json` e `PROMPT_EVALUATION.md` estão presentes e ligados aos protocolos de produto/processo.
- O repositório Git real, ou a sua ausência, está identificado sem criar um
  repositório aninhado acidental.
- Em `greenfield`, o destino contém apenas ficheiros necessários e, quando
  autorizado, o remote/SHA coincidem com o commit-base.
- Em `brownfield`, existe inventário `as-is`, baseline de comandos/resultados,
  classificação de falhas preexistentes e mapa de gaps para a arquitetura
  aprovada; `.git`, remotes e alterações locais permanecem intactos.
- O destino não conserva caminhos absolutos, imports ou dependências de runtime para a pasta de origem.
- Os módulos mantidos estão completos; os removidos não deixam packages, configuração, registos, endpoints, recursos ou testes órfãos.
- Restore, build e testes passam, ou cada impedimento externo fica demonstrado.

## Adoção brownfield

Executa esta secção apenas quando `[MODO_INICIATIVA]` for `brownfield`. Depois,
salta as secções greenfield.

1. Confirma que `[RAIZ_APLICACAO_EXISTENTE]` existe, é a raiz pretendida e não
   é o catálogo, o `BoilerPlateAdvance` nem a raiz do processo. Resolve
   junctions/symlinks antes de comparar caminhos. A raiz do processo também
   deve ficar fora da árvore do repositório Git existente para não criar
   alterações não rastreadas na própria aplicação.
2. Lê os `AGENTS.md`/`AGENTS.override.md` aplicáveis dentro da aplicação e
   inventaria soluções, projetos, manifests, dependências, CI, configuração,
   pontos de entrada e documentação sem alterar ficheiros.
3. Regista apenas metadados Git não sensíveis: raiz real, HEAD, branch, árvore
   limpa/suja, quantidade de alterações e quantidade/nomes de remotes. Nunca
   mostres URLs com credenciais nem conteúdos de ficheiros locais privados.
4. Preserva todas as alterações locais. Não uses checkout/reset/clean, não
   inicializes outro `.git`, não cries commits e não alteres remotes.
5. Descobre os comandos reais de restore, build, testes, lint/analyzers e
   execução a partir de CI, scripts e configuração. Executa apenas comandos
   locais e seguros; não uses serviços externos ou produção.
6. Produz no processo isolado `reports/brownfield-baseline.md` com:
   - mapa de projetos, responsabilidades e fronteiras;
   - plataformas/superfícies observadas;
   - comandos e exit codes;
   - baseline Git e limitações;
   - funcionalidades observadas ligadas a requisitos, marcadas `por verificar`
     até existir evidência comportamental;
   - gaps para arquitetura, threat model, segurança, testes, acessibilidade,
     observabilidade, operação e qualidade profissional;
   - classificação `preexistente`, `introduzido pela adoção` ou `não
     verificável` para cada finding.
7. Compara com o `BoilerPlateAdvance` apenas ao nível de capacidades e
   princípios aprovados. Não copies ficheiros, namespaces, identidade ou
   módulos por atacado e não transformes diferenças em defeitos sem requisito.
8. Mantém os artefactos do lifecycle na raiz isolada do processo. Só adiciona
   ou atualiza `AGENTS.md`, contratos ou scripts dentro da aplicação quando não
   houver colisão e essa mudança estiver explicitamente incluída no lote.
9. Atualiza `APP_CONTEXT.md` e `IMPLEMENTATION_STATUS.md` do processo com fontes,
   confiança, baseline, bloqueios e o menor próximo lote. Regista o resultado
   pelo orquestrador; não edites `currentPrompt` ou gates diretamente.
10. Conclui `completed` apenas quando a adoção e baseline forem reproduzíveis.
    Usa `partial` para cobertura incompleta e `blocked` quando faltar uma decisão
    material, acesso ou comando indispensável.

## Preparação — greenfield

1. Executa esta secção apenas quando `[MODO_INICIATIVA]` for `greenfield`.
2. Confirma os caminhos absolutos reais; não assumas `C:\Work` nem outra localização fixa.
3. Lê `AGENTS.md`, `README.md`, `MODULES.md`, manifests, soluções, projetos, configuração, CI e pontos de entrada da origem.
4. Confirma que `[PASTA_DESTINO]` não é a origem, não está dentro da origem e está vazia ou ainda não existe. Não apagues nem substituas um destino com conteúdo.
5. Inventaria todos os usos ativos de `BoilerPlateAdvance`: caminhos, nomes de projetos, assemblies, namespaces, solution filters, launch profiles, package IDs, recursos MAUI, application IDs, configuração, testes e documentação.
6. Cria um mapa de transformação antes de editar. Distingue o nome técnico, o nome público e identificadores de publicação; não faças uma substituição cega de texto.
7. Se o mapa revelar colisões de nomes, destination path inseguro ou identificadores externos não aprovados, para antes da cópia/renomeação afetada e apresenta a decisão mínima necessária.
8. Antes de qualquer ação GitHub:
   - confirma que `git` e GitHub CLI `gh` existem;
   - executa `gh auth status --hostname github.com` sem mostrar tokens e confirma que a conta ativa pode criar em `[GITHUB_OWNER]`;
   - verifica com `gh repo view` que o repositório não existe;
   - inspeciona `git remote -v` e bloqueia se existir um remote incompatível;
   - se `gh` estiver ausente ou a conta errada estiver ativa, não tentes contornar com tokens em comandos ou prompts: apresenta o passo de instalação/login necessário.

## Implementação — greenfield

1. Copia apenas a árvore fonte necessária. Exclui `.git`, `bin`, `obj`, caches, resultados de testes, ficheiros temporários, configurações pessoais e segredos.
2. Renomeia de forma consistente diretórios, ficheiros de solução/projeto, referências, namespaces, assemblies, root namespaces, testes e comandos documentados.
3. Atualiza o nome público apenas nas superfícies apropriadas; não uses nomes de marketing como namespaces se não forem identificadores válidos e estáveis.
4. Configura `[IDENTIFICADOR_INVERSO]` e recursos MAUI apenas quando MAUI estiver ativo. Não inventes certificados, perfis de assinatura ou IDs de loja.
5. Mantém por defeito a fundação indicada em `MODULES.md`: API/OpenAPI/ProblemDetails, SSR público, Web/PWA, EF Core/migrations, Identity, configuração validada, health, rate limiting, headers de segurança, logging e resiliência. Remove uma capacidade apenas quando `[DECISAO_DE_MODULOS]` o determinar.
6. Para cada capacidade removida, elimina o conjunto completo descrito em `MODULES.md`: código, serviços, middleware/endpoints, configuração, recursos, packages e testes. Compila após cada remoção relevante.
7. Mantém integrações opcionais inativas enquanto não houver configuração real. Usa placeholders, User Secrets, variáveis de ambiente ou cofre de segredos; nunca copies credenciais para `appsettings*.json`.
8. Copia `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`, `PRODUCT_DEFINITION.md`, `PRODUCT_QUALITY_BASELINE.md`, `PILOT_APPROVAL.md`, `LIFECYCLE_GATE_EVIDENCE.json`, `QUALITY_GATES.md`, `PROCESS_MANIFEST.json` e `PROMPT_EVALUATION.md` para a raiz do destino, bem como `software-lifecycle.ps1`, `scripts/Test-ProductDefinitionGate.ps1`, `scripts/Test-ImplementationReadinessGate.ps1`, `scripts/Test-ProductQualityGate.ps1`, `scripts/Test-LifecycleGateEvidence.ps1` e a skill `.agents/skills/build-professional-web-software`. Cria ou atualiza o `AGENTS.md` para exigir as leituras aplicáveis. Mantém no `AGENTS.md` apenas regras duradouras, comandos comprovados e links para documentação detalhada; não dupliques ali os protocolos integrais.
9. Se o destino já pertencer a um repositório Git pai, confirma que esse repositório é o alvo aprovado; não cries um repositório aninhado. Se for uma aplicação autónoma, inicializa Git localmente, configura a branch principal aprovada e verifica `.gitignore`.
10. Copia `APP_CONTEXT.md` e `IMPLEMENTATION_STATUS.md` para o destino quando forem fornecidos como artefactos do processo, atualizando apenas valores comprovados. Atualiza também `README.md`, CI e documentação operacional para refletirem os nomes, projetos e comandos reais.
11. Preserva o comportamento e os contratos da base que não estejam explicitamente no âmbito de personalização.
12. Depois de restore/build/test/smoke e da inspeção de segredos:
    - cria um único commit-base com mensagem objetiva;
    - se `[AUTORIZAR_CRIACAO_GITHUB_E_PUSH_INICIAL]` estiver confirmado, cria um repositório remoto vazio sem README/licença adicionais, usando a visibilidade aprovada;
    - adiciona `[GIT_REMOTE_NAME]`, faz o primeiro push com upstream e nunca usa `force`;
    - se o repositório já existir, não o apagues, importes ou adotes silenciosamente; exige autorização de adoção e prova de compatibilidade;
    - atualiza `APP_CONTEXT.md` e `IMPLEMENTATION_STATUS.md` com URL, branch e commit-base, sem tokens.

## Limites de segurança

- A criação local dentro de `[PASTA_DESTINO]` está autorizada; eliminar ou sobrescrever conteúdo existente não está.
- A autorização GitHub deste prompt limita-se ao repositório exato, ao commit-base e ao primeiro push. Não autoriza tornar público, substituir remotes, configurar billing, apagar repositórios, fazer force push ou publicar a aplicação.
- Não alteres a origem, não cries outros recursos cloud, não executes migrations em produção e não faças operações de lojas de aplicações.
- Não removas testes nem desatives validações para obter um build verde.
- Não edites `Server.Web` ou `Client.Windows`, preservados apenas como referência, salvo decisão explícita.

## Validação — greenfield

1. Procura o nome antigo e classifica cada ocorrência restante como erro ou referência histórica intencional.
2. Verifica referências de projetos, solution filters, packages bloqueados, configuração, rotas, recursos e IDs de aplicação.
3. Executa, adaptando os nomes reais:

```text
dotnet restore <Projeto>.Web.slnf --locked-mode
dotnet build <Projeto>.Web.slnf --no-restore --nologo -v:q
dotnet test --project src/Tests/<Projeto>.Tests.csproj --no-build --no-restore -v:q --no-progress --no-ansi
```

4. Compila MAUI apenas se estiver ativo e o workload necessário existir.
5. Faz um arranque/smoke test local mínimo do API, SSR e Web ativos. Confirma que a aplicação inicia sem exigir credenciais de integrações desativadas.
6. Antes do commit, executa `git status --short` e uma inspeção de segredos/artefactos. Confirma que não foram incluídos `bin`, `obj`, caches ou configuração privada.
7. Depois da sincronização autorizada, verifica `git remote get-url [GIT_REMOTE_NAME]`, `git ls-remote`, upstream da branch e igualdade entre `HEAD` e a referência remota. Um push aceite sem igualdade de SHA não conta como sincronização concluída.
8. Confirma que `AGENTS.md` liga para os caminhos corretos de `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`, `PRODUCT_DEFINITION.md`, `PRODUCT_QUALITY_BASELINE.md`, `QUALITY_GATES.md`, `PROCESS_MANIFEST.json` e `PROMPT_EVALUATION.md`, que podem ser lidos a partir da raiz e que instruções específicas não contradizem os protocolos.
9. Se o GitHub não tiver sido autorizado ou estiver indisponível, preserva o commit local e regista o bloqueio; não declares o Gate C concluído.

## Entrega

Apresenta o mapa de transformação, plataformas/módulos mantidos e removidos, ficheiros principais alterados, ocorrências intencionais do nome antigo, estado Git, commit-base, URL/visibilidade/branch do GitHub quando criado, comparação dos SHAs local/remoto, comandos e resultados, smoke tests, validação de `AGENTS.md` e dos protocolos, valores de configuração ainda necessários e bloqueios. Não declares o projeto concluído apenas porque os ficheiros foram copiados ou o push terminou sem verificação.

## Referências oficiais

- https://learn.microsoft.com/dotnet/core/tools/dotnet-sln
- https://learn.microsoft.com/aspnet/core/security/app-secrets?view=aspnetcore-10.0
- https://learn.microsoft.com/dotnet/core/tools/dotnet-restore
- https://cli.github.com/manual/gh_auth_status
- https://cli.github.com/manual/gh_repo_create
- https://docs.github.com/en/get-started/git-basics/managing-remote-repositories
