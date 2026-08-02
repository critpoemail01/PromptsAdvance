[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$failures = [System.Collections.Generic.List[string]]::new()
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) {
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    $powerShellExe = $pwshCommand.Source
}
if ([string]::IsNullOrWhiteSpace([string]$powerShellExe)) {
    throw 'PowerShell executable was not found.'
}

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Require-Pattern {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Description
    )

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Ficheiro obrigatorio ausente: $RelativePath"
        return
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if ($content -notmatch $Pattern) {
        Add-Failure "$Description ($RelativePath)"
    }
}

function Forbid-Pattern {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Description
    )

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Ficheiro obrigatorio ausente: $RelativePath"
        return
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if ($content -match $Pattern) {
        Add-Failure "$Description ($RelativePath)"
    }
}

$requiredDocuments = @(
    'START_HERE.md',
    'PROCESS_MANIFEST.json',
    'QUALITY_GATES.md',
    'README.md',
    'AGENTS.md',
    'EXECUTION_CONTRACT.md',
    'UPSTREAM_LEARNING.md',
    'CHANGE_CONTROL.md',
    'CLAUDE.md',
    'PRODUCT_EXCELLENCE.md',
    'REQUIREMENTS_ENGINEERING_CONTRACT.md',
    'HELP_AND_ACADEMY.md',
    'PRODUCT_DEFINITION.md',
    'PRODUCT_QUALITY_BASELINE.md',
    'VISUAL_SLICE_CONTRACT.md',
    'TEST_STRATEGY_CONTRACT.md',
    'APP_CONTEXT.md',
    'IMPLEMENTATION_STATUS.md',
    'LIFECYCLE_GATE_EVIDENCE.json',
    'PILOT_APPROVAL.md',
    'PROMPT_EVALUATION.md',
    'EVALUATION_IMPACT_MAP.json'
)

$requiredScripts = @(
    'scripts/Test-ProductDefinitionGate.ps1',
    'scripts/Test-ImplementationReadinessGate.ps1',
    'scripts/Test-Prompt02PilotArtifact.ps1',
    'scripts/Test-Prompt03PilotArtifact.ps1',
    'scripts/Test-PromptReferences.ps1',
    'scripts/Test-LifecycleGateEvidence.ps1',
    'scripts/Test-ProductQualityGate.ps1',
    'scripts/Test-SoftwareLifecycle.ps1',
    'scripts/Test-LifecycleMigration.ps1',
    'scripts/Test-ProcessInDisposableCopy.ps1',
    'scripts/Get-PromptEvaluationScope.ps1',
    'software-lifecycle.ps1'
)

foreach ($relativePath in $requiredDocuments) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf)) {
        Add-Failure "Documento obrigatorio ausente: $relativePath"
    }
}

foreach ($relativePath in $requiredScripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf)) {
        Add-Failure "Script obrigatorio ausente: $relativePath"
    }
}

Require-Pattern 'scripts/Test-ProcessInDisposableCopy.ps1' "catalogItem\.Name -eq '\.git'" 'A copia descartavel nao exclui explicitamente os metadados Git da origem.'
Require-Pattern 'scripts/Test-ProcessInDisposableCopy.ps1' 'must not inherit source Git metadata' 'A copia descartavel nao verifica a ausencia de metadados Git herdados.'
foreach ($portablePath in @(
    'APP_CONTEXT.md',
    'README.md',
    'START_HERE.md',
    'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md',
    'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md',
    'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md',
    'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md'
)) {
    Forbid-Pattern $portablePath 'C:\\Work\\BoilerPlateAdvance' 'Um documento ou prompt ativo conserva um caminho Windows fixo para o boilerplate.'
}

$promptRoot = Join-Path $root 'prompts'
$promptFiles = @(Get-ChildItem -LiteralPath $promptRoot -Recurse -File -Filter '*.md')
if ($promptFiles.Count -ne 76) {
    Add-Failure "Esperados 76 prompts; encontrados $($promptFiles.Count)."
}

$numbers = foreach ($file in $promptFiles) {
    if ($file.Name -notmatch '^(\d{2})-') {
        Add-Failure "Nome sem prefixo numerico: $($file.FullName)"
        continue
    }
    [int]$Matches[1]
}

$duplicates = @($numbers | Group-Object | Where-Object Count -gt 1)
foreach ($duplicate in $duplicates) {
    Add-Failure "Numero de prompt duplicado: $($duplicate.Name)"
}

foreach ($expected in 1..76) {
    if ($expected -notin $numbers) {
        Add-Failure "Numero de prompt em falta: $expected"
    }
}

$manifestPath = Join-Path $root 'PROCESS_MANIFEST.json'
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
        if ([int]$manifest.promptCount -ne 76) {
            Add-Failure "PROCESS_MANIFEST.json declara $($manifest.promptCount) prompts em vez de 76."
        }
        $manifestPromptIds = @($manifest.stages | ForEach-Object { @($_.promptIds) })
        foreach ($expected in 1..76 | ForEach-Object { '{0:D2}' -f $_ }) {
            if ($expected -notin $manifestPromptIds) {
                Add-Failure "Prompt $expected ausente do PROCESS_MANIFEST.json."
            }
        }
        $manifestDuplicates = @($manifestPromptIds | Group-Object | Where-Object Count -gt 1)
        foreach ($duplicate in $manifestDuplicates) {
            Add-Failure "Prompt duplicado no PROCESS_MANIFEST.json: $($duplicate.Name)"
        }
        if ([string]$manifest.releaseChannel -notin @('candidate', 'stable')) {
            Add-Failure "PROCESS_MANIFEST.json tem releaseChannel invalido: $($manifest.releaseChannel)."
        }
        $profileIds = @($manifest.promptExecutionProfiles.deep) + @($manifest.promptExecutionProfiles.fast)
        foreach ($profileId in $profileIds) {
            if ([string]$profileId -notin $manifestPromptIds) {
                Add-Failure "Perfil de execucao referencia prompt inexistente: $profileId"
            }
        }
        foreach ($duplicateProfileId in @($profileIds | Group-Object | Where-Object Count -gt 1)) {
            Add-Failure "Prompt aparece em mais de um perfil de execucao: $($duplicateProfileId.Name)"
        }
        foreach ($contextDocument in @($manifest.contextRouting.always)) {
            if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$contextDocument)) -PathType Leaf)) {
                Add-Failure "Routing de contexto obrigatorio referencia documento inexistente: $contextDocument"
            }
        }
        foreach ($contextGroup in @($manifest.contextRouting.groups)) {
            foreach ($contextPromptId in @($contextGroup.promptIds)) {
                if ([string]$contextPromptId -notin $manifestPromptIds) {
                    Add-Failure "Routing de contexto '$($contextGroup.name)' referencia prompt inexistente: $contextPromptId"
                }
            }
            foreach ($contextDocument in @($contextGroup.documents)) {
                if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$contextDocument)) -PathType Leaf)) {
                    Add-Failure "Routing de contexto '$($contextGroup.name)' referencia documento inexistente: $contextDocument"
                }
            }
        }
    }
    catch {
        Add-Failure "PROCESS_MANIFEST.json invalido: $($_.Exception.Message)"
    }
}

$catalogMarkdownRoots = @(
    (Join-Path $root '.agents'),
    (Join-Path $root 'pilot'),
    (Join-Path $root 'prompts'),
    (Join-Path $root 'plugins')
)
$markdownFiles = @(
    Get-ChildItem -LiteralPath $root -File -Filter '*.md'
    foreach ($catalogMarkdownRoot in $catalogMarkdownRoots) {
        if (Test-Path -LiteralPath $catalogMarkdownRoot -PathType Container) {
            Get-ChildItem -LiteralPath $catalogMarkdownRoot -Recurse -File -Filter '*.md'
        }
    }
) | Sort-Object FullName -Unique
$linkPattern = [regex]'\[[^\]]*\]\(([^)]+)\)'
foreach ($file in $markdownFiles) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    foreach ($match in $linkPattern.Matches($content)) {
        $target = $match.Groups[1].Value.Trim('<', '>')
        if ($target -match '^(https?://|mailto:|#)') {
            continue
        }

        $pathPart = ($target -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) {
            continue
        }

        try {
            $resolved = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathPart))
        }
        catch {
            Add-Failure "Link local invalido: $($file.FullName) -> $target"
            continue
        }
        if (-not (Test-Path -LiteralPath $resolved)) {
            Add-Failure "Link local quebrado: $($file.FullName) -> $target"
        }
    }
}

$contextPath = Join-Path $root 'APP_CONTEXT.md'
if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
    $context = Get-Content -Raw -Encoding UTF8 -LiteralPath $contextPath
    $placeholderPattern = [regex]'\[([^\]\r\n]+)\]'
    $placeholderCharacters = '^[A-Z0-9_\/., :\-\u00C0-\u00DE]+$'
    $placeholders = foreach ($file in $markdownFiles) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        foreach ($match in $placeholderPattern.Matches($content)) {
            $endIndex = $match.Index + $match.Length
            if ($endIndex -lt $content.Length -and $content[$endIndex] -eq '(') {
                continue
            }
            if ($match.Groups[1].Value -cmatch $placeholderCharacters) {
                $match.Value
            }
        }
    }

    foreach ($placeholder in @($placeholders | Sort-Object -Unique)) {
        if (-not $context.Contains($placeholder)) {
            Add-Failure "Placeholder sem declaracao literal em APP_CONTEXT.md: $placeholder"
        }
    }
}

Require-Pattern 'README.md' 'fatias verticais' 'O README nao define implementacao iterativa por fatias verticais.'
Require-Pattern 'README.md' '(?s)^# AdvanceAppFlow.*identificadores t.cnicos.*`promptsadvance`.*`advance-app`.*`\$advance-app-start`.*`\$advance-app-continue`' 'O README nao apresenta AdvanceAppFlow nem a compatibilidade dos IDs tecnicos.'
Require-Pattern 'CLAUDE.md' '^@AGENTS\.md' 'CLAUDE.md nao importa as instrucoes comuns.'
Require-Pattern '.github/workflows/process-validation.yml' 'actions/checkout@[a-f0-9]{40}' 'A CI do catalogo nao fixa checkout por full commit SHA.'
Require-Pattern '.github/workflows/process-validation.yml' '(?s)Test-PromptProcess\.ps1.*Test-SoftwareLifecycle\.ps1' 'A CI nao executa validacao estatica e lifecycle E2E.'
Require-Pattern 'START_HERE.md' '\$advance-app-start' 'START_HERE nao fornece o ponto de entrada para iniciar uma app.'
Require-Pattern 'START_HERE.md' '\$advance-app-continue' 'START_HERE nao fornece o ponto de entrada para continuar uma app.'
Require-Pattern 'START_HERE.md' 'codex plugin marketplace add critpoemail01/AdvanceAppFlow' 'START_HERE nao documenta a instalacao global do marketplace AdvanceAppFlow.'
Require-Pattern 'START_HERE.md' 'codex plugin add advance-app@promptsadvance' 'START_HERE nao documenta a instalacao global do plugin.'
Require-Pattern 'START_HERE.md' 'software-lifecycle\.ps1 start' 'START_HERE nao fornece inicializacao deterministica.'
Require-Pattern 'START_HERE.md' 'Continua o projeto Advance em' 'START_HERE nao fornece a entrada natural para continuar por caminho.'
Require-Pattern 'START_HERE.md' 'software-lifecycle\.ps1 continue.*-ProjectPath' 'START_HERE nao documenta a resolucao brownfield por caminho.'
Require-Pattern 'QUALITY_GATES.md' 'G04.*Dire..o profissional' 'Falta o gate profissional da primeira slice.'
Require-Pattern 'QUALITY_GATES.md' 'Hierarquia e composi..o' 'O gate visual nao verifica hierarquia e composicao.'
Require-Pattern 'QUALITY_GATES.md' 'rastreabilidade ponta a ponta' 'O gate de codigo nao exige rastreabilidade ponta a ponta.'
Require-Pattern 'AGENTS.md' 'REQUIREMENTS_ENGINEERING_CONTRACT\.md.*VISUAL_SLICE_CONTRACT\.md.*TEST_STRATEGY_CONTRACT\.md' 'O routing duradouro nao inclui os novos contratos de qualidade.'
Require-Pattern 'AGENTS.md' '(?s)(?=.*sempre que alterares qualquer\s+parte do processo)(?=.*depois das valida..es do processo)(?=.*cachebuster oficial)(?=.*valida o plugin e as skills)(?=.*codex plugin add advance-app@promptsadvance)(?=.*codex plugin list)(?=.*installed, enabled)(?=.*n.o autoriza\s+commit nem push)(?=.*`commit e sync`)(?=.*nico cachebuster antes do commit)(?=.*sem force push)(?=.*n.o volta a disparar)(?=.*segundo bump ou commit vazio)(?=.*tarefa nova)(?=.*parcial)(?=.*working tree limpa)' 'O projeto nao obriga toda alteracao do processo a atualizar e verificar a tool Advance sem recursao.'
Require-Pattern 'README.md' '(?s)qualquer altera..o ao processo termina com a atualiza..o da\s+tool Advance.*cachebuster oficial.*plugin e skills.*codex plugin add advance-app@promptsadvance.*installed, enabled.*n.o cria autoriza..o\s+para commit ou push.*`commit e sync`.*nico cachebuster.*depois do push.*n.o existe segundo bump ou commit vazio.*task nova' 'O README nao documenta a atualizacao automatica da tool depois de qualquer alteracao do processo.'
Require-Pattern 'PROCESS_MANIFEST.json' '"advanceToolUpdateAfterProcessChangeRequired": true' 'O manifesto nao declara a atualizacao obrigatoria da tool apos qualquer alteracao do processo.'
Require-Pattern 'PROCESS_MANIFEST.json' '"advanceToolUpdateAfterCommitSyncRequired": true' 'O manifesto nao declara a atualizacao obrigatoria da tool apos commit/sync.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)"upstreamLearningAfterApplicationCorrectionRequired": true.*"systemicCorrectionRequiresRegressionTest": true.*"applicationSpecificCorrectionMustNotMutateCatalog": true' 'O manifesto nao declara aprendizagem upstream segura depois de correcoes.'
Require-Pattern 'AGENTS.md' '(?s)UPSTREAM_LEARNING\.md.*corrige primeiro a\s+aplica..o.*erros\s+sist.micos.*regress.o.*n.o autoriza Git' 'As instrucoes nao obrigam revisao de recorrencia e generalizacao segura.'
Require-Pattern 'UPSTREAM_LEARNING.md' '(?s)(?=.*advanceappflow_systemic)(?=.*boilerplate_systemic)(?=.*application_specific)(?=.*unknown)(?=.*Corrige primeiro)(?=.*corre..o generalizada)(?=.*regress.o)(?=.*ADVANCEAPPFLOW_UPSTREAM_FEEDBACK\.md)(?=.*Nunca copies)(?=.*n.o autoriza commit, push)' 'O contrato upstream nao cobre classificacao, fallback, privacidade, regressao e autorizacoes.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-02-UPSTREAM(?=.*duas aplica..es descart.veis)(?=.*advanceappflow_systemic)(?=.*application_specific)(?=.*falha antes e passa depois)(?=.*checkout instalado)(?=.*altera..o concorrente)(?=.*ADVANCEAPPFLOW_UPSTREAM_FEEDBACK\.md)(?=.*n.o edita o cache)(?=.*commit, push, PR)' 'A avaliacao nao prova aprendizagem upstream sem contaminar o catalogo.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-02-SYNC(?=.*sem autorizar commit ou push)(?=.*depois das valida..es)(?=.*valide plugin e skills)(?=.*codex plugin add advance-app@promptsadvance)(?=.*codex plugin list)(?=.*installed, enabled)(?=.*n.o faz commit/push)(?=.*SoftwareProcesses)(?=.*Update-AdvanceLocalProjects\.ps1)(?=.*prompt deslocado)(?=.*tentativa ativa)(?=.*marcador de\s+recupera..o)(?=.*`commit e sync`)(?=.*nico cachebuster antes do commit)(?=.*mesmo SHA)(?=.*sem\s+force push)(?=.*depois do push)(?=.*n.o dispara outro bump)(?=.*segundo commit vazio)(?=.*parcial)(?=.*tarefa nova)' 'A avaliacao nao cobre atualizacao da tool, propagacao local e commit/sync sem recursao.'
Require-Pattern 'EVALUATION_IMPACT_MAP.json' '(?s)lifecycle-and-common-contract.*"cases": \["EVAL-02", "EVAL-03", "EVAL-04", "EVAL-11", "EVAL-12", "EVAL-13"\]' 'Alteracoes ao contrato comum nao selecionam EVAL-02-SYNC.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)"sliceWorkflows".*"page".*"implementationPrompt": "27".*"requirementsReconciliationPrompt": "20".*"acceptanceTestPrompt": "28".*"feature".*"implementationPrompt": "29".*"acceptanceTestPrompt": "30"' 'O manifesto nao conserva o routing semantico das fatias.'
Require-Pattern 'REQUIREMENTS_ENGINEERING_CONTRACT.md' '(?s)(?=.*tabela de\s+decis.o)(?=.*tabela de transi..es)(?=.*Est.mulo)(?=.*Medida/toler.ncia)(?=.*Rastreabilidade orientada ao risco)' 'O contrato de requisitos nao cobre decisoes, estados, NFR e risco-oraculo.'
Require-Pattern 'VISUAL_SLICE_CONTRACT.md' '(?s)duas ou tr.s alternativas de baixa fidelidade.*Decidir.*Implementar.*matriz responsiva' 'O contrato visual nao exige exploracao, decisao e responsividade verificavel.'
Require-Pattern 'TEST_STRATEGY_CONTRACT.md' '(?s)Unit.rio.*Componente.*Integra..o/provider real.*Contrato/compatibilidade.*Browser/nativo.*Lane.*Flakiness.*Failure modes' 'O contrato de testes nao cobre niveis, lanes, flakiness e failure modes.'
Require-Pattern '.agents/skills/advance-app-start/SKILL.md' '(?s)^---.*name: advance-app-start.*description:.*---' 'A skill de criacao do lifecycle nao tem frontmatter valido.'
Require-Pattern '.agents/skills/advance-app-start/SKILL.md' 'software-lifecycle\.ps1 start' 'A skill de criacao nao executa o inicializador deterministico.'
Require-Pattern '.agents/skills/advance-app-start/SKILL.md' '(?s)software-lifecycle\.ps1 record.*Summary.*RemainingWork' 'A skill de criacao nao fecha o prompt com resultado e trabalho em falta.'
Require-Pattern '.agents/skills/advance-app-start/SKILL.md' 'Do not execute prompt 02.*do not prepare' 'A skill de criacao pode ultrapassar o prompt 01.'
Require-Pattern '.agents/skills/advance-app-start/agents/openai.yaml' 'display_name: "Advance App Start"' 'A skill de criacao nao tem nome visivel proprio.'
Require-Pattern '.agents/skills/advance-app-start/agents/openai.yaml' 'default_prompt: "Use \$advance-app-start' 'A skill de criacao nao tem prompt explicito de invocacao.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)^---.*name: advance-app-continue.*description:.*---' 'A skill do lifecycle nao tem frontmatter valido.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' 'software-lifecycle\.ps1 record' 'A skill nao regista resultados no estado do lifecycle.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' 'continue -ProjectPath' 'A skill nao resolve continuacao/adocao a partir da raiz da aplicacao.'
Forbid-Pattern '.agents/skills/advance-app-continue/SKILL.md' '## Start a new initiative|software-lifecycle\.ps1 start -Name' 'A skill de continuacao voltou a acumular a criacao de iniciativas.'
Require-Pattern '.agents/skills/advance-app-continue/references/workflow.md' 'page: 27 -> 14\|16\|18 -> 20 -> 28' 'A skill nao define routing de vertical slices.'
Require-Pattern '.agents/skills/advance-app-continue/references/workflow.md' 'Test-PromptReferences\.ps1' 'A skill nao identifica o validador semantico do routing.'
Require-Pattern '.agents/plugins/marketplace.json' '"name": "promptsadvance"' 'O marketplace Advance nao tem identidade estavel.'
Require-Pattern '.agents/plugins/marketplace.json' '"displayName": "AdvanceAppFlow"' 'O marketplace nao apresenta a identidade visivel AdvanceAppFlow.'
Require-Pattern '.agents/plugins/marketplace.json' '"path": "\./plugins/advance-app"' 'O marketplace Advance nao aponta para o plugin empacotado.'
Require-Pattern '.agents/plugins/marketplace.json' '(?s)"installation": "AVAILABLE".*"authentication": "ON_INSTALL"' 'O marketplace Advance nao declara as politicas de instalacao.'
Require-Pattern 'plugins/advance-app/.codex-plugin/plugin.json' '"name": "advance-app"' 'O plugin Advance nao tem nome canonico.'
Require-Pattern 'plugins/advance-app/.codex-plugin/plugin.json' '"version": "0\.1\.0(?:\+codex\.[0-9A-Za-z.-]+)?"' 'O plugin Advance nao tem versao semantica/cachebuster valida.'
Require-Pattern 'plugins/advance-app/.codex-plugin/plugin.json' '"skills": "\./skills/"' 'O plugin Advance nao expoe as skills empacotadas.'
Require-Pattern 'plugins/advance-app/.codex-plugin/plugin.json' '"displayName": "AdvanceAppFlow"' 'O plugin Advance nao apresenta a identidade visivel AdvanceAppFlow.'
Require-Pattern 'plugins/advance-app/.codex-plugin/plugin.json' '(?s)"homepage": "https://github.com/critpoemail01/AdvanceAppFlow".*"repository": "https://github.com/critpoemail01/AdvanceAppFlow".*"websiteURL": "https://github.com/critpoemail01/AdvanceAppFlow"' 'O plugin nao aponta para o repositorio AdvanceAppFlow.'
Require-Pattern 'plugins/advance-app/skills/advance-app-start/SKILL.md' '(?s)^---.*name: advance-app-start.*description:.*---' 'O plugin nao expoe a skill global de criacao.'
Require-Pattern 'plugins/advance-app/skills/advance-app-start/SKILL.md' 'Resolve-AdvanceCatalog\.ps1' 'A skill global de criacao nao resolve o catalogo instalado.'
Require-Pattern 'plugins/advance-app/skills/advance-app-start/SKILL.md' '\.agents/skills/advance-app-start/SKILL\.md' 'A skill global de criacao nao delega na fonte canonica.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/SKILL.md' '(?s)^---.*name: advance-app-continue.*description:.*---' 'O plugin nao expoe a skill global de continuacao.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/SKILL.md' '\.agents/skills/advance-app-continue/SKILL\.md' 'A skill global de continuacao nao delega na fonte canonica.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)UPSTREAM_LEARNING\.md.*advanceappflow_systemic.*boilerplate_systemic.*application_specific.*unknown.*ADVANCEAPPFLOW_UPSTREAM_FEEDBACK\.md' 'A skill canonica nao aprende com correcoes da aplicacao.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/SKILL.md' '(?s)UPSTREAM_LEARNING\.md.*PreferDevelopmentClone.*generalized.*regression.*pending upstream feedback' 'A skill global nao encaminha a aprendizagem para um clone seguro.'
Require-Pattern 'plugins/advance-app/scripts/Resolve-AdvanceCatalog.ps1' '(?s)Test-AdvanceDevelopmentCatalog.*UPSTREAM_LEARNING\.md.*plugins/advance-app/\.codex-plugin/plugin\.json.*marketplaces.*PreferDevelopmentClone.*Documents/AdvanceAppFlow' 'O resolver nao separa um clone de desenvolvimento do cache/instancia quando corrige upstream.'
Require-Pattern 'plugins/advance-app/scripts/Resolve-AdvanceCatalog.ps1' 'PROMPTS_ADVANCE_ROOT' 'O plugin nao suporta configuracao explicita da raiz do catalogo.'
Require-Pattern 'plugins/advance-app/scripts/Resolve-AdvanceCatalog.ps1' '\.codex/\.tmp/marketplaces/promptsadvance' 'O plugin nao resolve o checkout instalado do marketplace.'
Require-Pattern 'plugins/advance-app/scripts/Resolve-AdvanceCatalog.ps1' '(?s)Documents/AdvanceAppFlow.*AdvanceAppFlow.*Documents/PromptsAdvance.*PromptsAdvance' 'O resolver nao prefere AdvanceAppFlow mantendo fallback para o nome anterior.'
Require-Pattern 'PROCESS_MANIFEST.json' '"name": "AdvanceAppFlow . Professional Advance \.NET Software Lifecycle"' 'O manifesto nao usa a identidade publica AdvanceAppFlow.'
Require-Pattern 'EXECUTION_CONTRACT.md' 'provider de documenta.*Context7' 'O contrato comum nao exige documentacao atual e versionada para APIs e SDKs.'
Require-Pattern 'EXECUTION_CONTRACT.md' 'connector/plugin oficial ou `gh`' 'O contrato comum nao define routing seguro para contexto GitHub.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'skill `playwright-cli`' 'O prompt 08 nao documenta a automacao de browser disponivel para o Codex.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'Context7; preserva biblioteca' 'O prompt 08 nao encaminha documentacao atual de bibliotecas.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'MCPs, plugins, hooks ou skills globais' 'O prompt 08 permite alterar capacidades globais sem proveniencia e opt-in.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'segundo framework de lifecycle' 'O prompt 08 nao impede metodologias concorrentes com Advance.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'CODEX_LAYOUT_TOOLING\.md' 'O prompt 08 nao conserva a decisao sobre ferramentas de layout.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'lacuna . candidato . fonte/vers.o . compatibilidade . licen.a . permiss.es/dados/telemetria' 'O prompt 08 nao exige uma comparacao auditavel das ferramentas de layout.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'Recomenda no m.ximo tr.s ferramentas' 'O prompt 08 pode instalar um conjunto ilimitado de ferramentas de layout.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' '\[AUTORIZAR_FERRAMENTAS_LAYOUT\]' 'O prompt 08 nao exige autorizacao nominal antes de configurar ferramentas de layout.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/08-otimizar-codex-e-projeto.md' 'Figma MCP e Code Connect.*Figma for fonte de verdade' 'O prompt 08 trata Figma como dependencia universal.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' 'CODEX_LAYOUT_TOOLING\.md' 'O prompt 13 nao recebe o handoff das ferramentas de layout.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' 'decis.o `manter\|remover`' 'O prompt 13 nao decide ferramentas de layout com evidencia da primeira slice.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)App\.Client\.Ssr.*App\.Client\.Web.*App\.Cliente\.Web.*App\.Client\.Maui.*TagLyght\.Client\.Maui' 'O prompt 13 nao cobre explicitamente as tres aplicacoes cliente SSR, Web e MAUI.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)Pesquisa online obrigat.ria.*cada uma das nove dire..es.*template, tema ou UI kit pago premium.*live preview p.blico.*aplica..es concorrentes/compar.veis.*inspira..o complementar' 'O prompt 13 nao usa templates premium como base das nove direcoes e rivais apenas como complemento.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*URL oficial)(?=.*Pre.o/licen.a/limite)(?=.*N.o compres)(?=.*n.o confi.vel)' 'O prompt 13 nao controla proveniencia, licenca, compra e prompt injection na pesquisa premium.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)Server\.Api.*n.o . uma aplica..o visual.*n.o recebe uma\s+proposta de layout.*n.o inventes.*quarta superf.cie' 'O prompt 13 ainda trata Server.Api como uma quarta aplicacao visual.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)INITIAL_LAYOUT_RESEARCH\.md.*INITIAL_LAYOUT_SPEC\.md.*INITIAL_LAYOUT_CRITIQUE\.md' 'O prompt 13 nao conserva research, direcao e critica em artefactos duraveis.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)tarefa separada e read-only de cr.tica de Product Design/UX.*findings cr.ticos e altos.*volta a renderizar' 'O prompt 13 nao exige critica de design separada e correcao antes da entrega.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)autocr.tica n.o independente.*termina `parcial`.*ignorar e avan.ar' 'O prompt 13 apresenta autorrevisao como parecer profissional ou torna o gate consultivo num bloqueio rigido.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*Decis.o obrigat.ria quando j. existe layout)(?=.*`novo do zero`)(?=.*`melhorar existente`)(?=.*n.o alteres ficheiros)(?=.*Queres eliminar a camada visual)(?=.*melhorar o layout existente)(?=.*`pr.ximo`.*n.o contam)' 'O prompt 13 nao pede uma escolha clara antes de alterar um layout existente.'
Require-Pattern 'PROCESS_MANIFEST.json' 'existingLayoutResetOrImproveDecisionRequired.*true' 'O manifesto nao conserva a decisao obrigatoria do prompt 13.'
Require-Pattern 'PROCESS_MANIFEST.json' 'visualDirectionOptionsPerClient.*3' 'O manifesto nao fixa tres direcoes visuais por aplicacao cliente.'
Require-Pattern 'PROCESS_MANIFEST.json' 'visualDirectionSelectionPerClientRequired.*true' 'O manifesto nao exige a escolha visual por aplicacao antes da implementacao.'
Require-Pattern 'PROCESS_MANIFEST.json' 'visualPreviewLinkPerDirectionRequired.*true' 'O manifesto nao exige um preview visual clicavel por direcao.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)premiumTemplatePrimaryBasisPerVisualDirectionRequired.*true.*competitorVisualReferencesSupplementaryOnly.*true' 'O manifesto nao declara templates premium como base e rivais apenas como complemento.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)INITIAL_LAYOUT_DECISION\.md.*resposta/fonte do programador.*tr.s aplica..es cliente.*remo..o integral.*nova escolha expl.cita' 'O prompt 13 nao conserva a escolha nem impede converter melhoria em reset silencioso.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*exatamente tr.s dire..es.*cada aplica..o)(?=.*nove propostas)(?=.*SSR-1.*SSR-2.*SSR-3)(?=.*WEB-1.*WEB-2.*WEB-3)(?=.*MAUI-1.*MAUI-2.*MAUI-3)(?=.*template premium base)(?=.*p.gina de\s+produto/licen.a)(?=.*rival/compar.vel opcional)' 'O prompt 13 nao cria nove direcoes baseadas em templates premium com rivais opcionais.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*tr.s tabelas curtas)(?=.*Recomenda exatamente uma op..o por aplica..o)(?=.*Escolhe uma dire..o visual para cada aplica..o)(?=.*usar as tr.s recomendadas)(?=.*INITIAL_LAYOUT_DIRECTIONS\.md)' 'O prompt 13 nao apresenta e recomenda tres opcoes claras para SSR, Web e MAUI.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*Links de preview obrigat.rios)(?=.*aplica..o online.*p.gina p.blica, demo)(?=.*template.*live preview)(?=.*MAUI/nativo.*App Store/Google Play)(?=.*nove dire..es.*preview visual p.blico)(?=.*Abre e verifica cada destino)' 'O prompt 13 nao exige previews visuais publicos e verificados para as nove opcoes.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*Template premium base.*Ver preview.*Ver rival \(opcional\))(?=.*links Markdown clic.veis)(?=.*live preview exato)(?=.*aplica..o rival.*apenas.*inspira..o)(?=.*n.o selecion.vel.*nunca a recomendes)' 'As tabelas do prompt 13 nao priorizam previews premium e rivais opcionais.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*sil.ncio, `pr.ximo`, uma escolha parcial)(?=.*n.o contam como autoriza..o)(?=.*Enquanto faltar uma das tr.s escolhas)(?=.*n.o apagues, alteres ou implementes)(?=.*Implementa apenas as op..es escolhidas)' 'O prompt 13 pode implementar uma recomendacao sem as tres escolhas do programador.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*Percurso A.*novo layout do zero)(?=.*INITIAL_LAYOUT_RESET\.md)(?=.*Remove primeiro)(?=.*layouts/shells)(?=.*CSS/SCSS)(?=.*componentes UI do BitPlatform)(?=.*aus.ncia de reutiliza..o)' 'O percurso novo do prompt 13 nao executa e prova o reset visual autorizado.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)Percurso B.*melhorar o layout existente.*INITIAL_LAYOUT_AUDIT\.md.*preservar \| melhorar \|\s+substituir \| remover.*n.o apagues por\s+atacado.*n.o\s+converte silenciosamente' 'O prompt 13 nao permite melhorar o layout existente com uma auditoria preservadora.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)(?=.*Preserva rotas, contratos)(?=.*autentica.*autoriza.*regras de neg.*cio)(?=.*infraestrutura BitPlatform.*visual)(?=.*Reimplementa do zero)(?=.*apagues.*gerado)(?=.*Todas as rotas existentes continuam a compilar)' 'Os percursos visuais do prompt 13 podem destruir comportamento ou infraestrutura nao visual.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)pesquisa deve sustentar explicitamente as tr.s aplica..es.*SSR.*Web.*MAUI.*refer.ncia Web n.o prova.*proposta MAUI' 'A pesquisa premium do prompt 13 nao sustenta individualmente as tres aplicacoes.'
$surfaceLayoutPromptPaths = @(
    'prompts/03-marca-e-layout/14-melhorar-layout-client-ssr.md',
    'prompts/03-marca-e-layout/15-concluir-layout-client-ssr.md',
    'prompts/03-marca-e-layout/16-melhorar-layout-client-web.md',
    'prompts/03-marca-e-layout/17-concluir-layout-client-web.md',
    'prompts/03-marca-e-layout/18-melhorar-layout-client-maui.md',
    'prompts/03-marca-e-layout/19-concluir-layout-client-maui.md'
)
foreach ($surfaceLayoutPromptPath in $surfaceLayoutPromptPaths) {
    Require-Pattern $surfaceLayoutPromptPath '(?s)prompt 13.*INITIAL_LAYOUT_DIRECTIONS\.md.*INITIAL_LAYOUT_RESEARCH\.md.*INITIAL_LAYOUT_SPEC\.md.*INITIAL_LAYOUT_CRITIQUE\.md.*PRODUCT_QUALITY_BASELINE\.md' "O prompt visual nao herda a escolha, os artefactos e a baseline do prompt 13: $surfaceLayoutPromptPath"
    Require-Pattern $surfaceLayoutPromptPath '(?s)(?=.*aplica..es premium/maduras)(?=.*templates.*pag.*premium)(?=.*URL oficial)(?=.*pre.o/moeda)(?=.*licen.a)(?=.*o que n.o copiar)' "O prompt visual nao exige pesquisa premium atual com proveniencia e licenca: $surfaceLayoutPromptPath"
    Require-Pattern $surfaceLayoutPromptPath '(?s)(?=.*(?:n.o confi.veis|instru..es externas))(?=.*(?:n.o compres|compras?))(?=.*login)(?=.*(?:download|descarreg))(?=.*c.digo)(?=.*trade dress)' "O prompt visual nao controla pesquisa externa, compras e copia: $surfaceLayoutPromptPath"
    Require-Pattern $surfaceLayoutPromptPath '(?s)tarefa separada e read-only de cr.tica.*findings.*cr.ticos.*altos.*volta a renderizar|volta a capturar' "O prompt visual nao exige critica separada e correcao/reteste: $surfaceLayoutPromptPath"
    Require-Pattern $surfaceLayoutPromptPath '(?s)autocr.tica n.o independente.*`parcial`.*ignorar e avan.ar' "O prompt visual apresenta autocrítica como parecer profissional ou bloqueia a decisao do programador: $surfaceLayoutPromptPath"
    Require-Pattern $surfaceLayoutPromptPath '(?s)(?=.*CODEX_LAYOUT_TOOLING\.md)(?=.*manter\|remover)' "O prompt visual nao exige decisao de tooling sustentada por evidencia: $surfaceLayoutPromptPath"
}
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-05.*prompt 13.*prompt 14, 16 ou\s+18.*15, 17 ou 19.*INITIAL_LAYOUT_RESEARCH\.md.*INITIAL_LAYOUT_SPEC\.md.*INITIAL_LAYOUT_CRITIQUE\.md' 'EVAL-05 nao exercita fundacao, melhoria, conclusao e artefactos visuais.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-05(?=.*sem\s+decis.o sobre o percurso)(?=.*nenhum ficheiro visual)(?=.*novo do zero)(?=.*melhorar existente)(?=.*INITIAL_LAYOUT_DECISION\.md)(?=.*INITIAL_LAYOUT_RESET\.md)(?=.*INITIAL_LAYOUT_AUDIT\.md)(?=.*Client\.Ssr)(?=.*Client\.Web)(?=.*Client\.Maui)' 'EVAL-05 nao verifica a decisao e os dois percursos do prompt 13.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-05(?=.*exatamente tr.s dire..es para cada aplica..o)(?=.*nove no\s+total)(?=.*SSR-2.*WEB-1.*MAUI-3)(?=.*usar as tr.s recomendadas)(?=.*INITIAL_LAYOUT_DIRECTIONS\.md)(?=.*nenhuma remo..o, melhoria, package, baseline visual ou implementa..o)' 'EVAL-05 nao verifica as nove direcoes nem a selecao obrigatoria por cliente.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-05(?=.*nove dire..es.*template/tema/UI kit\s+premium pago.*base principal)(?=.*Template premium\s+base.*Ver preview)(?=.*Ver rival \(opcional\))(?=.*nunca substitui o template)(?=.*link quebrado)(?=.*n.o selecion.vel.*nunca . recomendada)' 'EVAL-05 nao verifica templates premium como base, rivais opcionais e falhas de links.'
Require-Pattern 'pilot/cases/EVAL-05.md' '(?s)(?=.*prompts 13, 16 e 17)(?=.*`pr.ximo` n.o . uma escolha)(?=.*INITIAL_LAYOUT_DECISION\.md)(?=.*INITIAL_LAYOUT_RESET\.md)(?=.*INITIAL_LAYOUT_AUDIT\.md)(?=.*componentes UI\s+do\s+BitPlatform)(?=.*templates, temas ou UI kits pagos premium)(?=.*INITIAL_LAYOUT_RESEARCH\.md)(?=.*INITIAL_LAYOUT_SPEC\.md)(?=.*INITIAL_LAYOUT_CRITIQUE\.md)(?=.*tarefa separada)(?=.*findings cr.*ticos/altos)' 'O caso EVAL-05 nao reproduz decisao, pesquisa e qualidade visual ponta a ponta.'
Require-Pattern 'pilot/cases/EVAL-05.md' '(?s)(?=.*SSR-1\.\.3.*WEB-1\.\.3.*MAUI-1\.\.3)(?=.*tr.s tabelas curtas)(?=.*uma recomenda..o por aplica..o)(?=.*INITIAL_LAYOUT_DIRECTIONS\.md)(?=.*SSR-2.*WEB-1.*MAUI-3)(?=.*usar as tr.s recomendadas)(?=.*n.o autorizam a implementa..o)' 'O caso EVAL-05 nao prova a escolha das nove direcoes antes de alterar a UI.'
Require-Pattern 'pilot/cases/EVAL-05.md' '(?s)(?=.*nove\s+dire..es.*base premium principal)(?=.*Template premium base.*Ver preview.*Ver rival)(?=.*nove linhas.*links Markdown clic.veis)(?=.*n.o substitui a base premium)(?=.*preview inicialmente quebrado)(?=.*n.o selecion.vel.*n.o a recomenda)' 'O caso EVAL-05 nao exercita bases premium e rivais opcionais com links validos.'
Require-Pattern 'prompts/03-marca-e-layout/13-criar-layout-inicial.md' '(?s)VISUAL_SLICE_CONTRACT\.md.*alternativas de baixa fidelidade.*dire..o selecionada' 'A fundacao visual nao usa exploracao em duas passagens.'
Require-Pattern '.gitattributes' 'pilot/fixtures/lifecycle-gates/gate-artifact\.txt\s+text\s+eol=lf' 'O artefacto com hash dos gates nao fixa line endings portaveis.'
Require-Pattern 'scripts/Test-SoftwareLifecycle.ps1' 'prompts-boilerplate-fixture-' 'O lifecycle E2E depende de um BoilerPlateAdvance externo ao checkout.'
Require-Pattern 'scripts/Test-ProcessInDisposableCopy.ps1' 'prompts-boilerplate-source-' 'A copia descartavel depende de um BoilerPlateAdvance externo ao checkout.'
Require-Pattern 'software-lifecycle.ps1' 'ProcessRoot must be outside the prompt catalog' 'O inicializador nao impede instancias dentro do catalogo.'
Require-Pattern 'software-lifecycle.ps1' 'ProcessRoot must be outside BoilerplatePath' 'O inicializador permite contaminar o boilerplate.'
Require-Pattern 'software-lifecycle.ps1' 'Get-PhysicalPath' 'O isolamento nao resolve junctions ou links simbolicos.'
Require-Pattern 'software-lifecycle.ps1' "'start'.*'adopt'.*'continue'" 'O orquestrador nao suporta adocao/continuacao brownfield.'
Require-Pattern 'software-lifecycle.ps1' 'initiativeMode' 'O estado nao distingue greenfield de brownfield.'
Require-Pattern 'software-lifecycle.ps1' 'Existing application files, Git history and remotes: unchanged' 'A adocao nao confirma preservacao da aplicacao e Git.'
Require-Pattern 'software-lifecycle.ps1' '--no-optional-locks' 'A captura brownfield pode alterar metadados Git atraves de refresh opcional do indice.'
Require-Pattern 'software-lifecycle.ps1' 'Out-of-order result' 'O lifecycle nao bloqueia resultados fora de ordem.'
Require-Pattern 'software-lifecycle.ps1' 'Cannot select prompt.*while prompt.*is active' 'O lifecycle permite selecionar outro prompt durante trabalho ativo.'
Require-Pattern 'software-lifecycle.ps1' 'SliceKind is required' 'O lifecycle nao exige metadados da vertical slice.'
Require-Pattern 'software-lifecycle.ps1' 'Invoke-ManifestGateValidator' 'O lifecycle nao executa validadores mecanicos dos gates.'
Require-Pattern 'software-lifecycle.ps1' 'Get-AutomaticNextPrompt' 'O lifecycle nao encaminha transicoes deterministicas automaticamente.'

$pluginResolverPath = Join-Path $root 'plugins/advance-app/scripts/Resolve-AdvanceCatalog.ps1'
if (Test-Path -LiteralPath $pluginResolverPath -PathType Leaf) {
    $pluginResolverOutput = @(
        & $powerShellExe -NoProfile -File $pluginResolverPath -CatalogPath $root 2>&1
    )
    if ($LASTEXITCODE -ne 0 -or
        [string]@($pluginResolverOutput)[-1] -ne [System.IO.Path]::GetFullPath($root)) {
        Add-Failure 'O resolver do plugin nao devolveu a raiz exata do catalogo.'
    }
    $developmentResolverOutput = @(
        & $powerShellExe -NoProfile -File $pluginResolverPath `
            -CatalogPath $root -PreferDevelopmentClone 2>&1
    )
    if ($LASTEXITCODE -ne 0 -or
        [string]@($developmentResolverOutput)[-1] -ne [System.IO.Path]::GetFullPath($root)) {
        Add-Failure 'O resolver do plugin nao reconheceu o clone de desenvolvimento canónico.'
    }
}
Require-Pattern 'software-lifecycle.ps1' 'Get-AllowedSelectionPromptIds' 'O seletor nao restringe transicoes ao contexto atual.'
Require-Pattern 'software-lifecycle.ps1' "Command -eq 'decide'" 'O lifecycle nao permite registar exclusoes opcionais com evidencia.'
Require-Pattern 'software-lifecycle.ps1' "Command -eq 'gate'" 'O lifecycle nao permite decidir gates entre prompts.'
Require-Pattern 'software-lifecycle.ps1' 'Test-GatePrerequisites' 'Os pre-requisitos declarados dos gates nao sao aplicados.'
Require-Pattern 'software-lifecycle.ps1' 'Concurrent lifecycle update detected' 'O estado nao usa controlo de concorrencia otimista.'
Require-Pattern 'software-lifecycle.ps1' 'State catalogVersion.*does not match manifest' 'A validacao nao deteta catalogVersion corrompida.'
Require-Pattern 'software-lifecycle.ps1' '(?s)catalog-migration:.*Product content, prompt results, gates and attempts: preserved.*Embedded lifecycle routing rules' 'O lifecycle nao fornece migracao controlada para instancias congeladas.'
Require-Pattern 'software-lifecycle.ps1' '(?s)(?=.*Compare-CatalogVersion)(?=.*refuses to downgrade)(?=.*stable identity.*matches in the source catalog)(?=.*ambiguous prompt identity migration)' 'A migracao nao impede downgrade ou remocao/ambiguidade silenciosa de identidades e evidencia.'
Require-Pattern 'software-lifecycle.ps1' '(?s)Assert-CatalogEligibleForAutomaticUpgrade.*releaseChannel.*stable.*PILOT_APPROVAL\.md.*15/15.*Human evaluator.*Independent reviewer' 'O upgrade nao exige canal stable e piloto aprovado para a versao exata.'
Require-Pattern 'software-lifecycle.ps1' '(?s)ConfirmMigration.*AcceptCandidateCatalog.*Merge-CatalogPromptsIntoState.*Convert-LegacyStateToProgrammerControlled.*awaiting_programmer' 'A migracao explicita nao preserva/expande o estado legado para o fluxo controlado.'
Require-Pattern 'scripts/Test-LifecycleMigration.ps1' '(?s)legacyVersion.*prompt-04-partial.*controlled legacy migration.*preservedHistory.*skip-incomplete-and-advance:04->07' 'O teste de migracao nao prova preservacao de evidencia e avancar com gaps aceites.'
Require-Pattern 'PROCESS_MANIFEST.json' '"releaseChannel"\s*:\s*"candidate"' 'O catalogo ainda nao distingue a candidata da versao stable.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)"executionProfiles".*"fast".*"standard".*"deep".*"contextRouting"' 'O manifesto nao define perfis proporcionais e routing progressivo de contexto.'
Require-Pattern 'software-lifecycle.ps1' '(?s)(?=.*Execution profile:)(?=.*## Required context)(?=.*SHA-256)(?=.*execute only this prompt)(?=.*After recording, stop)' 'NEXT_TASK nao gera perfil, contexto auditavel e paragem obrigatoria.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' 'software-lifecycle\.ps1 upgrade.*lifecycle-root' 'A skill canonica nao atualiza instancias compativeis antes de continuar.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)automatic lifecycle upgrade.*stable.*PILOT_APPROVAL\.md.*explicitly asks.*ConfirmMigration' 'A skill nao separa upgrade automatico estavel de migracao candidata explicitamente autorizada.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)old lifecycle must not trap.*ConfirmMigration.*AcceptCandidateCatalog.*do not ask for a second confirmation.*does not authorize external' 'A skill nao permite migrar uma instancia antiga depois da decisao explicita do programador.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/SKILL.md' '(?s)predates `advance`.*ConfirmMigration.*AcceptCandidateCatalog.*Do not ask for a duplicate confirmation' 'A skill global nao encaminha a migracao explicita de instancias antigas.'
Require-Pattern 'software-lifecycle.ps1' '(?s)ConfirmMigration.*AcceptCandidateCatalog.*Merge-CatalogPromptsIntoState.*Convert-LegacyStateToProgrammerControlled.*controlled migration' 'O lifecycle nao suporta a migracao explicita e conservadora para o fluxo controlado pelo programador.'
Require-Pattern 'software-lifecycle.ps1' 'Assert-ApplicabilityDecisions' 'O routing nao bloqueia saidas com opcionais por decidir.'
Require-Pattern 'software-lifecycle.ps1' 'AcceptanceCriteria' 'O lifecycle nao preserva criterios de aceitacao da slice.'
Require-Pattern 'software-lifecycle.ps1' 'Required progress:' 'O estado nao distingue progresso obrigatorio de opcionais.'
Require-Pattern 'software-lifecycle.ps1' 'Active/latest slice:' 'O estado nao apresenta a fatia ativa e os seus criterios.'
Require-Pattern 'software-lifecycle.ps1' 'Gate command first:' 'O estado nao orienta a passagem do gate antes de selecoes bloqueadas.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)"workflowMode": "programmer_controlled".*"onePromptPerTask": true.*"manualPromptAdvance": true.*"taskLedgerRequired": false.*"findingsGateRequired": false' 'O manifesto nao define o fluxo simples controlado pelo programador.'
Require-Pattern 'PROCESS_MANIFEST.json' '"decisionFirstResponsesRequired": true' 'O manifesto nao exige respostas orientadas primeiro a decisao.'
Require-Pattern 'software-lifecycle.ps1' "Command -eq 'work-start'" 'O lifecycle nao inicia tentativas de trabalho estruturadas.'
Require-Pattern 'software-lifecycle.ps1' "(?s)Command -eq 'finding-add'.*Command -eq 'finding-resolve'.*Command -eq 'finding-gate'" 'O lifecycle nao implementa o ciclo completo de findings.'
Require-Pattern 'software-lifecycle.ps1' "(?s)Command -eq 'cycle-start'.*CHANGE_STATUS.*approved.*BASELINE_LIFECYCLE_STATE.*currentPrompt = '01'" 'O lifecycle nao inicia um novo ciclo apenas a partir de uma proposta aprovada e arquivada.'
Require-Pattern 'CHANGE_CONTROL.md' '(?s)CHANGE_ID.*CHANGE_STATUS.*Analisar impacto.*Iniciar ciclo.*Incorporar e fechar' 'O protocolo de mudancas nao cobre delta, impacto, execucao e incorporacao.'
Require-Pattern 'software-lifecycle.ps1' '(?s)Assert-WorkAttemptCanComplete.*open or blocked findings' 'O closeout nao bloqueia goals ou findings incompletos.'
Require-Pattern 'software-lifecycle.ps1' '(?s)Command -eq ''record''.*Test-TaskLedgerRequired.*Assert-WorkAttemptCanComplete' 'O record completed nao aplica mecanicamente o task ledger.'
Require-Pattern 'EXECUTION_CONTRACT.md' '(?s)partial.*blocked.*RemainingWork|RemainingWork.*parcial.*bloqueado' 'O contrato nao exige a lista de trabalho em falta.'
Require-Pattern 'EXECUTION_CONTRACT.md' '(?s)Resposta conversacional orientada . decis.o.*interface de decis.o.*Resultado.*Falta para terminar.*Prova.*Riscos e bloqueios.*Decis.o do programador.*artefactos dur.veis' 'O contrato comum nao separa uma resposta curta de decisao da evidencia detalhada.'
Require-Pattern 'AGENTS.md' 'HELP_AND_ACADEMY\.md' 'As instrucoes nao encaminham tarefas de ajuda e Academia para o protocolo proprio.'
Require-Pattern 'PROCESS_MANIFEST.json' '"HELP_AND_ACADEMY\.md"' 'O manifesto nao conserva o protocolo de ajuda como referencia autoritativa.'
Require-Pattern 'HELP_AND_ACADEMY.md' '(?s)(?=.*APP/PAGE/FNC)(?=.*HLP-\*)(?=.*VID-\*)(?=.*CRS-\*)(?=.*1920.1080)(?=.*1.4 minutos)(?=.*caption autom.tica)(?=.*nunca prova final)' 'O protocolo nao define inventario, IDs, perfil de video e captions verificaveis.'
Require-Pattern 'HELP_AND_ACADEMY.md' '(?s)(?=.*n.o listado.*n.o . controlo de\s+acesso)(?=.*fornecedor)(?=.*indisponibilidade)(?=.*fallback textual)(?=.*autoriza..o expl.cita)(?=.*conta/canal)' 'O protocolo nao trata privacidade, falha do provider e publicacao externa com fail-closed.'
Require-Pattern 'HELP_AND_ACADEMY.md' '(?s)Definition of Done por unidade.*UI e vers.o atuais.*idiomas.*rota/contexto.*player.*build e testes' 'O protocolo nao possui Definition of Done ponta a ponta por unidade de ajuda.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)Execute one prompt.*After `record`, do not continue automatically.*next.*repeat.*skip and advance' 'A skill nao para depois de cada prompt sob controlo do programador.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)corre a app.*Server\.Api.*Client\.Ssr.*Client\.Web.*Cliente\.Web.*persistent terminal sessions.*Keep all three processes alive.*does not authorize.*production' 'A skill canonica nao inicia e valida as tres superficies locais sem alterar o lifecycle.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/SKILL.md' '(?s)corre a app.*Server\.Api.*Client\.Ssr.*Client\.Web.*without advancing lifecycle state' 'A skill global nao encaminha o pedido de executar a app completa.'
Require-Pattern '.agents/skills/advance-app-continue/agents/openai.yaml' '(?s)short_description: "Continue, correct, or run an Advance app".*default_prompt: "Use \$advance-app-continue to continue, correct, or run my Advance application\."' 'A metadata da skill canonica nao apresenta continuacao, correcao e arranque.'
Require-Pattern 'plugins/advance-app/skills/advance-app-continue/agents/openai.yaml' '(?s)short_description: "Continue, correct, or run an Advance app".*default_prompt: "Use \$advance-app-continue to continue, correct, or run my Advance application\."' 'A metadata global da skill nao apresenta continuacao, correcao e arranque.'
Require-Pattern 'AGENTS.md' '(?s)corre a app.*Server\.Api.*Client\.Ssr.*Client\.Web.*readiness.*n.o avan.a o lifecycle' 'As instrucoes derivadas nao conservam o contrato de executar os tres projetos locais.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-04.*work ledger.*finding-gate.*record completed' 'O piloto nao exercita o findings gate durante a revisao adversarial.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-11.*awaiting_programmer.*parcial.*skip and advance.*request/repeat.*brownfield.*objetivo' 'O piloto nao cobre o fluxo controlado, gaps e reruns.'
Require-Pattern 'pilot/cases/EVAL-04.md' '(?s)work-start.*finding-add.*finding-gate.*finding-resolve.*attempt ID' 'O caso EVAL-04 nao conserva o ciclo completo do task ledger.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)sem `work-start`.*goals incompletos.*finding aberto.*activeWorkAttemptId.*goal ID' 'O caso EVAL-11 nao cobre bypass e corrupcao do task ledger.'
Require-Pattern 'README.md' 'DOR-01 a DOR-12.*passou' 'O README nao bloqueia a etapa 2 ate a definicao do produto passar.'
Require-Pattern 'AGENTS.md' '(?s)PRODUCT_DEFINITION\.md.*diagn.stico.*n.o bloqueies.*pr.ximo' 'As instrucoes duradouras nao tratam o Gate A como diagnóstico consultivo.'
Require-Pattern 'AGENTS.md' '(?s)Exatamente um prompt.*falta implementar.*pr.ximo.*repetir.*ignorar e avan.ar' 'As instrucoes duradouras nao aplicam o controlo do programador.'
Require-Pattern 'PRODUCT_DEFINITION.md' 'DOR-12' 'A definicao do produto nao contem a checklist completa do Gate A.'
Require-Pattern 'PRODUCT_DEFINITION.md' 'Decis.o do Gate A: GO' 'A definicao do produto nao especifica a decisao GO.'
Require-Pattern 'AGENTS.md' 'Test-ProductDefinitionGate\.ps1' 'As instrucoes duradouras nao executam o gate da definicao.'
Require-Pattern 'APP_CONTEXT.md' 'Raiz do BoilerPlateAdvance.*A preencher.*pendente.*software-lifecycle\.ps1' 'O contexto nao delega no lifecycle a resolucao portavel do BoilerPlateAdvance.'
Require-Pattern 'APP_CONTEXT.md' 'Entrada aut.noma da descoberta.*Prompt 01' 'O contexto ainda transforma preferências em entradas obrigatorias do prompt 01.'
Require-Pattern 'software-lifecycle.ps1' 'Join-Path\s+\(Split-Path\s+\$catalogRoot\s+-Parent\)\s+.+BoilerPlateAdvance' 'O orquestrador nao usa o BoilerPlateAdvance irmao do catalogo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'N.o existem entradas obrigat.rias do utilizador' 'O prompt 01 ainda exige um questionario inicial.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'A aus.ncia desses dados nunca bloqueia o prompt 01' 'O prompt 01 ainda pode bloquear sem preferencias do utilizador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Protocolo de execu..o obrigat.rio.*enquadrar o objetivo.*definir estrat.gia.*explorar amplamente.*triangular evid.ncia.*pontuar, comparar.*valida..o adversarial' 'O prompt 01 nao comeca por um plano completo dividido em etapas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Considera o plano aprovado.*avan.a sem pedir confirma..o' 'O prompt 01 ainda pausa para aprovar o plano de pesquisa local.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'Executa o plano como um .nico objetivo' 'O prompt 01 nao conserva um objetivo unico durante a execucao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Resultado obrigat.rio.*O trabalho s. fica `conclu.do` quando.*afirma..o material.*pontua..o for reproduz.vel' 'O prompt 01 nao define outcome e completion bar verificaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)sele..o conveniente de fontes.*sinais n.o independentes.*vi.s de novidade.*m.tricas sem proveni.ncia' 'A revisao adversarial do prompt 01 nao tenta refutar vieses materiais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Regista identidade ou tarefa.*m.todo de separa..o.*S. chama a esta valida..o `independente` quando essa evid.ncia existir' 'O prompt 01 pode declarar independencia sem separacao comprovada.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)tarefa ou agente separado, read-only e sem o transcript.*decis.o `GO` ou `NO-GO`.*sem editar os artefactos' 'O prompt 01 nao exige revisao realmente separada e read-only.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)plataforma n.o disponibilizar outro agente ou tarefa.*termina `parcial`.*nunca a descrevas como conclu.da ou independente' 'O prompt 01 pode concluir sem validacao independente.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Usa pesquisa web para amplitude.*abre a fonte original.*resultado for vazio, parcial ou suspeitosamente estreito.*fontes ou formula..es alternativas' 'O prompt 01 nao define routing e fallback de pesquisa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)usando apenas as notas inteiras.*valores decimais.*Intensidade do problema.*Todas as notas.*5 = oportunidade mais favor.vel.*remove individualmente cada fonte material.*maior queda.*URL can.nico em ordem' 'O prompt 01 nao possui scoring ponderado e reproduzivel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Condi..es de paragem da pesquisa.*duas rondas dirigidas consecutivas.*N.o fa.as novas pesquisas apenas para melhorar a reda..o' 'O prompt 01 nao possui stopping conditions verificaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Artefacto detalhado obrigat.rio.*DISCOVERY_RESEARCH\.md.*matriz de claims e fontes.*scoring reproduz.vel.*recibo da revis.o independente.*recomenda..o final' 'O prompt 01 nao conserva a investigacao detalhada num artefacto auditavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Resposta obrigat.ria ao programador.*bloco `Decis.o`.*at. tr.s raz.es.*\| # \| Hip.tese \| Utilizador e problema \| Proposta em uma frase \| Pontua..o/confian.a \| Risco decisivo \|.*m.ximo 12 palavras.*top 3 com um trade-off.*aprovar recomenda..o.*escolher hip.tese #N.*pedir rework' 'O prompt 01 nao entrega hipoteses curtas e comparaveis para decisao rapida.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Liga `DISCOVERY_RESEARCH\.md`.*n.o transcrevas.*linguagem direta.*t.tulos previs.veis.*Evita introdu.*gen.ricas.*jarg.o de startups' 'O prompt 01 nao separa a sintese clara do detalhe auditavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)proveni.ncia upstream diferente.*Republica..es, sindica..o.*contam como uma .nica fonte' 'O prompt 01 permite falsa independencia entre fontes derivadas da mesma origem.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Todas as notas est.o orientadas para `5 = oportunidade mais favor.vel`.*quatro cen.rios.*total continuar 100%.*ranking como inst.vel' 'O scoring e a sensibilidade do prompt 01 nao sao deterministicos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)Seleção determinística do modo.*change-cycle.*brownfield.*ideia-fornecida.*zero-input.*3–5 direções.*manter.*melhorar.*reposicionar.*integrar/substituir' 'O prompt 01 nao adapta a descoberta a ideia fornecida e aplicacao existente.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-01-IDEA.*EVAL-01-BROWNFIELD.*não aumentam a contagem de 15 casos' 'EVAL-01 nao cobre routing de ideia fornecida e brownfield.'
Require-Pattern 'EVALUATION_IMPACT_MAP.json' '(?s)targetedOnEveryChange.*fullSuiteRequiredForStablePromotion.*EVAL-15' 'A politica de avaliacao nao separa regressao dirigida de promocao stable.'
Require-Pattern 'scripts/Get-PromptEvaluationScope.ps1' '(?s)StablePromotion.*fullSuiteCaseIds.*impact-based regression' 'O seletor de avaliacoes por impacto esta incompleto.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)proxy de pagamento n.o satisfaz a .ncora 5 de monetiza..o.*canal apenas\s+plaus.vel n.o satisfaz a .ncora 5 de distribui..o' 'O prompt 01 permite notas maximas contraditas pela propria evidencia.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)top 3 corrente, depois de todas as corre..es.*linha por\s+URL can.nico.*n.o agregues v.rias fontes' 'O prompt 01 permite sensibilidade sobre finalistas antigas ou fontes agregadas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)finding alterar uma fonte material, nota, shortlist, top 3 ou finalista.*regenera a matriz de evid.ncia.*cen.rios de pesos.*recomenda..o' 'O prompt 01 nao invalida derivados depois de findings materiais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)m.trica observ.vel e\s+limiar expl.cito de decis.o definidos agora.*n.o adies a m.trica para o\s+prompt 02' 'O prompt 01 permite experimentos sem metrica e limiar atuais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)atualiza..es s.o obrigat.rias quando a tarefa executora tiver\s+`workspace-write`.*tentativa real falhar.*erro exato' 'O prompt 01 pode alegar read-only sem tentar persistir os artefactos.'
Require-Pattern 'pilot/cases/EVAL-01.md' '(?s)Executa apenas o prompt 01.*n.o\s+forneceu mercado.*12.20 espa.os.*scoring ponderado.*DISCOVERY_RESEARCH\.md.*tabela curta.*m.ximo 12 palavras.*tr.s respostas r.pidas.*termina\s+`parcial`' 'O caso executavel EVAL-01 nao exercita a descoberta zero-input com resposta concisa.'
Require-Pattern 'pilot/cases/EVAL-01.md' '(?s)executor principal est. em `workspace-write`.*proxy ou canal plaus.vel n.o justificam nota 5.*top 3 final.*m.trica observ.vel e um limiar' 'O caso EVAL-01 nao exercita os fallbacks descobertos no ensaio comportamental.'
Require-Pattern 'pilot/cases/EVAL-01.md' '(?s)\A(?!.*prompt 07)(?!.*07-criar-projeto).*\z' 'O caso executavel EVAL-01 ainda testa o prompt 07 antigo.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)07-criar-projeto-a-partir-do-boilerplate.*greenfield.*brownfield.*missing-application.*nenhuma aplica..o, processo parcial' 'O caso executavel EVAL-11 nao conserva os bloqueios de entradas do prompt 07.'
Require-Pattern 'pilot/cases/EVAL-11.md' 'reports/bitplatform-baseline-comparison\.md' 'EVAL-11 nao exige a matriz oficial do boilerplate.'
Require-Pattern 'pilot/cases/EVAL-11.md' 'tr.s deltas: uma capacidade ligada' 'EVAL-11 nao testa deltas com relevancia diferente.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)n.o aceites.*vers.o mais\s+recente' 'EVAL-11 nao testa a rejeicao da recencia como justificacao.'
Require-Pattern 'pilot/cases/EVAL-11.md' 'altera..es . origem' 'EVAL-11 nao protege a origem durante a comparacao.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)boilerplate-conformance\.md.*parcialmente conforme.*diverg.ncia intencional.*adaptar\|manter diverg.ncia\|adiar.*objetivo concreto.*`pr.ximo` n.o conta' 'EVAL-11 nao testa o consentimento brownfield antes de adaptar o boilerplate.'
Require-Pattern 'scripts/Invoke-PromptPilotCase.ps1' '(?s)Get-IgnoredFileSnapshot.*Get-FileHash -Algorithm SHA256.*Get-GitCommitObjectIds.*batch-all-objects.*newCommitObjectIds.*changedIgnoredPaths.*diff --name-only --no-renames HEAD.*ls-files --others --exclude-standard.*changedPaths = \$changedPaths' 'O runner piloto nao captura caminhos e commits de forma fechada.'
Require-Pattern 'scripts/Test-PromptPilotArtifacts.ps1' "(?s)newCommitObjectIds.*EVAL-01-R2.*DISCOVERY_RESEARCH.md.*PRODUCT_DEFINITION.md.*IMPLEMENTATION_STATUS.md.*missingPrompt01Paths.*beforeSha -ne.*afterSha" 'O oraculo piloto nao exige todos os artefactos e limita todas as escritas e commits do prompt 01.'
Require-Pattern 'scripts/New-PromptPilotBaseline.ps1' '(?s)BoilerPlateAdvance\.Web\.slnf.*--force-evaluate.*BoilerPlateAdvance\.Tests\.csproj.*PILOT_BASELINE\.json.*MAUI excluded' 'O preparador do piloto nao cria uma baseline Web portavel e verificavel.'
Require-Pattern 'scripts/Test-PromptPilotBaseline.ps1' '(?s)BoilerPlateAdvance\.Web\.slnf.*--locked-mode.*BoilerPlateAdvance\.Tests\.csproj.*beforeSha.*afterSha' 'O pre-check do piloto nao valida a baseline Web imutavel.'
Require-Pattern 'scripts/Invoke-PromptPilotCase.ps1' '(?s)(?=.*CaseInputFile)(?=.*unresolved token)(?=.*input\.json)(?=.*caseInputSha256)' 'O runner piloto nao renderiza inputs dinamicos com proveniencia.'
Require-Pattern 'scripts/New-PromptPilotAttestation.ps1' '(?s)(?=.*RSA)(?=.*Pss)(?=.*artifactSha256)(?=.*candidateSha)(?=.*issuer)(?=.*builder)(?=.*publicKeySha256)' 'O piloto nao produz attestation criptograficamente assinada.'
Require-Pattern 'scripts/New-PromptPilotSigningKey.ps1' '(?s)(?=.*ExportPkcs8PrivateKeyPem)(?=.*ExportSubjectPublicKeyInfoPem)(?=.*SetUnixFileMode)(?=.*Private key: created outside the worktree)' 'O builder piloto nao cria uma chave isolada e pre-autorizavel.'
Require-Pattern 'scripts/New-PromptPilotAttestation.ps1' '(?s)(?=.*PrivateKeyPath)(?=.*must remain outside the candidate worktree)(?=.*ImportFromPem)' 'A attestation piloto nao usa a chave isolada do builder.'
Require-Pattern 'scripts/Test-PromptPilotAttestation.ps1' '(?s)(?=.*RSA-PSS-SHA256)(?=.*VerifyData)(?=.*ExpectedRepository)(?=.*ExpectedWorkflow)(?=.*ExpectedCandidateSha)(?=.*ExpectedArtifactSha256)(?=.*ExpectedIssuer)(?=.*ExpectedBuilder)(?=.*ExpectedPublicKeySha256)' 'O piloto nao verifica integralmente a attestation assinada.'
Require-Pattern 'scripts/Test-PromptPilotArtifacts.ps1' '(?s)expectedEval13Scenarios.*missing.*tampered.*unauthorized-wrong-commit.*valid.*signatureValid.*publicKeyTrusted.*candidateMatches' 'O oraculo EVAL-13 nao testa attestations ausentes, alteradas, nao autorizadas, de outro commit e validas.'
Require-Pattern 'scripts/Test-PromptPilotArtifacts.ps1' '(?s)(?=.*releaseOrder)(?=.*release chain does not continue)(?=.*input\.json)(?=.*caseInputSha256)' 'O oraculo EVAL-13 ainda depende de SHAs historicos em vez da cadeia dinamica atual.'
Require-Pattern 'pilot/cases/EVAL-13-REVIEW-1.md' '(?s)\{\{baseSha\}\}.*\{\{candidateSha\}\}.*\{\{artifactSha256\}\}.*\{\{trustedPublicKeySha256\}\}.*Test-PromptPilotAttestation' 'O caso EVAL-13 nao recebe identidades dinamicas nem verifica a attestation.'
Require-Pattern 'scripts/Test-PromptPilotArtifacts.ps1' '(?s)\A(?!.*5bd59f8c56b72d34613e5a5923a0091a25751229)(?!.*80903df4ff43aacec9db5609f585a93d93b4dfd8).*\z' 'O oraculo EVAL-13 ainda contem SHAs congelados da execucao historica.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'DISCOVERY_RESEARCH\.md.*quando existir' 'O prompt 07 nao conserva a evidencia detalhada da descoberta.'
Require-Pattern 'scripts/Test-PromptPilotArtifacts.ps1' "(?s)readOnlyCases.*EVAL-11.*isExpectedReadOnly.*beforeSha -ne.*afterSha" 'O oraculo piloto permite que EVAL-11 esconda alteracoes num commit.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'N.o solicites, estimes nem uses `\[OR.AMENTO\]` ou `\[PRAZO\]` nesta fase' 'O prompt 01 voltou a depender de orcamento ou prazo durante a descoberta.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'validados no DOR-09 antes do Gate A' 'O prompt 01 nao encaminha orcamento e prazo para a validacao posterior correta.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'MVP m.nimo.*sem estimar dura..o ou custo' 'O prompt 01 voltou a produzir estimativas prematuras de prazo ou custo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'pesquisa online . obrigat.ria' 'O prompt 01 permite recomendar ideias apenas pela memoria do modelo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '(?s)avan.ar.*valida..o com\s+utilizadores.*n.o.*Gate A' 'O prompt 01 confunde desk research com validacao de mercado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '12.20 espa.os de problema' 'O prompt 01 nao exige exploracao ampla do mercado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'Reddit, Hacker News, Indie Hackers' 'O prompt 01 nao pesquisa foruns e comunidades atuais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'aplica..o recente com boa aceita..o p.blica.*fragilidades concretas' 'O prompt 01 nao procura apps recentes aceites com fragilidades melhoraveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'categoria dispersa.*combinar v.rias aplica..es' 'O prompt 01 nao deteta necessidades dispersas por varias ferramentas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'pelo menos dois tipos de fonte' 'O prompt 01 nao exige triangulacao suficiente para a recomendacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'n.o devolvas um question.rio inicial' 'O prompt 01 ainda pode terminar pedindo dados ao utilizador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)exclusivamente pelo caminho absoluto registado no.*lifecycle' 'O prompt 03 nao resolve de forma portavel a localizacao canonica do BoilerPlateAdvance.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'caminho absoluto registado no lifecycle' 'O prompt 07 nao identifica a origem canonica registada no lifecycle.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)Comparação obrigatória.*proveni.ncia da origem local.*bitplatform\.dev/templates.*github\.com/bitfoundation/bitplatform.*tags/releases.*branch de desenvolvimento.*n.o . automaticamente uma baseline' 'O prompt 07 nao compara a origem com fontes oficiais estaveis e rastreaveis do BitPlatform.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)bitplatform-baseline-comparison\.md.*capacidade/estrutura.*evid.ncia local.*evid.ncia oficial.*desatualizado.*divergente.*n.o\s+verific.vel.*manter.*adotar.*adiar.*rejeitar' 'O prompt 07 nao produz a matriz de deltas e decisoes do boilerplate.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)Mais recente.*n.o significa.*adequado.*responde a requisito.*compat.vel.*benef.cio.*risco' 'O prompt 07 pode adotar novidades apenas por serem recentes.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'A\s+origem local permanece imut.vel' 'O prompt 07 pode atualizar destrutivamente o BoilerPlateAdvance de origem.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'N.o atualizes a origem local' 'O prompt 07 pode sincronizar silenciosamente a origem com o online.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'reports/boilerplate-conformance\.md' 'O prompt 07 nao produz a auditoria de conformidade brownfield.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)parcialmente conforme.*diverg.ncia intencional.*n.o\s+conforme.*n.o verific.vel' 'O prompt 07 nao possui classificacao honesta de conformidade.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'auditoria de conformidade: n.o voltes a' 'O prompt 07 pode recopiar uma base ja aplicada.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)Queres adaptar o projeto atual.*objetivo concreto.*manter a diverg.ncia ou adiar.*n.o transformes `pr.ximo`.*n.o alteres c.digo.*responder explicitamente' 'O prompt 07 nao pede consentimento claro antes da adaptacao brownfield.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '(?s)manter a diverg.ncia ou adiar.*regista a decis.o e n.o bloqueies.*baseline restante' 'O prompt 07 torna obrigatoria uma conformidade que o programador decidiu nao adotar.'
Require-Pattern 'PROCESS_MANIFEST.json' '(?s)officialBoilerplateComparisonRequired.*brownfieldBoilerplateAdaptationConsentRequired.*"deep": \[[^\]]*"07"' 'O manifest nao aplica pesquisa profunda e consentimento ao prompt 07.'
Require-Pattern 'EVALUATION_IMPACT_MAP.json' '(?s)foundation-and-boilerplate-adoption.*07-criar-projeto-a-partir-do-boilerplate.*EVAL-02.*EVAL-03.*EVAL-11.*EVAL-12' 'O mapa de impacto nao seleciona a regressao do prompt 07.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'GO.*REWORK.*NO-GO' 'O prompt 04 nao produz uma decisao completa do Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'DOR-01 a DOR-12' 'O prompt 04 nao audita todos os criterios de passagem.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)DOR-03/DOR-08.*\| 04 \|.*DOR-09.*\| 04 \|.*DOR-12.*\| 04 \|' 'O prompt 04 nao conserva evidencias, viabilidade e aprovacao no proprio Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)currentPrompt = 04.*resolve_current_prompt.*N.o declares.*repetir o prompt 01.*entrevistar utilizadores.*or.amento, prazo e equipa' 'O prompt 04 ainda pode criar o ciclo impossivel entre descoberta e Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)S. uma conclus.o que altere materialmente.*reabre o\s+prompt propriet.rio 01, 02 ou 03' 'O prompt 04 reabre prompts anteriores sem mudanca da fonte canonica.'
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)mant.m o prompt 04 quando falta autoriza..o.*or.amento, prazo, compet.ncias ou aprova..o.*reabre exatamente o prompt 01, 02 ou 03 apenas quando' 'A regra do Gate A ainda encaminha pendencias operacionais para a descoberta.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)DOR-03/DOR-08.*DOR-09.*DOR-12.*prompt 04 ainda ativo.*proibido.*repetir o prompt 01' 'EVAL-11 nao cobre a regressao de routing do Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '10.15 nomes' 'O prompt 02 nao exige uma shortlist final de 10 a 15 nomes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'OVHcloud.*dispon.vel para registo' 'O prompt 02 nao exige disponibilidade especifica na OVHcloud.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '\[CUSTO_MAXIMO_ANUAL_DOMINIO\]' 'O prompt 02 nao possui um limite de custo verificavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '(?s)idiomas materiais n.o forem fornecidos.*portugu.s europeu \(pt-PT\) \+ ingl.s internacional.*default revers.vel do prompt 02.*avan.a sem pedir confirma..o' 'O prompt 02 nao aplica os idiomas default sem bloquear.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '(?s)limite n.o for fornecido.*30 EUR/ano, IVA inclu.do.*registo inicial.*renova..o.*default revers.vel do prompt 02' 'O prompt 02 nao aplica o orcamento default ao registo e renovacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '(?s)decis.o expl.cita.*prevalece.*N.o bloqueies apenas pela aus.ncia destes dois valores' 'O prompt 02 nao define precedencia e pode continuar a bloquear pelos defaults ausentes.'
Require-Pattern 'APP_CONTEXT.md' '(?s)No prompt 02.*portugu.s europeu \(pt-PT\) \+ ingl.s internacional.*30 EUR/ano, IVA inclu.do.*registo e renova..o.*decis.o expl.cita.*prevalece' 'O contexto nao documenta os defaults reversiveis do prompt 02.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'pre.o de registo.*pre.o de renova..o' 'O prompt 02 nao compara registo e renovacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'resposta `200`' 'O prompt 02 nao identifica um registo RDAP ativo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '`404`/`not found`' 'O prompt 02 nao trata um dominio sem registo RDAP encontrado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'CAPTCHA.*rate limits' 'O prompt 02 nao trata bloqueios e limites da verificacao externa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '(?s)N.o consultes bases jur.dicas especializadas.*n.o pe.as ao utilizador.*CAPTCHA.*Interven..o manual solicitada: n.o' 'O prompt 02 ainda pode introduzir a triagem juridica ou uma pausa manual intermedia.'
Forbid-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '(?i)WIPO|EUIPO' 'O prompt 02 ainda conserva as bases juridicas removidas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'WhatsApp, Instagram, TikTok, Telegram e X' 'O prompt 02 nao inclui o benchmark de comunicacao e social.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Gmail, Google Drive, Google Docs, Word, Excel, PowerPoint, Zoom, Microsoft Teams e Notion' 'O prompt 02 nao inclui o benchmark de produtividade.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'YouTube, Spotify e Netflix' 'O prompt 02 nao inclui o benchmark de conteudo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Google Maps, Waze, Uber e Bolt' 'O prompt 02 nao inclui o benchmark de mobilidade.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Amazon, MB WAY e Revolut' 'O prompt 02 nao inclui o benchmark de comercio e financas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'variantes.*imita..o' 'O prompt 02 nao impede imitacoes das marcas de referencia.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'mec.nico, artificial' 'O prompt 02 nao rejeita nomes mecanicos ou artificiais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'conjunto coerente de duas palavras internacionais' 'O prompt 02 nao permite compostos internacionais coerentes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Triagem fon.tica e lingu.stica online' 'O prompt 02 nao exige validacao sonora online.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'separa..o sil.bica.*s.laba t.nica.*pron.ncia esperada' 'O prompt 02 nao documenta a pronuncia esperada.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Forvo, YouGlish' 'O prompt 02 nao indica fontes online complementares de pronuncia.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'n.o prova objetivamente que um nome.*soa bem' 'O prompt 02 apresenta a sonoridade subjetiva como prova objetiva.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'dom.nio `.com` formado pela concatena..o sem espa.os nem h.fenes' 'O prompt 02 nao normaliza o dominio de nomes com duas palavras.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'palavra-base, raiz lexical, estrutura e met.fora dominante' 'O prompt 02 nao agrupa nem elimina familias de naming repetitivas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'N.o leves para a shortlist final mais do que um candidato da mesma fam.lia' 'O prompt 02 permite variantes superficiais na shortlist final.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'pesquisa separadamente cada palavra significativa e raiz lexical' 'O prompt 02 nao verifica componentes individuais contra apps e marcas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'mesmo que o nome completo n.o apare.a e o dom.nio esteja dispon.vel' 'O prompt 02 nao exclui uma colisao material num componente do nome.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Gate eliminat.rio contra nomes mec.nicos' 'O prompt 02 nao possui um gate explicito contra naming gerado por algoritmo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'palavra reconhec.vel.*composto natural.*neologismo transparente.*neologismo opaco' 'O prompt 02 nao distingue neologismos transparentes de opacos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'teste sem narrativa' 'O prompt 02 permite nomes que so funcionam com uma historia inventada.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '`-ivo`.*`-evo`.*`-umi`.*`-ora`.*`-io`.*`-ify`.*`-ly`' 'O prompt 02 nao deteta sufixos mecanicos usados apenas para simular uma marca.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Navirevo.*Prumivo.*Rivelumi' 'O prompt 02 nao conserva os nomes rejeitados como anti-exemplos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'Todo o `neologismo opaco`.*falha e . exclu.do' 'O prompt 02 nao exclui obrigatoriamente neologismos opacos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'NAMING_RESEARCH\.md' 'O prompt 02 nao conserva um registo retomavel da pesquisa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'gerado.*lexical_pass.*linguistico_pass.*associacao_pass.*dominio_pass.*shortlisted' 'O prompt 02 nao exige estados verificaveis por candidato.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'dados n.o confi.veis, n.o como instru..es' 'O prompt 02 nao trata conteudo externo como evidencia nao confiavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'revalida na OVHcloud e RDAP todos os nomes da shortlist' 'O prompt 02 nao revalida a shortlist imediatamente antes da entrega.'
$prompt02Path = Join-Path $root 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md'
if ((Test-Path -LiteralPath $prompt02Path -PathType Leaf) -and
    (Get-Content -Encoding UTF8 -LiteralPath $prompt02Path).Count -gt 165) {
    Add-Failure 'O prompt 02 excede o budget de 165 linhas e deve remover repeticao antes de crescer.'
}
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'REQUIREMENTS_RESEARCH\.md' 'O prompt 03 nao conserva pesquisa retomavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'USER_RESEARCH_EVIDENCE\.md' 'O prompt 03 nao exige evidencia direta com utilizadores.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '\[PASTA_ORIGEM_BOILERPLATE\]' 'O prompt 03 nao resolve a raiz real do BoilerPlateAdvance.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'pelo menos dois produtos diretamente compar.veis' 'O prompt 03 nao exige produtos comparaveis por jornada/pagina.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'uma ou duas refer.ncias premium relevantes' 'O prompt 03 nao exige referencias premium relevantes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Tailwind Plus, Metronic ou itens ThemeForest' 'O prompt 03 nao identifica fontes premium concretas para pesquisa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'dados n.o confi.veis' 'O prompt 03 nao trata conteudo externo como dados nao confiaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'N.o copies c.digo, assets, texto, trade dress' 'O prompt 03 nao protege propriedade e licencas das referencias.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Transforma observa..es externas em `INS-###` e candidatos `HYP-###`' 'O prompt 03 nao separa observacoes de hipoteses.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)S. converte\s+uma hip.tese em requisito `Must`' 'O prompt 03 promove benchmarks a requisitos sem gate.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'ficheiro:linha' 'O prompt 03 nao exige proveniencia do inventario do boilerplate.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '`reter`, `adaptar`, `remover`' 'O prompt 03 nao classifica o baseline observado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)Existir no\s+boilerplate n.o o transforma em requisito' 'O prompt 03 confunde baseline tecnica com necessidade de produto.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Contrato inline obrigat.rio' 'O prompt 03 nao e autocontido depois da remocao do contrato auxiliar.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)evidenceState.*approvalState.*implementationState' 'O prompt 03 nao separa evidencia, aprovacao e implementacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'BPP projeto boilerplate' 'O prompt 03 nao modela projetos reais do boilerplate.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'URL da licen.a oficial' 'O prompt 03 nao exige proveniencia oficial da licenca premium.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)estados: inicial, loading/progresso.*concorr.ncia/conflito.*recupera..o' 'O contrato PAGE inline nao cobre estados completos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)status HTTP.*canonical.*robots' 'O contrato PAGE inline nao cobre semantica e descoberta de paginas publicas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'relat.rio de cobertura' 'O prompt 03 nao possui gate de cobertura.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/REQUIREMENTS_SPECIFICATION\.md' 'O prompt 03 nao exige uma especificacao versionada canonica.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)(?=.*REQUIREMENTS_ENGINEERING_CONTRACT\.md)(?=.*REQUIREMENTS_QUALITY_MATRIX\.md)(?=.*decis.es, transi..es)(?=.*est.mulo.*medida/toler.ncia)(?=.*risco.*or.culo)' 'O prompt 03 nao aplica o contrato de qualidade dos requisitos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/DEVELOPER_REQUIREMENTS_CHECKLIST\.md' 'O prompt 03 nao gera a checklist legivel para o programador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/ALL_FUNCTIONALITIES\.md' 'O prompt 03 nao gera o ficheiro unico de todas as funcionalidades.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'ID \| Quem \| Onde \| Quando \| O qu.' 'O ficheiro unico do prompt 03 nao usa as cinco colunas obrigatorias.'
Require-Pattern 'REQUIREMENTS_ENGINEERING_CONTRACT.md' '(?s)(?=.*Exaustividade e formato invariantes)(?=.*sem amostragem)(?=.*projeto.*p.gina/ecr..*endpoint.*opera..o)(?=.*ID \| Quem \| Onde \| Quando \| O qu.)(?=.*globalmente .nico)(?=.*zero omiss.es sem justifica..o)' 'O contrato de requisitos nao exige levantamento exaustivo no formato indicado pelo programador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)(?=.*m.ximo detalhe poss.vel toda a aplica..o)(?=.*P.GINA\|ECR.\|ENDPOINT\|OPERA..O-N.O-VISUAL)(?=.*amostragem)(?=.*principais funcionalidades)(?=.*IDs apresentados em exemplos nunca s.o reutilizados)' 'O prompt 03 nao cobre toda a aplicacao no formato exato e com IDs unicos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)n.o existe\s+n.mero fixo de linhas.*confirma..o.*sucesso parcial.*notifica..o.*concorr.ncia' 'O prompt 03 nao exige decomposicao funcional por todos os ramos e efeitos distintos.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'linhas gen.ricas repetidas' 'O prompt 03 permite requisitos compactos genericos sem regra observavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'OPERA..O-N.O-VISUAL' 'O prompt 03 inventa paginas para operacoes tecnicas nao visuais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'ALL_FUNCTIONALITIES\.md.*ausente.*vazio.*formato obrigat.rio' 'O prompt 04 nao bloqueia o Gate A quando o ficheiro unico esta ausente ou invalido.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)reconcilia..o mec.nica.*APP.*PAGE.*FNC.*RF-P.*AC' 'O prompt 04 nao exige paridade mecanica de todos os identificadores.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)REQUIREMENTS_ENGINEERING_CONTRACT\.md.*REQUIREMENTS_QUALITY_MATRIX\.md.*tabelas de decis.o/transi..o.*invariante/or.culo' 'O Gate A nao audita a qualidade semantica e o oraculo dos requisitos.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/27-implementar-requisitos-de-pagina.md' '(?s)Definition of Ready.*approved_for_refinement.*n.o autoriza implementa..o' 'A slice de pagina nao refina requisitos antes do codigo.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/29-implementar-funcionalidades-especificas.md' '(?s)Definition of Ready.*approved_for_refinement.*n.o autoriza implementa..o' 'A slice funcional nao refina requisitos antes do codigo.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/27-implementar-requisitos-de-pagina.md' '(?s)TEST_STRATEGY_CONTRACT\.md.*quality/TEST_MATRIX\.md.*provider.*contrato' 'A slice de pagina nao conserva uma matriz de testes multinivel.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/29-implementar-funcionalidades-especificas.md' '(?s)TEST_STRATEGY_CONTRACT\.md.*quality/TEST_MATRIX\.md.*provider real.*compatibilidade OpenAPI' 'A slice funcional nao cobre provider real e compatibilidade de contrato.'
Require-Pattern 'TEST_STRATEGY_CONTRACT.md' '(?s)(?=.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md)(?=.*Cada `RF-P` definido tem exatamente um teste Playwright prim.rio)(?=.*mobile.*tablet.*desktop)(?=.*APIRequestContext)(?=.*exclusivamente nativo MAUI)(?=.*skip.*fixme)(?=.*IDs ausentes, duplicados)' 'O contrato de testes nao exige cobertura Playwright rastreavel por requisito e resolucao.'
Require-Pattern 'TEST_STRATEGY_CONTRACT.md' '(?s)PRODUCT_QUALITY_BASELINE\.md.*390.844.*768.1024.*1440.900.*nunca pode\s+reduzir as tr.s classes' 'O contrato Playwright nao fixa tres resolucoes concretas ou uma baseline equivalente.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/28-criar-testes-playwright-para-requisitos-de-pagina.md' '(?s)(?=.*teste Playwright prim.rio independente para cada `RF-P`)(?=.*mobile.*tablet.*desktop)(?=.*RF-P . teste Playwright prim.rio)(?=.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md)(?=.*resultado por `RF-P . projeto`)(?=.*n.o agrega v.rios `RF-P`)' 'O prompt 28 nao cria e executa um teste por requisito nas tres resolucoes.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/30-criar-testes-playwright-para-funcionalidade-especifica.md' '(?s)(?=.*exatamente um teste Playwright prim.rio independente por cada)(?=.*mobile.*tablet.*desktop)(?=.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md)(?=.*um teste prim.rio n.o cobre dois requisitos)(?=.*skip.*fixme)' 'O prompt 30 nao cria e executa um teste por requisito nas tres resolucoes.'
Require-Pattern 'prompts/08-qualidade-e-hardening/55-testar-aplicacao-geral.md' '(?s)(?=.*or.amento n.o.*omitir)(?=.*censo completo de `RF-P`)(?=.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md)(?=.*mobile/tablet/desktop)(?=.*n.o declares a aplica..o funcionalmente testada)' 'A auditoria geral pode omitir requisitos ou resolucoes por budget/infraestrutura.'
Require-Pattern 'QUALITY_GATES.md' '(?s)exatamente um teste Playwright prim.rio identific.vel por cada `RF-P`.*mobile, tablet e desktop.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md.*zero IDs ausentes ou\s+duplicados' 'G05 nao bloqueia requisitos sem teste Playwright ou resolucao.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-06.*teste Playwright prim.rio independente.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md.*mobile, tablet e desktop.*API usa request context.*MAUI-only.*skip.*fixme' 'EVAL-06 nao verifica a cobertura funcional Playwright por requisito e plataforma.'
Require-Pattern 'pilot/cases/EVAL-06.md' '(?s)exatamente um teste Playwright prim.rio.*cada `RF-P`.*mobile, tablet e desktop.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md' 'O caso EVAL-06 nao exige um teste Playwright por requisito nas tres resolucoes.'
Require-Pattern 'pilot/cases/EVAL-12-06.md' '(?s)exatamente um teste Playwright prim.rio.*cada `RF-P`.*mobile, tablet e desktop.*PLAYWRIGHT_REQUIREMENTS_COVERAGE\.md' 'A repeticao EVAL-12-06 nao conserva o gate Playwright por requisito.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' '(?s)funcionalidade com confirma..o.*dois ramos.*resultado\s+parcial.*Quem/Onde/Quando/O qu.' 'A revisao adversarial do prompt 04 nao tenta reconstruir uma funcionalidade ramificada.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)fonte can.nica\s+detalhada.*vista\s+derivada' 'O prompt 03 nao distingue a especificacao detalhada da vista do programador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)antes de desenvolver.*durante a implementa..o.*pronto para validar' 'A checklist do programador nao possui checkpoints de implementacao e validacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)PAGE -> funcionalidade -> requisito detalhado -> AC -> prova' 'A vista do programador nao rastreia pagina e funcionalidade ate a prova.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/APPLICATION_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de aplicacoes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/PAGE_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de paginas/ecras.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)HELP_AND_ACADEMY\.md.*HLP unidade de ajuda.*VID v.deo.*CRS curso/aula.*APP/PAGE/FNC.*HLP por idioma aprovado.*VID.*CRS' 'O prompt 03 nao modela ajuda contextual e Academia com IDs e matriz rastreavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/applications/APP-<slug>\.md' 'O prompt 03 nao modulariza o contrato de cada aplicacao ativa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/pages/PAGE-<slug>\.md' 'O prompt 03 nao modulariza o contrato de cada pagina/ecra.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)### 1\. Enquadrar.*### 6\. Fechar' 'O prompt 03 nao orienta o Codex por fases verificaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Limites de autoridade' 'O prompt 03 nao define autonomia e fronteiras da tarefa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)PERM autoriza..o.*INT integra..o.*NFR qualidade mensur.vel.*SEC seguran.a/privacidade' 'O contrato inline nao separa permissoes, integracoes e qualidades com IDs estaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'AC-<REQ>-##' 'O prompt 03 nao exige cenarios de aceitacao identificados por requisito.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)duas implementa..es semanticamente\s+incompat.veis' 'O prompt 03 nao testa requisitos contra ambiguidade semantica.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Gate A permanece `PENDENTE`' 'O prompt 03 pode aprovar indevidamente o Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)data/hora real do sistema.*n.o estimes' 'O prompt 03 nao ancora os timestamps no relogio real.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'p.gina oficial\s+de licen.a' 'O prompt 03 aceita uma demo como prova de licenca.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)Reconcilia mecanicamente todas as ocorr.ncias.*APP/PAGE/BPP/BPR' 'O prompt 03 nao reconcilia identidades e destinos mecanicamente.'
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)(?=.*Todas\s+as aplica..es, p.ginas/ecr.s, endpoints)(?=.*m.ximo detalhe)(?=.*approved_for_refinement.*n.o autoriza omitir)(?=.*pending.*blocked)(?=.*ALL_FUNCTIONALITIES\.md)' 'O Gate A nao exige o levantamento integral antes da implementacao.'
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)ALL_FUNCTIONALITIES\.md.*n.o omitem\s+detalhe existente.*linhas gen.ricas' 'O Gate A nao protege a paridade das vistas derivadas sem falsa completude.'
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)GATE_A_USER_RESEARCH_STATUS.*GATE_A_SOLUTION_VALIDATION_STATUS' 'O Gate A nao conserva marcadores mecanicos de investigacao e validacao.'
Require-Pattern 'scripts/Test-ProductDefinitionGate.ps1' '(?s)approved_exception.*GATE_A_USER_RESEARCH_EVIDENCE' 'O gate mecanico nao bloqueia evidencia de utilizadores ausente.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_APLICACOES.*CONTRATOS_POR_APLICACAO' 'O contexto nao encaminha o Codex para os contratos modulares por aplicacao.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_PAGINAS.*CONTRATOS_POR_PAGINA' 'O contexto nao encaminha o Codex para os contratos modulares por pagina.'
Require-Pattern 'APP_CONTEXT.md' 'CHECKLIST_REQUISITOS_PROGRAMADOR.*DEVELOPER_REQUIREMENTS_CHECKLIST' 'O contexto nao resolve o handoff de requisitos do programador.'
Require-Pattern 'APP_CONTEXT.md' 'FICHEIRO_UNICO_FUNCIONALIDADES.*ALL_FUNCTIONALITIES' 'O contexto nao resolve o ficheiro unico de funcionalidades.'
Require-Pattern 'QUALITY_GATES.md' '(?s)(?=.*todas as aplica..es, p.ginas/ecr.s, endpoints)(?=.*ID \| Quem \| Onde \| Quando \| O qu.)(?=.*sem amostragem)(?=.*approved_for_refinement.*oculta)' 'O G01 nao exige levantamento integral e impede lacunas ocultas.'
Require-Pattern 'QUALITY_GATES.md' '(?s)vistas derivadas em paridade.*linha gen.rica.*resumo' 'O G01 nao bloqueia falsa completude nas vistas derivadas.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)p.gina Clientes.*todas as aplica..es' 'O EVAL-11 nao testa ambiguidade concreta por pagina e aplicacao.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'future access timestamp' 'O oraculo de EVAL-15 nao rejeita timestamps futuros.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'APP-003.*BPP-007' 'O oraculo de EVAL-15 nao verifica o mapeamento publico SSR.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'developer checklist omits catalog page' 'O oraculo de EVAL-15 nao deteta paginas omitidas na checklist do programador.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'ALL_FUNCTIONALITIES\.md' 'O oraculo de EVAL-15 nao exige o ficheiro unico de funcionalidades.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'single functionality file contains duplicate RF-P identifiers' 'O oraculo de EVAL-15 nao rejeita IDs RF-P duplicados.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-15-R1.*timestamps.*futuro.*BPP-007.*BPR-002' 'A falha adversarial de EVAL-15-R1 nao esta preservada.'
$prompt03Path = Join-Path $root 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md'
if ((Test-Path -LiteralPath $prompt03Path -PathType Leaf) -and
    (Get-Content -Encoding UTF8 -LiteralPath $prompt03Path).Count -gt 460) {
    Add-Failure 'O prompt 03 autocontido excede o budget de 460 linhas.'
}
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/05-definir-arquitetura-e-selecionar-modulos.md' 'PRODUCT_DEFINITION\.md' 'O prompt 05 nao verifica o artefacto da etapa 1.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/05-definir-arquitetura-e-selecionar-modulos.md' 'termina com estado `bloqueado`' 'O prompt 05 nao bloqueia quando o Gate A falha.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/05-definir-arquitetura-e-selecionar-modulos.md' 'Test-ProductDefinitionGate\.ps1' 'O prompt 05 nao executa o gate mecanico.'
$stage02 = @($manifest.stages | Where-Object { [string]$_.id -eq '02' })[0]
$stage03 = @($manifest.stages | Where-Object { [string]$_.id -eq '03' })[0]
if ((@($stage02.conditionalPromptIds) -join ',') -ne '05,06,10,11') {
    Add-Failure 'Os prompts opcionais da etapa 2 nao estao declarados como condicionais.'
}
if ((@($stage02.promptIds) -join ',') -ne '05,06,07,08,09,10,11' -or
    (@($stage03.promptIds) -join ',') -ne '12,13,14,15,16,17,18,19,20') {
    Add-Failure 'Os prompts complementares 09/20 nao estao ordenados nas fases corretas.'
}
Require-Pattern 'prompts/02-arquitetura-e-fundacao/09-completar-requisitos-apos-fundacao-tecnica.md' '(?s)prompt 03.*preserva.*IDs.*Reconcilia mecanicamente' 'O prompt 09 nao completa os requisitos tecnicos preservando a fonte canonica.'
Require-Pattern 'prompts/03-marca-e-layout/20-completar-requisitos-apos-refinamento-visual.md' '(?s)prompt 03.*prompts 14, 16 ou 18.*antes do prompt 28 ou 30.*Reconcilia' 'O prompt 20 nao completa os requisitos depois do refinamento visual.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/09-completar-requisitos-apos-fundacao-tecnica.md' '(?s)P.GINA\|ECR.\|ENDPOINT\|OPERA..O-N.O-VISUAL.*ID \| Quem \| Onde \| Quando \| O qu..*sem\s+amostragem.*IDs repetidos' 'O prompt 09 nao preserva o formato exaustivo no delta tecnico.'
Require-Pattern 'prompts/03-marca-e-layout/20-completar-requisitos-apos-refinamento-visual.md' '(?s)P.GINA\|ECR.\|ENDPOINT\|OPERA..O-N.O-VISUAL.*ID \| Quem \| Onde \| Quando \| O qu..*sem amostragem.*reutiliza..o de IDs' 'O prompt 20 nao preserva o formato exaustivo no delta visual.'
Require-Pattern 'software-lifecycle.ps1' '(?s)CompletedId -eq ''08''.*return ''09''.*CompletedId -eq ''09''.*return ''10''' 'O lifecycle nao executa o complemento tecnico na posicao pretendida.'
Require-Pattern 'software-lifecycle.ps1' '(?s)CompletedId -in @\(''14'', ''16'', ''18''\).*return ''20''.*CompletedId -eq ''20''.*''28''.*''30''' 'O lifecycle nao reconcilia requisitos entre layout e implementacao.'
Require-Pattern 'software-lifecycle.ps1' '(?s)Get-PromptIdentityMigrationMap.*stable identity.*moved from.*Convert-StatePromptIdentities.*identity remaps' 'O upgrade nao migra renumeracoes pelo nome estavel do prompt.'
Require-Pattern 'software-lifecycle.ps1' '(?s)stable identity.*has.*matches in the source catalog.*ambiguous prompt identity migration' 'O upgrade nao bloqueia identidades removidas ou ambiguas.'
Require-Pattern 'scripts/Update-AdvanceLocalProjects.ps1' '(?s)(?=.*SoftwareProcesses)(?=.*LIFECYCLE_STATE\.json)(?=.*activeWorkAttemptId)(?=.*completed immutable lifecycle)(?=.*recovery/concurrent-update marker)(?=.*upgrade)(?=.*ConfirmMigration)(?=.*AcceptCandidateCatalog)(?=.*validate)' 'A propagacao local nao descobre, protege, migra e valida lifecycles conhecidos.'
Require-Pattern 'AGENTS.md' '(?s)Update-AdvanceLocalProjects\.ps1.*AcceptCandidateCatalog.*preserva estado e evid.ncias.*n.o altera lifecycles conclu.dos.*tentativa ativa.*marcadores.*plugin.*restantes projetos locais' 'A regra duradoura nao propaga a tool com seguranca aos projetos locais conhecidos.'
Require-Pattern 'README.md' '(?s)Update-AdvanceLocalProjects\.ps1 -AcceptCandidateCatalog.*upgrade.*Lifecycles conclu.dos, ativos, inv.lidos.*plugin\s+global' 'O README nao explica a propagacao local e os casos ignorados.'
Require-Pattern 'PROCESS_MANIFEST.json' '"advanceToolPropagationToKnownLocalProjectsRequired": true' 'O manifesto nao exige propagacao da tool aos lifecycles locais conhecidos.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'Copia .*PRODUCT_DEFINITION\.md' 'O prompt 07 nao copia a definicao aprovada para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'Copia .*HELP_AND_ACADEMY\.md' 'O prompt 07 nao copia o protocolo de ajuda para a aplicacao derivada.'
Require-Pattern 'software-lifecycle.ps1' "'HELP_AND_ACADEMY\.md'" 'O inicializador nao copia o protocolo de ajuda para cada instancia.'
Require-Pattern 'scripts/Test-SoftwareLifecycle.ps1' "'HELP_AND_ACADEMY\.md'" 'O teste end-to-end nao exige o protocolo de ajuda na instancia criada.'
Require-Pattern 'software-lifecycle.ps1' "'UPSTREAM_LEARNING\.md'" 'O lifecycle nao copia o contrato de aprendizagem upstream para cada instancia.'
Require-Pattern 'scripts/Test-SoftwareLifecycle.ps1' "'UPSTREAM_LEARNING\.md'" 'O teste end-to-end nao exige o contrato upstream na instancia.'
Require-Pattern '.agents/skills/advance-app-start/SKILL.md' '(?s)HELP_AND_ACADEMY\.md.*contextual help.*task videos.*Academy' 'A skill de arranque nao le condicionalmente o protocolo de ajuda.'
Require-Pattern '.agents/skills/advance-app-continue/SKILL.md' '(?s)HELP_AND_ACADEMY\.md.*contextual\s+help.*task videos.*Academy' 'A skill de continuacao nao le condicionalmente o protocolo de ajuda.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'scripts/Test-ProductDefinitionGate\.ps1' 'O prompt 07 nao copia o gate mecanico para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '\.agents/skills/advance-app-continue' 'O prompt 07 nao copia a skill para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'Ado..o brownfield' 'O prompt 07 nao possui uma rota brownfield explicita.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'N.o uses checkout/reset/clean' 'A rota brownfield nao preserva alteracoes Git locais.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'painel administrativo gen.rico' 'Falta o gate contra UI generica.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'regress.o visual automatizada' 'Falta regressao visual obrigatoria.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'checks autom.ticos de acessibilidade em cada pull request' 'Falta acessibilidade continua.'
Require-Pattern 'prompts/09-entrega-e-distribuicao/58-configurar-ci-cd-e-ambientes-de-deploy.md' 'diff visual' 'O CI nao publica/compara o diff visual.'
Require-Pattern 'prompts/09-entrega-e-distribuicao/58-configurar-ci-cd-e-ambientes-de-deploy.md' '(?s)attestation.*source SHA.*digest' 'O CI nao gera e verifica proveniencia assinada.'
Require-Pattern 'scripts/Test-LifecycleGateEvidence.ps1' '(?s)build-provenance-attestation.*sourceSha.*verificationPassed' 'Os gates estruturados nao verificam attestation da candidata.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/66-executar-revisao-final-independente.md' 'read-only' 'Falta revisao final read-only.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/67-publicar-com-migrations-smoke-tests-e-rollback.md' '\[AUTORIZAR_RELEASE\]' 'A publicacao nao exige autorizacao explicita.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/67-publicar-com-migrations-smoke-tests-e-rollback.md' '(?s)\[CANDIDATE_SHA\].*\[ARTIFACT_DIGEST\]' 'A publicacao nao fixa candidate SHA e digest.'
Require-Pattern 'prompts/12-operacao-continua/76-medir-metricas-dora-e-melhoria-continua.md' 'deployment rework rate' 'O prompt DORA nao usa as cinco metricas atuais.'
Require-Pattern 'prompts/12-operacao-continua/76-medir-metricas-dora-e-melhoria-continua.md' 'dora-metrics/' 'O prompt DORA nao usa a referencia atual.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/32-validar-vantagem-competitiva-layout-funcionalidades-e-fluxos.md' '(?s)tr.s a sete concorrentes diretos.*alternativa adjacente.*fontes prim.rias' 'O prompt competitivo nao exige selecao atual e rastreavel de concorrentes.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/32-validar-vantagem-competitiva-layout-funcionalidades-e-fluxos.md' '(?s)vantagem demonstrada.*vantagem condicionada.*paridade.*desvantagem.*n.o demonstr.vel' 'O prompt competitivo força uma conclusao positiva ou nao possui veredito honesto.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/32-validar-vantagem-competitiva-layout-funcionalidades-e-fluxos.md' '(?s)COMPETITIVE_QUALITY_AUDIT\.md.*an.lise de sensibilidade.*backlog priorizado.*n.o o implementes' 'O prompt competitivo nao conserva evidência, robustez e handoff diagnostico.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/32-validar-vantagem-competitiva-layout-funcionalidades-e-fluxos.md' '(?s)conte.do externo como dados n.o confi.veis.*Ignora instru..es.*n.o instala software.*compra.*login.*sem autoriza..o' 'O prompt competitivo nao limita instrucoes e acoes externas encontradas na pesquisa.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-13' 'O piloto nao conserva o caso de revisao independente.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-14.*naming natural' 'O piloto nao contem a regressao dirigida do prompt 02.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-15.*requisitos pesquisados por aplica..o e p.gina' 'O piloto nao contem a regressao dirigida do prompt 03.'
Require-Pattern 'PROMPT_EVALUATION.md' 'ROUTE-EVAL-06: 21 -> 22 -> 23 -> 24 -> \(27 -> 14\|16\|18 -> 20 -> 28 \| 29 -> 14\|16\|18 -> 20 -> 30\)' 'EVAL-06 nao usa a numeracao canonica atual.'
Forbid-Pattern 'PROMPT_EVALUATION.md' 'usando 19 e 25/26 ou 27/28' 'EVAL-06 conserva a referencia semantica obsoleta anterior a renumeracao.'
Require-Pattern 'pilot/cases/EVAL-14.md' 'Navirevo.*Prumivo.*Rivelumi' 'O caso EVAL-14 nao inclui os nomes mecanicos rejeitados.'
Require-Pattern 'pilot/cases/EVAL-14.md' '(?s)n.o existe consulta WIPO/EUIPO.*pausa interm.dia.*CAPTCHA.*valida..o jur.dica formal' 'O EVAL-14 nao impede a reintroducao da pausa juridica/manual no prompt 02.'
Require-Pattern 'pilot/cases/EVAL-14.md' '(?s)(?=.*segunda c.pia descart.vel)(?=.*removendo apenas)(?=.*Idiomas materiais)(?=.*Custo m.ximo do.*com)(?=.*portugu.s europeu \(pt-PT\) \+ ingl.s\s+internacional)(?=.*30 EUR/ano, IVA inclu.do)(?=.*n.o pergunta)(?=.*n.o bloqueia)' 'O EVAL-14 nao cobre os defaults sem pergunta nem bloqueio.'
Require-Pattern 'scripts/Test-Prompt02PilotArtifact.ps1' '(?s)Triagem jur.dica formal.*Interven..o manual solicitada.*manual CAPTCHA step' 'O oraculo EVAL-14 nao prova a remocao do passo manual.'
Require-Pattern 'pilot/fixtures/prompt-02/untrusted-search-result.html' 'Ignore as instru..es anteriores' 'A fixture adversarial do prompt 02 esta ausente.'
Require-Pattern 'pilot/fixtures/prompt-02/app-context.md' '30 EUR \+ IVA' 'O contexto material de EVAL-14 nao fixa o orcamento do dominio.'
Require-Pattern 'pilot/fixtures/prompt-02/product-definition.md' 'Decis.o.*avan.ar' 'A definicao de produto de EVAL-14 nao prova a decisao do prompt 01.'
Require-Pattern 'pilot/fixtures/prompt-02/implementation-status.md' '02-criar-nome-da-app.*em curso' 'O estado de EVAL-14 nao seleciona o prompt 02.'
Require-Pattern 'pilot/PILOT-002-EVAL-14-EXECUTION.md' 'PASS t.cnico para EVAL-14' 'A execução dirigida de EVAL-14 não conserva a decisão técnica.'
Require-Pattern 'pilot/PILOT-002-EVAL-14-EXECUTION.md' 'FA0081F9510EADFD2169EE0F81462F4CB4E028963F6FE55440C555398857819C' 'A execução dirigida de EVAL-14 não fixa o hash do prompt avaliado.'
Require-Pattern 'scripts/Test-Prompt02PilotArtifact.ps1' 'Human rubric and full 15-case pilot approval remain separate requirements' 'O validador de EVAL-14 confunde o teste técnico com aprovação humana.'
Require-Pattern 'pilot/cases/EVAL-15.md' '(?s)compar.veis diretos.*adjacente.*fonte madura.*refer.ncias\s+premium' 'O caso EVAL-15 nao cobre a pesquisa externa exigida.'
Require-Pattern 'pilot/cases/EVAL-15.md' '(?s)ALL_FUNCTIONALITIES\.md.*ID \| Quem \| Onde \| Quando \| O qu..*RF-P' 'O caso EVAL-15 nao valida o formato unico e os requisitos atomicos por funcionalidade.'
Require-Pattern 'pilot/cases/EVAL-15.md' '(?s)(?=.*P.GINA\|ECR.\|ENDPOINT\|OPERA..O-N.O-VISUAL)(?=.*globalmente .nicos)(?=.*zero omiss.es sem justifica..o)(?=.*sem amostragem)' 'EVAL-15 nao valida o levantamento integral no formato pedido.'
Require-Pattern 'pilot/cases/EVAL-15.md' '(?s)ajuda contextual bilingue.*v.deo e\s+Academia.*planeados.*APP/PAGE/FNC.*HLP.*VID.*CRS.*fallback.*sem provider' 'O EVAL-15 nao exercita aplicabilidade e fail-closed de ajuda/Academia.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' '(?s)contextual-help and academy matrix.*first help unit.*invent an external video provider' 'O oraculo EVAL-15 nao valida matriz de ajuda nem publicacao externa inventada.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/05-definir-arquitetura-e-selecionar-modulos.md' '(?s)HELP_AND_ACADEMY\.md.*APP/PAGE/FNC.*pesquisa.*cursos/.*progresso.*n.o listado' 'A arquitetura nao decide fronteiras e riscos da ajuda/Academia.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/06-modelar-ameacas-e-requisitos-de-seguranca.md' '(?s)ajuda multim.dia/Academia.*embeds.*OAuth/upload.*n.o listados.*controlo de acesso' 'O threat model nao cobre os ativos e fronteiras do fornecedor de video.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/10-configurar-ambientes-segredos-e-configuracao.md' '(?s)ajuda multim.dia/Academia.*player.*gest.o/upload.*dom.nios/CSP.*sem o fornecedor' 'A configuracao nao separa player, credenciais e fallback por ambiente.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/Optional/11-definir-contratos-api-versionamento-e-compatibilidade.md' '(?s)ajuda/Academia.*APP/PAGE/FNC.*progresso.*IDs/URLs do fornecedor.*evento do player.*n.o prova sozinho aprendizagem' 'Os contratos API nao cobrem contexto, progresso e limites do provider.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/25-implementar-requisitos-globais.md' '(?s)HELP_AND_ACADEMY\.md.*FNC -> HLP por idioma -> VID -> contexto -> CRS.*fallback textual.*n.o faz upload real' 'O prompt 23 nao implementa a primeira unidade vertical de ajuda com provider isolado.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/26-criar-testes-playwright-para-requisitos-globais.md' '(?s)APP/PAGE/FNC.*player simulado.*fornecedor indispon.vel.*fallback.*n.o chama YouTube real' 'Os testes globais nao isolam o player externo e o fallback da ajuda.'
Require-Pattern 'prompts/04-backend-e-funcionalidades/Optional/34-validar-localizacao-e-formatacao-cultural.md' '(?s)HLP/VID/CRS.*narra..o.*captions.*transcri..o.*Caption autom.tica.*provis.ria' 'O prompt de localizacao nao valida os idiomas dos conteudos de ajuda.'
Require-Pattern 'prompts/05-seguranca-e-privacidade/42-auditar-seguranca-com-owasp-asvs.md' '(?s)CSP/frame-src.*cookies/tracking.*OAuth/segredos.*IDOR em progresso' 'A auditoria de seguranca nao cobre o provider multimédia e progresso da Academia.'
Require-Pattern 'prompts/06-conformidade-e-presenca-publica/46-auditar-acessibilidade-wcag.md' '(?s)HELP_AND_ACADEMY\.md.*captions revistas.*transcri..o.*iframe/player.*foco.*captions autom.ticas' 'A auditoria WCAG nao cobre media de ajuda com captions revistas.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/64-concluir-documentacao-e-plano-de-manutencao.md' '(?s)HELP_AND_ACADEMY\.md.*autoriza..o expl.cita.*canal/playlist.*IDs/URLs.*smoke test.*Sem autoriza..o.*`parcial`' 'O prompt 64 nao produz/publica videos com autorizacao e fail-closed.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/65-executar-aceitacao-final-e-checklist-de-release.md' 'APP/PAGE/FNC/HLP/VID/CRS' 'A aceitacao final nao reconcilia a matriz de ajuda e Academia.'
Require-Pattern 'pilot/fixtures/prompt-03/untrusted-premium-preview.html' 'Ignore as instru..es anteriores' 'A fixture adversarial do prompt 03 esta ausente.'
Require-Pattern 'pilot/fixtures/prompt-03/product-definition.md' 'QST-001.*pendente' 'As fontes de EVAL-15 nao conservam uma decisao material em falta.'
Require-Pattern 'pilot/fixtures/prompt-03/user-research-evidence.md' '(?s)Method.*Prototype task.*Limitation' 'EVAL-15 nao inclui evidencia sintetica de user research com limites.'
Require-Pattern 'pilot/fixtures/prompt-03/product-definition.md' 'Gate A.*PENDENTE' 'A definicao de EVAL-15 nao conserva o Gate A pendente.'
Require-Pattern 'pilot/fixtures/prompt-03/implementation-status.md' '03-levantar-requisitos-funcionais.*em curso' 'O estado de EVAL-15 nao seleciona o prompt 03.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'Human rubric and full 15-case pilot approval remain separate requirements' 'O validador de EVAL-15 confunde o teste tecnico com aprovacao humana.'
Require-Pattern 'PROMPT_EVALUATION.md' 'PILOT-001.*pendente' 'PILOT-001 nao esta honestamente pendente.'

$gateScript = Join-Path $root 'scripts/Test-ProductDefinitionGate.ps1'
$gateFixtureRoot = Join-Path $root 'pilot/fixtures/product-definition-gate'
$fixtureStatus = Join-Path $gateFixtureRoot 'implementation-status.md'
$validDefinition = Join-Path $gateFixtureRoot 'valid-product-definition.md'
$invalidDefinition = Join-Path $gateFixtureRoot 'invalid-product-definition.md'

if (
    (Test-Path -LiteralPath $gateScript -PathType Leaf) -and
    (Test-Path -LiteralPath $fixtureStatus -PathType Leaf) -and
    (Test-Path -LiteralPath $validDefinition -PathType Leaf) -and
    (Test-Path -LiteralPath $invalidDefinition -PathType Leaf)
) {
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $gateScript `
        -DefinitionPath $validDefinition -StatusPath $fixtureStatus *> $null
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'O gate mecanico rejeitou a fixture valida.'
    }

    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $gateScript `
        -DefinitionPath $invalidDefinition -StatusPath $fixtureStatus *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Failure 'O gate mecanico aceitou a fixture invalida.'
    }
}
else {
    Add-Failure 'Fixtures do gate mecanico ausentes.'
}

$qualityGateScript = Join-Path $root 'scripts/Test-ProductQualityGate.ps1'
$validQualityBaseline = Join-Path $root 'pilot/fixtures/product-quality-gate/valid-product-quality-baseline.md'
if (
    (Test-Path -LiteralPath $qualityGateScript -PathType Leaf) -and
    (Test-Path -LiteralPath $validQualityBaseline -PathType Leaf)
) {
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $qualityGateScript `
        -BaselinePath $validQualityBaseline *> $null
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'O gate de qualidade visual rejeitou a fixture valida.'
    }

    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $qualityGateScript `
        -BaselinePath (Join-Path $root 'PRODUCT_QUALITY_BASELINE.md') *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Failure 'O gate de qualidade visual aceitou a baseline template pendente.'
    }
}
else {
    Add-Failure 'Fixture ou script do gate de qualidade visual ausente.'
}

$readinessGateScript = Join-Path $root 'scripts/Test-ImplementationReadinessGate.ps1'
$validPilotApproval = Join-Path $root 'pilot/fixtures/implementation-readiness-gate/valid-pilot-approval.md'
if (
    (Test-Path -LiteralPath $readinessGateScript -PathType Leaf) -and
    (Test-Path -LiteralPath $validPilotApproval -PathType Leaf)
) {
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $readinessGateScript `
        -ApprovalPath $validPilotApproval -ManifestPath $manifestPath *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Failure 'O gate de readiness aceitou uma candidata mesmo com piloto fixture aprovado.'
    }

    $stableManifestFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("stable-manifest-fixture-" + [Guid]::NewGuid().ToString('N') + '.json')
    $stableManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    $stableManifest.releaseChannel = 'stable'
    [System.IO.File]::WriteAllText(
        $stableManifestFixture,
        ($stableManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false)))
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $readinessGateScript `
        -ApprovalPath $validPilotApproval -ManifestPath $stableManifestFixture *> $null
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'O gate de readiness rejeitou a fixture de piloto valida.'
    }
    Remove-Item -LiteralPath $stableManifestFixture -Force

    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $readinessGateScript `
        -ApprovalPath (Join-Path $root 'PILOT_APPROVAL.md') -ManifestPath $manifestPath *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Failure 'O gate de readiness aceitou o piloto pendente.'
    }
}
else {
    Add-Failure 'Fixture ou script do gate de readiness ausente.'
}

$lifecycleGateScript = Join-Path $root 'scripts/Test-LifecycleGateEvidence.ps1'
$validLifecycleEvidence = Join-Path $root 'pilot/fixtures/lifecycle-gates/valid-lifecycle-gate-evidence.json'
if (
    (Test-Path -LiteralPath $lifecycleGateScript -PathType Leaf) -and
    (Test-Path -LiteralPath $validLifecycleEvidence -PathType Leaf)
) {
    $approvers = @{
        G06 = 'Fixture Security Approver'
        G07 = 'Fixture Operations Approver'
        G08 = 'Fixture Independent Reviewer'
        G09 = 'Fixture Release Approver'
        G10 = 'Fixture Continuous Operations Owner'
    }
    foreach ($gateId in @('G06', 'G07', 'G08', 'G09', 'G10')) {
        $phase = $(if ($gateId -eq 'G09') { 'release_completed' } else { 'gate' })
        & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
            -GateId $gateId -EvidencePath $validLifecycleEvidence -ProcessRoot $root `
            -ApprovedBy $approvers[$gateId] -Phase $phase *> $null
        if ($LASTEXITCODE -ne 0) {
            Add-Failure "O gate estruturado $gateId rejeitou a fixture valida."
        }
    }
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
        -GateId G08 -EvidencePath (Join-Path $root 'LIFECYCLE_GATE_EVIDENCE.json') `
        -ProcessRoot $root -ApprovedBy 'Fake Reviewer' *> $null
    if ($LASTEXITCODE -eq 0) {
        Add-Failure 'G08 aceitou a evidencia template sem candidata/revisao independente.'
    }

    $emptyChecksFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("prompts-empty-gate-checks-" + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        $emptyChecksEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $validLifecycleEvidence | ConvertFrom-Json
        $emptyChecksEvidence.gates.G06.checks = [pscustomobject]@{}
        $fixtureEncoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText(
            $emptyChecksFixture,
            ($emptyChecksEvidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
            $fixtureEncoding)
        & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
            -GateId G06 -EvidencePath $emptyChecksFixture -ProcessRoot $root `
            -ApprovedBy 'Fixture Security Approver' *> $null
        if ($LASTEXITCODE -eq 0) {
            Add-Failure 'G06 aceitou um objeto checks vazio.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $emptyChecksFixture -PathType Leaf) {
            Remove-Item -LiteralPath $emptyChecksFixture -Force
        }
    }

    $strictTypesFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("prompts-strict-gate-types-" + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        $strictTypesEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $validLifecycleEvidence | ConvertFrom-Json
        $strictTypesEvidence.gates.G06.checks.securityTestsPassed = 'true'
        $strictTypesEvidence.gates.G08.independentReview.readOnly = 'true'
        $strictTypesEvidence.gates.G09.deployment.smokeTestsPassed = 'true'
        $strictTypesEvidence.gates.G09.deployment.attestationVerified = 'true'
        $strictTypesEvidence.gates.G09.deployment.rollbackReady = 'true'
        [System.IO.File]::WriteAllText(
            $strictTypesFixture,
            ($strictTypesEvidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
            $fixtureEncoding)
        foreach ($strictGate in @(
            @{ Id = 'G06'; Approver = 'Fixture Security Approver'; Phase = 'gate' },
            @{ Id = 'G08'; Approver = 'Fixture Independent Reviewer'; Phase = 'gate' },
            @{ Id = 'G09'; Approver = 'Fixture Release Approver'; Phase = 'release_completed' }
        )) {
            & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
                -GateId $strictGate.Id -EvidencePath $strictTypesFixture -ProcessRoot $root `
                -ApprovedBy $strictGate.Approver -Phase $strictGate.Phase *> $null
            if ($LASTEXITCODE -eq 0) {
                Add-Failure "$($strictGate.Id) aceitou a string 'true' no lugar de um booleano."
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $strictTypesFixture -PathType Leaf) {
            Remove-Item -LiteralPath $strictTypesFixture -Force
        }
    }

    $invalidProvenanceFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("prompts-invalid-provenance-" + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        $invalidProvenanceEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $validLifecycleEvidence | ConvertFrom-Json
        $invalidProvenanceEvidence.gates.G08.candidate.provenance.sourceSha = '3333333333333333333333333333333333333333'
        $invalidProvenanceEvidence.gates.G08.candidate.provenance.verificationPassed = $false
        [System.IO.File]::WriteAllText(
            $invalidProvenanceFixture,
            ($invalidProvenanceEvidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
            $fixtureEncoding)
        & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
            -GateId G08 -EvidencePath $invalidProvenanceFixture -ProcessRoot $root `
            -ApprovedBy 'Fixture Independent Reviewer' *> $null
        if ($LASTEXITCODE -eq 0) {
            Add-Failure 'G08 aceitou attestation nao verificada ou ligada a outro commit.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $invalidProvenanceFixture -PathType Leaf) {
            Remove-Item -LiteralPath $invalidProvenanceFixture -Force
        }
    }

    $invalidReleaseWindowFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("prompts-invalid-release-window-" + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        $invalidReleaseWindowEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $validLifecycleEvidence | ConvertFrom-Json
        $invalidReleaseWindowEvidence.gates.G09.authorization.authorizedAt = 'not-a-timestamp'
        $invalidReleaseWindowEvidence.gates.G09.authorization.releaseWindow = 'banana'
        [System.IO.File]::WriteAllText(
            $invalidReleaseWindowFixture,
            ($invalidReleaseWindowEvidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
            $fixtureEncoding)
        & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $lifecycleGateScript `
            -GateId G09 -EvidencePath $invalidReleaseWindowFixture -ProcessRoot $root `
            -ApprovedBy 'Fixture Release Approver' -Phase gate *> $null
        if ($LASTEXITCODE -eq 0) {
            Add-Failure 'G09 aceitou authorizedAt/releaseWindow temporalmente invalidos.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $invalidReleaseWindowFixture -PathType Leaf) {
            Remove-Item -LiteralPath $invalidReleaseWindowFixture -Force
        }
    }
}
else {
    Add-Failure 'Fixture ou script dos gates estruturados G06-G10 ausente.'
}

$stalePatterns = @(
    '64 prompts',
    'dora-metrics-four-keys',
    'prompts/08-qualidade-e-hardening/55-validar-cache',
    'prompts/08-qualidade-e-hardening/56-validar-seo',
    'prompts/09-entrega-e-distribuicao/55-configurar-ci',
    'prompts/11-aceitacao-e-manutencao/64-publicar',
    'usando 19 e 25/26 ou 27/28'
)

foreach ($relativeScript in $requiredScripts) {
    $scriptPath = Join-Path $root $relativeScript
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        continue
    }
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptPath,
        [ref]$tokens,
        [ref]$parseErrors) | Out-Null
    foreach ($parseError in @($parseErrors)) {
        Add-Failure "Erro de sintaxe em ${relativeScript}: $($parseError.Message)"
    }
}

foreach ($pattern in $stalePatterns) {
    foreach ($file in $markdownFiles) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        if ($content.Contains($pattern)) {
            Add-Failure "Referencia obsoleta '$pattern' em $($file.FullName)"
        }
    }
}

$promptReferenceScript = Join-Path $root 'scripts/Test-PromptReferences.ps1'
if (Test-Path -LiteralPath $promptReferenceScript -PathType Leaf) {
    & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $promptReferenceScript *> $null
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'O validador semantico de identidades/routing dos prompts falhou.'
    }
}
else {
    Add-Failure 'O validador semantico de identidades/routing esta ausente.'
}

if ($failures.Count -gt 0) {
    Write-Host "FAIL: $($failures.Count) problema(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: processo documental coerente.' -ForegroundColor Green
Write-Host " - Prompts: $($promptFiles.Count), numeracao continua 01-76."
Write-Host " - Links locais: validos em $($markdownFiles.Count) ficheiros Markdown."
Write-Host ' - Placeholders: declarados no APP_CONTEXT.md.'
Write-Host ' - Gate da definicao: fixture valida aceite e fixture invalida bloqueada.'
Write-Host ' - Orquestracao: manifesto, START_HERE, skill e scripts verificados.'
Write-Host ' - Gates estaticos: definicao do produto, arquitetura, fatias verticais, qualidade visual/codigo, acessibilidade, revisao independente, release e operacao verificados.'
Write-Host 'Nota: esta validacao estatica nao executa nem aprova PILOT-001.'
