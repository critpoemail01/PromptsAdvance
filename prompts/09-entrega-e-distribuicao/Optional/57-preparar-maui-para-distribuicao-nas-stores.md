# Preparar MAUI para distribuição nas lojas

## Aplicabilidade

Executa quando `Client.Maui` será distribuído em `[PLATAFORMAS_E_LOJAS]`. Trata uma combinação `[PLATAFORMA_ATUAL]` + `[LOJA_ATUAL]` por execução.

## Objetivo

Prepara builds de release, identidade, versão, assinatura, permissões, deep links, assets e metadados técnicos para as lojas selecionadas, sem submeter ou comprar serviços sem autorização explícita.

## Critérios de sucesso

- Application ID/bundle ID e versionamento são estáveis e aprovados.
- Release build é reproduzível e usa assinatura fora do repositório.
- Permissions/entitlements correspondem apenas às funcionalidades usadas.
- Deep/universal links e force update têm estratégia testada.
- Artefactos passam validação local/da ferramenta da plataforma disponível.

## Processo

1. Lê documentação MAUI e force update do boilerplate, project files, manifests, resources e workflows.
2. Confirma plataformas, IDs, contas, certificados/perfis, versão mínima e política de rollout.
3. Inventaria privacy declarations, permissões, ícones, splash, screenshots e textos exigidos.
4. Não inventa IDs de loja, certificados, contactos ou declarações legais.
5. Consulta documentação e políticas atuais da plataforma/loja selecionada e regista a data; requisitos de submissão mudam fora do ciclo do código.

## Implementação e validação

- Separa version name e build number com incremento determinístico.
- Carrega certificados/profiles/passwords apenas através do mecanismo seguro do ambiente.
- Remove permissions não usadas e documenta justificação das restantes.
- Configura universal/app links com domínio e ficheiros de associação autorizados.
- Cria artefactos release para workloads disponíveis; testa instalação limpa, upgrade, deep link, notificações e arranque offline quando aplicável.
- Prepara rollout faseado e critérios de pausa/rollback.
- Não submete a lojas nem torna a release pública.

## Entrega

Apresenta plataforma/loja executada, fontes/data, IDs/versões não sensíveis, artefactos gerados, comandos/resultados, permissões, assets/metadados pendentes, validações, restantes plataformas não tocadas e passos manuais de assinatura/submissão.

## Referências oficiais

- https://learn.microsoft.com/dotnet/maui/deployment/?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/core/tools/dotnet-publish
- https://developer.apple.com/help/app-store-connect/
- https://support.google.com/googleplay/android-developer/
