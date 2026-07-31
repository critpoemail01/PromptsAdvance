# Auditar e melhorar a fidelização dos utilizadores existentes

## Objetivo

Usa dados e feedback existentes para priorizar e implementar até duas melhorias de fidelização para `[SEGMENTO]`. Este prompt assume que a instrumentação básica já existe; se não existir, recomenda primeiro o prompt de fundação de retenção e não inventes métricas.

## Gate

Exige owner, baseline, custo/recompensa máximo, população elegível e guardrails aprovados. Sem estes elementos, entrega ranking e desenho do experimento, mas não ativa benefícios, referrals, campanhas ou rollout real.

## Diagnóstico

1. Analisa coortes por data/canal/plano/plataforma e janelas adequadas ao ciclo do produto.
2. Mapeia os motivos para regressar e para abandonar: feedback, suporte, cancelamentos, falhas, tempo até valor e utilização de funcionalidades.
3. Segmenta utilizadores novos, ativos, em risco, inativos e pagos sem criar perfis sensíveis.
4. Avalia oportunidades em:
   - continuidade do trabalho, histórico, favoritos e sincronização;
   - personalização explícita e preferências;
   - suporte, recuperação e transparência de estado;
   - conteúdo/valor recorrente;
   - benefícios de lealdade ou referral, apenas se economicamente e legalmente válidos.
5. Pontua impacto esperado, evidência, esforço, risco, reversibilidade e capacidade de medir.
6. Aplica o `PRODUCT_EXCELLENCE.md` às oportunidades mais fortes. Estuda continuidade, preferências, suporte e lealdade em produtos maduros comparáveis; não assumes que streaks, pontos ou padrões de uma app popular são adequados a este produto.

## Implementação

Escolhe no máximo duas melhorias com hipótese, baseline, métrica primária e guardrails. Implementa por feature flag, rollout gradual e rollback. Mantém:

- autorização e privacidade por defeito;
- experiência útil mesmo sem notificações;
- opt-out e cancelamento simples;
- regras/recompensas transparentes e idempotentes;
- acessibilidade e igualdade entre segmentos;
- limites de frequência e ausência de urgência falsa.

Não uses pontos/streaks por padrão, não penalizes pausas e não escondas preços/cancelamento. Não envies campanhas reais durante testes.

## Validação

Testa segmentação, elegibilidade, duplicação, expiração, rollback, preferências e falhas. Valida métricas sem eventos duplicados e monitora guardrails. Executa build/test do `*.Web.slnf`; usa MAUI apenas se alterado.

## Entrega

Apresenta owner, qualidade dos dados, diagnóstico de coortes, benchmark de experiência, ranking, hipóteses escolhidas, implementação ou desenho apenas, custo/guardrails, plano de experiência/rollout, testes, decisão de manter/parar e riscos éticos/financeiros.

## Referências oficiais

- https://firebase.google.com/docs/ab-testing/ab-concepts
- https://firebase.google.com/docs/remote-config/rollouts
- https://www.edpb.europa.eu/documents/guideline/guidelines-032022-on-deceptive-design-patterns-in-social-media-platform_en
- https://developer.apple.com/design/human-interface-guidelines/notifications
