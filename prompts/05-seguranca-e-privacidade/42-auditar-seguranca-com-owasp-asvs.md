# Auditar e corrigir segurança com OWASP ASVS

## Objetivo

Executa uma auditoria de segurança baseada em risco contra `[VERSAO_ASVS]`, `[NIVEL_ASVS]` e `[AMBITO_ASVS]`, cobrindo apenas superfícies e módulos ativos. Confirma a versão atual da norma na fonte oficial e regista a versão aprovada no `APP_CONTEXT.md`; não aplica silenciosamente um valor por defeito. Corrige vulnerabilidades dentro de `[AUTORIZACAO_DE_CORRECAO]` e produz evidência para as restantes.

## Critérios de sucesso

- O âmbito e a versão do ASVS são explícitos.
- Cada requisito selecionado tem resultado, evidência e severidade.
- Achados são reproduzíveis e ligados a causa e correção.
- Nenhum teste afeta produção, utilizadores ou fornecedores reais.
- Correções passam testes de regressão e não removem comportamento exigido.

## Preparação

1. Lê o threat model, arquitetura, requisitos de segurança, configuração, dependências, CI e testes.
2. Confirma superfícies/módulos ativos e ambiente local/teste autorizado.
3. Confirma a versão estável atual; não mistures IDs de versões diferentes. Seleciona requisitos aplicáveis e usa IDs completos versionados, por exemplo `v5.0.0-x.y.z`, na matriz:

| ASVS ID | Requisito | Aplicável | Evidência | Resultado | Severidade | Correção/teste |
|---|---|---|---|---|---|---|

4. Prioriza controlo de acesso, identidade/sessões, validação, criptografia, comunicação, configuração, dados, logging e API.

## Execução

- Faz revisão de código/configuração, análise de dependências e testes dinâmicos controlados.
- Verifica autorização por função e objeto, mass assignment, enumeração, rate limits e abuso de negócio.
- Revê tokens, cookies, CORS, CSP/headers, Data Protection, secrets e logs.
- Testa uploads, SSR, PWA, WebAuthn, SignalR, jobs e integrações apenas quando ativos.
- Quando ajuda multimédia estiver ativa, revê CSP/frame-src, origem e
  allowlist do embed, cookies/tracking, OAuth/segredos, autorização de artigos/
  cursos, IDOR em progresso, validação de IDs/URLs e indisponibilidade do provider.
- Não usa scanners como prova única e valida falsos positivos.
- Não divulga payloads ofensivos, segredos ou dados pessoais no relatório.

## Correção e validação

Corrige por severidade e explorabilidade, adicionando teste de regressão antes ou com a correção. Executa build/test e reproduz o cenário depois da alteração. Se uma correção exigir decisão arquitetural ou quebra de contrato, documenta-a em vez de improvisar.

## Entrega

Apresenta versão/nível/âmbito, cobertura ASVS, matriz com IDs versionados, achados priorizados, correções, testes/resultados, riscos aceites, falsos positivos e áreas não verificadas. Não declares conformidade para além dos requisitos comprovados.

## Referências oficiais

- https://owasp.org/www-project-application-security-verification-standard/
- https://owasp.org/www-project-web-security-testing-guide/
- https://owasp.org/API-Security/editions/2023/en/0x11-t10/
