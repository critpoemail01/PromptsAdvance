# Implementar privacidade operacional e direitos de dados

## Aplicabilidade

Executa quando a aplicação trata contas ou dados pessoais. Usa `[INVENTARIO_DE_DADOS]`, `[MERCADOS]` e decisões revistas por responsável jurídico/DPO; este prompt não substitui aconselhamento jurídico.

## Gate de decisão

Exige `[MATRIZ_APROVADA_DE_DADOS_E_RETENCAO]` com categoria, finalidade, localização, proprietário, prazo, destino no fim de vida, exceções/legal hold e fornecedores. Se estiver incompleta, produz mapa, threat model e workflow proposto, mas não implementa eliminação, anonimização ou exportação que possa omitir ou destruir dados.

## Objetivo

Implementa processos técnicos verificáveis para acesso/exportação, retificação, eliminação, restrição e retenção conforme os requisitos aprovados, sem expor dados de terceiros nem apagar dados sujeitos a obrigação de conservação.

## Critérios de sucesso

- Cada categoria de dados tem proprietário, finalidade, localização, retenção e ação de fim de vida.
- Pedidos exigem autenticação/verificação proporcional e têm auditoria segura.
- Exportação é completa no âmbito definido, legível e entregue de forma protegida.
- Eliminação distingue apagar, anonimizar, bloquear e conservar por obrigação.
- Backups, logs, providers e dados derivados têm tratamento documentado.

## Processo

1. Mapeia dados em base, storage, logs, telemetry, backups, emails, pagamentos e fornecedores.
2. Liga identificadores entre sistemas e identifica dados de terceiros/tenants.
3. Confirma no artefacto aprovado workflow, prazos, aprovações, exceções, legal hold e comunicação ao titular.
4. Regista divergências; não inventa bases legais ou prazos nem escolhe silenciosamente entre código e política.

## Implementação e validação

- Autoriza todos os pedidos no servidor e protege contra enumeração/IDOR.
- Usa jobs idempotentes e retomáveis para operações longas.
- Redige segredos e dados de terceiros na exportação.
- Regista quem, quando, âmbito, resultado e exceção, minimizando dados no próprio audit log.
- Testa utilizador normal, conta comprometida simulada, dados partilhados, pedido repetido, provider indisponível, legal hold e recuperação parcial.
- Executa em dados sintéticos; não processa pedidos reais sem autorização.

## Entrega

Apresenta modo executado, matriz aprovada usada, mapa de dados, workflows, decisões, ficheiros, testes/resultados, fornecedores afetados, limitações de backups e itens para revisão jurídica.

## Referências oficiais

- https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng
- https://www.edpb.europa.eu/sme-data-protection-guide/respect-individuals-rights_en
- https://cheatsheetseries.owasp.org/cheatsheets/User_Privacy_Protection_Cheat_Sheet.html
