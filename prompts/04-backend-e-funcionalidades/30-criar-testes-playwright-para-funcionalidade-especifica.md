# Criar testes Playwright para uma funcionalidade específica

## Objetivo

Implementa exatamente um teste Playwright primário independente por cada
`RF-P` de `[FUNCIONALIDADE]`, além dos cenários suplementares exigidos por
`[CRITERIOS_DE_ACEITACAO]`. Executa cada requisito Web nos projetos `mobile`,
`tablet` e `desktop`, aplica `TEST_STRATEGY_CONTRACT.md` e cobre a jornada
completa, efeitos persistidos e recuperação. Inclui apenas integrações
autorizadas em sandbox/fake; nunca executa efeitos reais.

## Critérios de sucesso

- Happy path e riscos críticos têm cenários independentes e rastreáveis.
- Autorizações por função e por objeto são exercitadas pela UI e confirmadas no resultado.
- Repetição, concorrência, cancelamento e idempotência são cobertos quando o fluxo os permite.
- O teste prova o efeito final, não apenas a existência de uma mensagem de sucesso.
- Falhas produzem diagnóstico suficiente sem expor segredos.
- Estados visuais estáveis e acessibilidade automática da jornada bloqueiam regressões em CI.
- A matriz contém um resultado executado por `RF-P × mobile/tablet/desktop`;
  nenhum requisito está agregado, omitido, `skip` ou `fixme`.

## Preparação

1. Mapeia a jornada `precondição → ações → API/jobs/integrações → estado final`.
2. Identifica atores, dados, invariantes, efeitos externos, tempos assíncronos e compensações.
3. Decide o que é melhor validado por unitário, integração ou Playwright; evita duplicação sem valor.
4. Define cenários positivos, negativos e de recuperação numa matriz com prioridade de risco.
5. Reconcilia `quality/TEST_MATRIX.md`; lacunas de provider, contrato,
   arquitetura, performance ou resiliência ficam no nível/lane proprietário.
6. Atualiza `quality/PLAYWRIGHT_REQUIREMENTS_COVERAGE.md` com o teste primário,
   oráculo e resultados de cada `RF-P` nos três projetos.

## Implementação

- Prepara dados isolados por fixtures/APIs de teste e limpa apenas recursos próprios.
- Usa contas de teste por papel/permissão, nunca utilizadores reais.
- Usa locators acessíveis e assertions web-first.
- Inclui o ID `RF-P` no título/tag/trait/metadata de exatamente um teste
  primário; um teste primário não cobre dois requisitos.
- Para trabalho assíncrono, espera por um estado observável com timeout explícito; não usa sleeps fixos.
- Valida efeitos persistidos e ausência de efeitos em falha, incluindo operações duplicadas.
- Substitui email, SMS, push, pagamentos, armazenamento ou outros fornecedores por fakes/sandboxes previstos na infraestrutura.
- Substitui também o player/API de vídeo externo; valida o `VID` correto,
  artigo relacionado, captions/transcrição disponíveis, fallback e progresso
  idempotente sem interpretar um evento do player como prova de aprendizagem.
- Recolhe trace/vídeo/screenshot segundo a política existente e redige valores sensíveis.
- Para estados visualmente estáveis, compara snapshots aprovados de
  mobile/tablet/desktop, temas suportados e normal/loading/vazio/erro/conteúdo
  longo num ambiente fixo; publica o diff e nunca atualiza a baseline sem
  `[AUTORIZAR_ALTERACAO_DE_BASELINE_VISUAL]`.
- Executa checks automáticos de acessibilidade e regista a avaliação manual da jornada crítica.
- Não alteres o comportamento da aplicação para facilitar o teste. Limita alterações de produto a seams/fakes e identificadores estáveis semânticos estritamente necessários, revendo que não ficam backdoors de teste em produção.

## Validação

Executa os testes focados em `mobile`, `tablet` e `desktop`, repete-os sob a
mesma seed/ambiente, corre a suite da feature e verifica paralelismo. Reconcilia
automaticamente todos os `RF-P` da funcionalidade com os testes descobertos e
o relatório dos três projetos. Provoca pelo menos uma falha funcional, uma
diferença visual e uma violação automática de acessibilidade controladas para
confirmar que o diagnóstico e os gates funcionam; reverte-as depois. Reporta
dependências que impedem execução local ou CI em vez de usar `skip`/`fixme`.
Confirma as resoluções aprovadas ou os defaults `390×844`, `768×1024` e
`1440×900`, incluindo largura e altura no relatório.

## Entrega

Apresenta o mapa `RF-P → teste primário → mobile/tablet/desktop → resultado`,
mapa da jornada, matriz de riscos/cenários/níveis, ficheiros de teste e seams,
fixtures, clock/seed/locale/timezone, comandos/resultados, duração, artefactos,
flakiness com owner/prazo e cobertura nativa/API complementar. Não declares
cobertura total fora dos requisitos e critérios efetivamente executados.

## Referências oficiais

- https://playwright.dev/docs/best-practices
- https://playwright.dev/dotnet/docs/test-assertions
- https://playwright.dev/dotnet/docs/trace-viewer
- https://playwright.dev/docs/test-snapshots
- https://playwright.dev/docs/test-projects
- https://www.w3.org/WAI/test-evaluate/
- https://owasp.org/www-project-web-security-testing-guide/
