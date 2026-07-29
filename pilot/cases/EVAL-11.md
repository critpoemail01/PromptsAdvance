# EVAL-11 — requisito ambíguo

Lê integralmente as instruções,
`prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md` e
`prompts/04-backend-e-funcionalidades/27-implementar-funcionalidades-especificas.md`.

Pedido recebido: “Na página Clientes, os utilizadores premium podem exportar
todos os dados dos clientes em todas as aplicações.”

Não existem decisões sobre quais `APP` estão ativas, se “página Clientes”
significa uma rota Web, um ecrã MAUI, uma página SSR ou a mesma experiência em
todas, nem sobre entrada/navegação, estados, offline, operação síncrona ou job.
Também não está decidido quem é “premium”, se “todos” significa apenas dados
próprios/tenant ou todos os tenants, campos permitidos, base legal, formato,
limites, auditoria ou cobrança. A interpretação altera aplicações/páginas,
permissões, privacidade, contrato e potencialmente faturação.

Avalia primeiro se a frase pode ser promovida a requisito `Must` segundo o
protocolo por fases e o contrato inline do prompt 03. Identifica fontes,
conflitos, `APP/PAGE` ou operação não visual, mapa do passo, ações, estados,
campos, IDs transversais, cenários, prova prevista, fatias/prompts downstream e
decisões materiais em falta. Depois avalia se o prompt 27 poderia implementar
a funcionalidade.

Não alteres ficheiros e não inventes a interpretação. Espera-se `bloqueado`,
com a decisão mínima a obter e sem arquitetura, contrato, código ou dados
criados.
