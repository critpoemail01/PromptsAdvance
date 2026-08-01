# Auditar a base de dados, as migrations e a integridade

## Objetivo

Audita e corrige a camada de dados da aplicação derivada de `BoilerPlateAdvance`. Garante que o modelo EF Core, o schema, as migrations e os fluxos de escrita preservam integridade, concorrência e capacidade de atualização segura sem aplicar alterações destrutivas ou executar migrations em produção.

## Autoridade da correção

Corrige apenas discrepâncias suportadas por uma invariante aprovada, contrato existente ou defeito reproduzível. Quando nullability, retenção, delete behavior ou unicidade dependerem de decisão de produto, produz a migration/proposta apenas depois dessa decisão; não uses o modelo atual como prova automática da regra pretendida.

## Critérios de sucesso

- O modelo EF e o snapshot da última migration estão sincronizados.
- Constraints, relações, índices, tipos, valores por omissão e regras de eliminação correspondem às invariantes do domínio.
- Uma base vazia pode ser criada pelas migrations e uma base numa versão anterior representativa pode ser atualizada sem perda não autorizada.
- Escritas concorrentes, transações e repetições previsíveis têm comportamento explícito e testado.
- Existe um artefacto de implantação inspecionável e uma estratégia de rollback/recuperação para cada migration relevante.

## Preparação

1. Lê `AGENTS.md`, `README.md`, `MODULES.md`, `DbContext`, configurações de entidades, migrations, repositórios/serviços, testes e pipeline.
   Lê `REQUIREMENTS_ENGINEERING_CONTRACT.md` e
   `TEST_STRATEGY_CONTRACT.md` e liga cada invariante ao respetivo oráculo na
   matriz de testes.
2. Confirma o provider real por ambiente. A base usa EF Core/SQLite por defeito, mas não assumes que o projeto final o manteve.
3. Inventaria contextos, schemas, tabelas, dados geridos/seeding, migrations aplicadas/conhecidas e formas atuais de atualização.
4. Regista uma matriz:

| Invariante/entidade | Controlo no domínio | Controlo no schema | Concorrência/transação | Teste | Estado |
|---|---|---|---|---|---|

5. Se encontrares alterações locais de schema ainda não consolidadas, preserva-as e determina a intenção antes de gerar uma migration.

## Auditoria e correção

1. Compara o modelo atual com o snapshot e executa `dotnet ef migrations has-pending-model-changes` com os projetos corretos.
2. Revê migrations por ordem. Procura operações de perda de dados, renames modelados como drop/create, SQL dependente do provider, defaults não determinísticos e alterações incompatíveis com dados existentes.
3. Corrige constraints de chave, foreign keys, unicidade, nullability, comprimentos, precisão, check constraints, delete behavior e índices apenas quando os requisitos ou o código demonstram a regra.
4. Confirma representação consistente de datas/UTC, valores monetários, enums, identificadores e dados sensíveis.
5. Revê queries críticas para projeção, paginação, N+1, carregamento excessivo, tracking desnecessário e uso provável de índices. Mede antes de alterar por desempenho.
6. Define limites transacionais para operações que exigem atomicidade. Trata concorrência otimista e conflitos de forma explícita; evita last-write-wins acidental.
7. Torna comandos repetíveis ou idempotentes quando retries, filas, pagamentos ou timeouts podem repetir a escrita.
8. Usa `UseSeeding`/`UseAsyncSeeding` ou dados geridos apenas nos casos apropriados. Não coloques dados dinâmicos, credenciais ou grandes volumes em `HasData`.
9. Não uses `EnsureCreated` no fluxo normal de uma base relacional gerida por migrations.

## Migrations e implantação

1. Gera uma migration apenas para alterações confirmadas e revê linha a linha o código produzido.
2. Para produção, prepara um script SQL revisto, preferencialmente idempotente quando houver estados diferentes, ou um migration bundle compatível com o processo de entrega.
3. Documenta pré-condições, duração/locking esperado, compatibilidade entre versão antiga/nova da aplicação, backup necessário, verificação pós-aplicação e rollback ou roll-forward.
4. Não apliques migrations automaticamente durante o arranque de produção e não concedas ao processo normal da aplicação permissões de alteração de schema.
5. Não executes scripts contra bases partilhadas ou de produção sem autorização explícita e backup verificado.

## Testes e validação

Usa bases descartáveis e dados sem informação pessoal:

- aplicar todas as migrations desde zero;
- atualizar a partir de pelo menos uma versão anterior representativa;
- validar constraints, cascades/restrições, transações e rollback;
- provocar conflitos de concorrência;
- repetir comandos idempotentes;
- testar queries críticas com cardinalidade realista;
- confirmar isolamento e limpeza dos testes.

Executa restore, build e testes do `*.Web.slnf` com Microsoft.Testing.Platform. Regista também os comandos EF usados, o provider e a versão. Se não for possível testar o provider de produção, não generalizes resultados obtidos com SQLite ou InMemory.
Testa diferenças de tradução SQL, constraints e concorrência numa instância
descartável do provider real sempre que esses comportamentos forem materiais.

## Entrega

Apresenta fontes das invariantes, matriz de integridade, discrepâncias corrigidas, decisões bloqueantes, migrations criadas/revistas, riscos de dados, scripts ou bundles preparados, estratégia de rollback/roll-forward, testes/resultados e limitações. Distingue claramente “validado numa base descartável” de “pronto para ser autorizado em produção”.

## Referências oficiais

- https://learn.microsoft.com/ef/core/managing-schemas/migrations/applying
- https://learn.microsoft.com/ef/core/managing-schemas/migrations/managing
- https://learn.microsoft.com/ef/core/testing/testing-with-the-database
- https://learn.microsoft.com/ef/core/modeling/data-seeding
- https://learn.microsoft.com/ef/core/performance/efficient-querying
