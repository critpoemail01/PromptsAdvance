# Triar bugs e feedback de suporte

## Objetivo

Transforma sinais de `[CANAIS_DE_BUGS_E_FEEDBACK]` em problemas reproduzíveis, deduplicados e priorizados, protegendo dados pessoais e distinguindo defeitos, pedidos, confusão de UX e incidentes.

## Processo

1. Confirma canais, janela, política de acesso/privacidade e taxonomia.
2. Redige dados pessoais/segredos antes de copiar evidência para tickets ou documentação.
3. Agrupa duplicados por comportamento, versão, jornada e causa provável; preserva links às fontes autorizadas.
4. Tenta reproduzir num ambiente seguro com dados sintéticos e regista passos, resultado esperado/real, frequência e impacto.
5. Classifica severidade, alcance, regressão, workaround, requisito afetado e owner.
6. Liga findings de UX à `PRODUCT_QUALITY_BASELINE.md` e defeitos técnicos ao teste de regressão necessário.
7. Não responde a utilizadores, fecha tickets ou publica roadmaps sem autorização.

## Critérios de sucesso

- Itens críticos têm owner e escalamento imediato.
- “Não reproduzido” não significa “não existe”; inclui ambiente e evidência em falta.
- Popularidade de um pedido não substitui impacto, estratégia ou investigação.
- Correções concluídas ligam commit/release, teste e verificação pós-release.

## Entrega

Apresenta clusters, bugs reproduzidos/não reproduzidos, feedback UX/produto, severidade, evidência redigida, owners, próximos passos e tendências sem expor utilizadores.

## Referências

- https://learn.microsoft.com/azure/well-architected/operational-excellence/observability
- https://sre.google/workbook/postmortem-culture/

