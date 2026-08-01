# Contrato de estratégia e matriz de testes

Este contrato define como cada risco obtém uma prova adequada sem concentrar
toda a confiança em testes end-to-end. Aplica-se desde a primeira vertical
slice e é atualizado quando requisitos, arquitetura, providers ou riscos mudam.

## Artefactos obrigatórios

Mantém:

- `quality/TEST_STRATEGY.md` — ambientes, níveis, lanes de CI, dados, políticas
  de determinismo/flakiness, ferramentas e responsabilidades;
- `quality/TEST_MATRIX.md` — uma linha por requisito/risco material, atualizada
  em cada slice.

## Matriz mínima

| Requisito/risco | Invariante/oráculo | Unitário | Componente | Integração/provider real | Contrato/compatibilidade | Browser/nativo | Visual | A11y | Performance/resiliência | Evidência |
|---|---|---|---|---|---|---|---|---|---|---|

Usa `sim`, `não aplicável` com razão ou `bloqueado` com owner/prazo. Não marques
uma célula como coberta apenas porque outro nível executou uma jornada feliz.

## Escolha do nível

- **Unitário/propriedades:** invariantes, cálculos, parsing, transições e lógica
  combinatória. Usa testes property-based ou mutation testing apenas quando a
  ferramenta já existir ou o risco justificar a adoção aprovada; conserva seed,
  mutantes sobreviventes e custo.
- **Componente:** estados e interação de UI/serviço isolados com contratos
  estáveis, incluindo acessibilidade básica.
- **Integração:** serialização, Identity, EF, migrations, filas, storage e
  configuração. Comportamento dependente de SQL/provider usa uma instância
  descartável do provider real; SQLite/InMemory não prova outro provider.
- **Contrato:** OpenAPI/eventos e consumers/providers. Executa diff de
  compatibilidade e testes de consumidor/provedor quando uma interface atravessa
  equipas, processos ou versões.
- **Arquitetura:** automatiza limites entre módulos/camadas quando uma referência
  proibida possa compilar e degradar o desenho.
- **Browser/nativo:** jornadas críticas, integrações reais visíveis,
  autorização, efeitos persistidos, recuperação e regressão interativa.
- **Visual, acessibilidade, performance e resiliência:** gates próprios para
  riscos que testes funcionais não observam.

## Lanes de CI

| Lane | Objetivo | Conteúdo mínimo | Budget/política |
|---|---|---|---|
| Commit | feedback rápido | build, unitários, componentes e checks estáticos afetados | rápida e determinística |
| Pull request | integração e regressão | integração/provider, contrato, arquitetura, browser focado, a11y e diff visual | bloqueia defeitos materiais |
| Nightly | amplitude | cross-browser/dispositivo, dados volumosos, concorrência, mutation/property quando adotados, performance e resiliência segura | findings com owner; sem esconder falhas |
| Release | candidata imutável | suite de risco, migrations, segurança, acessibilidade, performance, recuperação e smoke sobre o mesmo SHA/artefacto | fail-closed |

Não uses uma lane posterior para justificar ausência permanente de feedback
rápido no nível mais baixo adequado.

## Determinismo, dados e diagnóstico

- fixa ou regista clock, timezone, locale, cultura, random seed, browser,
  viewport, fontes, animações, versões e dados;
- cada teste cria recursos próprios e elimina apenas esses recursos;
- efeitos externos usam fake/sandbox autorizado, nunca contas ou produção reais;
- espera por estados observáveis com timeout explícito; não usa sleeps fixos;
- em falha conserva logs, trace, screenshot/diff, request/correlation ID e estado
  suficiente, redigindo segredos e dados pessoais;
- repete falhas de forma controlada para distinguir produto, ambiente e teste.

## Política de flakiness

Um teste flaky continua a ser uma falha. Pode ser colocado numa lane de
diagnóstico apenas com finding, owner, severidade, causa provável, prazo e
cobertura compensatória. São proibidos retries ilimitados, `skip`, sleeps
arbitrários e relaxamento de assertions/thresholds apenas para tornar CI verde.
Depois da correção, executa repetições com a mesma seed e com seeds variadas
quando o risco o justificar.

## Failure modes e robustez

Para cada jornada crítica mantém:

| Falha/modo | Causa | Efeito local | Efeito no utilizador/dados | Deteção | Prevenção/mitigação | Recuperação | Teste | Owner |
|---|---|---|---|---|---|---|---|---|

Prioriza por impacto, probabilidade e detetabilidade. Cobre timeout, resposta
inválida, indisponibilidade, repetição, concorrência, perda parcial, restart,
limites de capacidade e recuperação. Combina carga e fault injection apenas em
ambiente descartável autorizado, com hard stops, SLO/RTO/RPO aprovados e sem
efeitos externos reais.

## Conclusão honesta

Entrega cobertura por requisito/risco, comandos e exit codes, ambientes e
providers usados, mutações/falhas provocadas, artefactos, zonas não testadas,
flakiness e riscos residuais. Nunca uses “sem bugs” ou “cobertura total” fora do
âmbito e dos oráculos demonstrados.
