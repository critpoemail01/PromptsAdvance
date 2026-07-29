# Implementar faturação, pagamentos e integração contabilística

## Objetivo

Desenha ou implementa um fluxo aprovado em `[REQUISITOS_DE_FATURAÇÃO]` com um único `[PROVIDER]`, um `[MERCADO_PRIMARIO]` e eventual SAP Business One `[SIM/NÃO]`. `[MODO]` é `desenhar` ou `implementar`; usa `desenhar` quando decisões financeiras/fiscais ainda não estiverem aprovadas. Trata pagamentos e documentos fiscais como sistemas distintos, ligados por estados auditáveis.

## Decisões obrigatórias

Antes de editar, confirma:

- produto/preço/moeda/impostos e B2B/B2C;
- compra única, subscrição, trial, upgrade/downgrade, cancelamento e reembolso;
- merchant of record, provider de pagamento e emissor legal da fatura;
- canais web e MAUI e regras de in-app purchase aplicáveis;
- sistema contabilístico/fiscal e fonte de verdade;
- requisitos portugueses de certificação, séries/ATCUD, QR e comunicação à AT quando aplicáveis.

Se estas decisões não existirem, entrega desenho e, apenas se útil, um spike isolado de sandbox sem o integrar na aplicação. Não inventes regras financeiras. Confirma na execução a documentação atual do provider, do mercado fiscal e das lojas aplicáveis; documentação genérica ou recordada não substitui regras atuais.

## Arquitetura e implementação

1. Modela uma state machine explícita para checkout, pagamento, subscrição, fatura, crédito/reembolso e reconciliação.
2. Preços, permissões e montantes são calculados/validados no servidor.
3. Usa idempotency keys em criação e guarda IDs de eventos processados.
4. Verifica assinatura e corpo bruto dos webhooks, aceita só tipos necessários, responde rapidamente e processa de forma assíncrona/idempotente. Não assumes ordem de entrega.
5. Aplica autorização por conta/objeto, minimiza dados PCI e nunca guarda dados de cartão.
6. Se SAP B1 for necessário:
   - usa Service Layer OData v4 e metadata real;
   - mantém URL, company ID e credenciais em secrets;
   - mapeia documentos/campos explicitamente, com reconciliação, retries limitados e dead-letter;
   - testa apenas company/base sandbox.
7. Para Portugal, implementa apenas após validação por contabilista/fiscalista e documentação AT atual.
8. Mantém audit trail, correlation IDs, métricas e operações compensatórias.
9. Não generalizes a implementação para outros providers ou mercados; regista diferenças como backlog.

## Testes

Usa sandbox/test clocks quando disponíveis. Cobre sucesso, decline, abandono, webhook duplicado/fora de ordem/inválido, timeout, refund, mudança de plano, imposto, falha SAP e reconciliação. Não cobra cartões, emite documentos fiscais ou comunica à AT em produção.

## Entrega

Apresenta modo, provider/mercado, fontes consultadas e data, decisões, state machine, contratos/migrations, segurança/idempotência, sandbox usada, testes/resultados, configuração sem segredos e passos jurídicos/contabilísticos pendentes.

## Referências oficiais

- https://docs.stripe.com/webhooks
- https://docs.stripe.com/api/idempotent_requests
- https://help.sap.com/doc/056f69366b5345a386bb8149f1700c19/10.0/en-US/Service%20Layer%20API%20Reference.html
- https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Negocios/Faturacao/Regras_mecanismos_comunicacao/Paginas/default.aspx
- https://developer.apple.com/app-store/review/guidelines/
