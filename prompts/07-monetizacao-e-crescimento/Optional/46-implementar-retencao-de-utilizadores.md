# Implementar uma fundação ética de retenção e experimentação

## Objetivo

Melhora ativação e retenção para `[PRODUTO/PÚBLICO]` através de instrumentação, onboarding e um primeiro experimento controlado. Não implementes indiscriminadamente gamificação, notificações, streaks e recompensas sem hipótese e evidência.

## Gate de evidência

Exige `[OWNER_DO_EXPERIMENTO]`, uma hipótese falsificável, baseline confiável, evento de exposição, população elegível e guardrails mensuráveis. Se a instrumentação não for íntegra ou a amostra/duração não permitirem decisão útil, corrige apenas a medição autorizada e não inicia o experimento.

## Descoberta

1. Define valor recorrente, evento de ativação, hábito legítimo e métricas atuais.
2. Mapeia o funil `aquisição → ativação → valor repetido → retenção`, por coorte.
3. Audita eventos, consentimento, notificações, jobs, configuração remota/feature flags e mecanismos existentes no boilerplate.
4. Identifica o maior ponto de abandono com evidência; distingue correlação de causa.
5. Verifica duplicação, perdas, mudanças de schema, consentimento e cobertura dos eventos antes de calcular a baseline.
6. Aplica o `PRODUCT_EXCELLENCE.md` ao ponto de abandono: compara onboarding e retorno em produtos profissionais com valor recorrente semelhante, mas transforma o padrão numa hipótese testável e rejeita pressão, dependência ou cópia superficial.

## Plano de medição

Cria uma taxonomia versionada com evento, trigger, propriedades mínimas, finalidade, base legal/consentimento, owner e testes. Não recolhas conteúdo sensível, texto livre ou identificadores desnecessários. Define:

- métrica primária e janela;
- guardrails: churn, crashes, cancelamentos, denúncias, acessibilidade e receita;
- baseline, segmento, tamanho/duração aproximados e critério de parar;
- exposição e atribuição consistentes.

## Implementação

1. Corrige primeiro o caminho até ao valor: onboarding curto, progressivo, recuperável e com skip quando adequado.
2. Implementa um único experimento de alto impacto por feature flag, com controlo e rollback.
3. Se usar notificações/email:
   - pede permissão em contexto, depois de explicar valor;
   - permite preferências granulares e opt-out simples;
   - respeita horário/frequência e evita conteúdo sensível;
   - deduplica jobs e torna envios idempotentes.
4. Usa capacidades existentes (`AdsPush`, Hangfire, telemetry) apenas se ativas e adequadas; não introduzas Firebase por padrão.
5. Evita dark patterns, urgência falsa, culpa, recompensas aleatórias sem transparência e mecanismos que penalizem pausas.
6. Não ativa o experimento para tráfego real sem owner, janela, critério de pausa e autorização de rollout.

## Validação

Testa atribuição/eventos sem duplicação, consentimento/opt-out, feature flag/rollback, acessibilidade, notificações negadas e falhas de provider. Usa sinks/test devices; não envia campanhas reais. Executa build/test do `*.Web.slnf` e MAUI apenas quando alterado.

## Entrega

Apresenta qualidade da evidência, owner, diagnóstico, benchmark de jornada, hipótese, métrica/guardrails, eventos, experimento implementado ou motivo para não o iniciar, validações, dashboard/query propostos, decisão de rollout e riscos éticos/privacidade.

## Referências oficiais

- https://firebase.google.com/docs/ab-testing
- https://firebase.google.com/docs/ab-testing/ab-concepts
- https://developer.apple.com/design/human-interface-guidelines/notifications
- https://developer.android.com/develop/ui/compose/notifications/notification-permission
- https://www.edpb.europa.eu/documents/guideline/guidelines-032022-on-deceptive-design-patterns-in-social-media-platform_en
