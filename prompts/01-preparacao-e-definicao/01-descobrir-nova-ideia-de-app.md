# Descobrir e validar uma oportunidade de aplicação

## Objetivo

Como primeiro passo de produto, identifica oportunidades de aplicações web/mobile com procura comprovável, problema claro e potencial de negócio compatível com o `BoilerPlateAdvance` localizado em `C:\Work\BoilerPlateAdvance`. Produz uma recomendação fundamentada; não implementes código.

Este prompt inicia, mas não aprova, `PRODUCT_DEFINITION.md`. Mesmo quando a recomendação for `avançar`, o Gate A permanece `PENDENTE` até o prompt 04 validar toda a definição.

## Entradas obrigatórias

Recolhe mercado/geografia `[MERCADO]`, público `[PÚBLICO]`, competências `[COMPETÊNCIAS]`, orçamento `[ORÇAMENTO]`, prazo `[PRAZO]`, modelo de receita preferido `[MODELO]` e restrições `[RESTRIÇÕES]`. Se faltarem mercado, orçamento, prazo ou público, podes explorar hipóteses conservadoras, mas não escolher uma recomendação final: apresenta as perguntas mínimas que mudam a decisão.

## Método

1. Analisa 8–12 espaços de problema, não apenas ideias de produto.
2. Pesquisa fontes atuais e regista data, região e link:
   - tendências de pesquisa e sazonalidade;
   - concorrentes web e lojas de aplicações;
   - reviews negativas e necessidades recorrentes;
   - maturidade da experiência dos concorrentes e padrões usados por produtos profissionais comparáveis;
   - dimensão/proxy de procura e disposição para pagar;
   - dificuldade de aquisição, regulação, privacidade e dependências externas.
   Para afirmações materiais, prefere dados primários/oficiais; usa reviews e fóruns como sinais qualitativos, não como estimativas de mercado. Confirma sinais importantes em pelo menos duas fontes independentes quando possível.
3. Não trates Google Trends como inquérito nem volume absoluto: os dados são amostrados e normalizados.
4. Elimina ideias que dependam de scraping proibido, direitos não obtidos, aconselhamento regulado sem controlo profissional ou efeitos de rede irrealistas.
5. Pontua as 5 melhores de 1–5 em: intensidade do problema, frequência, procura, diferenciação, monetização, distribuição, risco, complexidade e adequação técnica.
6. Para as 3 finalistas, aplica o `PRODUCT_EXCELLENCE.md` e cria um benchmark inicial de produtos amplamente utilizados, design systems e referências premium relevantes. Extrai padrões de jornada e qualidade, mas não confundas acabamento visual com prova de procura.
7. Para as 3 finalistas, define:
   - segmento e “job to be done”;
   - alternativa atual e vantagem defensável;
   - MVP de 4–8 semanas, excluindo explicitamente o que fica fora;
   - hipótese de preço e canal de aquisição;
   - experimento barato de validação e métrica de decisão;
   - ajuste ao boilerplate: SSR/SEO público, área autenticada WASM/PWA, API, jobs, notificações e MAUI apenas se necessários.

## Critérios de decisão

Recomenda uma ideia só se houver evidência de problema, acesso plausível ao público, viabilidade dentro do orçamento/prazo e um teste falsificável. Usa `não avançar` quando existir impedimento material de legalidade, distribuição ou custo; usa `não avançar ainda` quando a evidência for insuficiente. Separa factos, inferências e pressupostos e não substituas dados em falta por confiança retórica.

## Entrega

Apresenta âmbito e data da pesquisa, resumo executivo, tabela comparativa, top 3, benchmark inicial de produto/experiência, recomendação final ou decisão de não avançar, MVP, riscos, experimento de validação e fontes. Não prometas “grande aceitação”; atribui um nível de confiança por dimensão e explica-o.

Atualiza apenas as secções 1–3, 5, 7 e 8 aplicáveis de `PRODUCT_DEFINITION.md`, mantendo o documento como `rascunho` ou `em validação` e a decisão do Gate A como `PENDENTE`. Atualiza também o prompt 01 em `IMPLEMENTATION_STATUS.md`. Se não existir uma oportunidade recomendada como `avançar`, regista o bloqueio e não autorizes o prompt 02.

## Referências oficiais

- https://support.google.com/trends/answer/4359550
- https://support.google.com/trends/answer/4365533
- https://developer.apple.com/app-store/review/guidelines/
- https://play.google.com/about/developer-content-policy/
