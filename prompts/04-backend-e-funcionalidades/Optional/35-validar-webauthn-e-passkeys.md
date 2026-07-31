# Validar WebAuthn e passkeys

## Aplicabilidade

Executa quando a capacidade FIDO2/WebAuthn do boilerplate é mantida.

## Objetivo

Audita e conclui registo, autenticação e gestão de passkeys em `[DOMINIOS_E_CLIENTES]`, preservando MFA e recuperação de conta. Valida o código real baseado em Fido2NetLib/WebAuthn; não assumes suporte apenas pela presença de packages.

## Matriz de suporte

Regista `[BROWSERS_PLATAFORMAS_E_VERSOES]`, data da validação, RP ID, origins e tipo de authenticator disponível. Não extrapoles sucesso num browser/dispositivo para toda a plataforma.

## Critérios de sucesso

- RP ID, origins, challenge, user verification e attestation têm política explícita.
- Challenges são aleatórios, de uso único, expiram e estão ligados à cerimónia/utilizador.
- Credenciais são geridas sem expor material sensível e sign count é tratado corretamente.
- Registo, login, remoção e recuperação resistem a account takeover.
- UX funciona em browsers/plataformas suportados e degrada de forma clara.

## Processo

1. Inventaria endpoints, DTOs, armazenamento, configuração, JS interop, Web e MAUI.
2. Mapeia cerimónias de criação e obtenção do challenge até à persistência/verificação.
3. Confirma política para discoverable credentials, user verification, múltiplos dispositivos e credenciais perdidas.
4. Revê threat model antes de editar.

## Implementação e validação

- Valida origin/RP ID no servidor e não confia em dados do cliente.
- Previne replay, enumeração de contas e substituição silenciosa de credenciais.
- Exige reautenticação adequada para adicionar/remover passkeys.
- Não torna passkeys obrigatórias sem caminho de recuperação aprovado.
- Testa happy path, challenge expirado/repetido, origin/RP inválido, utilizador errado, credencial desconhecida, remoção e recuperação.
- Usa browser/dispositivo compatível em ambiente de teste e executa testes unitários/integração além do E2E.

## Entrega

Apresenta versão das referências/biblioteca, configuração, fluxos, ameaças/controlos, matriz datada de plataformas testadas, ficheiros, testes/resultados e limitações conhecidas.

## Referências oficiais

- https://www.w3.org/TR/webauthn-3/
- https://www.w3.org/TR/secure-contexts/
- https://fidoalliance.org/passkeys/
