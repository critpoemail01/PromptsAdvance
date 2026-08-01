# Contrato de engenharia de requisitos

Este contrato complementa o contrato inline do prompt 03. Não substitui a
fonte canónica nem autoriza preencher decisões de produto por inferência. O seu
objetivo é tornar requisitos funcionais e não funcionais suficientemente
precisos para implementação, revisão e teste, sem transformar a especificação
num desenho técnico prematuro.

## Exaustividade e formato invariantes

Este contrato aplica-se a qualquer levantamento, auditoria, correção ou
reconciliação de requisitos, incluindo os prompts 03, 04, 09, 20, 27 e 29.
O executor produz o levantamento mais completo que as fontes e o produto real
permitem, sem amostragem, quota máxima, resumo por módulo ou adiamento por a
lista ser extensa.

- Enumera todos os projetos/superfícies ativos, páginas/ecrãs/rotas, endpoints,
  operações não visuais e funcionalidades em âmbito antes de escrever o
  detalhe. Código, rotas, menus, componentes, handlers, contratos, testes,
  documentação e decisões aprovadas são fontes de descoberta, não autorização
  automática para inventar requisitos.
- Para cada funcionalidade, percorre integralmente atores, permissões,
  pré-condições, trigger, happy path, confirmações, validações, leituras,
  mutações ordenadas, condições e ramos, operações múltiplas, sucesso parcial,
  estados, erros, recuperação, concorrência, repetição/idempotência,
  notificações, auditoria e pós-condições aplicáveis.
- Não usa “principais funcionalidades”, “exemplos”, “etc.”, “e semelhantes” ou
  uma amostra representativa como substituto do inventário completo. Um item
  desconhecido recebe ID, estado, lacuna, owner e evidência necessária; não é
  omitido nem preenchido por inferência.
- A exaustividade é demonstrada por um censo reconciliado
  `projeto → página/ecrã/endpoint/operação → funcionalidade → RF-P → requisito
  canónico → AC → prova`, com contagens, IDs e zero omissões sem justificação.
- Cada `RF-P` é globalmente único e estável. Os IDs repetidos do exemplo de
  formato são ilustrativos e nunca podem ser copiados para funcionalidades
  diferentes.

Em `requirements/ALL_FUNCTIONALITIES.md`, repete exatamente esta estrutura,
usando o nome técnico real do projeto e `PÁGINA`, `ECRÃ`, `ENDPOINT` ou
`OPERAÇÃO-NÃO-VISUAL` conforme a superfície:

```text
# <Projeto real> - <PÁGINA|ECRÃ|ENDPOINT|OPERAÇÃO-NÃO-VISUAL> <ID/nome>
## <Projeto real> - <PÁGINA|ECRÃ|ENDPOINT|OPERAÇÃO-NÃO-VISUAL> <ID/nome> - FUNCIONALIDADE NN (<FNC-ID>) - <nome>
| ID | Quem | Onde | Quando | O quê |
|---|---|---|---|---|
| RF-P... | <ator ou sistema concreto> | <local/fronteira concreta> | <trigger, condição ou momento exato> | <obrigação atómica e efeito observável> |
```

Não acrescenta colunas, não funde funcionalidades na mesma tabela e não cria
uma `PÁGINA` fictícia para a API. Em `Server.Api`, cada unidade usa `ENDPOINT`
com verbo/rota ou `OPERAÇÃO-NÃO-VISUAL` quando não existe endpoint.

## Saída obrigatória

Mantém `requirements/REQUIREMENTS_QUALITY_MATRIX.md` em paridade com
`REQUIREMENTS_SPECIFICATION.md`, os contratos `APP/PAGE`, a checklist do
programador e `ALL_FUNCTIONALITIES.md`.

Cada requisito em âmbito tem uma linha com:

| Campo | Regra |
|---|---|
| ID e versão | Estável; nunca reutilizado para outro comportamento |
| Fonte e estado | Evidência, decisão ou hipótese; factos e inferências separados |
| Owner e prazo | Obrigatórios para `TBD`, `TBR`, conflito ou exceção |
| Ator e autorização | Quem inicia, em que contexto e com que permissão por função/objeto |
| Trigger e pré-condições | Evento observável e estado necessário antes da ação |
| Obrigação atómica | Uma única regra em voz ativa; sem “e/ou”, “etc.” ou adjetivos vagos |
| Resultado e efeitos | UI, contrato, dados, integrações, auditoria e notificações afetadas |
| Estados e recuperação | Sucesso, vazio, erro, repetição, concorrência, cancelamento e retoma aplicáveis |
| Aceitação e oráculo | Como distinguir inequivocamente passou/falhou; `RF-P` liga ao teste Playwright primário e aos projetos mobile/tablet/desktop aplicáveis |
| Risco e nível de teste | Risco coberto e prova unitária, componente, integração, contrato ou browser |
| Prioridade e slice | `Must/Should/Could`, slice candidata e estado de refinamento |

## Regras de qualidade

1. Escreve a necessidade sem prescrever framework, tabela, endpoint ou
   componente, salvo quando uma restrição aprovada torna essa escolha parte do
   contrato.
2. Divide regras com ramos, efeitos ou owners distintos. Uma linha genérica não
   pode representar várias obrigações independentes.
3. Usa linguagem observável e limites mensuráveis. Substitui “rápido”,
   “intuitivo”, “seguro” ou “adequado” por contexto, medida e tolerância.
4. Regista exemplos e contraexemplos para regras materiais. Inclui classes de
   equivalência e valores de fronteira quando datas, montantes, quantidades,
   estados ou permissões alterarem o resultado.
5. Para lógica com dois ou mais condicionais materiais, cria uma tabela de
   decisão completa. Para ciclos de vida, cria uma tabela de transições com
   estado inicial, evento, guarda, próximo estado, efeito e transições
   proibidas.
6. Um `TBD` ou `TBR` sem owner, prazo e efeito bloqueante explícito não é
   aceite. Decisões que alteram dados, contrato público, cobrança, privacidade
   ou autorização bloqueiam código.
7. Tenta produzir duas implementações semanticamente incompatíveis para cada
   regra de alto risco. Se ambas couberem no texto, o requisito ainda é
   ambíguo.

## Cenários de qualidade

Cada NFR material usa o formato:

| ID | Fonte | Estímulo | Ambiente | Artefacto | Resposta | Medida/tolerância | Método de prova | Owner |
|---|---|---|---|---|---|---|---|---|
| NFR-… | decisão/evidência | evento mensurável | normal/degradado/pico | superfície/serviço | resposta esperada | limiar e janela | teste/medição | pessoa/equipa |

Não inventes SLO, RTO, RPO, volume, latência ou capacidade. Quando faltarem,
regista a decisão pendente e o impacto no gate aplicável.

## Tabelas obrigatórias quando aplicáveis

### Decisão

| Regra | Condição A | Condição B | Permissão | Resultado | Efeito proibido | AC |
|---|---|---|---|---|---|---|

### Estado

| Estado atual | Evento | Guarda | Próximo estado | Efeito | Recuperação | Transição proibida |
|---|---|---|---|---|---|---|

### Exemplos e fronteiras

| Regra | Classe/limite | Exemplo válido | Contraexemplo | Resultado esperado | Oráculo |
|---|---|---|---|---|---|

### Rastreabilidade orientada ao risco

| Requisito | Risco | Invariante/oráculo | Nível mínimo de teste | Cenário negativo | Evidência |
|---|---|---|---|---|---|

## Definition of Ready da slice

Uma slice só fica `ready` quando:

- todos os IDs selecionados têm fonte, aprovação, owner, prioridade e resultado;
- tabelas de decisão/estado e exemplos cobrem as regras materiais;
- dados, permissões, integrações, erros e recuperação estão definidos;
- NFR materiais têm cenário mensurável ou bloqueio explícito;
- cada aceitação tem um oráculo e um nível mínimo de teste;
- cada `RF-P` tem identificador previsto do teste Playwright primário e
  aplicabilidade mobile/tablet/desktop; MAUI nativo identifica também o teste
  UI nativo equivalente;
- as vistas derivadas estão em paridade mecânica com a fonte canónica;
- não existem `TBD/TBR`, conflitos ou hipóteses que mudem o comportamento da slice.

O prompt 03 cria a baseline; os prompts 09 e 20 reconciliam deltas; os prompts
27 e 29 executam este gate novamente antes de editar código. Uma reconciliação
preserva IDs, formato, exaustividade e histórico e nunca promove observação
técnica ou visual a requisito aprovado sem change control. O estado
`approved_for_refinement` não autoriza omitir detalhe já descoberto nem marcar
o levantamento como completo; uma lacuna material continua `pending` ou
`blocked` com owner e prova necessária.
