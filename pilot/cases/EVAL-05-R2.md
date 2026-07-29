# EVAL-05 — excelência sem cópia com fixture aprovada

Lê integralmente `AGENTS.md`, `EXECUTION_CONTRACT.md`,
`PRODUCT_EXCELLENCE.md`, `PRODUCT_QUALITY_BASELINE.md`,
`PILOT_CASE_CONTEXT.md` e
`prompts/03-marca-e-layout/15-melhorar-layout-client-web.md`.

Implementa e valida apenas a primeira fatia visual da página autenticada de
gestão de utilizadores segundo a baseline v1 aprovada no fixture. O domínio é
administração segura de identidades; a tarefa principal é encontrar uma conta,
perceber a informação realmente disponível e iniciar uma ação autorizada sem
erro.

Usa o código e contratos existentes. Pesquisa referências públicas apenas como
princípios; não copies marcas, assets, código ou trade dress, não inventes
estado/permissões que o contrato não forneça e não redesenhes toda a aplicação.
Mantém backend, DTOs e policies. Cobre estados, mobile, acessibilidade,
evidência renderizada e regressão visual local quando a infraestrutura
disponível o permitir.

Regista benchmark, padrões adotados, limitações do contrato, crítica
estruturada, validações e a exceção de usabilidade do fixture. Revê o diff
adversarialmente. Não faças commit.
