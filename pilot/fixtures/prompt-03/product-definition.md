# Definição de produto — EVAL-15

| Campo | Valor |
|---|---|
| Versão | eval-15-v1 |
| Estado | em preparação |
| Decisão do prompt 01 | avançar |
| Prompt 01 | concluído |
| Prompt 02 | concluído |
| Prompt 03 | em curso |
| Gate A | PENDENTE |
| Owner | Fixture Product Owner |

## Oportunidade selecionada

Pequenas empresas de manutenção coordenam visitas através de chamadas,
mensagens e folhas dispersas. O coordenador não consegue confirmar rapidamente
quem executa cada trabalho; o técnico recebe alterações tardias e o cliente não
sabe se a visita continua prevista.

## Job to be done

Quando um pedido de manutenção é aceite, a equipa quer planear, executar e
comprovar a visita num único fluxo, para reduzir falhas de coordenação sem
expor dados de outros clientes ou exigir formação longa.

## Proposta de valor

Uma experiência simples de coordenação entre escritório, terreno e cliente,
centrada no estado verificável da visita e na recuperação quando a rede falha.

## MVP preliminar aprovado

- criar um trabalho com cliente, local, descrição, janela e responsável;
- atribuir ou reatribuir a um técnico e conservar o histórico;
- técnico consultar apenas trabalhos atribuídos e respetivas alterações;
- técnico registar chegada, checklist, nota e conclusão;
- anexar até 3 fotografias apenas quando o cliente autorizou a evidência;
- funcionar com leitura e registo local durante uma interrupção de rede, com
  estado de sincronização visível e resolução de conflito ainda por decidir;
- cliente consultar data/janela e estado da sua visita sem ver notas internas,
  moradas de terceiros ou identidade de outros clientes;
- coordenador consultar atrasos e trabalhos que exigem intervenção.

## Exclusões aprovadas

- pagamentos, faturação, chat geral, otimização de rotas, tracking contínuo,
  marketplace, gravação de áudio e serviço de emergência;
- nenhuma paridade automática entre Web/PWA, SSR, mobile e API;
- nenhum módulo do boilerplate é aprovado por esta definição.

## Decisões e lacunas

| ID | Estado | Descrição | Owner |
|---|---|---|---|
| DEC-001 | aprovado | Produto, público e owner acima | Fixture Product Owner |
| DEC-002 | aprovado | Mercados e idiomas acima | Fixture Product Owner |
| DEC-003 | aprovado | Exclusões e limites acima | Fixture Product Owner |
| DEC-004 | aprovado | Retenção das fotografias: 30 dias após conclusão; eliminação antecipada a pedido validado do cliente | Fixture Product Owner |
| QST-001 | pendente | Regra de precedência quando coordenador e técnico alteram o mesmo trabalho offline | Fixture Product Owner |
| QST-002 | pendente | Método autorizado para acesso do cliente à experiência pública | Security/Product |
| QST-003 | pendente | Limiares mensuráveis de performance e sincronização | Product/Engineering |

As lacunas não podem ser preenchidas por comportamento de concorrentes,
boilerplate, tema premium ou preferência do executor.
