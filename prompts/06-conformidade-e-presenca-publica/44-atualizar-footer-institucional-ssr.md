# Atualizar o rodapé institucional

## Objetivo

Implementa um footer público, acessível e configurável com os dados reais de `[ENTIDADE]` e `[PRODUTO]`, sem hardcodes temporais nem informação inventada.

## Dados necessários

`[NOME_LEGAL]`, `[NOME_COMERCIAL]`, `[NIF/REGISTO]`, `[MORADA]`, `[EMAIL_SUPORTE]`, `[EMAIL_PRIVACIDADE]`, `[REDES_VALIDAS]`, idiomas, rotas legais e fonte/owner de cada dado. Se algum dado obrigatório faltar, usa um placeholder explícito em desenvolvimento e não publiques.

## Execução

1. Audita footer/layout/tokens e rotas legais em `Client.Ssr`.
2. Cria uma estrutura semântica `<footer>` com:
   - identidade e descrição curta;
   - navegação agrupada;
   - links de Privacidade, Termos, Cookies e preferências;
   - contacto real e redes confirmadas;
   - copyright com ano atual calculado, não fixo.
3. Usa configuração/localização existente para nome e contactos que variem por ambiente/mercado.
4. Garante labels acessíveis em ícones, foco, contraste, área de toque, wrapping e `mailto:` correto.
5. Links externos abrem de forma segura quando necessário; não uses `#`, destinos vazios ou URLs de exemplo.
6. Não adiciones selos, certificações, claims ou contactos sem fonte.

## Validação

Verifica todos os links/status, HTML sem JavaScript, 320–1440 px, teclado, zoom 200%, temas e idiomas. Executa testes SSR/build relevantes. Confirma que o footer não duplica CTAs nem prejudica LCP/CLS.

## Entrega

Apresenta dados usados, respetiva origem/owner/data de confirmação, ficheiros, screenshots, validação de links e placeholders/lacunas.

## Referências oficiais

- https://www.w3.org/TR/WCAG22/
- https://developers.google.com/search/docs/fundamentals/seo-starter-guide
