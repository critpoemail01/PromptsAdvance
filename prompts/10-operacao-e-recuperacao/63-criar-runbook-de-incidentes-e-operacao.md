# Criar o runbook de incidentes e operação

## Objetivo

Cria runbooks acionáveis para `[SERVICOS_E_JORNADAS_CRITICAS]`, ligando alertas a diagnóstico, contenção, recuperação, comunicação e aprendizagem. Não inclui credenciais nem comandos destrutivos sem gates explícitos.

## Critérios de sucesso

- Severidades, funções, contactos funcionais e canais estão definidos.
- Cada alerta crítico aponta para ação inicial e evidência necessária.
- Runbooks cobrem indisponibilidade, erros, segurança, dados, jobs, fornecedores e release defeituosa.
- Há critérios objetivos para escalar, conter, rollback e encerrar.
- Postmortem e exercícios têm cadência e responsáveis.

## Processo

1. Lê arquitetura, observabilidade, SLOs, alerts, CI/CD, backup/DR e threat model.
2. Cria catálogo `sintoma → impacto → owner → dashboard/query → diagnóstico → mitigação → recuperação`.
3. Define incident commander, operações, comunicação e scribe; adapta à dimensão da equipa.
4. Se contactos/owners não existirem, usa placeholders bloqueantes sem inventar pessoas.

## Conteúdo mínimo

- declaração e classificação;
- segurança da cena e preservação de evidência;
- triagem e timelines;
- contenção reversível;
- rollback/roll-forward e restauro;
- comunicação interna/externa aprovada;
- verificação de recuperação e monitorização reforçada;
- handoff, encerramento, RCA e postmortem sem culpa;
- acompanhamento de ações com owner/prazo.

Comandos que eliminem, restaurem, façam failover, rodem credenciais ou alterem tráfego devem aparecer como passos parametrizados com pré-condições, confirmação do alvo, autoridade necessária e verificação posterior; não os executes ao criar ou validar o runbook.

## Validação

Executa tabletop exercise de um incidente provável em ambiente não produtivo. Verifica links, queries, permissões e comandos não destrutivos. Mede tempo até deteção, triagem e decisão; corrige lacunas. Não contacta utilizadores/autoridades nem executa resposta real sem autorização.

## Entrega

Apresenta catálogo de runbooks, severidades/roles, gates das ações de alto impacto, exercício e resultados, lacunas de observabilidade/acesso, ações e calendário de revisão.

## Referências oficiais

- https://learn.microsoft.com/azure/well-architected/operational-excellence/incident-response
- https://learn.microsoft.com/security/operations/incident-response-overview
- https://sre.google/sre-book/managing-incidents/
