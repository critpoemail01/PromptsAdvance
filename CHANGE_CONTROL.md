# Controlo de mudanças do produto e do lifecycle

Este protocolo aplica-se depois de existir uma definição de produto aprovada e
continua válido após a primeira release. Nenhuma alteração material é executada
como pedido informal, patch isolado ou edição direta de gates. A mudança deve
ser rastreável desde o sinal que a originou até à atualização da fonte canónica,
validação, release e aprendizagem observada.

## Princípios

- A especificação aprovada descreve a verdade atual; uma proposta de mudança
  descreve apenas um delta ainda não aprovado.
- Feedback, métricas, findings, vulnerabilidades e pedidos de stakeholders são
  sinais, não requisitos aprovados.
- A aprovação de uma mudança não aprova automaticamente arquitetura, baseline
  visual, custos, ações externas ou produção.
- A mudança reentra no prompt mais antigo que detém a decisão afetada e invalida
  todos os gates downstream materialmente dependentes.
- Não se edita `currentPrompt`, gates ou snapshots diretamente. Numa instância
  concluída, usa-se `software-lifecycle.ps1 cycle-start`.

## Artefacto obrigatório

Cria `changes/CHG-####/PROPOSAL.md` com estes marcadores legíveis pelo
orquestrador:

```text
CHANGE_ID: CHG-####
CHANGE_STATUS: proposed | approved | rejected | superseded | completed
CHANGE_OWNER: <identidade ou função>
CHANGE_APPROVER: <identidade autorizada>
CHANGE_BASELINE: <versão, commit, release ou evidência imutável>
CHANGE_CREATED_AT: <ISO 8601 com fuso>
CHANGE_APPROVED_AT: <ISO 8601 com fuso ou pending>
```

O documento inclui ainda:

| Secção | Conteúdo mínimo |
|---|---|
| Sinal e proveniência | feedback, métrica, incidente, obrigação, finding ou hipótese; fonte, data, população e limitações |
| Resultado pretendido | utilizador/ator, comportamento atual, comportamento pretendido e métrica de decisão |
| Delta | requisitos, regras, dados, permissões, contratos, UI, operação e exclusões; sem reescrever a baseline inteira |
| Impacto | `APP/PAGE/JRN/FR/AC`, arquitetura, threat model, privacidade, acessibilidade, compatibilidade, migração, observabilidade e custos |
| Invalidação | prompt proprietário mais antigo, gates e aprovações que deixam de ser válidos, com justificação |
| Entrega | slice mínima, rollout, rollback/roll-forward, experiência/flag quando aplicável e prova esperada |
| Decisão | owner, aprovador, data, `approved/rejected/rework`, condições e riscos aceites |

## Workflow

1. **Capturar:** regista o sinal sem o promover a requisito. Deduplica sinais
   relacionados e preserva proveniência, população e limitações.
2. **Clarificar:** separa defeito, dívida, melhoria, experiência, requisito
   regulatório, alteração arquitetural e incidente. Define o resultado
   observável e a menor mudança capaz de testar a hipótese.
3. **Analisar impacto:** identifica a fonte canónica e o prompt proprietário
   mais antigo. Lista gates, candidatas, baselines e autorizações invalidados.
4. **Decidir:** o owner autorizado aprova, rejeita ou pede rework sobre uma
   versão exata da proposta. Sem aprovação, apenas pesquisa e diagnóstico
   read-only podem continuar.
5. **Iniciar ciclo:** quando a instância anterior estiver `completed`, executa:

   ```powershell
   .\software-lifecycle.ps1 cycle-start `
     -ProcessRoot . `
     -ChangeId CHG-0001 `
     -Evidence changes/CHG-0001/PROPOSAL.md
   ```

   O comando verifica a proposta aprovada, arquiva o estado anterior,
   reinicializa prompts/gates de forma determinística e prepara o prompt 01.
   Os prompts 01–04 revalidam o produto e integram o delta; não repetem
   investigação ou naming não afetados sem necessidade.
6. **Executar:** implementa uma slice pequena e completa, seguindo o lifecycle.
   Atualiza primeiro a fonte canónica; gera ou reconcilia vistas derivadas.
7. **Verificar:** prova critérios novos e regressão dos comportamentos
   preservados. Uma mudança de candidata, digest, attestation, baseline ou
   ambiente exige nova revisão aplicável.
8. **Incorporar e fechar:** depois dos gates, incorpora o delta na especificação
   corrente, marca a proposta `completed`, liga evidência da release/resultado e
   conserva o diretório da mudança como histórico imutável.
9. **Aprender:** na cadência definida, compara a métrica com a baseline. Um
   resultado negativo ou inconclusivo cria nova proposta; não reescreve a
   decisão histórica.

## Reentrada conservadora

Um novo ciclo começa no prompt 01 porque qualquer mudança pode revelar uma
premissa de produto inválida. O prompt 01 usa o modo `change-cycle` para validar
o sinal e o resultado pretendido; o prompt 02 confirma a identidade existente
quando naming não está afetado; o prompt 03 aplica o delta à especificação; o
prompt 04 volta a decidir G01. Os prompts seguintes revalidam apenas o que for
materialmente afetado, mas nenhum gate é herdado por texto ou conveniência.

## Critério de conclusão

Uma mudança só fica `completed` quando a proposta aprovada, fonte canónica,
traceabilidade, implementação, testes, gates, release aplicável e resultado
observado apontam para as mesmas identidades. Um delta implementado mas ainda
sem evidência de resultado permanece `implemented/monitoring`, não “validado”.
