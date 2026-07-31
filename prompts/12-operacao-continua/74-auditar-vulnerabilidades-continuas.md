# Auditar vulnerabilidades continuamente

## Objetivo

Executa a cadência `[CADENCIA_VULNERABILIDADES]` para código, dependências, imagens, workflows, configuração e superfícies expostas, deduplicando findings e verificando correções sem realizar exploração destrutiva.

## Processo

1. Define repositório/commit, ambientes autorizados, scanners existentes, feed/advisories, owners e SLA por severidade.
2. Recolhe dependency/code/secret/container/IaC findings dos mecanismos aprovados e preserva proveniência.
3. Valida versão afetada, reachability/exposição, compensações e falsos positivos.
4. Prioriza por impacto, explorabilidade, exposição, dados e criticidade da jornada, não apenas CVSS.
5. Para correções autorizadas, atualiza no menor lote, executa testes/regressões e confirma que o finding desaparece.
6. Findings não corrigidos exigem risco, compensação, owner, prazo e aprovação.
7. Verifica que novos commits não reintroduzem a vulnerabilidade.

## Limites

Não roda credenciais, ataca terceiros, testa produção de forma intrusiva, publica vulnerabilidades nem atualiza dependências fora do lote aprovado. Não guarda tokens ou payloads sensíveis na evidência.

## Entrega

Apresenta commit/âmbito, ferramentas/fontes, findings novos/recorrentes/resolvidos, validação/falsos positivos, SLA, correções/testes, riscos aceites e tendências.

## Referências

- https://owasp.org/www-project-application-security-verification-standard/
- https://docs.github.com/en/code-security
- https://www.cisa.gov/known-exploited-vulnerabilities-catalog

