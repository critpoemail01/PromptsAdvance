# Publicar com migrations, smoke tests e rollback

## Objetivo

Prepara ou executa uma publicação controlada para `[AMBIENTE_ALVO]`, usando exatamente a candidata imutável aprovada nos prompts 64 e 65, migrations explícitas, verificações pré/pós-deploy e critérios de rollback ou roll-forward. `[MODO]` é `preparar` ou `executar`; se estiver ausente, usa `preparar`.

## Entradas e autoridade

- Sempre: `[AMBIENTE_ALVO]`, `[BASE_SHA]`, `[CANDIDATE_SHA]`,
  `[ARTIFACT_DIGEST]`, `[ATTESTATION_DIGEST]`, issuer/builder autorizados,
  janela, runbook e responsáveis.
- Para executar: `[MODO]=executar`, decisão `GO` do prompt 64, decisão `[DECISAO_REVISAO_INDEPENDENTE]=GO` do prompt 65 para o mesmo SHA/digest, identificador inequívoco do ambiente e `[AUTORIZAR_RELEASE]` explícito imediatamente antes da primeira ação externa.
- Se qualquer commit, artefacto, attestation, configuração material ou migration mudar depois das aprovações, termina `NO-GO` e regressa aos prompts 64 e 65.
- A autorização para deploy não autoriza automaticamente rollback destrutivo, restauro, limpeza de dados, alteração de DNS ou rotação de segredos.
- No modo `preparar`, podes ler, validar localmente, gerar checklist/scripts e apresentar um go/no-go; não contactes o ambiente nem alteres estado externo.
- Se o ambiente real não corresponder ao identificador autorizado, para sem tentar corrigir o alvo.

## Critérios de sucesso

- Release, artefacto, commit, configuração e migration estão identificados.
- Backup/restauro e compatibilidade de schema são avaliados antes da migration.
- Health e smoke tests comprovam jornadas mínimas após deployment.
- Critérios de abortar, rollback e roll-forward estão definidos antes da execução.
- A entrega produz timeline e evidência auditável.
- No modo `preparar`, todas as ações externas ficam representadas por comandos revistos, mas não executados.
- A verificação pós-release a 30 minutos, 24 horas e 7 dias e os prompts 67–75 ficam agendados com owners.

## Preparação

1. Lê workflow, decisões dos prompts 64/65, manifesto da candidata, runbook, migrations, topologia, health, observabilidade e mudanças desde a release anterior.
2. Classifica alterações de schema, configuração, contratos, jobs, cache e service worker.
3. Define checklist com responsáveis, janela, comunicação, comandos exatos e agenda de 30m/24h/7d.
4. Gera script/idempotent bundle de migration revisto; não usa migration automática no arranque de produção.

## Fase 1 — Preparação e go/no-go

1. Completa a checklist e executa validações locais/não mutáveis disponíveis.
2. Verifica identidade SHA/digest e a attestation assinada para o mesmo subject,
   source SHA, issuer e builder; verifica ainda compatibilidade expand/contract,
   rollback técnico, backup, observabilidade, SLI/SLO/error budget e smoke tests.
3. Produz um go/no-go com bloqueios. No modo `preparar`, termina aqui.

## Fase 2 — Execução autorizada

- Confirma ambiente e artefacto por identificadores, não por nomes ambíguos.
- Volta a verificar a attestation no ambiente/pipeline de promoção antes de
  executar qualquer migration ou deploy.
- Verifica backup recente/restaurável conforme o runbook.
- Coloca alterações incompatíveis em sequência expand/contract quando possível.
- Executa migration e deployment apenas no ambiente autorizado.
- Observa health, erros, latência, filas/jobs e métricas de negócio.
- Executa smoke tests sem efeitos reais: API, SSR, Web, autenticação de teste e jornada crítica segura.
- Inicia a recolha de evidência para os prompts 67–75 e confirma owners/alertas; não inventa resultados futuros.
- Se um gatilho ocorrer, pausa novas alterações e apresenta a evidência. Executa rollback/roll-forward apenas dentro da autoridade concedida; pede autorização específica para ações adicionais de alto impacto.

## Validação e entrega

Confirma versão servida, schema, caches, service worker, jobs e compatibilidade de clientes. Apresenta modo, alvo confirmado, base/candidate SHA e digest aprovados/servidos, autorização, go/no-go, timeline, comandos executados ou apenas preparados, métricas, smoke tests, decisão de rollback/roll-forward e agenda dos prompts 67–75. Não marca a release concluída enquanto gates obrigatórios estiverem pendentes.

## Referências oficiais

- https://learn.microsoft.com/ef/core/managing-schemas/migrations/applying
- https://docs.github.com/actions/deployment/about-deployments/deploying-with-github-actions
- https://learn.microsoft.com/azure/architecture/framework/devops/release-engineering-cd
