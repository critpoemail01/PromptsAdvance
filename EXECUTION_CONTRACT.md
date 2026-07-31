# Contrato comum de execução e validação

Este contrato aplica-se a todos os prompts da coleção. Define o comportamento comum; cada prompt acrescenta o objetivo, as entradas, os limites, os critérios de aceitação e as validações próprias da tarefa.

## 1. Interpretar a tarefa e o estado real

Antes de alterar ficheiros:

1. Lê as instruções aplicáveis, o prompt completo e os documentos que este referencia.
2. Inspeciona o repositório, o estado Git, as alterações locais e o código/configuração/testes afetados.
3. Resolve os valores entre `[COLCHETES]` através de `APP_CONTEXT.md`, decisões aprovadas e fontes de verdade do projeto.
4. Apresenta, quando existirem placeholders materiais, a matriz `entrada → valor → fonte → confiança → estado`.
5. Distingue factos comprovados, inferências reversíveis, decisões pendentes e conflitos.
6. Define o resultado observável, o âmbito e o que fica explicitamente fora dele.
7. Quando `LIFECYCLE_STATE.json` existir, confirma que o prompt atual coincide com `NEXT_TASK.md` e valida a instância antes de implementar.
8. Para APIs, SDKs, frameworks e ferramentas com evolução frequente, consulta primeiro a documentação oficial da versão em uso ou um provider de documentação atual como Context7 quando estiver disponível. Regista a biblioteca, versão e fonte consultada; não uses memória do modelo como prova de uma assinatura atual.
9. Para contexto alojado no GitHub, prefere o connector/plugin oficial ou `gh` já autenticado. Começa por operações read-only e mantém qualquer escrita, alteração de settings, criação de recursos, commit ou push sujeita ao alvo e à autorização explícitos.

Não transformes uma entrada material em pressuposto. Se a ausência alterar arquitetura, dados, permissões, contratos públicos, cobrança, retenção, identidade, publicação ou uma ação irreversível, limita-te ao diagnóstico/proposta e termina como `bloqueado`.

## 2. Planear por etapas e avançar com autonomia proporcional

Antes da implementação, cria um plano curto, ordenado e verificável. Para alterações não triviais, divide-o pelo menos em:

1. descoberta e baseline;
2. implementação do menor lote coerente;
3. validação direcionada;
4. revisão adversarial e entrega de evidências.

Cada etapa deve indicar o resultado esperado e como será validada. Atualiza o plano quando a realidade do repositório contrariar uma premissa.

Quando o lifecycle estiver ativo, inicia uma tentativa estruturada com
`software-lifecycle.ps1 work-start` antes de executar o prompt. Mantém os
objetivos no `LIFECYCLE_STATE.json` apenas através de `checkpoint`, regista
validações com `verify` e não reutilizes evidência de outra tentativa. Um plano
conversacional não substitui este ledger durável.

Depois da fundação, o lote predefinido é uma vertical slice pequena e completa: requisito, UI, contrato, backend/dados, autorização, estados, testes e observabilidade mínima. Não termines grandes fases de UI ou backend isoladamente quando a qualidade só puder ser avaliada na jornada integrada.

Avança autonomamente em ações locais, reversíveis e claramente incluídas no âmbito. Não peças confirmações repetidas para decisões de implementação normais que possam ser comprovadas pelo repositório.

Para e pede a decisão mínima necessária perante:

- ação externa, destrutiva, financeira ou de produção sem autorização específica;
- destino, ambiente, conta, tenant, subscrição ou recurso externo ambíguo;
- criação/adoção de repositório remoto, alteração de `origin`, commit/push ou mudança de visibilidade/regras sem alvo e autorização explícitos;
- alteração incompatível de dados, API, identidade, segurança ou arquitetura não aprovada;
- segredo, acesso, dependência ou decisão de produto indispensável e indisponível.

Um texto como “aprova o plano automaticamente” não amplia autorizações nem substitui estes limites. Não afirmes ter mudado um modo da interface; demonstra o comportamento através do plano, da execução e das evidências.

## 3. Executar o menor conjunto suficiente

- Implementa uma etapa coerente de cada vez e valida-a antes de expandir o diff.
- Preserva arquitetura, contratos, estilo e componentes existentes que já cumprem os requisitos.
- Não aproveites o contexto para refatorar ou corrigir áreas adjacentes.
- Não removas funcionalidade, validações ou testes apenas para obter um resultado verde.
- Não alteres baselines, snapshots, thresholds ou expectativas sem uma alteração de comportamento aprovada e uma justificação verificável.
- Adiciona ou atualiza testes proporcionais ao risco e ao comportamento alterado.
- Mantém segurança, autorização, privacidade, acessibilidade, observabilidade, compatibilidade e recuperação coerentes com o âmbito.
- Regista descobertas fora do âmbito como trabalho futuro; não as implementes silenciosamente.
- Depois de existir uma definição aprovada, aplica `CHANGE_CONTROL.md`: feedback
  e findings criam um delta proposto, não alteram silenciosamente a fonte
  canónica; identifica o prompt proprietário e invalida gates dependentes.

Quando existir uma falha preexistente, prova essa condição sempre que possível, separa-a do efeito da implementação e não a escondas.

## 4. Escolher validações adequadas à tarefa

Executa o menor conjunto de validações capaz de produzir confiança proporcional ao risco. Usa ferramentas apenas quando existirem e forem aplicáveis.

| Tipo de tarefa | Validação mínima esperada |
|---|---|
| Descoberta, requisitos ou documentação | coerência interna, rastreabilidade às fontes, links/caminhos, conflitos, critérios verificáveis e atualidade das fontes externas relevantes |
| Arquitetura e configuração | compatibilidade com o repositório, alternativas e trade-offs, contratos, threat model, configuração por ambiente e build/teste quando houver alteração executável |
| Backend, dados ou integrações | restore/build, análise estática existente, testes unitários e de integração afetados, contratos, migrations, autorização, idempotência, concorrência e falhas de dependências |
| UI web ou SSR | build/testes, browser ou Playwright quando disponível e útil — incluindo a skill/CLI instalada sem a transformar numa dependência da aplicação —, consola, rede, estados HTTP/UI, teclado, checks automáticos de acessibilidade, avaliação manual proporcional, viewports, jornadas afetadas e regressão visual para componentes/estados estáveis |
| MAUI/nativo | build da plataforma disponível, testes afetados, navegação, ciclo de vida, permissões, offline e validação no dispositivo/emulador disponível |
| Segurança e privacidade | testes negativos, autenticação/autorização por objeto/função, validação de entradas/saídas, segredos, logs, dependências e abuso dentro do ambiente autorizado |
| Performance ou resiliência | baseline, orçamento de carga/falha autorizado, métricas, repetição controlada, recuperação e comparação antes/depois |
| Entrega ou produção | preparação/dry-run, artefacto e ambiente exatos, CI, migrations, smoke tests, observabilidade e rollback; executar mudanças externas apenas com autorização explícita |

Não obrigues prompts documentais a executar Playwright. Não consideres inspeção de código suficiente quando o comportamento alterado puder ser executado e observado.

## 5. Executar uma revisão adversarial antes de concluir

Depois da implementação e dos testes direcionados, assume que o resultado está errado e tenta demonstrá-lo:

1. Relê o objetivo, os critérios de aceitação, o âmbito e as exclusões.
2. Revê o diff integral e o estado final do repositório, incluindo ficheiros inesperados, código morto, segredos e alterações acidentais.
3. Executa o menor conjunto suficiente de restore, build, análise estática e testes adequado aos projetos afetados.
4. Quando existir UI ou comportamento de browser em âmbito, valida com browser ou Playwright quando disponível, incluindo consola e rede.
5. Testa casos limite relevantes: entradas vazias, inválidas e extremas; ausência de permissões; repetição e idempotência; concorrência; timeouts; falhas parciais; estados offline/expirados e recuperação.
6. Corrige apenas falhas causadas pela implementação ou incluídas no âmbito autorizado. Regista separadamente problemas preexistentes ou adjacentes.
7. Repete os testes afetados depois de cada correção e termina apenas quando os critérios passarem ou o impedimento estiver demonstrado.

Cada problema aceite durante a revisão deve ser registado com `finding-add`.
Um finding só passa a `resolved` com evidência da correção, comando de
verificação, exit code zero e resultado observado. `finding-gate` e o fecho da
tentativa falham enquanto existir um finding `open` ou `blocked`. Não omitas um
finding por ser incómodo ou fora do lote: resolve-o, termina `partial`/`blocked`
ou regista-o no mecanismo de backlog autorizado pelo prompt antes de abrir uma
nova tentativa.

Uma autorrevisão adversarial feita pelo mesmo agente não deve ser descrita como “independente”. Usa esse termo apenas quando a verificação tiver sido executada por outra tarefa, outro agente/revisor ou uma execução sem o contexto da implementação, e identifica a evidência dessa separação.

### Revisão final independente

Antes de uma publicação de produção, executa uma revisão separada e read-only sobre uma candidata imutável. Regista:

- base SHA, candidate SHA e digest do artefacto;
- critérios congelados, ambiente e dados de teste;
- identidade da tarefa/revisor e método de separação;
- comandos, resultados e relatórios utilizados;
- confirmação de que o revisor não recebeu o raciocínio/transcript da implementação e não alterou a working tree.

O revisor produz apenas findings e uma decisão `GO` ou `NO-GO`; não corrige a candidata que está a avaliar. Se encontrar uma falha, o implementador corrige-a, cria novo commit/artefacto e submete a nova candidata a outra revisão independente. Uma aprovação não transita para um SHA ou digest diferente.

## 6. Preservar a integridade da validação

- Não desatives, ignores ou tornes mais permissivos testes, analyzers, quality gates ou controlos de segurança para declarar sucesso.
- Não escondas falhas através de retries ilimitados, sleeps arbitrários, mocks que removam o comportamento em teste ou filtros injustificados.
- Não atualizes snapshots ou baselines visuais apenas para eliminar um diff; exige revisão explícita da mudança e ambiente de comparação reproduzível.
- Não declares cobertura total, “sem bugs”, conformidade integral ou sucesso a 100% com base numa amostra.
- Não exponhas segredos nem dados pessoais em comandos, logs, screenshots ou evidências.
- Não uses produção nem efeitos reais quando um ambiente isolado, sandbox, test double ou dry-run for suficiente.

## 7. Entregar evidências e um estado honesto

Na entrega, apresenta de forma concisa:

- âmbito e etapas efetivamente executadas;
- ficheiros alterados;
- comandos, ferramentas e resultados relevantes;
- critérios de aceitação verificados e respetiva evidência;
- falhas encontradas na revisão adversarial e correções efetuadas;
- base/candidate SHA e digest do artefacto quando a tarefa fizer parte de uma release;
- identidade, separação e decisão do revisor independente quando este gate for aplicável;
- áreas não validadas e o motivo concreto;
- falhas preexistentes e riscos residuais;
- próximo passo recomendado, sem o executar fora do âmbito;
- estado final: `concluído`, `parcial`, `bloqueado` ou `não aplicável`.
- prompt/gate atual e registo correspondente em `LIFECYCLE_STATE.json`, quando o lifecycle estiver ativo.
- identificador da tentativa, objetivos, verificações e findings do task ledger
  quando o lifecycle estiver ativo.

Usa `concluído` apenas quando todos os critérios em âmbito tiverem evidência suficiente. Usa `parcial` quando existe progresso utilizável mas falta validação ou implementação em âmbito. Usa `bloqueado` quando uma dependência material impede prosseguir com segurança. Usa `não aplicável` apenas com justificação.

Não declares sucesso sem evidência concreta.
