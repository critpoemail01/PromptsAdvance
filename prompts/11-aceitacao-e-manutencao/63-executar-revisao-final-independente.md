# Executar revisão final adversarial independente

## Objetivo

Avalia a candidata identificada por `[BASE_SHA]`, `[CANDIDATE_SHA]`,
`[ARTIFACT_PATH]` e `[ARTIFACT_DIGEST]` numa tarefa/revisor separado,
read-only e sem contexto de implementação. Confirma primeiro que o artefacto
está realmente acessível, calcula o digest no próprio ambiente de revisão e
compara-o com o valor congelado. Tenta demonstrar que a candidata não cumpre os
critérios e produz apenas findings e decisão `GO` ou `NO-GO`.

Antes de iniciar a revisão, prova que a sandbox read-only consegue executar a
verificação de integridade. Se a política bloquear comandos de hashing, usa
apenas um verificador pequeno, versionado, inspecionável e executado pelo
próprio revisor que leia o artefacto e compare o SHA-256 congelado. O verificador
tem de falhar perante ficheiro ausente ou conteúdo diferente. Um digest apenas
declarado, um ficheiro de texto não verificado ou o resultado fornecido pelo
implementador não substituem este cálculo. Se nenhum método independente for
executável, decide `NO-GO`.

## Independência obrigatória

- Usa `[REVISOR_INDEPENDENTE]` e regista `[EVIDENCIA_DE_SEPARACAO]`.
- Preferencialmente executa `/review` em modo Detached, uma tarefa/agente reviewer com sandbox read-only ou um revisor humano/técnico diferente.
- O revisor recebe requisitos, critérios, base/candidate SHA, artefacto, comandos, ambiente e evidências, mas não o transcript/raciocínio da implementação.
- A working tree começa e termina inalterada. O revisor não faz correções, commits, pushes, atualizações de snapshots ou mudanças de critérios.
- Se não existir separação real, termina `bloqueado`; uma autorrevisão não satisfaz este prompt.

## Critérios de sucesso

- A candidata e o artefacto são imutáveis e correspondem à aceitação do prompt 62.
- O diff integral e os gates bloqueantes são revistos com evidência atual.
- Findings incluem severidade, localização, reprodução, impacto e critério violado.
- Falhas críticas/altas ou evidência material ausente produzem `NO-GO`.
- `GO` só vale para o candidate SHA e digest avaliados.

## Processo read-only

1. Verifica base/candidate SHA, assinatura/digest do artefacto, estado limpo e proveniência dos relatórios.
2. Revê todas as alterações, ficheiros inesperados, segredos, código morto, permissões, dados, migrations, contratos e configuração.
3. Reexecuta o menor conjunto suficiente de restore, build, análise estática, testes unitários/integração/E2E e verificações de supply chain.
4. Para UI, exercita jornadas críticas, permissões, casos limite, mobile/desktop, acessibilidade, snapshots/diffs, consola e rede.
5. Revê `PRODUCT_QUALITY_BASELINE.md`, usabilidade, performance, SLI/SLO, observabilidade, DR, runbooks, rollback e documentação.
6. Tenta falhas negativas: entradas inválidas/extremas, IDOR/permissões, repetição, concorrência, timeout, falha parcial, sessão expirada, offline e recuperação.
7. Confirma que testes, thresholds, snapshots e exceções não foram enfraquecidos.

## Loop de findings

Entrega `NO-GO` e devolve os findings ao implementador. Depois de qualquer correção:

1. o implementador cria novo commit e artefacto;
2. atualiza SHA/digest e reexecuta os testes afetados;
3. uma nova execução independente deste prompt avalia a nova candidata desde o início.

Não reutilizes uma aprovação antiga nem permitas que o revisor “corrija e aprove” a mesma candidata.

## Entrega

Apresenta identidade/método de separação, base/candidate SHA, digest, confirmação read-only, âmbito, comandos/resultados, findings priorizados, áreas não validadas, riscos e decisão `GO`/`NO-GO`. Regista tudo no manifesto de evidência de `IMPLEMENTATION_STATUS.md`.

## Referências oficiais

- https://learn.chatgpt.com/docs/code-review
- https://learn.chatgpt.com/docs/agent-configuration/subagents
- https://google.github.io/eng-practices/review/
