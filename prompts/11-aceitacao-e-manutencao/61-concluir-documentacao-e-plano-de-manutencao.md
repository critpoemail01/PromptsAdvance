# Concluir documentação e plano de manutenção

## Objetivo

Entrega documentação verificável para desenvolvimento, operação, administração, suporte e utilização de `[PRODUTO]`, juntamente com ownership e cadência de manutenção. Documenta o sistema real; não copia instruções do boilerplate que deixaram de ser verdade.

## Critérios de sucesso

- Um novo colaborador consegue configurar, executar, testar e compreender a arquitetura.
- API, configuração, dados, releases, operação e recuperação têm fontes claras.
- Utilizadores/administradores têm instruções para jornadas e erros relevantes.
- Dependências, segurança, backups, certificados, domínios e lojas têm calendário/owner.
- Princípios de produto, benchmark e licenças de temas/assets incorporados têm fonte e owner.
- SLI/SLO, error budget, pós-release, triagem diária, RUM, suporte, custos, vulnerabilidades e métricas DORA têm runbook, cadência e owner.
- Links, comandos e exemplos foram validados.

## Processo

1. Inventaria `README`, `AGENTS.md`, ADRs, OpenAPI, `.docs`, runbooks, release notes e comentários operacionais.
2. Classifica conteúdo como correto, obsoleto, duplicado, ausente ou não verificável.
3. Mantém `AGENTS.md` curto e orientado a trabalho; coloca explicações profundas na documentação adequada.
4. Cria um mapa `necessidade → documento → proprietário → revisão`.
5. Antes de remover ou arquivar documentação, confirma referências e preserva conteúdo único num destino explícito. Não elimines informação apenas por estar desatualizada se ainda não existir substituto validado.

## Conteúdo mínimo

- visão, arquitetura e módulos selecionados;
- setup local, configuração sem segredos e comandos reais;
- desenvolvimento, migrations, testes e troubleshooting;
- API/contratos e integrações;
- deployment, rollback, observabilidade, incidentes e DR;
- SLI/SLO/error budget e política de consumo; verificações pós-release a 30 minutos, 24 horas e 7 dias;
- triagem operacional diária, Core Web Vitals/RUM, bugs/feedback de suporte, custos/anomalias, vulnerabilidades contínuas e métricas DORA;
- documentação separada para utilização, administração, desenvolvimento, operação e suporte, sem misturar instruções privilegiadas com conteúdo público;
- changelog/release notes e política de depreciação;
- princípios de experiência do `PRODUCT_EXCELLENCE.md`, referências adotadas e registo de licenças, sem redistribuir material premium;
- calendário de dependências, vulnerabilidades, certificados, backups e revisão legal.

## Validação

Executa ou confirma comandos, verifica caminhos/links, gera OpenAPI quando aplicável e faz uma passagem de onboarding limpa sem conhecimento implícito. Confirma que cada fluxo operacional tem consulta read-only, limiar, owner, escalamento, autoridade corretiva e evidência guardada. Não coloca credenciais, endpoints privados ou dados pessoais em documentação versionada.

## Entrega

Apresenta documentos criados/atualizados por audiência, mapa de ownership, comandos validados, conteúdo preservado/removido/arquivado e respetivo destino, lacunas e plano de manutenção com cadência e responsáveis. Atualiza o manifesto de evidência de `IMPLEMENTATION_STATUS.md` para a candidata que seguirá para os prompts 62 e 63.

## Referências oficiais

- https://learn.microsoft.com/contribute/content/
- https://spec.openapis.org/oas/latest.html
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
