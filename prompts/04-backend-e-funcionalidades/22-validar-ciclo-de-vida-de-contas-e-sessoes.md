# Validar o ciclo de vida de contas e sessões

## Objetivo

Implementa, audita e testa o ciclo de vida completo das contas e sessões para `[MODELO_DE_CONTA]`: registo ou convite, confirmação, login, recuperação, alteração de credenciais, sessões ativas, logout, bloqueio, desativação e eliminação. Preserva a experiência entre `Client.Web` e `Client.Maui` sem comprometer segurança, privacidade ou integridade de dados.

## Gate de decisão

Antes de editar, exige `[MODELO_DE_AQUISICAO_DE_CONTA]` e `[MATRIZ_APROVADA_DE_RETENCAO_E_ELIMINACAO]`, incluindo tratamento de subscrições, auditoria, dados partilhados e identidade reutilizada. Se faltarem, audita o estado atual, produz a state machine e as decisões bloqueantes, mas não implementa transições irreversíveis nem vários modelos de aquisição.

## Critérios de sucesso

- Todos os estados de conta e transições permitidas estão definidos e testados.
- Recuperação e confirmação usam tokens de uso único, com validade limitada, sem enumeração de contas.
- Logout, revogação e expiração invalidam efetivamente o acesso no servidor e limpam estado sensível no cliente.
- Alterações críticas exigem autenticação recente ou MFA e notificam o titular quando apropriado.
- Desativação/eliminação respeita retenção, faturação, auditoria e relações de dados sem deixar acesso ativo.

## Preparação

1. Lê requisitos, políticas legais, modelo de Identity, emails transacionais, entidades relacionadas, subscrições, auditoria, clientes e testes.
2. Confirma o modelo aprovado de aquisição: registo público, convite, SSO ou administração. Não implementes todos os modelos em paralelo.
3. Modela explicitamente os estados e transições, por exemplo:

```text
pendente -> confirmada -> ativa -> bloqueada/desativada -> eliminada/anónima
```

4. Cria uma matriz com evento, pré-condições, autorização/MFA, alteração de estado, revogação de sessões, notificação, retenção e teste.
5. Identifica decisões de negócio irreversíveis — prazo de recuperação, eliminação imediata/diferida, tratamento de subscrições e dados legalmente retidos — e não as inventes.

## Implementação

1. Registo/convite:
   - valida e normaliza identificadores sem revelar contas existentes;
   - evita duplicados e corridas;
   - exige confirmação quando definido;
   - limita reenvios e invalida tokens anteriores quando necessário.
2. Recuperação:
   - devolve resposta equivalente para contas existentes e inexistentes;
   - usa tokens aleatórios, armazenados de forma segura, de uso único e com expiração;
   - não altera a conta até o token ser validado;
   - depois da recuperação, exige login normal e permite/impõe revogação das sessões anteriores.
3. Alterações críticas:
   - exige password atual, autenticação recente ou MFA conforme o risco;
   - confirma novo email antes de o tornar principal;
   - invalida tokens e sessões afetados;
   - envia notificação de segurança sem dados sensíveis.
4. Sessões:
   - define timeouts de inatividade e absolutos coerentes;
   - suporta listar e revogar sessões/dispositivos quando o modelo de tokens o permitir;
   - trata rotação/reutilização de refresh tokens e concorrência de renovações;
   - impede que logout seja apenas uma limpeza visual do cliente.
5. Bloqueio e abuso:
   - aplica rate limiting e sinais de risco;
   - distingue bloqueio temporário, suspensão administrativa e desativação voluntária;
   - mantém mensagens que evitem enumeração.
6. Desativação/eliminação:
   - revoga primeiro todas as sessões, fatores e integrações;
   - termina ou transfere responsabilidades e subscrições de forma definida;
   - elimina, anonimiza ou retém dados segundo os requisitos;
   - garante que a mesma identidade não reativa acidentalmente uma conta eliminada durante o período de retenção.
7. Mantém emails, SMS e notificações reais substituídos por fakes/sandboxes nos testes.

## Segurança e experiência

- Não uses security questions como único mecanismo de recuperação.
- Não coloques tokens em logs, analytics, URLs persistidas ou mensagens de erro.
- Protege respostas autenticadas com cache adequado e limpa estado sensível no logout sem destruir dados offline legítimos sem necessidade.
- Em PWA/MAUI, trata rede offline, sessão expirada durante trabalho pendente e sincronização posterior sem perder dados silenciosamente.
- Mantém as mensagens acionáveis, acessíveis e consistentes entre plataformas.

## Testes

Cobre happy path e abuso para cada transição: token expirado/reutilizado/adulterado, pedidos concorrentes, confirmação repetida, recuperação de conta inexistente, mudança de email, password e MFA, sessões múltiplas, revogação remota, logout offline, bloqueio, reativação, eliminação com dependências e tentativas de login posteriores.

Mede também se respostas e tempos permitem enumerar contas. Executa build e testes do projeto; usa contas e dados descartáveis, sem envios ou operações financeiras reais.

## Entrega

Apresenta modo executado, diagrama/matriz de estados, transições implementadas, artefacto de retenção usado, sessões e tokens tratados, notificações, testes/resultados e casos bloqueados por decisão de negócio. Não declares eliminação definitiva quando existirem dados legal ou tecnicamente retidos.

## Referências oficiais

- https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- https://learn.microsoft.com/aspnet/core/security/authentication/mfa?view=aspnetcore-10.0
