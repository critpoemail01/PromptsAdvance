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

Antes da implementação, cria um plano proporcional ao âmbito. Para uma tarefa
trivial e de um só passo, basta uma frase visível com o resultado pretendido e
a validação; não cries um artefacto separado, cerimónia ou gate de aprovação.
Para alterações não triviais, apresenta um plano curto, ordenado e verificável
e divide-o pelo menos em:

1. descoberta e baseline;
2. implementação do menor lote coerente;
3. validação direcionada;
4. revisão adversarial e entrega de evidências.

Cada etapa não trivial deve indicar o resultado esperado e como será validada.
Atualiza o plano quando a realidade do repositório contrariar uma premissa.
Apresentar ou atualizar o plano não é um pedido de aprovação: continua
automaticamente enquanto as ações seguintes permanecerem dentro da autoridade
existente.

Quando o lifecycle estiver ativo, executa apenas o prompt atual. Usa
`work-start`, `checkpoint`, `verify` e o ledger durável quando a complexidade ou
o risco justificar esse detalhe; o ledger não é uma condição de entrada nem de
fecho para o desenvolvimento local normal.

Depois da fundação, o lote predefinido é uma vertical slice pequena e completa: requisito, UI, contrato, backend/dados, autorização, estados, testes e observabilidade mínima. Não termines grandes fases de UI ou backend isoladamente quando a qualidade só puder ser avaliada na jornada integrada.

Avança autonomamente em ações locais, reversíveis e claramente incluídas no
âmbito. Toma decisões técnicas e de implementação normais sem pedir aprovação
quando forem reversíveis, compatíveis com os limites aprovados e verificáveis
no repositório. Não pares apenas porque uma decisão é relevante ou “material”;
para apenas quando estiver fora do âmbito, for incompatível ou irreversível, ou
exigir uma das autorizações abaixo.

Para e pede a decisão mínima necessária perante:

- ação externa, destrutiva, financeira ou de produção sem autorização específica;
- destino, ambiente, conta, tenant, subscrição ou recurso externo ambíguo;
- criação/adoção de repositório remoto, alteração de `origin`, commit/push ou mudança de visibilidade/regras sem alvo e autorização explícitos;
- alteração incompatível de dados, API, identidade, segurança ou arquitetura não aprovada;
- segredo, acesso, dependência ou decisão de produto indispensável e indisponível.

Um texto como “aprova o plano automaticamente” não amplia autorizações nem substitui estes limites. Não afirmes ter mudado um modo da interface; demonstra o comportamento através do plano, da execução e das evidências.

Dentro do prompt atual, executa continuamente todas as etapas necessárias sem
pedir aprovação entre descoberta, implementação, validação e revisão
adversarial. A validação entre etapas controla o tamanho e a direção do diff;
não é um gate humano. Quando o prompt atual terminar, regista e apresenta o
resultado e para, mesmo sem bloqueios. Só prepares ou executes outro prompt
depois de o programador dizer explicitamente `próximo`, `repetir`, `corrigir`,
`ignorar e avançar` ou indicar o prompt pretendido.

### Flexibilidade antes de executar um prompt

Cada prompt pertence exatamente a uma classe declarada em
`PROCESS_MANIFEST.json`:

| Classe | Comportamento |
|---|---|
| `hard_required` | Invariante crítico; tem de ser executado para declarar o processo integralmente concluído e não aceita dispensa. |
| `recommended` | Faz parte do percurso normal, mas o programador pode dispensá-lo ou adiá-lo com uma razão curta. |
| `conditional` | Executa-se quando a capacidade, superfície ou risco se aplica; caso contrário pode ser marcado não aplicável. |
| `optional` | Melhoria facultativa, executada apenas quando trouxer valor ao produto atual. |

Antes de executar um prompt não crítico, o programador pode registar uma destas
decisões sem alterar a sua classe:

- `not_applicable`: o âmbito não se aplica a esta aplicação;
- `waived`: aplica-se, mas o programador aceita conscientemente não o executar;
- `deferred`: fica adiado e pode ser reaberto numa iteração posterior.

A decisão exige apenas uma razão curta e fica preservada no estado e histórico.
Não cria um gate adicional nem obriga o programador a preencher formulários.
Os estados `partial` e `blocked` continuam reservados ao resultado de trabalho
que chegou a ser executado. Um prompt adiado, dispensado ou não aplicável é
ignorado por `advance`; pode ser reaberto por `request`/`repeat`, com o objetivo
da nova execução.

Os prompts `07`, `42`, `55`, `56`, `65`, `66` e `67` são `hard_required`:
fundação verificável, segurança, testes gerais, supply chain, aceitação final,
revisão independente e release exata. O lifecycle não força a sua execução,
mas também não permite ocultar a sua ausência através de uma dispensa. Se o
programador parar antes deles, o estado deve continuar a mostrar a lacuna e não
declarar conclusão integral.

### Destino único: produção

Todas as iniciativas Advance são tratadas como aplicações finais destinadas a
produção. Não existem perfis de maturidade `prototype`, `MVP`, `pilot` ou
“produção mais tarde”. Os perfis de execução `fast`, `standard` e `deep`
ajustam apenas a profundidade da investigação e da validação de uma tarefa; não
reduzem a qualidade exigida ao produto final.

Esta premissa não obriga a publicar nem amplia autorização externa. Significa
que o lifecycle só pode declarar `production_ready` quando:

1. todos os prompts `hard_required` estiverem `completed`;
2. cada prompt não crítico tiver sido concluído ou possuir uma decisão explícita
   `not_applicable`, `waived` ou `deferred`;
3. não existirem resultados `partial` ou `blocked` por resolver;
4. o Gate G10 tiver passado com a cadeia de evidências e autorizações exigida.

O programador pode parar, mudar a ordem ou continuar com lacunas a qualquer
momento. Nesse caso, o processo permanece `not_production_ready` e apresenta o
que falta; nunca converte o fim da numeração ou uma dispensa num falso estado de
produção. Deploy, lojas, custos, recursos externos e produção real continuam a
exigir autorização específica para o alvo exato.

### Portas locais exclusivas por aplicação

Várias aplicações Advance podem executar simultaneamente na mesma máquina.
Antes de criar/configurar a fundação ou responder a `corre a app`, usa
`scripts/Manage-AdvanceLocalPorts.ps1` para reservar um bloco persistente de dez
portas por raiz física de aplicação. A reserva é protegida por lock de ficheiro
e confrontada com os listeners TCP reais.

O mapeamento estável é: API HTTP/HTTPS em `base/base+1`, SSR em
`base+2/base+3` e Web em `base+4/base+5`; as quatro portas restantes ficam
reservadas para crescimento local da mesma aplicação. MAUI consome o URL da API
e não abre um listener adicional. A atribuição fica em `APP_LOCAL_PORTS.json`
no lifecycle e no registo local da máquina; é configuração local, não contém
segredos e nunca deve ser commitada ou propagada para staging/produção.

Reutiliza uma reserva existente e uma instância saudável da própria aplicação.
Se houver colisão com outro processo, prova primeiro o proprietário e realoca o
bloco completo, nunca uma porta isolada. Volta a ligar API, clientes, CORS e
redirects aos URLs devolvidos e repete os testes de arranque. Parar processos
mantém a reserva estável; libertá-la exige um pedido explícito do programador.

## 3. Executar o menor conjunto suficiente

- Implementa uma etapa coerente de cada vez e valida-a antes de expandir o
  diff, continuando automaticamente para a etapa seguinte do mesmo prompt
  quando a validação passar.
- Preserva arquitetura, contratos, estilo e componentes existentes que já cumprem os requisitos.
- Não aproveites o contexto para refatorar ou corrigir áreas adjacentes.
- Não removas funcionalidade, validações ou testes apenas para obter um resultado verde.
- Não alteres baselines, snapshots, thresholds ou expectativas sem uma alteração de comportamento aprovada e uma justificação verificável.
- Adiciona ou atualiza testes proporcionais ao risco e ao comportamento alterado.
- Mantém segurança, autorização, privacidade, acessibilidade, observabilidade, compatibilidade e recuperação coerentes com o âmbito.
- Regista descobertas fora do âmbito como trabalho futuro; não as implementes silenciosamente.
- Numa release ou baseline formalmente aprovada, aplica `CHANGE_CONTROL.md` a
  alterações materiais. Durante o desenvolvimento normal, atualiza a fonte
  canónica e regista claramente o motivo sem criar cerimónia de release.

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

Regista problemas materiais de forma durável no artefacto do prompt, no backlog
ou, quando o ledger estiver em uso, com `finding-add`. Não escondas um problema:
resolve-o, termina `partial`/`blocked` ou lista-o explicitamente em
`RemainingWork` antes de parar.

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

### Resposta conversacional orientada à decisão

A resposta ao programador é uma interface de decisão, não a reprodução do
relatório completo. Começa sempre pelo resultado e usa esta ordem, adaptando
apenas os campos não aplicáveis:

1. `Resultado` — estado (`concluído`, `parcial`, `bloqueado` ou `não aplicável`)
   e uma frase sobre o que foi alcançado;
2. `Falta para terminar` — lista concreta do que ainda tem de ser implementado
   para cumprir o objetivo do prompt, ou `nada`;
3. `Porquê` — no máximo três razões determinantes, uma frase por razão;
4. `Opções` — apenas quando existir escolha material, entre duas e cinco opções
   comparáveis por `opção | ganho | custo/risco | evidência/confiança`, com uma
   opção explicitamente recomendada;
5. `Prova` — alterações, verificações e resultados indispensáveis para confiar
   na recomendação, sem despejar logs;
6. `Riscos e bloqueios` — no máximo três riscos materiais e a condição concreta
   para os resolver;
7. `Decisão do programador` — `próximo`, `repetir`, `corrigir` ou
   `ignorar e avançar`. Não prepares o prompt seguinte antes dessa resposta.

O primeiro bloco deve caber normalmente em 8–12 linhas e permitir compreender
o resultado sem ler o restante. Usa `Decisão necessária: nenhuma` quando não
for exigida intervenção humana. Não listes alternativas que não recomendarias,
não repitas contexto já aprovado e não escondas a conclusão no fim.

Conserva matrizes, investigação, requisitos, logs, cálculos, findings e outra
evidência extensa nos artefactos duráveis exigidos pelo prompt. Se o prompt não
nomear um artefacto para um relatório material, cria um ficheiro de evidência
com nome explícito dentro do âmbito autorizado e liga-o na resposta. A síntese
conversacional referencia esses artefactos e não os transcreve. Um formato curto
nunca autoriza omitir evidência, incerteza, estado do gate ou bloqueios.

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
- identificador da tentativa, objetivos, verificações e findings quando o task
  ledger tiver sido usado.

Usa `concluído` apenas quando todos os critérios em âmbito tiverem evidência suficiente. Usa `parcial` quando existe progresso utilizável mas falta validação ou implementação em âmbito. Usa `bloqueado` quando uma dependência material impede prosseguir com segurança. Usa `não aplicável` apenas com justificação.

Não declares sucesso sem evidência concreta.
