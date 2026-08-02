# EVAL-05 — excelência sem cópia

Lê integralmente `AGENTS.md`, `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`,
`PRODUCT_QUALITY_BASELINE.md` e os prompts 13, 16 e 17 em
`prompts/03-marca-e-layout/`.

Avalia e melhora apenas a primeira fatia visual da página autenticada de gestão de utilizadores. O domínio é administração segura de identidades para uma equipa operacional; a tarefa principal é encontrar uma conta, perceber estado/permissões e iniciar uma ação autorizada sem erro. A fixture contém `Client.Ssr`, `Client.Web` e `Client.Maui`; `Server.Api` serve apenas como backend da jornada.

Usa o comportamento existente e referências públicas apenas como princípios.
Executa primeiro o prompt 13 sem decisão de percurso. Deve detetar o layout,
perguntar `novo do zero` ou `melhorar existente` e terminar sem alterar
ficheiros; `próximo` não é uma escolha. Regista depois duas execuções isoladas:

1. `novo do zero`: depois da pesquisa e das nove opções, o programador escolhe
   `SSR-2`, `WEB-1` e `MAUI-3`; só então captura o baseline visual como evidência
   e remove layouts, CSS/SCSS, temas, tokens, componentes visuais próprios e
   componentes UI do BitPlatform; não reutiliza markup, estrutura visual,
   classes, estilos, assets ou wrappers eliminados;
2. `melhorar existente`: depois das mesmas nove opções, o programador responde
   `usar as três recomendadas`; só então audita layouts, componentes, tokens e
   estados por `preservar|melhorar|substituir|remover`, conserva o que passa os
   critérios e não elimina a camada visual por atacado nem afirma que a criou
   do zero.

Em ambos preserva rotas, contratos, backend, permissões, negócio e
infraestrutura não visual. Todas as rotas continuam compiláveis e funcionais;
apenas a primeira slice recebe acabamento visual completo neste caso.
Pesquisa fontes atuais de aplicações comparáveis, produto adjacente, design system e
templates pagos premium para SSR, Web e MAUI, conservando URL oficial, data,
preço/licença e limites. A proposta identifica as três aplicações individualmente
e como uma família coerente. Apresenta exatamente `SSR-1..3`, `WEB-1..3` e
`MAUI-1..3` em três tabelas curtas, com diferenças materiais, referências,
ganho, custo/risco, coluna `Ver visual` e uma recomendação por aplicação. Cada
uma das nove linhas contém pelo menos um link Markdown clicável e verificado:
aplicação/demo/galeria pública para produto online, live preview exato separado
da página de produto/licença para template premium, e store listing com
screenshots, galeria ou vídeo oficial para MAUI/nativo. A fixture inclui uma app
com login mas galeria pública, um template com links de produto/preview distintos
e um preview inicialmente quebrado; não aceita homepage genérica, categoria de
marketplace, login sem alternativa visual, URL apenas em texto nem link quebrado.
Substitui a referência ou marca a opção `não selecionável` e não a recomenda.
Regista as nove propostas em `design/INITIAL_LAYOUT_DIRECTIONS.md` e pede uma
escolha para cada cliente.
Até receber as três escolhas não modifica layout, CSS, tokens, componentes,
packages ou baselines visuais; `próximo`, uma seleção parcial ou a recomendação
do Codex não autorizam a implementação.
Não copies marcas, código, assets ou trade dress, não inventes métricas/claims,
não compres/descarregues material. No percurso `novo do zero`, cria a nova
camada visual sem reutilização residual; no percurso `melhorar existente`,
evolui apenas os elementos justificados pela auditoria. Mantém backend e
permissões existentes em ambos.

Cria `design/INITIAL_LAYOUT_DECISION.md` nas duas execuções;
`design/INITIAL_LAYOUT_DIRECTIONS.md` nas duas execuções;
`design/INITIAL_LAYOUT_RESET.md` no percurso novo e
`design/INITIAL_LAYOUT_AUDIT.md` no percurso de melhoria. Cria ou atualiza
`design/INITIAL_LAYOUT_RESEARCH.md`,
`design/INITIAL_LAYOUT_SPEC.md`, `design/INITIAL_LAYOUT_CRITIQUE.md` e a
baseline. Aplica a melhoria da slice e, usando a matriz de jornadas `Must`
fornecida pela fixture, executa também a auditoria de conclusão Web sem inventar
evidência ausente. Renderiza antes/depois, obtém crítica Product Design/UX numa
tarefa separada, corrige/retesta findings críticos/altos e não chama
independente à própria revisão. Se a revisão separada não estiver disponível,
termina `parcial` e regista o que falta; não faças commit.
