# Implementar emails transacionais seguros e testáveis

## Objetivo

Implementa os emails transacionais necessários para `[EVENTOS]`, reutilizando o stack existente (`FluentEmail.Smtp`, Identity, localização e Hangfire quando adequado). Entrega templates, dispatch, observabilidade e testes sem enviar emails reais.

## Entradas

Define `[CLIENTES_EMAIL_ALVO]`, idiomas, remetente/domínios de teste e eventos/owners. Se não houver conteúdo aprovado, usa copy técnica marcada para revisão; não inventa obrigações, contactos ou claims.

## Inventário

Cria uma matriz:

| Evento | Destinatário | Trigger | Dados mínimos | Urgência | Retry/idempotência | Template/idioma |
|---|---|---|---|---|---|---|

Inclui, quando existentes: confirmação de conta, recuperação de password, alteração de email/password, alertas de segurança, recibos/faturas e notificações de negócio. Separa transacional de marketing.

Aplica o `PRODUCT_EXCELLENCE.md`: compara padrões atuais de emails transacionais de produtos profissionais, clientes de email e templates premium autorizados. Extrai hierarquia, clareza da ação, confiança, fallback e comportamento mobile/dark mode; não copies conteúdo, identidade ou código sem licença.

## Implementação

1. Usa templates responsivos em HTML + alternativa plain text, com encoding, localização, branding e links absolutos da configuração.
2. Centraliza contratos/rendering; não construa HTML disperso em controllers.
3. Para Identity:
   - resposta uniforme a pedidos de reset para evitar enumeração;
   - tokens aleatórios/seguros, expirados e de uso único segundo o mecanismo do framework;
   - não incluir passwords, tokens em logs ou dados sensíveis no assunto.
4. Enfileira envios quando isso melhora resiliência. Jobs devem ser idempotentes, ter retry limitado/backoff e estado observável.
5. Distingue “aceite pelo SMTP/provider” de “entregue”. Regista IDs/estado sem armazenar corpo sensível.
6. Configura SMTP/from/host por User Secrets, env ou cofre. Não coloques credenciais em `appsettings`.
7. Requer SPF/DKIM/DMARC e TLS como passos operacionais. One-click unsubscribe aplica-se a marketing/subscrições, não é requisito para emails puramente transacionais.

## Testes

Usa um sink/local SMTP ou fake controlado. Testa rendering em todos os idiomas e clientes alvo disponíveis, links, escaping, textos longos, dark mode, acessibilidade, duplicação, retry e token inválido/expirado. Guarda previews/screenshots sem dados reais. Não contactes destinatários reais.

## Entrega

Apresenta matriz, referências e padrões adotados, templates, conteúdo por rever, configuração necessária sem valores, mecanismo de envio/retry, clientes testados, previews, licenças, testes/resultados e checklist DNS/provider ainda manual.

## Referências oficiais

- https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
- https://support.google.com/mail/answer/81126
- https://support.google.com/mail/answer/14229414
- https://learn.microsoft.com/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-10.0
