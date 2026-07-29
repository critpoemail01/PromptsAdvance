# Fechar a definição do produto e executar o Gate A

## Objetivo

Antes de iniciar arquitetura ou fundação técnica, audita os resultados dos prompts 01–03, completa a rastreabilidade e decide se a definição do produto está suficientemente concreta para passar à etapa 2. Esta tarefa é o gate final da etapa 1: não implementa código, não define a arquitetura e não cria o projeto.

## Fontes obrigatórias

Lê integralmente:

- `AGENTS.md`;
- `EXECUTION_CONTRACT.md`;
- `PRODUCT_EXCELLENCE.md`;
- `PRODUCT_DEFINITION.md`;
- `APP_CONTEXT.md`;
- `IMPLEMENTATION_STATUS.md`;
- resultados e artefactos versionados dos prompts 01, 02 e 03.

Se `PRODUCT_DEFINITION.md` não existir, estiver vazio ou não for rastreável aos resultados anteriores, termina `bloqueado`. Não recries silenciosamente toda a descoberta dentro deste prompt.

## Princípio de decisão

“Parece uma boa ideia” não é uma definição pronta. Só existe passagem para a etapa 2 quando uma equipa de arquitetura consegue tomar decisões sem inventar:

- qual é o problema e para quem;
- qual é a jornada principal e o resultado pretendido;
- o que pertence ou não ao primeiro produto;
- quais os requisitos `Must` e como serão aceites;
- que dados, atores, permissões e riscos são materiais;
- que métricas determinam continuar, corrigir ou parar;
- quais são as limitações de orçamento, prazo e competências.

## Auditoria

1. Confirma que os prompts 01, 02 e 03 estão registados em `IMPLEMENTATION_STATUS.md`, com estado, fontes, decisões e evidências.
2. Verifica a consistência entre oportunidade, público, nome de trabalho, posicionamento, requisitos, orçamento, prazo e restrições.
3. Confirma que factos, inferências, pressupostos e decisões estão separados. Uma repetição da mesma afirmação não conta como segunda evidência.
4. Audita a especificação:
   - todos os requisitos `Must` têm ID estável, fonte, critério de aceitação observável, prioridade, dependências e aprovação;
   - jornadas críticas incluem happy path, alternativas, erros, recuperação e autorização;
   - NFR materiais são mensuráveis ou originam uma decisão bloqueante;
   - conflitos e perguntas em aberto não foram escondidos em texto narrativo.
5. Confirma que o MVP contém uma jornada ponta a ponta coerente e pequena, com inclusões e exclusões explícitas.
6. Confirma a viabilidade face ao `BoilerPlateAdvance` em `C:\Work\BoilerPlateAdvance`, orçamento, prazo, competências, dependências, legalidade, privacidade e acesso ao público. Limita-te a adequação e riscos; não escolhas ainda módulos ou topologia.
7. Confirma que existe uma métrica de resultado, baseline ou método para a obter, meta, horizonte temporal, métricas de proteção e critério de continuar/parar.
8. Atualiza em `PRODUCT_DEFINITION.md` DOR-01 a DOR-12 como `passou`, `falhou` ou `não verificável`, sempre com evidência e ação concreta.

## Regras bloqueantes

O Gate A não pode receber `GO` se ocorrer qualquer uma destas condições:

- problema, público, job to be done ou jornada principal definidos apenas com adjetivos ou generalidades;
- recomendação do prompt 01 diferente de `avançar`;
- nome de trabalho ainda não aprovado pelo responsável de produto;
- algum requisito `Must` sem fonte, aceitação observável, dependências ou aprovação;
- conflito material sobre dados, permissões, cobrança, retenção, contrato, legalidade, orçamento, prazo ou viabilidade;
- métrica de resultado ou critério de continuar/parar ausente;
- DOR-01 a DOR-12 sem estado `passou` e evidência;
- aprovação do responsável de produto ausente ou não ligada à versão auditada.

Não transformes uma condição bloqueante em pressuposto para conseguir avançar. Uma questão reversível só transita quando tiver impacto limitado, owner, prazo e teste registados e não afetar nenhuma condição acima.

## Decisão

Produz exatamente uma destas decisões:

- `GO` — a definição está aprovada, DOR-01 a DOR-12 passaram com evidência e a etapa 2 pode iniciar no prompt 05;
- `REWORK` — existe uma oportunidade plausível, mas faltam elementos concretos; identifica os DOR falhados e manda repetir apenas os prompts 01, 02 ou 03 necessários;
- `NO-GO` — a oportunidade deixou de satisfazer os critérios de problema, procura, viabilidade, legalidade ou adequação.

Só no caso `GO` atualiza:

```text
Estado do documento: aprovado
Decisão do Gate A: GO
```

Nos restantes casos mantém a etapa 2 `bloqueada`. Não executes o prompt 05 como continuação desta tarefa.

## Atualizações obrigatórias

1. Atualiza `PRODUCT_DEFINITION.md`, incluindo versão, checklist DOR, decisão e histórico.
   Mantém o bloco `GATE_A_*` sincronizado com a tabela humana; o script usa esse registo para impedir passagens ambíguas.
2. Atualiza `APP_CONTEXT.md` apenas com valores confirmados e respetivas fontes.
3. Atualiza `IMPLEMENTATION_STATUS.md`:
   - estado e evidência dos prompts 01–04;
   - resumo DOR-01 a DOR-12;
   - decisão do Gate A;
   - bloqueios e prompt exato a repetir;
   - próximo lote, que só pode ser o prompt 05 quando a decisão for `GO`.
4. Não marques o Gate B como iniciado.
5. Depois de gravar todas as atualizações, executa:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ProductDefinitionGate.ps1
```

Uma decisão `GO` só é válida se este comando terminar com exit code 0. Se falhar, corrige inconsistências documentais sustentadas pelas fontes ou muda a decisão para `REWORK`; não ignores o resultado.

## Revisão adversarial

Antes de concluir, assume que a definição é vaga e tenta demonstrá-lo:

1. pede a um leitor sem contexto que explique o problema, público, jornada, âmbito e sucesso apenas a partir dos artefactos;
2. procura linguagem não mensurável, requisitos compostos, fontes circulares, contradições e decisões sem owner;
3. tenta encontrar um requisito `Must` que permita duas implementações incompatíveis e ainda assim “passe”;
4. confirma que orçamento, prazo e competências suportam de forma plausível o MVP;
5. verifica que a aprovação corresponde à versão atual, não a uma versão anterior.

Corrige apenas falhas documentais sustentadas pelas fontes. Se a correção exigir uma decisão de produto ou nova pesquisa, usa `REWORK`; não a inventes.

## Entrega

Apresenta:

- versão auditada de `PRODUCT_DEFINITION.md`;
- decisão `GO`, `REWORK` ou `NO-GO`;
- DOR-01 a DOR-12 com evidência;
- contradições e lacunas encontradas;
- prompts que devem ser repetidos, quando aplicável;
- ficheiros atualizados;
- áreas não verificáveis e riscos residuais;
- próximo prompt autorizado ou confirmação de que a etapa 2 permanece bloqueada.

Não declares a definição “concreta”, “completa” ou “aprovada” sem evidência ligada a todos os critérios bloqueantes.
