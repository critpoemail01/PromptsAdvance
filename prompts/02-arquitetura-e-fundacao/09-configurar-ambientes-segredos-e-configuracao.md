# Configurar ambientes, segredos e validação de configuração

## Objetivo

Implementa uma estratégia coerente de configuração para `[AMBIENTES]` no projeto derivado de `BoilerPlateAdvance`, mantendo segredos fora do repositório e falhando cedo quando opções obrigatórias são inválidas.

## Critérios de sucesso

- Development, test, staging e production têm responsabilidades e diferenças documentadas.
- Opções críticas são tipadas, validadas no arranque e têm defaults apenas quando seguros.
- Segredos entram por User Secrets, variáveis de ambiente, OIDC/cofre ou mecanismo aprovado.
- Data Protection, domínios, CORS, providers, telemetria e feature flags respeitam o ambiente.
- A aplicação arranca localmente com integrações opcionais desativadas.

## Preparação

1. Inventaria `appsettings*`, launch profiles, environment variables, options, validação, workflows e documentação.
2. Pesquisa segredos versionados e valores duplicados sem os reproduzir no relatório.
3. Classifica cada valor como código, configuração não sensível, segredo, identificador público ou configuração operacional.
4. Define a matriz:

| Chave/opção | Proprietário | Ambientes | Sensível | Obrigatória quando | Fonte | Validação |
|---|---|---|---|---|---|---|

Usa primeiro scanners já existentes. Se não houver scanner, faz pesquisa dirigida por padrões e histórico apenas quando autorizado, redigindo valores; não instales tooling nem imprimas correspondências sensíveis só para completar a auditoria.

## Implementação

- Reutiliza Options pattern e validação no arranque.
- Mantém placeholders sem aparência de credenciais reais.
- Não coloca tokens, connection strings, certificados privados ou passwords em `appsettings*.json`, scripts, testes ou logs.
- Garante que integrações condicionais ficam inativas quando a configuração está ausente.
- Configura persistência/proteção de Data Protection em produção segundo a topologia, sem inventar certificados.
- Restringe CORS, origins, redirect URIs e hosts por ambiente.
- Atualiza documentação e templates de variáveis sem valores secretos.
- Roda credenciais expostas apenas com autorização e fora deste prompt; reporta o incidente de forma redigida.

## Validação

Testa arranque com configuração mínima válida, opção obrigatória ausente, valor malformado e integração opcional desativada. Executa build/test e scanners de segredos já disponíveis. Confirma que mensagens de erro são acionáveis sem divulgar valores.

## Entrega

Apresenta matriz de configuração, ficheiros alterados, método/âmbito da pesquisa de segredos, testes/resultados, valores que o operador deve fornecer, diferenças por ambiente e exposições encontradas de forma redigida.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/fundamentals/configuration/options?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/security/app-secrets?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-10.0
