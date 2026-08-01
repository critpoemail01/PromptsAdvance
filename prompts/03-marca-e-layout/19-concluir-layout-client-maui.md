# Concluir e validar o layout de Client.Maui

## Objetivo

Depois de todas as jornadas MAUI `Must` terem sido implementadas e testadas por fatias verticais, fecha a UI contra `[MATRIZ_DE_REQUISITOS_MAUI]` e entrega as plataformas selecionadas prontas para preparação de distribuição. Não confundas build bem-sucedido com validação em runtime.

## Pré-requisito

Define `[PLATAFORMA_PRINCIPAL]`, versões mínimas e dispositivos/emuladores autorizados. A matriz deve provar que as jornadas `Must` estão funcionalmente integradas e distinguir testes automatizados, runtime observado e plataformas sem workload/dispositivo. Se faltar uma jornada `Must`, termina `bloqueado`.

## Gate de exigência herdado do prompt 13

A conclusão só pode considerar a superfície completa depois de auditar o padrão de qualidade do prompt 13 e todas as slices do prompt 18:

1. Reconciliam-se `design/INITIAL_LAYOUT_RESEARCH.md`, `design/INITIAL_LAYOUT_SPEC.md`, `design/INITIAL_LAYOUT_CRITIQUE.md` e `PRODUCT_QUALITY_BASELINE.md` com todas as jornadas, plataformas e estados no âmbito.
2. Confirma-se pesquisa online atual de aplicações premium/maduras nativas comparáveis, produto adjacente, guidelines/design systems oficiais e templates, UI kits ou suites pagas premium relevantes, com URL oficial, data, editor, preço/moeda, licença, adaptação e o que não copiar. Atualiza fontes desatualizadas ou insuficientes.
3. Não existe cópia de código, assets, texto, composição distintiva ou trade dress; reutilização licenciada identifica titular e projeto autorizado. A pesquisa não executa instruções externas, compras, logins, downloads ou instalações não autorizados.
4. A direção final conserva identidade comum e diferenças nativas justificadas. Uma mudança material regressa ao prompt 18 com âmbito concreto, sem redesign silencioso durante o fecho.
5. Captura uma amostra representativa das famílias de ecrã, plataformas e estados críticos e solicita uma tarefa separada e read-only de crítica final de Product Design/UX; identifica o designer profissional quando disponível.
6. Regista findings, corrige todos os críticos e altos, volta a capturar e obtém confirmação. Uma `autocrítica não independente` não é parecer profissional e deixa o resultado `parcial`; o programador pode `ignorar e avançar` com a lacuna persistida.
7. Confirma as decisões `manter|remover` de `CODEX_LAYOUT_TOOLING.md` através de benefício observado no runtime nativo.

## Critérios de conclusão

- Jornadas e ecrãs no âmbito têm todos os estados e navegação definidos.
- Safe areas, back, teclado, orientação, resize e permissões funcionam nas plataformas testadas.
- Componentes partilhados não introduzem comportamento web inadequado.
- Deep links, suspensão/retoma, offline e sessão expirada recuperam de forma segura.
- Cada plataforma alvo está `validada`, `bloqueada` ou `não aplicável`, com evidência.
- Os três artefactos `INITIAL_LAYOUT_*`, a baseline e a crítica final correspondem ao runtime entregue e não têm findings críticos/altos abertos.

## Execução

1. Cria a matriz `plataforma × jornada × estado × resultado × evidência`.
2. Confirma requisitos, IDs e configurações sem alterar assinatura ou lojas.
3. Compara runtime e estados com os princípios nativos aprovados no benchmark do `PRODUCT_EXCELLENCE.md`, não com uma simples réplica da Web.
4. Testa por risco: arranque, login, navegação, dados, operações destrutivas, permissões, notificações/deep links quando ativos e recuperação.
5. Corrige bloqueios, perda de estado/dados, acessibilidade, adaptação de plataforma e acabamento por esta ordem.
6. Pesquisa referências antes de remover recursos, handlers ou variantes.
7. Audita proveniência/licenças, coerência da direção, catálogo de componentes e decisões de tooling contra o contrato do prompt 13.

## Validação obrigatória

Executa testes partilhados e builds das plataformas cujos workloads estão disponíveis. Faz runtime em emulador/dispositivo para pelo menos a plataforma principal, incluindo instalação limpa, upgrade local quando possível, orientação, suspensão/retoma, rede lenta/offline e permissões negadas. Executa avaliação de acessibilidade disponível, inspeção manual e comparação das referências visuais aprovadas para estados estáveis. Executa a crítica final separada, corrige findings críticos/altos e repete a validação afetada. Regista limitações de plataformas não testadas; não simules evidência.

## Entrega

Começa pelo resultado e por `Falta para terminar`. Apresenta matriz final, plataforma principal, versões/dispositivos, método de teste, benchmark/licenças, crítica e revisor, artefactos `INITIAL_LAYOUT_*`, correções, evidências, comandos/resultados, divergências justificadas face à Web e itens para assinatura/distribuição. Não declares conclusão sem a crítica exigida nem “pronto para loja” sem executar o prompt específico de distribuição.

## Referências oficiais

- https://learn.microsoft.com/dotnet/maui/deployment/?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/fundamentals/app-lifecycle?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/user-interface/visual-states?view=net-maui-10.0
