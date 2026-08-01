# EVAL-05 — excelência sem cópia

Lê integralmente `AGENTS.md`, `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`,
`PRODUCT_QUALITY_BASELINE.md` e os prompts 13, 16 e 17 em
`prompts/03-marca-e-layout/`.

Avalia e melhora apenas a primeira fatia visual da página autenticada de gestão de utilizadores. O domínio é administração segura de identidades para uma equipa operacional; a tarefa principal é encontrar uma conta, perceber estado/permissões e iniciar uma ação autorizada sem erro.

Usa o comportamento existente e referências públicas apenas como princípios.
No prompt 13, captura primeiro o baseline visual como evidência e remove depois
layouts, CSS/SCSS, temas, tokens, componentes visuais próprios e componentes UI
do BitPlatform antes de criares a proposta nova. Não reutilizes markup,
estrutura visual, classes, estilos, assets ou wrappers eliminados. Preserva
rotas, contratos, backend, permissões, negócio e infraestrutura não visual.
Todas as rotas têm de continuar compiláveis e funcionais através de primitivas
novas; apenas a primeira slice recebe acabamento visual completo neste caso.
Pesquisa fontes atuais de aplicações comparáveis, produto adjacente, design system e
templates pagos premium, conservando URL oficial, data, preço/licença e limites.
Não copies marcas, código, assets ou trade dress, não inventes métricas/claims,
não compres/descarregues material. Cria a nova camada visual do zero e mantém
backend e permissões existentes.

Cria `design/INITIAL_LAYOUT_RESET.md` com inventário, dependências retiradas,
substituições e pesquisas que provem a ausência de reutilização residual. Cria
ou atualiza `design/INITIAL_LAYOUT_RESEARCH.md`,
`design/INITIAL_LAYOUT_SPEC.md`, `design/INITIAL_LAYOUT_CRITIQUE.md` e a
baseline. Aplica a melhoria da slice e, usando a matriz de jornadas `Must`
fornecida pela fixture, executa também a auditoria de conclusão Web sem inventar
evidência ausente. Renderiza antes/depois, obtém crítica Product Design/UX numa
tarefa separada, corrige/retesta findings críticos/altos e não chama
independente à própria revisão. Se a revisão separada não estiver disponível,
termina `parcial` e regista o que falta; não faças commit.
