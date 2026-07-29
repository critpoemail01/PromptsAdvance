# Monitorizar custos e anomalias

## Objetivo

Compara custos reais com `[ORCAMENTOS_DE_CUSTO]`, procura anomalias e liga variações a utilização, arquitetura, releases e fornecedores sem executar compras, eliminações ou mudanças de capacidade por defeito.

## Processo

1. Confirma contas/subscrições, moeda, impostos, janela, budgets, tags e owners.
2. Recolhe custo amortizado/real conforme a política e normaliza por utilizador, pedido, job, storage ou outra unidade útil.
3. Compara dia/semana/mês, previsão versus budget e baseline sazonal.
4. Segmenta por serviço, ambiente, região, recurso, tag e release.
5. Deteta spikes, crescimento sustentado, recursos ociosos, egress, logs/cardinalidade e compromissos subutilizados.
6. Valida hipóteses com métricas técnicas/negócio; não atribui causalidade sem evidência.
7. Propõe mitigação com impacto, risco e poupança estimada. Alterações externas exigem `[AUTORIZAR_ACOES_CORRETIVAS_OPERACIONAIS]`.

## Critérios de sucesso

- Custos sem owner/tag e dados incompletos ficam visíveis.
- Alertas usam thresholds absolutos e relativos proporcionais.
- Otimização não reduz SLO, segurança, backup, observabilidade ou capacidade sem decisão aprovada.
- Estimativas distinguem poupança potencial de poupança observada.

## Entrega

Apresenta custo/budget/previsão, anomalias, drivers, confiança, recursos sem owner, recomendações priorizadas, ações autorizadas e métricas para confirmar poupança.

## Referências

- https://learn.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices
- https://learn.microsoft.com/cloud-computing/finops/

