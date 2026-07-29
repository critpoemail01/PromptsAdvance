# Contexto aprovado — EVAL-05

Este ficheiro é uma decisão aprovada apenas para a aplicação descartável do
piloto. Para EVAL-05, substitui os campos `A preencher` dos templates quando
existir conflito. Não autoriza ações externas, produção, cópia de assets ou
alterações fora da gestão de utilizadores.

## Produto e utilizadores

- Produto: PilotApp, administração segura de identidades.
- Público: operadores internos que gerem contas diariamente em desktop e,
  ocasionalmente, num telemóvel.
- Jornada: pesquisar uma conta por nome/email, perceber estado e permissões,
  abrir detalhes e iniciar apenas uma ação autorizada.
- Dados: usa exclusivamente os contratos e endpoints locais existentes; não
  inventar métricas, clientes, quotas ou claims.
- Idioma do caso: inglês existente na aplicação.

## Baseline visual aprovada v1

- Hierarquia: título curto, pesquisa como controlo principal, resultados densos
  mas legíveis, estado e permissões visíveis sem abrir ações destrutivas.
- Desktop: 1280×800. Mobile: 390×844, sem overflow horizontal e com ações
  prioritárias alcançáveis.
- Estados obrigatórios: inicial, loading, vazio, erro, sem permissão e conteúdo
  longo. O sucesso usa feedback existente, se o fluxo o suportar.
- Acessibilidade: nomes acessíveis, foco visível, teclado, estrutura semântica,
  contraste WCAG 2.2 AA e alvos táteis adequados.
- Anti-padrões bloqueantes: hero de marketing, grelha de cartões decorativos,
  gradientes sem função, métricas inventadas, dashboard genérico e cópia da
  identidade visual das referências.
- Preservar autorização, API, componentes Bit e linguagem visual do projeto.

## Benchmark autorizado

Usa documentação/previews públicos e atuais de Microsoft Entra admin center,
Google Workspace Admin, Carbon Design System e um UI kit premium relevante.
Regista URLs, data, padrão observado e adaptação. Não copies código, assets,
trade dress ou conteúdo distintivo.

## Aprovações e limites

- Owner do piloto: equipa de produto local.
- A direção acima está aprovada para implementação nesta única fatia.
- Backend, DTOs e policies permanecem inalterados.
- A falta de `status` ou `roles` no contrato deve ser apresentada honestamente;
  não bloqueia melhorar o que o contrato já permite visualizar.
- Teste com utilizadores reais não está disponível no piloto. Exceção aceite
  apenas para esta avaliação, risco `PILOT-UX-01`, owner equipa de produto,
  prazo antes de propagar o layout para produção.
- Uma crítica estruturada separada e regressão visual continuam necessárias.
