# Implementar publicidade com consentimento, segurança e controlo de produto

## Objetivo

Implementa apenas os formatos aprovados em `[PLANO_DE_MONETIZAÇÃO]` para um `[PROVEDOR]`, uma `[SUPERFICIE_ATUAL]` e `[MERCADO_ATUAL]` por execução. Usa IDs de teste/sandbox até existir autorização de produção. Não instales todos os formatos nem confundas AdSense web com AdMob nativo.

## Decisão antes do código

Cria uma matriz:

| Superfície | Formato | Objetivo | Local | Consentimento | Provider/SDK | Guardrails | Aprovado? |
|---|---|---|---|---|---|---|---|

Avalia separadamente:

- `Client.Ssr`: publicidade web apenas em páginas com conteúdo público suficiente;
- `Client.Web`: evita ads em autenticação, comunicação privada, páginas sem conteúdo e controlos críticos;
- `Client.Maui`: integração nativa compatível com MAUI/plataformas, sem assumir que JavaScript/webview substitui SDK nativo.

Escolhe uma única linha aprovada da matriz para implementar. Antes de editar, consulta a documentação e políticas atuais do provider, consentimento e loja/mercado aplicáveis; se houver conflito com o plano, para e apresenta a decisão necessária.

Aplica o `PRODUCT_EXCELLENCE.md` a essa linha: estuda placements equivalentes em produtos profissionais e investigação de UX, distinguindo padrões que preservam conteúdo e confiança de práticas agressivas. Um tema comercial ou concorrente não prova que o placement seja permitido, ético ou eficaz.

## Implementação

1. Reutiliza a CMP/consentimento; bloqueia personalização e identificadores até escolha válida.
2. Em iOS, pede ATT apenas se a integração realmente fizer tracking cross-app/site e depois de explicar o contexto.
3. Usa configuração por ambiente, feature flags, test IDs e kill switch. Secrets ficam fora do repositório.
4. Mantém anúncios distinguíveis de conteúdo e afastados de navegação, botões, formulários e áreas propensas a clique acidental.
5. Implementa loading/falha/no-fill sem bloquear conteúdo, layout ou acessibilidade.
6. Para rewarded ads, concede recompensa por callback verificado/idempotente; nunca por clique e nunca confies só no cliente.
7. Publica `ads.txt`/`app-ads.txt` com valores fornecidos pelo provider, host/status corretos e testes de crawl.
8. Regista métricas técnicas e receita sem dados pessoais desnecessários.

## Limites

Não cliques em anúncios reais, não incentives cliques, não mostres anúncios em emails/popups proibidos, não uses produção nos testes e não alteres políticas do provider. Não atives publicidade para menores/mercados restritos sem decisão jurídica e de produto.

## Validação

Testa consentimento aceite/rejeitado/retirado, ATT negado, no-fill, offline, rotação/background, acessibilidade, frequência, recompensa duplicada e kill switch. Usa test devices/IDs e tráfego de sandbox. Executa build/test web e MAUI aplicável.

## Entrega

Apresenta linha executada, fontes/data, benchmark e matriz aprovada, SDK/configuração, placements, consentimento, ads files, testes, IDs ainda placeholder, restantes superfícies não tocadas, riscos de loja/política e passos manuais.

## Referências oficiais

- https://support.google.com/adsense/answer/48182
- https://support.google.com/adsense/answer/12171612
- https://support.google.com/admob/answer/9363762
- https://developer.apple.com/documentation/apptrackingtransparency
- https://developer.apple.com/app-store/review/guidelines/
- https://www.edpb.europa.eu/contact/frequently-asked-questions_en
