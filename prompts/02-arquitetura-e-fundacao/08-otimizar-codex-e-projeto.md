# Preparar o projeto para utilização eficiente pelo Codex

## Objetivo

Depois de a aplicação ter sido criada a partir do boilerplate, audita e melhora as instruções, a documentação técnica e as capacidades de desenvolvimento do novo repositório para que futuras tarefas do Codex encontrem rapidamente o contexto, os comandos, os ficheiros e as ferramentas relevantes. Para layout, pesquisa e seleciona apenas capacidades que resolvam uma lacuna comprovada; configura-as apenas com autorização e valida-as depois na primeira vertical slice real. Não alteres comportamento, arquitetura, APIs, base de dados ou dependências de produção.

## Contexto esperado

O projeto deriva de `BoilerPlateAdvance`: .NET 10/C# 14, Bit Platform, site público em `Client.Ssr`, aplicação autenticada WASM/PWA em `Client.Web`, UI partilhada em `Client.Core`, cliente `Client.Maui` e API em `Server.Api`. Confirma tudo no repositório porque nomes e módulos podem ter mudado. `Server.Web` e `Client.Windows` são referências, não projetos ativos.

## Critérios de sucesso

- `AGENTS.md` contém apenas regras duradouras, comandos comprovados e critérios de verificação.
- `AGENTS.md` exige a leitura integral de `EXECUTION_CONTRACT.md`, e o contrato comum não está duplicado nos prompts.
- Para tarefas que afetem produto ou experiência, `AGENTS.md` exige a leitura de `PRODUCT_EXCELLENCE.md`.
- Informação detalhada fica em documentação ligada, sem duplicação contraditória.
- Workflows repetidos com entradas/saídas estáveis ficam propostos como skills focadas, não como instruções gigantes no `AGENTS.md`.
- O routing de ferramentas distingue documentação atual, automação local de browser e contexto GitHub, com fallback explícito e sem duplicar conectores já disponíveis.
- A capacidade de layout fica registada em `CODEX_LAYOUT_TOOLING.md` como decisão curta e auditável, com no máximo três ferramentas aprovadas e ligação à primeira slice que demonstrará o benefício.
- Cada ferramenta visual candidata tem origem oficial, compatibilidade, licença, permissões, dados/telemetria, âmbito, benefício mensurável e rollback registados.
- Todos os comandos e caminhos documentados foram confirmados no repositório ou marcados como não verificados.
- Nenhuma alteração funcional, dependência ou configuração de runtime foi introduzida; ferramentas pessoais ou de desenvolvimento só são configuradas quando nomeadas em `[AUTORIZAR_FERRAMENTAS_LAYOUT]`.

## Execução

1. Confirma a raiz, o estado Git, alterações locais e a cadeia aplicável de `AGENTS.md`/`AGENTS.override.md`. Lê `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`, `APP_CONTEXT.md` e `IMPLEMENTATION_STATUS.md` quando existirem, sem assumir que valores pendentes estão aprovados.
2. Lê `README.md`, `MODULES.md`, manifests, solução/filtros, CI e pontos de entrada. Usa código e configuração executados como fonte de verdade.
3. Cria ou melhora o `AGENTS.md` da raiz com:
   - obrigação explícita de ler `EXECUTION_CONTRACT.md` antes de agir;
   - obrigação de ler `PRODUCT_EXCELLENCE.md` nas tarefas de produto, UI, UX, marca, conteúdo ou jornadas;
   - mapa curto dos projetos ativos e respetivas responsabilidades;
   - comandos reais de restore, build, execução e testes;
   - convenções comprovadas, limites e critérios de conclusão;
   - documentos a consultar por tipo de tarefa;
   - exclusões de pesquisa para builds, caches e ficheiros gerados.
4. Mantém o `AGENTS.md` curto. Conserva os protocolos comuns em `EXECUTION_CONTRACT.md` e `PRODUCT_EXCELLENCE.md`; move outra informação menos frequente para documentação existente e liga-a indicando quando deve ser lida.
5. Atualiza um mapa “necessidade → caminho” apenas se trouxer valor. Não descrevas todos os ficheiros.
6. Identifica tarefas repetidas que justificam uma skill com uma única responsabilidade, entradas, passos, validação e saída. Propõe a skill; não a cries se não fizer parte do âmbito autorizado.
7. Corrige documentação apenas quando o código/configuração comprovar que está errada. Preserva conteúdo duvidoso e assinala-o no relatório.
8. Documenta as regras específicas desta base:
   - site público static SSR separado da app autenticada WASM/PWA;
   - compilação normal pelo ficheiro `*.Web.slnf`;
   - MAUI apenas quando a tarefa o exigir e o workload existir;
   - testes com Microsoft.Testing.Platform, sem argumentos VSTest `--logger`/`--report-trx` nem `-clp`;
   - migrations explícitas em produção e segredos fora de ficheiros versionados.
9. Regista no `AGENTS.md` ou num documento técnico ligado o routing mínimo de capacidades, apenas quando a capacidade existir:
   - documentação de APIs/SDKs/frameworks: documentação oficial da versão em uso ou Context7; preserva biblioteca, versão e URL/ID consultado;
   - browser e jornadas web: browser existente ou skill `playwright-cli`; usa-a como ferramenta pessoal do Codex, não como package ou dependência de produção da aplicação;
   - GitHub: connector/plugin oficial ou `gh`, começando por leitura; escrita, settings, criação de recursos e push continuam a exigir alvo e autorização explícitos.
10. Não configures silenciosamente MCPs, plugins, hooks ou skills globais no repositório derivado. Descobre o que já está instalado, documenta o fallback e, quando a capacidade faltar, propõe a instalação separadamente com proveniência, permissões mínimas e forma de remoção.
11. Para melhorar layout, inspeciona primeiro o design system, a fonte de verdade visual, a stack de testes e as capacidades já disponíveis. Pesquisa apenas documentação e repositórios oficiais atuais e cria em `CODEX_LAYOUT_TOOLING.md` a matriz `lacuna → candidato → fonte/versão → compatibilidade → licença → permissões/dados/telemetria → âmbito pessoal|projeto|runtime → benefício mensurável → instalação → rollback → estado`.
12. Compara apenas candidatos adequados à stack real. Considera:
   - Figma MCP e Code Connect apenas quando Figma for fonte de verdade, existir acesso/licença compatível e o mapeamento para os componentes reais puder ser mantido;
   - browser existente ou `playwright-cli` para renderização, viewports, jornadas e screenshots;
   - `axe-core` integrado nos testes apenas quando não existir cobertura automática equivalente e uma dependência de desenvolvimento tiver sido autorizada;
   - Chrome DevTools MCP apenas quando existir uma lacuna concreta de consola, rede, renderização ou performance não coberta pelas capacidades atuais.
13. Recomenda no máximo três ferramentas, ordenadas por ganho esperado, custo/risco e confiança, e identifica uma opção recomendada. Prefere as capacidades, o design system e a regressão visual existentes. Não uses popularidade, listas genéricas ou uma framework usada pela referência como justificação.
14. Instala ou configura apenas os candidatos explicitamente nomeados em `[AUTORIZAR_FERRAMENTAS_LAYOUT]`, com origem oficial, versão fixada quando aplicável, permissões mínimas e rollback testado. Autenticação, subscrição paga, connector/MCP/skill/plugin global, envio de dados externo ou dependência de projeto exigem autorização específica para esse alvo. Se não existir autorização, conclui a matriz e entrega a decisão sem instalar.
15. Faz um smoke test local de cada capacidade configurada, sem a considerar aprovada para o processo visual. Regista o handoff para o prompt 12: hipótese de benefício, superfície/estado da primeira slice, evidência a recolher, critério `manter|remover` e rollback. A aceitação final da ferramenta ocorre apenas com a validação renderizada do prompt 12.
16. Quando existir uma lacuna recorrente de configuração do Codex, propõe uma
    `.codex/config.toml` local ao projeto com apenas chaves suportadas pela
    documentação oficial atual. Não fixa segredos, tokens, identidade pessoal
    nem configuração global. Modelo, sandbox, MCP/connectors e permissões só
    entram quando melhorarem uma tarefa concreta, forem compatíveis com a
    política do repositório e estiverem nominalmente autorizados em
    `[AUTORIZAR_CONFIG_CODEX_PROJETO]`.
17. Para repositórios GitHub, prefere GitHub MCP em modo read-only e com
    toolsets/allowlists mínimos quando isso reduzir consultas manuais reais;
    escrita continua separada e explicitamente autorizada. Usa como referência
    atual os exemplos de `openai/plugins`, não o repositório descontinuado
    `openai/skills`.

## Limites

- Não inventes comandos, scripts, lint, typecheck ou Playwright inexistentes.
- Não atualizes packages, lockfiles ou workloads.
- A exceção ao ponto anterior é apenas a nova dependência de desenvolvimento identificada e autorizada nominalmente em `[AUTORIZAR_FERRAMENTAS_LAYOUT]`; não atualizes dependências adjacentes e conserva o diff mínimo do lockfile.
- Não elimines documentação sem confirmar referências e conteúdo único.
- Não copies o conteúdo integral de `EXECUTION_CONTRACT.md` para `AGENTS.md` ou para cada prompt.
- Não copies o conteúdo integral de `PRODUCT_EXCELLENCE.md` para todos os prompts; mantém neles apenas os critérios específicos.
- Não copies segredos para documentação.
- Não graves tokens, headers de autenticação ou configuração privada de connectors/MCP em ficheiros versionados.
- Não instales um segundo framework de lifecycle ou metodologia que concorra com o processo Advance.
- Não faças uma refatoração funcional disfarçada de otimização.

## Validação

Confirma todos os caminhos e links, incluindo as referências de `AGENTS.md` para `EXECUTION_CONTRACT.md` e `PRODUCT_EXCELLENCE.md`. Executa, quando aplicável, os comandos descobertos no próprio projeto, normalmente:

```text
dotnet restore <Projeto>.Web.slnf --locked-mode
dotnet build <Projeto>.Web.slnf --no-restore --nologo -v:q
dotnet test --project src/Tests/<Projeto>.Tests.csproj --no-build --no-restore -v:q --no-progress --no-ansi
```

Adapta os nomes ao repositório. Se algo não puder ser executado, indica o comando, o erro e o impacto. Revê o diff e confirma que não houve alterações funcionais.

## Entrega

Apresenta diagnóstico, ficheiros alterados, comandos/resultados, validação do carregamento de `AGENTS.md` e da leitura dos protocolos aplicáveis, informação obsoleta ou incerta, limitações e a forma concreta como a nova estrutura reduz pesquisas repetidas. Para layout, apresenta a recomendação curta, o estado de `[AUTORIZAR_FERRAMENTAS_LAYOUT]`, o conteúdo de `CODEX_LAYOUT_TOOLING.md`, smoke tests e o handoff verificável para o prompt 12. Não alegues poupanças de tokens nem melhoria visual sem medição.

## Referências oficiais

- https://learn.chatgpt.com/guides/best-practices
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
- https://learn.chatgpt.com/docs/build-skills
- https://learn.chatgpt.com/docs/extend/mcp
- https://github.com/microsoft/playwright-cli
- https://github.com/upstash/context7
- https://github.com/github/github-mcp-server
- https://developers.figma.com/docs/figma-mcp-server/
- https://developers.figma.com/docs/code-connect/
- https://github.com/dequelabs/axe-core
- https://github.com/ChromeDevTools/chrome-devtools-mcp
- https://github.com/openai/plugins
- https://github.com/openai/codex
