# Auditar e corrigir acessibilidade segundo WCAG

## Objetivo

Audita e corrige as superfícies Web ativas contra `[NIVEL_WCAG]` no âmbito realmente testado. Confirma a versão e o nível aprovados no `APP_CONTEXT.md`; não os escolhe silenciosamente. Abrange o site público `Client.Ssr`, a aplicação autenticada `Client.Web` e componentes partilhados em `Client.Core`; avalia `Client.Maui` separadamente segundo as convenções nativas das plataformas.

## Âmbito obrigatório

Define `[JORNADAS_E_ESTADOS_CRITICOS]`, browsers/viewports e tecnologias de apoio disponíveis. Se o âmbito não for fornecido, inventaria e propõe uma amostra baseada em risco, mas não declara conformidade global.

## Critérios de sucesso

- As páginas, componentes e estados críticos possuem uma matriz WCAG com resultado e evidência.
- Jornadas essenciais funcionam por teclado, com foco visível e ordem lógica, sem keyboard traps.
- Estrutura semântica, nomes acessíveis, formulários, erros, contraste, zoom/reflow e conteúdo dinâmico são utilizáveis.
- Falhas críticas e graves encontradas no âmbito são corrigidas ou ficam bloqueadas por uma razão concreta.
- O relatório não confunde ausência de erros automáticos com conformidade WCAG.

## Preparação

1. Lê `AGENTS.md`, design system, tokens, componentes, rotas, testes e requisitos de público-alvo.
2. Inventaria páginas e estados representativos: navegação, autenticação, formulários, tabelas/listas, modais, notificações, loading, vazio, erro, conteúdo longo e fluxos críticos.
3. Define combinações de browser, viewport, teclado e tecnologia de apoio disponíveis.
4. Regista uma matriz:

| Página/componente/estado | Critério WCAG | Método | Resultado | Evidência | Correção |
|---|---|---|---|---|---|

5. Usa WCAG 2.2 como referência estável e identifica o nível pretendido. Requisitos legais específicos devem ser confirmados separadamente.

## Auditoria e correção

1. Semântica:
   - idioma da página, título, landmarks, headings hierárquicos, listas, tabelas e elementos nativos corretos;
   - links e botões distinguíveis pelo propósito;
   - ARIA apenas quando HTML nativo não resolve, sem estados ou relações inválidos.
2. Teclado e foco:
   - acesso a todas as ações;
   - ordem previsível, foco visível, skip link e devolução de foco em diálogos;
   - sem traps, foco perdido após navegação ou alterações dinâmicas.
3. Formulários:
   - labels e instruções associadas;
   - autocomplete/input purpose quando aplicável;
   - erros identificados em texto, ligados ao campo e resumidos sem depender apenas de cor;
   - preservação segura de dados após erro.
4. Perceção visual:
   - contraste de texto, controlos, estados e foco;
   - zoom a 200%, text spacing e reflow próximo de 320 CSS px sem perda de conteúdo/ação;
   - target size, orientação e movimento/reduced motion quando aplicável.
5. Imagens e media:
   - alternativas textuais orientadas ao propósito;
   - imagens decorativas ignoradas;
   - legendas, transcrições e controlos acessíveis quando existir áudio/vídeo.
6. Conteúdo dinâmico:
   - nomes/roles/values corretos;
   - anúncios proporcionais por live regions;
   - loading, progresso, erros e sucesso percetíveis sem criar ruído excessivo.
7. SSR:
   - conteúdo e estrutura essenciais acessíveis no HTML inicial;
   - validação sem JavaScript quando essa experiência é suportada.
8. MAUI:
   - verifica nomes, descrições, ordem semântica, tamanhos, contraste e navegação com leitores nativos;
   - reporta resultados por plataforma; não extrapoles uma auditoria Web para Android/iOS/Windows.

## Validação

Combina ferramentas automáticas existentes com inspeção manual. Se axe, Lighthouse ou Playwright não estiverem instalados, não adiciones uma dependência sem justificar a sua manutenção; usa o browser e testes existentes e propõe a automatização duradoura.

Executa pelo menos:

- navegação completa só com teclado;
- zoom/reflow e diferentes viewports;
- contraste e estados de foco/hover/disabled/error;
- leitor de ecrã disponível numa amostra das jornadas críticas;
- análise automática por página/estado;
- regressão dos componentes corrigidos.

Guarda screenshots, resultados da ferramenta e passos reproduzíveis. Confirma que as correções não quebram responsive design, SSR, tradução ou comportamento funcional.

## Limites

Não alteres identidade visual ou fluxos de negócio além do necessário para acessibilidade sem assinalar o impacto. Não escondas controlos, reduzas informação ou removas funcionalidades apenas para eliminar findings. Não declares certificação legal ou conformidade total sem auditoria independente do âmbito completo.

## Entrega

Apresenta âmbito/amostragem e ambiente, matriz por critério, problemas corrigidos, evidência antes/depois, testes automáticos/manuais, tecnologias de apoio usadas, limitações por plataforma e backlog priorizado. A conclusão deve ser limitada às páginas, estados, critérios e tecnologias efetivamente avaliados.

## Referências oficiais

- https://www.w3.org/WAI/standards-guidelines/wcag/
- https://www.w3.org/WAI/WCAG22/quickref/
- https://www.w3.org/WAI/test-evaluate/
- https://www.w3.org/WAI/ARIA/apg/
- https://learn.microsoft.com/en-us/dotnet/maui/fundamentals/accessibility?view=net-maui-10.0
