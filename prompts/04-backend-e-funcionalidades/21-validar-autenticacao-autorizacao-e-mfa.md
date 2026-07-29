# Validar autenticação, autorização e MFA

## Objetivo

Audita, corrige e testa a autenticação e a autorização em todas as superfícies ativas da aplicação. Garante controlo de acesso no servidor, políticas coerentes, separação correta entre 401 e 403 e MFA adequado ao risco, reutilizando Identity, bearer authentication, roles e permissions do `BoilerPlateAdvance`.

## Critérios de sucesso

- Cada endpoint e operação sensível tem uma decisão explícita: anónimo, autenticado, policy/permission e autorização ao nível do recurso.
- A UI não é usada como barreira de segurança; o servidor rejeita acesso indevido mesmo com pedidos construídos manualmente.
- Login, tokens/cookies, MFA, recuperação e logout não permitem enumeração, replay evidente, bypass ou exposição de segredos.
- Funções administrativas e ações de alto impacto exigem MFA ou reautenticação quando os requisitos de risco o justificam.
- Existem testes negativos para utilizadores anónimos, autenticados sem permissão, com role errada e a tentar aceder a recursos de terceiros.

## Preparação

1. Lê `AGENTS.md`, `README.md`, `MODULES.md`, configuração de Identity, handlers, policies, roles/permissions, endpoints, clientes Web/MAUI e testes.
2. Confirma os esquemas reais: bearer, cookie, external providers ou combinação. Não atives login social apenas porque o boilerplate o suporta.
3. Identifica atores e ações sensíveis. Cria a matriz:

| Superfície/rota | Ação/recurso | Acesso esperado | Policy/permission | MFA/reauth | Teste/evidência |
|---|---|---|---|---|---|

4. Usa o código e os requisitos como fonte de verdade. Não derives autorização apenas da visibilidade de menus.
5. Se passkeys/WebAuthn estiverem ativas, usa os resultados do prompt 33 e mantém MFA, recuperação e step-up coerentes entre os dois fluxos.

## Auditoria e implementação

1. Separa autenticação de autorização. Aplica policies/requirements reutilizáveis e testáveis; evita verificações de role/permission espalhadas ou apenas no cliente.
2. Protege por defeito as superfícies privadas, mantendo `AllowAnonymous` apenas onde seja intencional. Não bloqueies o site público `Client.Ssr`.
3. Valida autorização ao nível da função e do objeto para impedir IDOR/BOLA. Nunca confies em user IDs, tenant IDs, roles, preços ou ownership enviados pelo cliente.
4. Confirma que APIs devolvem 401 para ausência/invalidade de autenticação e 403 para identidade válida sem autorização, sem redirects HTML inesperados.
5. Revê emissão, validação, expiração, renovação e revogação de tokens/cookies. Limita relógio tolerado, audience/issuer e persistência ao necessário; não registes tokens.
6. Mantém tokens fora de armazenamento inseguro. Reutiliza os mecanismos já estabelecidos para Web/PWA e armazenamento seguro nativo para MAUI.
7. Configura proteção contra brute force e credential stuffing sem criar uma negação de serviço trivial por lockout. Mantém mensagens e tempos que não revelem se a conta existe.
8. Para MFA, privilegia TOTP suportado por ASP.NET Core Identity. Força MFA/step-up para administração e operações críticas quando aplicável; implementa enrollment, confirmação, recovery codes, dispositivos lembrados e recuperação segura.
9. Não escolhas SMS como fator preferencial. Não afirmes suporte nativo a passkeys/FIDO2 sem confirmar a implementação/provider real.
10. Exige reautenticação ou MFA depois de recuperação de conta e antes de alterar password, email, fatores MFA, faturação ou outras definições críticas.
11. Mantém chaves, client secrets e Data Protection fora do repositório e separados por ambiente.

## Testes

Testa pelo menos:

- login válido/inválido, conta não confirmada/bloqueada e rate limiting;
- token/cookie ausente, expirado, revogado, adulterado e destinado a outro issuer/audience;
- 401 versus 403;
- role/permission ausente e elevação de privilégios;
- acesso horizontal a objetos de outro utilizador/tenant;
- MFA enrollment, challenge, recovery code de uso único, dispositivo lembrado e reset;
- reautenticação nas ações críticas;
- logout e revogação em Web e MAUI;
- external providers apenas quando configurados.

Executa os testes de integração contra a configuração realista mais próxima do ambiente final. Não uses produção nem contas reais.

## Limites

Não reduzas políticas, desatives MFA, exponhas detalhes internos ou cries backdoors para fazer testes passar. Não alteres regras de acesso de negócio sem evidência; regista decisões em falta. Alterações a providers externos, domínios, certificados ou recursos cloud exigem autorização e configuração próprias.

## Entrega

Apresenta a matriz final de acesso, vulnerabilidades e causas corrigidas, policies/handlers alterados, desenho de MFA e dependências de passkeys, testes/resultados, configuração necessária sem segredos e riscos residuais. Não declares a autenticação “segura” fora dos fluxos e ataques efetivamente validados.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/security/authorization/policies?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/security/authentication/mfa?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/security/authorization/secure-data?view=aspnetcore-10.0
- https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- https://owasp.org/www-project-application-security-verification-standard/
