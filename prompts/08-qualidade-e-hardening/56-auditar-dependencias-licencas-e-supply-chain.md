# Auditar dependências, licenças e supply chain

## Objetivo

Audita a cadeia de fornecimento do repositório e, apenas em `[MODO]=corrigir`, altera componentes listados em `[LOTE_DE_ATUALIZACAO_APROVADO]` segundo `[POLITICA_DE_ATUALIZACAO]`. O modo predefinido é `auditar`.

## Critérios de sucesso

- Dependências diretas e transitivas vulneráveis estão identificadas com origem e uso.
- Packages/ações não usados e versões fora de suporte ficam classificados.
- Licenças têm compatibilidade avaliada para distribuição prevista.
- Temas, UI kits, templates, fontes, ícones, imagens e outros assets premium têm origem, titular, projeto autorizado e evidência de licença.
- Workflows usam permissões mínimas, segredos seguros e actions imutáveis.
- Existe inventário/SBOM reproduzível quando suportado.
- A build gera proveniência/attestation assinada quando a plataforma a suporta,
  ligada ao repositório, workflow, commit e digest do artefacto.

## Processo

1. Inventaria `*.csproj`, central package management, lockfiles, tools, workloads, scripts, containers, actions e assets de terceiros. Inclui materiais utilizados através do `PRODUCT_EXCELLENCE.md`, distinguindo `inspiração pública apenas` de conteúdo efetivamente incorporado.
2. Executa auditoria NuGet incluindo transitivas e ferramentas já configuradas.
3. Revê proveniência, manutenção, licença, release notes e compatibilidade antes de atualizar; regista data/hora e fonte dos advisories.
4. Revê como SBOM e attestations são gerados, assinados, armazenados e
   verificados; identifica issuer, builder identity, predicate, source SHA e
   política de confiança. Ausência de suporte fica explicitamente justificada.
5. Cria a matriz:

| Componente | Versão/origem | Uso | Vulnerabilidade/licença | Risco | Ação | Validação |
|---|---|---|---|---|---|---|

## Regras

- Não faz upgrades em massa sem necessidade; separa correções de segurança de upgrades funcionais.
- Não atualiza dependências de produção fora do lote aprovado; se o lote estiver ausente, limita-se ao relatório.
- Mantém lockfiles e central versions coerentes.
- Fixa GitHub Actions de terceiros por full commit SHA e documenta origem/renovação.
- Define `permissions` mínimas para `GITHUB_TOKEN`; prefere OIDC a segredos cloud duradouros.
- Não aceita uma attestation criada no mesmo passo mutável que altera o
  artefacto depois do digest; a proveniência tem de referenciar o conteúdo final.
- Não ignora advisories sem justificação, prazo e compensação.
- Não remove dependências exigidas apenas para obter um relatório limpo.
- Não trata compra, acesso a uma demo ou licença pessoal como autorização automática para redistribuição, conversão de framework ou utilização por toda a equipa.
- Não inventa conclusões jurídicas sobre licenças; encaminha ambiguidades.

## Validação

Após cada grupo pequeno de alterações, executa restore locked, build, testes e smoke tests afetados. Reexecuta auditorias, valida workflows e gera SBOM com ferramenta existente ou padrão suportado. Confirma que nenhum segredo entrou no diff/log.

## Entrega

Apresenta modo, data/fontes da auditoria, matriz, lote aprovado, atualizações/remoções, advisories resolvidos e aceites, registo de temas/assets premium, licenças pendentes para revisão competente, actions/permissões, SBOM, attestation/proveniência e respetiva verificação, comandos/resultados e riscos residuais.

## Referências oficiais

- https://learn.microsoft.com/nuget/concepts/auditing-packages
- https://docs.github.com/actions/security-guides/security-hardening-for-github-actions
- https://docs.github.com/code-security/supply-chain-security
- https://docs.github.com/actions/security-for-github-actions/using-artifact-attestations
- https://spdx.dev/
