# Implementar uma funcionalidade específica de ponta a ponta

## Objetivo

Implementa `[FUNCIONALIDADE]` para `[ATORES]` com estes critérios: `[CRITÉRIOS_DE_ACEITAÇÃO]`. Entrega o menor corte vertical completo e testável, preservando arquitetura e comportamento não relacionado.

## Entradas e âmbito

Recebe uma única funcionalidade, IDs de requisitos/aceitação, atores/permissões, dependências concluídas e `[FORA_DO_AMBITO]`. Se `[FUNCIONALIDADE]` representar várias capacidades, divide-a e implementa apenas a primeira fatia explicitamente escolhida. Não corrijas funcionalidades adjacentes sem as registar e obter novo âmbito.

## Descoberta

0. Executa o Definition of Ready da slice: cada ID selecionado tem fonte,
   aprovação, comportamento/estados, `RF-P`, `AC`, dados, permissões,
   dependências e prova. Atualiza primeiro a especificação canónica e reconcilia
   checklist/`ALL_FUNCTIONALITIES.md`. Se exigir decisão de produto, bloqueia
   antes de código; `approved_for_refinement` não autoriza implementação.
   Aplica `REQUIREMENTS_ENGINEERING_CONTRACT.md`: exige tabelas de
   decisão/transição, exemplos/fronteiras e oráculos para as regras materiais.
   Lê `TEST_STRATEGY_CONTRACT.md` e atualiza `quality/TEST_MATRIX.md`.
1. Lê instruções e encontra funcionalidades análogas no projeto.
2. Quando existir experiência visível, aplica o `PRODUCT_EXCELLENCE.md` e compara a jornada completa com produtos profissionais relevantes; não limites a referência ao screenshot do estado ideal.
   Quando existir unidade de ajuda associada, lê `HELP_AND_ACADEMY.md` e inclui
   no lote apenas os `HLP/VID/CRS` aprovados para esta `FNC`.
3. Mapeia UI, contratos, API, domínio, persistência, autorização, jobs/integrações e testes.
4. Regista invariantes, ownership, estados, concorrência, repetição, erros e requisitos de auditoria.
5. Expõe perguntas que mudariam contrato, dados, cobrança, privacidade ou permissões. Usa pressupostos apenas quando reversíveis.
6. Confirma que cada ficheiro planeado contribui diretamente para os IDs selecionados.

## Implementação

- Respeita os limites de `Client.Ssr`, `Client.Web`/`Client.Core`, `Client.Maui` e `Server.Api`.
- Segue os padrões Bit/.NET já usados; não introduzas abstrações ou packages por antecipação.
- Mantém DTOs explícitos, validação server-side e ProblemDetails.
- Aplica autorização a cada operação/objeto e rate limiting a fluxos abusáveis.
- Usa migration e transação quando necessárias; torna callbacks/jobs/comandos idempotentes.
- Trata loading, vazio, erro, offline/retry e double-submit.
- Mantém secrets fora do código e não chama serviços reais nos testes.
- Não declares a unidade de ajuda concluída sem paridade entre idiomas, associação
  contextual, permissões, versão, owner, fallback e prova da tarefa completa;
  gravação/publicação final fica para conteúdo estável e autorização própria.

## Validação

Cria testes para invariantes, arquitetura, contrato e integração; usa o provider real descartável quando a semântica depender dele e browser/E2E para o fluxo crítico quando a infraestrutura existir. Inclui casos anónimo, sem permissão, dados inválidos/limite, repetição, falha externa e concorrência relevantes. Executa restore/build/test do `*.Web.slnf`, revê migration e executa diff de compatibilidade OpenAPI/eventos quando aplicável. Mantém a matriz por requisito/risco e não duplica cobertura sem valor.

## Conclusão

A funcionalidade só está concluída quando cada ID selecionado tem evidência, os estados de erro são úteis, a autorização está testada e não existem falhas conhecidas escondidas. Entrega âmbito/exclusões, benchmark e padrões adotados quando aplicável, ficheiros, decisões, comandos/resultados, configuração sem valores secretos, requisitos adjacentes não executados e riscos residuais.

## Referências

- https://learn.microsoft.com/aspnet/core/fundamentals/error-handling-api?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/performance/rate-limit?view=aspnetcore-10.0
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/
