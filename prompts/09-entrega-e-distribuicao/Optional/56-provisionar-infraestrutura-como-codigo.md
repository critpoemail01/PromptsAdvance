# Provisionar infraestrutura como código

## Aplicabilidade

Executa quando `[RECURSOS_EXTERNOS]` precisam de provisionamento repetível e `[FERRAMENTA_IAC]`, `[CLOUD_PROVIDER]`, conta/subscrição e ambientes foram aprovados.

## Objetivo

Cria ou adapta definições de infraestrutura como código e produz um plan revisto, com módulos, estado, segurança, observabilidade e destruição protegida. O modo predefinido não executa `apply`, não cria recursos cloud e não gera custos.

## Critérios de sucesso

- Recursos e dependências correspondem à arquitetura aprovada.
- Ambientes são isolados e diferenças ficam em parâmetros, não em cópias divergentes.
- Segredos não entram no código, estado exposto ou outputs.
- Planos são revistos antes de apply e recursos críticos têm proteção.
- Drift, ownership, custos e recuperação do estado têm procedimento.

## Processo

1. Inventaria provider, IaC existente, contas/subscrições, state backend, naming, tags e políticas.
2. Mapeia `recurso → requisito → ambiente → dados → rede → identidade → observabilidade → custo`.
3. Define importação de recursos existentes antes de tentar recriá-los.
4. Se não existir ferramenta/provider decidido, entrega desenho e interfaces sem escolher por conveniência.
5. Mantém importação e criação em planos separados; não importes recursos e alteres simultaneamente a sua configuração sem revisão intermédia.

## Implementação e validação

- Reutiliza módulos e convenções existentes.
- Usa identidade federada/managed identity e least privilege.
- Cifra state, aplica locking, backups e acesso restrito.
- Define lifecycle/proteção para dados, domínios e produção.
- Expõe apenas outputs não sensíveis necessários ao deployment.
- Executa format/validate/lint e um plan em ambiente autorizado.
- Revê criação, alteração e destruição inesperadas; não executa apply de produção neste prompt.
- Não executa `apply` noutro ambiente salvo autorização explícita com alvo e plan exatos; por omissão, termina no plan.

## Entrega

Apresenta ferramenta/provider, arquitetura de recursos, módulos/parameters, plano de importação ou criação, plan resumido, custos identificáveis, segurança do state, comandos/resultados e ações que requerem aprovação.

## Referências oficiais

- https://learn.microsoft.com/azure/developer/terraform/best-practices-integration-testing
- https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices
- https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
