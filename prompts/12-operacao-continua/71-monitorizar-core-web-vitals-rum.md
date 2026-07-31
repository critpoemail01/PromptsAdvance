# Monitorizar Core Web Vitals com dados reais

## Objetivo

Implementa e opera monitorização RUM para Core Web Vitals e jornadas Web relevantes através de `[FONTE_RUM]`, complementando testes de laboratório/CI sem recolher dados pessoais desnecessários.

## Critérios de sucesso

- LCP, INP e CLS são recolhidos segundo definições atuais, com versão e atribuição úteis.
- Resultados usam percentis e segmentação com amostras mínimas explícitas.
- Dados de campo são comparados com laboratório sem tratar um como substituto do outro.
- Privacidade, consentimento, retenção, cardinalidade e custo estão controlados.
- Regressões ficam ligadas a release, rota/template, dispositivo e owner quando a evidência permitir.

## Processo

1. Confirma superfícies, mercados, consentimento, ferramenta, sampling, retenção e orçamento.
2. Instrumenta biblioteca/mecanismo oficial compatível; evita duplicar analytics.
3. Regista versão/build, rota normalizada, tipo de navegação, device class e attribution sem URLs/IDs sensíveis.
4. Cria dashboards por percentil 75 e segmentos materialmente representativos.
5. Define alertas/tendências e um workflow de diagnóstico com testes de laboratório reproduzíveis.
6. Valida eventos, consentimento, payload, cardinalidade e ausência de PII em não produção antes de ativar externamente.

## Limites

Ativar um provider, cookie, script ou custo externo exige autorização. Não concluas que uma regressão foi causada por uma release apenas por coincidência temporal. Marca segmentos com baixo volume como `dados insuficientes`.

## Entrega

Apresenta instrumentação, esquema de eventos, privacidade/sampling, dashboards, baseline, segmentos, alertas, custos, resultados de validação e backlog de regressões.

## Referências

- https://web.dev/articles/vitals-tools
- https://web.dev/articles/vitals
- https://www.w3.org/WAI/test-evaluate/

