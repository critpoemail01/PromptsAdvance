# Implementar os requisitos de uma página ou ecrã

## Objetivo

Implementa os requisitos `[IDS_OU_DESCRIÇÃO]` na rota/ecrã `[ROTA]`, incluindo estados, autorização, API e testes necessários. Mantém o âmbito nesta jornada e nos componentes/contratos indispensáveis.

## Limite

Recebe IDs estáveis e `[FORA_DO_AMBITO]`. Se o pedido abranger várias rotas ou jornadas independentes, divide-o e executa apenas a rota indicada. Regista inconsistências adjacentes sem as corrigir automaticamente.

## Preparação

1. Confirma a superfície: `Client.Ssr`, `Client.Web`/`Client.Core` ou `Client.Maui`.
2. Reproduz o estado atual e identifica layout, componentes, serviços, endpoint, modelo, policy e testes relacionados.
3. Aplica o `PRODUCT_EXCELLENCE.md` ao padrão principal da página. Compara jornadas equivalentes de produtos profissionais e referências premium, adaptando apenas o que melhorar os critérios desta rota.
4. Converte o pedido em critérios observáveis:

| Cenário | Pré-condição | Ação | Resultado UI | Resultado servidor/dados |
|---|---|---|---|---|

Inclui loading, vazio, erro, sem permissão, conteúdo longo e repetição.

## Implementação

- Reutiliza componentes Bit, tokens e padrões existentes.
- Mantém conteúdo público essencial no HTML de `Client.Ssr`; não introduzas dependência de JavaScript sem necessidade.
- Faz validação útil no cliente e autoritativa no servidor.
- Garante autorização por recurso e evita confiar em IDs/roles do browser.
- Usa operações assíncronas canceláveis, feedback claro e prevenção de double-submit.
- Preserva query string, deep links, back/forward, localização e acessibilidade.
- Não alteres outras páginas apenas para “uniformizar” sem relação com o requisito.

## Testes

Acrescenta testes no nível mais baixo que prove o comportamento e integração/browser apenas para o que atravessa camadas. Testa anónimo, autorizado e sem permissão quando aplicável; teclado, mobile/tablet/desktop; erros de API e dados limite. Usa dados isolados e secrets de ambiente, nunca credenciais no código.

Executa testes direcionados, build do `*.Web.slnf` e suite relevante. Se Playwright não existir, não o instales automaticamente para um único caso; usa testes existentes e browser local, registando a lacuna.

## Entrega

Apresenta IDs e exclusões, referências e padrões adotados, critérios cumpridos com evidência, ficheiros, decisões, comandos/resultados, screenshots úteis, licenças, itens adjacentes não executados e limitações.

## Referências

- https://www.w3.org/TR/WCAG22/
- https://playwright.dev/docs/best-practices
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/
