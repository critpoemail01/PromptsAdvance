# Preparar o projeto para utilização eficiente pelo Codex

## Objetivo

Depois de a aplicação ter sido criada a partir do boilerplate, audita e melhora as instruções e a documentação técnica do novo repositório para que futuras tarefas do Codex encontrem rapidamente o contexto, os comandos e os ficheiros relevantes. Não alteres comportamento, arquitetura, APIs, base de dados ou dependências de produção.

## Contexto esperado

O projeto deriva de `BoilerPlateAdvance`: .NET 10/C# 14, Bit Platform, site público em `Client.Ssr`, aplicação autenticada WASM/PWA em `Client.Web`, UI partilhada em `Client.Core`, cliente `Client.Maui` e API em `Server.Api`. Confirma tudo no repositório porque nomes e módulos podem ter mudado. `Server.Web` e `Client.Windows` são referências, não projetos ativos.

## Critérios de sucesso

- `AGENTS.md` contém apenas regras duradouras, comandos comprovados e critérios de verificação.
- `AGENTS.md` exige a leitura integral de `EXECUTION_CONTRACT.md`, e o contrato comum não está duplicado nos prompts.
- Para tarefas que afetem produto ou experiência, `AGENTS.md` exige a leitura de `PRODUCT_EXCELLENCE.md`.
- Informação detalhada fica em documentação ligada, sem duplicação contraditória.
- Workflows repetidos com entradas/saídas estáveis ficam propostos como skills focadas, não como instruções gigantes no `AGENTS.md`.
- Todos os comandos e caminhos documentados foram confirmados no repositório ou marcados como não verificados.
- Nenhuma alteração funcional, dependência ou configuração de runtime foi introduzida.

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

## Limites

- Não inventes comandos, scripts, lint, typecheck ou Playwright inexistentes.
- Não atualizes packages, lockfiles ou workloads.
- Não elimines documentação sem confirmar referências e conteúdo único.
- Não copies o conteúdo integral de `EXECUTION_CONTRACT.md` para `AGENTS.md` ou para cada prompt.
- Não copies o conteúdo integral de `PRODUCT_EXCELLENCE.md` para todos os prompts; mantém neles apenas os critérios específicos.
- Não copies segredos para documentação.
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

Apresenta diagnóstico, ficheiros alterados, comandos/resultados, validação do carregamento de `AGENTS.md` e da leitura dos protocolos aplicáveis, informação obsoleta ou incerta, limitações e a forma concreta como a nova estrutura reduz pesquisas repetidas. Não alegues poupanças de tokens sem medição.

## Referências oficiais

- https://learn.chatgpt.com/guides/best-practices
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
- https://learn.chatgpt.com/docs/build-skills
