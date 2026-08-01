# Validar login com fornecedores externos

## Aplicabilidade

Executa um fornecedor de `[FORNECEDORES_SELECIONADOS]` por vez, com credenciais e redirect URIs de ambiente de teste autorizados. Se forem indicados vários, cria a matriz comum e implementa apenas `[FORNECEDOR_ATUAL]`.

## Objetivo

Configura e valida login externo no sistema Identity existente sem enfraquecer login local, MFA, ligação de contas ou recuperação. Mantém providers não selecionados desativados.

## Critérios de sucesso

- Cada provider tem configuração validada por ambiente e redirect URIs mínimas.
- Login, cancelamento, erro, email ausente e conta já existente têm comportamento seguro.
- Ligação/desligação de identidade exige sessão recente e não permite account takeover.
- Tokens do provider não aparecem em logs, URL persistente ou cliente indevido.

## Processo

1. Confirma packages, handlers, endpoints, configuração `Authentication`, claims e UI existentes.
2. Define a política para correspondência por email, email verificado, criação de conta, consentimento e ligação manual.
3. Modela ameaças de state/nonce, redirect, CSRF, confusão de provider e tomada de conta.
4. Não assumes que claims têm o mesmo significado entre providers.
5. Consulta a documentação atual do fornecedor e do handler ASP.NET Core antes de alterar configuração, scopes ou claims.

## Implementação e testes

- Ativa apenas providers configurados; oculta opções indisponíveis.
- Usa state, nonce, PKCE e correlation conforme o protocolo/handler.
- Restringe redirect URIs e não aceita destinos arbitrários.
- Guarda apenas tokens estritamente necessários, protegidos e com ciclo de vida definido.
- Testa sucesso, cancelamento, token/estado inválido, email não verificado/ausente, colisão com conta local, ligação/desligação, 2FA e revogação.
- Usa contas sandbox/de teste e nunca publica credenciais.

## Entrega

Apresenta fornecedor executado, fontes/data, política aprovada de claims/ligação, configuração necessária sem valores, fluxos testados, comandos/resultados, riscos, restantes fornecedores não tocados e passos manuais nos portais externos.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/security/authentication/social/?view=aspnetcore-10.0
- https://datatracker.ietf.org/doc/html/rfc9700
- https://openid.net/specs/openid-connect-core-1_0.html
