# Contrato visual por vertical slice

Este contrato transforma uma intenção visual em decisões verificáveis. Aplica-se
à primeira slice e a qualquer alteração material de layout, jornada ou sistema
de componentes. Complementa `PRODUCT_EXCELLENCE.md` e
`PRODUCT_QUALITY_BASELINE.md`.

## Artefacto da slice

Cria ou atualiza `design/slices/<SLICE-ID>-VISUAL_BRIEF.md`. O brief liga a
decisão a requisitos reais e contém:

| Secção | Conteúdo mínimo |
|---|---|
| Tese da tarefa | Quem, trabalho a concluir, contexto e resultado observável |
| Tese visual | Hierarquia, densidade, tom e sinais de confiança próprios do domínio |
| Tese de interação | Ação principal, sequência, feedback, prevenção e recuperação |
| Tipo de superfície | Pública/marketing, operacional autenticada ou nativa; diferenças intencionais |
| Conteúdo real | Texto/dados aprovados ou placeholders explícitos; nunca claims inventados |
| Referências | Comparáveis, design system e referências premium, com data, licença e insight adaptável |
| Anti-direções | Padrões rejeitados e motivo ligado a requisito/risco |
| Responsividade | Comportamento dos componentes por viewport, não apenas screenshots reduzidos |
| Estados | Normal, loading, vazio, erro, sucesso, sem permissão, offline e conteúdo limite aplicáveis |
| Acessibilidade | Semântica, foco, teclado/toque, contraste, zoom e movimento reduzido |
| Performance | Budget ou não-regressão mensurável para a superfície |
| Evidência | Protótipos, decisão humana, renders, diffs, testes e métricas |

## Processo em duas passagens

1. **Explorar:** produz duas ou três alternativas de baixa fidelidade para a
   mesma tarefa. Varia hierarquia, composição ou modelo de interação; não cria
   várias implementações polidas nem duplica código de produção.
2. **Comparar:** avalia cada alternativa com a mesma rubrica: clareza da tarefa,
   adequação ao domínio, eficiência, recuperação, responsividade,
   acessibilidade, performance, complexidade e risco.
3. **Decidir:** um owner/revisor identificado seleciona uma direção ou pede
   iteração. Regista alternativas rejeitadas, trade-offs, data e evidência.
4. **Implementar:** implementa apenas a direção escolhida na menor slice real
   com backend, dados, permissões e erros exercitáveis.
5. **Inspecionar:** renderiza com browser/emulador real, compara o resultado com
   o brief e corrige problemas observados antes de propagar o padrão.

Sem decisão registada, a exploração pode terminar `parcial`, mas não autoriza
propagação nem atualização de baselines.

## Matriz responsiva e de estados

| Componente/tarefa | Mobile estreito | Tablet | Desktop | Conteúdo longo/zoom | Teclado/toque |
|---|---|---|---|---|---|

| Estado | Trigger real | Conteúdo e ação | Foco/anúncio | Recuperação | Snapshot estável? |
|---|---|---|---|---|---|

## Validação mínima

- browser/emulador inspecionado em mobile e desktop ou plataforma nativa alvo;
- jornada real com dados normais e pelo menos os estados de maior risco;
- checks automáticos de acessibilidade e verificação manual proporcional;
- consola, rede, clipping, overflow, layout shift, foco e deep links revistos;
- snapshots apenas de estados estáveis, em ambiente determinístico;
- baseline alterada apenas com diff, requisito, revisor e autorização explícita;
- comparação antes/depois ligada a métricas da tarefa e budget de performance;
- crítica humana da primeira slice e teste de usabilidade ou exceção aprovada.

Uma galeria bonita, um mock estático ou um smoke test da ferramenta não prova
qualidade da aplicação.
