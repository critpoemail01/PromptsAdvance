# Implementar a área legal pública e os controlos de consentimento

## Objetivo

Implementa em `Client.Ssr` as páginas legais públicas e os controlos de consentimento a partir de `[CONTEUDO_LEGAL_APROVADO]` e `[MATRIZ_DE_PRIVACIDADE_APROVADA]`, para `[ENTIDADE]`, `[PRODUTO]` e `[MERCADOS]`. Este prompt não define políticas, bases legais, retenção nem fluxos operacionais de direitos e não declara conformidade legal.

## Pré-requisitos e comportamento quando faltam

- Conteúdo legal factual revisto, ainda que marcado como rascunho: entidade, contactos, finalidades, bases propostas, fornecedores, transferências e retenção.
- Inventário técnico de cookies/storage, analytics, ads, push, email, pagamentos e integrações ativas.
- Decisões de consentimento por finalidade e mercados.
- Para acesso, exportação, retificação, eliminação ou restrição de dados, usa primeiro o prompt 40 e fornece aqui apenas as rotas/explicações aprovadas.

Se faltar informação factual material ou `[RESPONSAVEL_REVISAO_JURIDICA]`, cria apenas estrutura não indexável com o texto visível `REVISÃO JURÍDICA PENDENTE`; não publiques, não inventes texto e não simules fluxos de direitos. Este marcador não é um novo placeholder e deve desaparecer apenas após aprovação registada do responsável.

## Critérios de sucesso

- O conteúdo público corresponde exatamente aos artefactos aprovados e está versionado.
- Scripts/cookies não essenciais respeitam a decisão antes de carregar.
- Aceitar, rejeitar, personalizar e retirar são equivalentes em clareza e esforço.
- Páginas e controlos são static SSR, acessíveis, localizáveis e testados sem JavaScript essencial.
- Placeholders, lacunas jurídicas e dependências do prompt 40 permanecem visíveis.

## Descoberta obrigatória

1. Confirma responsáveis/processadores, finalidades, categorias de dados/titulares, bases propostas, destinatários, transferências, retenção, medidas de segurança e direitos nos artefactos aprovados; não os redescubras como decisão.
2. Audita cookies/local storage, analytics, ads, push, email, pagamentos, attachments, logs e integrações ativas.
3. Identifica requisitos específicos de menores, conteúdo do utilizador, subscrições ou mercados regulados.
4. Regista divergências entre o produto e os artefactos. Não escolhas silenciosamente qual é correto.

## Implementação

- Política de Privacidade, Termos/Condições, Cookies e contactos em rotas públicas static SSR.
- Conteúdo versionado com data de vigência e idioma; links permanentes no footer e em pontos de recolha.
- Avisos just-in-time nos formulários e preferências acessíveis.
- Consentimento separado por finalidade quando essa for a base; recusar deve ser tão simples como aceitar e retirar tão simples como dar.
- Bloqueia scripts/cookies não essenciais antes da escolha. Regista versão, finalidade, escolha e timestamp sem recolher mais dados do que o necessário.
- Apresenta links e explicações aprovadas para pedidos de direitos; a implementação autenticada pertence ao prompt 40.
- Mostra a lista aprovada de processadores/transferências e prazos sem a transformar numa decisão técnica nova.

## Limites

Não uses banners manipulativos, caixas pré-selecionadas ou cookie walls indiscriminadas. Não copies políticas de concorrentes. Não confundas consentimento com todas as bases legais. Não mostres emails/telefones falsos. Não alteres retenção nem apagues/exportes dados neste prompt.

## Validação

Testa HTML bruto, primeira visita, aceitar/rejeitar/personalizar/retirar, ausência de trackers antes de consentimento, teclado/mobile, persistência e mudança de versão. Executa build/test e inspeciona rede/storage. Mantém indexação ou publicação bloqueada enquanto existirem placeholders materiais ou faltar revisão por jurista/DPO.

## Entrega

Apresenta artefactos de entrada, páginas/controlos, placeholders, testes, divergências encontradas, dependências do prompt 40 e questões para revisão jurídica.

## Referências oficiais

- https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng
- https://www.edpb.europa.eu/documents/guideline/guidelines-052020-on-consent-under-regulation-2016679_en
- https://www.edpb.europa.eu/contact/frequently-asked-questions_en
- https://www.cnpd.pt/media/x2zdus50/nota-informativa-cnpd_cookies_20210625.pdf
- https://www.w3.org/TR/WCAG22/
