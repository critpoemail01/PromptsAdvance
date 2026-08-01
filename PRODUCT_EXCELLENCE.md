# Protocolo de excelência de produto, UX e UI

Este protocolo aplica-se a tarefas que definam ou alterem a ideia do produto, requisitos, marca, conteúdo, layouts, páginas, jornadas, emails, monetização, retenção ou qualquer experiência visível pelo utilizador. Complementa o `EXECUTION_CONTRACT.md` e materializa os critérios aprovados em `PRODUCT_QUALITY_BASELINE.md`; não substitui requisitos, testes, acessibilidade, segurança, privacidade ou validação com utilizadores reais.

## 1. Princípio

O objetivo não é produzir uma interface apenas funcional nem copiar uma aplicação conhecida. O objetivo é compreender porque é que produtos maduros resolvem bem problemas comparáveis e adaptar esses padrões ao público, domínio, identidade e arquitetura desta aplicação.

Benchmark e desk research não validam o problema nem a solução. Antes de G01,
exige evidência direta com utilizadores representativos segundo
`PRODUCT_DEFINITION.md`; antes de propagar a primeira slice, exige o teste de
usabilidade deste protocolo.

Uma aplicação de excelência deve parecer coerente e intencional, não uma colagem de componentes, tendências ou marcas. Cada decisão relevante deve estar ligada a um problema do utilizador, a uma referência observada, a evidência de usabilidade ou a um princípio aprovado.

## 2. Pesquisa obrigatória de referências

Antes de definir uma direção visual ou alterar uma jornada relevante:

1. Confirma o público, o trabalho a realizar, a plataforma, o contexto de uso, o estado atual e os critérios de sucesso.
2. Pesquisa referências atuais e comparáveis. Para uma superfície importante, procura normalmente:
   - duas aplicações profissionais e amplamente utilizadas com uma jornada semelhante;
   - uma aplicação reconhecida de um domínio adjacente que resolva bem o mesmo problema de interação;
   - um design system oficial e maduro adequado à plataforma;
   - um tema, template, UI kit ou catálogo premium de qualidade quando trouxer padrões adicionais relevantes.
3. Escolhe referências pela semelhança da jornada, público, densidade de informação e plataforma — não apenas por popularidade ou aparência.
4. Inspeciona, quando legalmente acessível, mais do que a homepage: navegação, estados, formulários, tabelas/listas, feedback, erros, responsividade, acessibilidade aparente e recuperação.
5. Regista a data e as fontes. Se a pesquisa web, demo ou documentação não estiver acessível, identifica a limitação e não inventes observações.

As quantidades são uma orientação, não um objetivo artificial. Usa menos referências quando a jornada for simples ou o domínio muito específico, justificando a cobertura; usa mais apenas quando alterarem a decisão.

## 3. Matriz de benchmark

Cria uma matriz antes de implementar:

| Referência | Tipo e fonte | Jornada/superfície | Padrão observado | Problema que resolve | Evidência/limite | Adaptação proposta | O que não copiar | Licença |
|---|---|---|---|---|---|---|---|---|

Tipos possíveis: `concorrente direto`, `produto adjacente`, `design system`, `pesquisa UX`, `tema/template premium` ou `baseline atual`.

Não uses “é moderno” ou “parece profissional” como justificação. Descreve padrões observáveis, por exemplo:

- arquitetura de informação, navegação e progressive disclosure;
- hierarquia, densidade, grelha, tipografia, espaçamento, cor e elevação;
- ações primárias, pesquisa, filtros, tabelas, formulários e diálogos;
- loading, vazio, erro, sucesso, offline, sem permissão e sessão expirada;
- prevenção de erros, confirmação, undo, autosave e recuperação;
- onboarding, time-to-value, ajuda contextual e conteúdo;
- responsividade, toque, teclado, safe areas e convenções nativas;
- confiança, privacidade, preços, cancelamento e ausência de dark patterns;
- desempenho percebido, movimento, feedback e estabilidade visual.

## 4. Síntese antes do design

Converte a pesquisa em:

1. cinco a dez princípios de experiência específicos do produto;
2. padrões a preservar do baseline;
3. padrões a adaptar e respetiva razão;
4. anti-padrões e excessos a evitar;
5. critérios mensuráveis para a jornada;
6. uma direção coerente com a identidade aprovada.

Não combines automaticamente “as melhores partes” de todas as referências. Resolve conflitos e escolhe uma direção. A identidade final deve ser reconhecível como a aplicação atual, não como uma imitação de GitHub, Microsoft, Apple, Atlassian, Shopify, Stripe, Linear ou qualquer tema comercial.

Para cada vertical slice visível aplica `VISUAL_SLICE_CONTRACT.md`. Explora
duas ou três alternativas de baixa fidelidade para a mesma tarefa, compara-as
com uma rubrica comum e regista uma decisão humana antes de implementar. Não
constrói várias versões polidas nem propaga uma direção sem brief, trade-offs e
alternativas rejeitadas.

## 5. Baseline profissional obrigatória

Antes do primeiro layout ou da primeira vertical slice visível, cria e aprova `PRODUCT_QUALITY_BASELINE.md`. O documento deve conservar:

- benchmark, fontes, datas e limites de licença;
- princípios de experiência específicos do produto;
- rubrica `pass/fail` com critérios bloqueantes;
- estratégia mobile Web/PWA e nativa quando aplicável;
- plano e resultados de crítica profissional, usabilidade e regressão visual;
- findings, exceções, owners e prazos.
- briefs por slice com tese da tarefa, visual e interação, conteúdo real,
  matriz responsiva/estados, anti-direções e direção selecionada.

A rubrica não pode usar apenas adjetivos como “moderno”, “premium” ou “profissional”. Define resultados observáveis para adequação ao domínio, arquitetura de informação, eficiência da tarefa, estados e recuperação, mobile, acessibilidade, consistência visual, conteúdo/confiança e performance.

Para a primeira vertical slice exige uma crítica estruturada:

| Problema | Evidência | Princípio/critério | Impacto | Alterar/não alterar | Revisor | Resultado |
|---|---|---|---|---|---|---|

Identifica o revisor humano ou a tarefa separada de Product Design/UX e o revisor de engenharia/frontend. O implementador pode fazer uma autorrevisão útil, mas não a apresenta como opinião profissional independente.

## 6. Utilização de design systems e produtos maduros

Design systems oficiais ajudam a compreender componentes, tokens, conteúdo, acessibilidade e comportamento em escala. Seleciona-os conforme a superfície:

- Web e aplicações de dados: Primer, Fluent, Atlassian Design System e sistemas comparáveis;
- administração e comércio: padrões atuais de Shopify e pesquisa de usabilidade aplicável;
- Android: Material Design e convenções atuais da plataforma;
- Apple: Human Interface Guidelines;
- experiências cross-platform: extrai princípios comuns, preservando diferenças nativas.

Estes sistemas são referências, não dependências automáticas. Não introduzas React, Tailwind, outro framework ou uma biblioteca concorrente apenas porque uma referência os utiliza. Implementa os padrões através dos componentes Bit, Blazor, CSS/tokens e MAUI já aprovados no projeto.

## 7. Temas, templates e investigação premium

Catálogos como Tailwind Plus, Metronic e outros produtos premium podem revelar composição, cobertura de componentes, densidade e acabamento profissional. Investigação paga, como benchmarks de UX, pode fornecer evidência mais forte do que preferência visual.

Aplica estas regras:

- Sem licença confirmada, observa apenas previews e documentação pública; não descarregues, transcrevas ou reproduzas código, assets, ilustrações, fontes ou layouts distintivos.
- Com licença, confirma titular, projeto autorizado, número de utilizadores, direitos de modificação/distribuição e localização segura dos ficheiros antes de reutilizar qualquer material.
- Não converts um template premium para outro framework para redistribuição quando a licença o proibir.
- Regista a origem e a licença de cada asset ou componente incorporado.
- A compra ou utilização de um tema não substitui a adaptação ao produto, acessibilidade, performance e validação dos estados reais.

## 8. Implementação orientada a qualidade

- Começa por uma vertical slice real e pequena: UI, contrato, backend/dados, autorização, estados, testes e observabilidade mínimos. Valida a direção antes de a propagar.
- Implementa apenas a alternativa selecionada no brief; protótipos de baixa
  fidelidade servem para decidir, não para multiplicar código de produção.
- Usa tokens semânticos e componentes consistentes, evitando valores e variantes casuais.
- Preserva comportamentos corretos e a arquitetura do projeto.
- Cobre todos os estados da jornada, não apenas o screenshot ideal.
- Prioriza clareza, eficiência, prevenção de erros e recuperação antes de decoração.
- Usa conteúdo real aprovado ou placeholders explícitos; não inventes métricas, clientes, testemunhos ou claims.
- Mantém desempenho, acessibilidade, localização, privacidade e segurança como propriedades do design.
- Justifica qualquer divergência entre SSR, Web/PWA e MAUI pelas necessidades da plataforma.
- Não concluas shells e páginas contra dados falsos antes de existirem contratos, permissões e falhas reais da vertical slice.
- Em SaaS, ferramentas operacionais e áreas autenticadas, evita heroes, cartões decorativos repetidos, gradientes sem função e composição de marketing. Escolhe deliberadamente densidade, grelha, hierarquia e controlos adequados ao tipo de dado e à frequência da tarefa.
- A aplicação autenticada não deve resultar num painel administrativo genérico. A identidade vem do domínio, da linguagem, dos dados, das tarefas e dos estados reais, não de ornamento.
- Web/PWA mobile não é apenas desktop reduzido: reconsidera navegação, ações principais alcançáveis, alvos táteis, conteúdo, densidade, formulários, filtros, tabelas, modais, número de passos e uso com uma mão.
- Cria um catálogo de componentes, variantes e estados quando a dimensão ou repetição do produto o justificar.
- Executa checks automáticos de acessibilidade em cada pull request e avaliação manual nas jornadas críticas desde a primeira slice; a auditoria dedicada complementa esta prática e não a substitui.

## 9. Quality gate visual e de experiência

Antes de concluir:

1. Compara baseline, resultado renderizado e princípios extraídos do benchmark — não pixels de uma referência.
2. Exercita a jornada completa e os estados aplicáveis em mobile, tablet, desktop ou dispositivo nativo.
3. Inspeciona hierarquia, alinhamento, ritmo, densidade, consistência, conteúdo, foco, contraste, toque, movimento e feedback.
4. Verifica consola, rede, erros, latência, layout shift, conteúdo extremo, localização e permissões.
5. Recolhe evidência visual antes/depois para os estados e viewports que sustentam a conclusão.
6. Para componentes e estados estáveis, executa regressão visual automatizada em mobile/desktop, temas suportados e estados aplicáveis como loading, vazio, erro e conteúdo longo.
7. Gera e compara snapshots num ambiente CI reproduzível. Atualiza baselines apenas depois de rever o diff visual, ligar a alteração a um requisito e obter aprovação explícita.
8. Executa checks automáticos de acessibilidade e a verificação manual proporcional à jornada.
9. Executa a revisão adversarial do `EXECUTION_CONTRACT.md` e corrige regressões.

Uma comparação heurística não prova sucesso com utilizadores. Para a principal jornada, jornadas críticas ou decisões de alto risco, executa teste de usabilidade com tarefas, participantes representativos e métricas definidas antes de propagar o layout. Se isso não for possível, termina como `bloqueado` ou regista uma exceção explícita com risco, owner, prazo e aprovação; não declares usabilidade validada.

## 10. Entrega

Inclui:

- referências, data e matriz de benchmark;
- princípios de experiência adotados;
- decisões adaptadas e alternativas rejeitadas;
- confirmação de licenças ou indicação de uso apenas como inspiração pública;
- baseline e evidência renderizada antes/depois;
- critérios observados e métricas quando disponíveis;
- estados, plataformas e viewports validados;
- estado da rubrica em `PRODUCT_QUALITY_BASELINE.md`;
- crítica da primeira vertical slice e respetivos revisores;
- resultados de usabilidade ou exceção aprovada;
- snapshots estáveis, ambiente de comparação e aprovação de alterações de baseline;
- checks automáticos e avaliação manual de acessibilidade;
- lacunas de pesquisa e riscos residuais.

## Referências iniciais

Confirma sempre as versões e orientações atuais na execução:

- https://primer.style/
- https://fluent2.microsoft.design/
- https://atlassian.design/
- https://m3.material.io/
- https://developer.apple.com/design/human-interface-guidelines/
- https://shopify.dev/docs/apps/design
- https://tailwindcss.com/plus
- https://tailwindcss.com/plus/license
- https://keenthemes.com/metronic
- https://baymard.com/research
- https://baymard.com/research/methodology
- https://developers.openai.com/api/docs/guides/frontend-prompt
- https://playwright.dev/docs/test-snapshots
- https://www.w3.org/WAI/test-evaluate/
