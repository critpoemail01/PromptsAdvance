# Modelar ameaças e definir requisitos de segurança

## Objetivo

Antes de criar a aplicação e iniciar a implementação principal, cria um threat model acionável para `[ARQUITETURA_E_JORNADAS]`. Identifica ativos, fronteiras de confiança, ameaças e controlos verificáveis para API, SSR, Web/PWA, MAUI, dados e integrações selecionadas.

## Pré-requisito

Usa a arquitetura, os módulos e os fluxos de dados aprovados no prompt 05. Se estiverem ausentes ou contraditórios, produz apenas um modelo provisório marcado e bloqueia requisitos que dependam da decisão em falta.

## Critérios de sucesso

- O modelo representa a arquitetura real e as jornadas de maior impacto.
- Cada ameaça relevante tem cenário, impacto, probabilidade, mitigação, proprietário e teste.
- Requisitos de autenticação, autorização, privacidade, logging e recuperação são concretos.
- Riscos aceites e decisões pendentes ficam explícitos.

## Processo

1. Lê arquitetura, requisitos, `MODULES.md`, fluxos de dados, configuração, endpoints, identidade e deployment.
2. Inventaria atores, ativos, entradas, dados sensíveis, processos, armazenamentos, canais externos e trust boundaries.
3. Desenha um diagrama de fluxo de dados simples e numera os elementos.
4. Analisa spoofing, tampering, repudiation, information disclosure, denial of service e elevation of privilege, complementando com abuso de lógica de negócio.
5. Prioriza por impacto e explorabilidade; não atribuas números pseudoexatos sem dados.

## Matriz obrigatória

| ID | Ativo/fluxo | Ameaça/cenário | Precondição | Impacto | Controlos atuais | Mitigação | Teste/evidência | Estado |
|---|---|---|---|---|---|---|---|---|

## Requisitos mínimos

- autorização no servidor por função e objeto;
- validação de input/output e limites de recursos;
- proteção de credenciais, tokens, cookies, chaves e dados pessoais;
- rate limiting e resistência a enumeração/automação;
- sessões, MFA/passkeys quando aplicável e recuperação de conta;
- logs auditáveis sem segredos, deteção e resposta;
- integridade de migrations, backups e operações irreversíveis;
- segurança de browser, PWA, links, uploads e integrações selecionadas.

## Limites

Não executes exploração contra produção nem fornecedores externos. Usa ambiente local ou de teste, dados descartáveis e testes controlados. Não declares risco eliminado sem controlo implementado e evidência.

## Entrega

Produz o diagrama, matriz priorizada, requisitos de segurança com IDs estáveis, backlog de mitigação, testes previstos, riscos aceites com owner/aprovação e questões de arquitetura. Liga cada requisito `Must` ao prompt ou fase que o implementará.

## Referências oficiais

- https://learn.microsoft.com/azure/security/develop/threat-modeling-tool-threats
- https://owasp.org/www-community/Threat_Modeling
- https://owasp.org/www-project-application-security-verification-standard/
