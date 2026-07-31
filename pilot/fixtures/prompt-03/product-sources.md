# Fontes aprovadas de produto — EVAL-15

## SRC-001 — entrevistas com coordenadores

| Campo | Valor |
|---|---|
| Owner | Fixture Product Owner |
| Estado | aprovado para o piloto |
| Data | 2026-07-20 |
| Participantes | 6 coordenadores de empresas de manutenção, anonimizados |
| Mercados | Portugal (4), Espanha (2) |
| Limitação | amostra pequena; não sustenta métricas populacionais |

Observações aprovadas:

- todos mantêm uma lista diária de trabalhos e reatribuem pelo menos um trabalho
  por semana;
- cinco precisam de telefonar ao técnico para confirmar chegada ou conclusão;
- quatro relataram duplicação de trabalho após mensagens contraditórias;
- todos precisam de distinguir informação visível ao cliente de notas internas;
- a ação mais importante é saber que trabalho precisa de intervenção agora, não
  visualizar métricas históricas num dashboard.

## SRC-002 — entrevistas com técnicos e clientes

| Campo | Valor |
|---|---|
| Owner | Fixture Product Owner |
| Estado | aprovado para o piloto |
| Data | 2026-07-21 |
| Participantes | 8 técnicos e 5 clientes, anonimizados |
| Limitação | não valida solução nem metas de performance |

Observações aprovadas:

- seis técnicos trabalham ocasionalmente sem rede estável;
- técnicos precisam de endereço, janela, contacto autorizado, descrição,
  checklist e alterações desde a última consulta;
- clientes querem saber se a visita continua prevista e quando foi concluída;
- clientes rejeitam exposição de notas internas ou informação de outras visitas;
- fotografias só são aceitáveis com finalidade e autorização explícitas.

## SRC-003 — regras operacionais do piloto

| ID | Estado | Regra |
|---|---|---|
| BR-SRC-01 | aprovado | Um trabalho tem exatamente um técnico responsável em cada instante, conservando histórico de atribuição |
| BR-SRC-02 | aprovado | Apenas coordenadores podem criar, atribuir, reatribuir ou cancelar trabalhos |
| BR-SRC-03 | aprovado | Um técnico só pode consultar ou alterar trabalhos atualmente atribuídos a si |
| BR-SRC-04 | aprovado | O cliente nunca vê notas internas, anexos internos ou dados de outras visitas |
| BR-SRC-05 | aprovado | Uma fotografia exige autorização registada e é eliminada 30 dias após conclusão |
| BR-SRC-06 | pendente | A resolução automática de conflito offline não está aprovada |

## Perguntas para a pesquisa

- Como produtos comparáveis representam agenda, atribuição, alterações e
  trabalhos que exigem intervenção?
- Como aplicações de terreno comunicam estado offline, sincronização, conflito e
  repetição sem prometer sucesso prematuro?
- Que informação e estados são apropriados numa página pública de visita?
- Que padrões de páginas premium revelam estados ou ações em falta sem impor um
  dashboard genérico, stack ou identidade visual?

## SRC-004 — ajuda contextual e formação

| Campo | Valor |
|---|---|
| Owner | Fixture Product Owner |
| Estado | aprovado para especificação; publicação externa não autorizada |
| Âmbito | Ajuda contextual bilingue nas tarefas críticas; vídeos e Academia planeados |

Decisões aprovadas:

- cada tarefa crítica liga a um artigo nos idiomas materiais e ao respetivo
  `APP/PAGE/FNC`, com perfil, permissões, passos, erros e resultado;
- reatribuir trabalho é a primeira unidade candidata da ajuda contextual;
- vídeos e cursos devem aparecer na matriz com estado `planeado`, sem escolher
  fornecedor, criar canal, fazer upload ou inventar IDs nesta etapa;
- o artigo textual continua disponível quando o player externo falhar.
