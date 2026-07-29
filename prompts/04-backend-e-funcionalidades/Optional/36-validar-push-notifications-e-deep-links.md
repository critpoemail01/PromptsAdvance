# Validar notificações push e deep links

## Aplicabilidade

Executa apenas para os canais `[WEB_PUSH_APNS_FIREBASE]` e plataformas realmente selecionadas. Trata um canal/provider por lote; se existirem vários, começa por `[CANAL_ATUAL]` e não assume que configuração, payloads ou ciclo de vida são equivalentes.

## Objetivo

Implementa e valida opt-in, subscrições/tokens, envio seguro, navegação por deep link e ciclo de vida das notificações sem tornar o canal obrigatório para o funcionamento do produto.

## Critérios de sucesso

- A permissão é pedida no contexto certo e a recusa não bloqueia a aplicação.
- Tokens/subscrições são associados ao utilizador/dispositivo correto, renovados e removidos.
- Payloads não expõem dados sensíveis no lock screen ou logs.
- Deep links validam destino e autorização depois de abrir a aplicação.
- Envio é idempotente, observável e testável sem mensagens reais.

## Processo

1. Inventaria service worker, APNS/Firebase/Web Push, configuração, jobs, handlers MAUI e rotas.
2. Define casos de uso, preferências, consentimento/base legal, TTL, prioridade e quiet hours.
3. Mapeia estados foreground/background/terminated e comportamento sem sessão.
4. Mantém providers sem configuração desativados.
5. Consulta documentação atual do canal/provider e da plataforma antes de configurar credenciais, capabilities, payloads ou políticas de entrega.

## Implementação e validação

- Valida URLs/deep links contra allowlist e resolve autorização no servidor.
- Trata token rotation, logout, dispositivos múltiplos e respostas de token inválido.
- Mantém payload mínimo e obtém detalhes protegidos após abrir.
- Usa fakes/emuladores/sandboxes; não envia push para utilizadores reais.
- Testa aceitar/recusar/revogar, token expirado, logout, deep link válido/inválido, sessão expirada, foreground/background e provider indisponível.
- Executa build/test e runtime nas plataformas disponíveis.

## Entrega

Apresenta canal/provider e plataformas do lote, fontes/data, preferências, payloads sem dados reais, rotas, testes/resultados, configuração necessária, canais adiados e limitações de dispositivos não testados.

## Referências oficiais

- https://developer.mozilla.org/docs/Web/API/Push_API
- https://developer.apple.com/documentation/usernotifications
- https://firebase.google.com/docs/cloud-messaging
- https://learn.microsoft.com/dotnet/maui/android/app-links?view=net-maui-10.0
