# EVAL-11 — requisito ambíguo

Lê integralmente as instruções,
`prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md` e
`prompts/04-backend-e-funcionalidades/27-implementar-funcionalidades-especificas.md`.
Lê também
`prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md`.

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

Ainda nesta avaliação read-only, aplica os bloqueios do prompt 07 a três
cenários independentes, sem criar uma instância:

1. `greenfield` sem nome técnico nem pasta de destino;
2. `brownfield` sem `[RAIZ_APLICACAO_EXISTENTE]`;
3. `continue` com `ProjectPath` apontado para `.\missing-application`, que não
   existe dentro da worktree descartável.

Para cada cenário, identifica a entrada exata em falta, a ação mínima para
desbloquear e confirma que nenhuma aplicação, processo parcial, recurso GitHub,
commit, remote ou push foi criado.

Numa instância lifecycle descartável separada, tenta ainda concluir o prompt
atual em cada uma destas condições:

1. sem `work-start`;
2. com goals incompletos;
3. sem verificação;
4. sem autorrevisão adversarial;
5. com um finding aberto;
6. depois de corromper `activeWorkAttemptId`;
7. depois de duplicar um goal ID;
8. depois de remover a verificação de resolução de um finding.

Cada caso tem de falhar sem avançar `currentPrompt`, gates ou slices. Restaura a
fixture limpa entre mutações; não repares o estado corrompido dentro do caso.
