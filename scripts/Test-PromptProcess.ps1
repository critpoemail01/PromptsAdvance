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

$requiredDocuments = @(
    'START_HERE.md',
    'PROCESS_MANIFEST.json',
    'QUALITY_GATES.md',
    'README.md',
    'AGENTS.md',
    'EXECUTION_CONTRACT.md',
    'PRODUCT_EXCELLENCE.md',
    'PRODUCT_DEFINITION.md',
    'PRODUCT_QUALITY_BASELINE.md',
    'APP_CONTEXT.md',
    'IMPLEMENTATION_STATUS.md',
    'LIFECYCLE_GATE_EVIDENCE.json',
    'PILOT_APPROVAL.md',
    'PROMPT_EVALUATION.md',
    'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt'
)

$requiredScripts = @(
    'scripts/Test-ProductDefinitionGate.ps1',
    'scripts/Test-ImplementationReadinessGate.ps1',
    'scripts/Test-LifecycleGateEvidence.ps1',
    'scripts/Test-ProductQualityGate.ps1',
    'scripts/Test-SoftwareLifecycle.ps1',
    'scripts/Test-ProcessInDisposableCopy.ps1',
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

$promptRoot = Join-Path $root 'prompts'
$promptFiles = @(Get-ChildItem -LiteralPath $promptRoot -Recurse -File -Filter '*.md')
if ($promptFiles.Count -ne 73) {
    Add-Failure "Esperados 73 prompts; encontrados $($promptFiles.Count)."
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

foreach ($expected in 1..73) {
    if ($expected -notin $numbers) {
        Add-Failure "Numero de prompt em falta: $expected"
    }
}

$manifestPath = Join-Path $root 'PROCESS_MANIFEST.json'
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
        if ([int]$manifest.promptCount -ne 73) {
            Add-Failure "PROCESS_MANIFEST.json declara $($manifest.promptCount) prompts em vez de 73."
        }
        $manifestPromptIds = @($manifest.stages | ForEach-Object { @($_.promptIds) })
        foreach ($expected in 1..73 | ForEach-Object { '{0:D2}' -f $_ }) {
            if ($expected -notin $manifestPromptIds) {
                Add-Failure "Prompt $expected ausente do PROCESS_MANIFEST.json."
            }
        }
        $manifestDuplicates = @($manifestPromptIds | Group-Object | Where-Object Count -gt 1)
        foreach ($duplicate in $manifestDuplicates) {
            Add-Failure "Prompt duplicado no PROCESS_MANIFEST.json: $($duplicate.Name)"
        }
    }
    catch {
        Add-Failure "PROCESS_MANIFEST.json invalido: $($_.Exception.Message)"
    }
}

$markdownFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md')
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

        $resolved = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathPart))
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
Require-Pattern 'START_HERE.md' '\$build-professional-web-software' 'START_HERE nao fornece o ponto de entrada da skill.'
Require-Pattern 'START_HERE.md' 'software-lifecycle\.ps1 start' 'START_HERE nao fornece inicializacao deterministica.'
Require-Pattern 'START_HERE.md' 'Continua o projeto Advance em' 'START_HERE nao fornece a entrada natural para continuar por caminho.'
Require-Pattern 'START_HERE.md' 'software-lifecycle\.ps1 continue.*-ProjectPath' 'START_HERE nao documenta a resolucao brownfield por caminho.'
Require-Pattern 'QUALITY_GATES.md' 'G04.*Dire..o profissional' 'Falta o gate profissional da primeira slice.'
Require-Pattern 'QUALITY_GATES.md' 'Hierarquia e composi..o' 'O gate visual nao verifica hierarquia e composicao.'
Require-Pattern 'QUALITY_GATES.md' 'rastreabilidade ponta a ponta' 'O gate de codigo nao exige rastreabilidade ponta a ponta.'
Require-Pattern '.agents/skills/build-professional-web-software/SKILL.md' '(?s)^---.*name: build-professional-web-software.*description:.*---' 'A skill do lifecycle nao tem frontmatter valido.'
Require-Pattern '.agents/skills/build-professional-web-software/SKILL.md' 'software-lifecycle\.ps1 record' 'A skill nao regista resultados no estado do lifecycle.'
Require-Pattern '.agents/skills/build-professional-web-software/SKILL.md' 'continue -ProjectPath' 'A skill nao resolve continuacao/adocao a partir da raiz da aplicacao.'
Require-Pattern '.agents/skills/build-professional-web-software/references/workflow.md' 'page: 25 -> 13\|15\|17 -> 26' 'A skill nao define routing de vertical slices.'
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
Require-Pattern 'software-lifecycle.ps1' 'Get-AllowedSelectionPromptIds' 'O seletor nao restringe transicoes ao contexto atual.'
Require-Pattern 'software-lifecycle.ps1' "Command -eq 'decide'" 'O lifecycle nao permite registar exclusoes opcionais com evidencia.'
Require-Pattern 'software-lifecycle.ps1' "Command -eq 'gate'" 'O lifecycle nao permite decidir gates entre prompts.'
Require-Pattern 'software-lifecycle.ps1' 'Test-GatePrerequisites' 'Os pre-requisitos declarados dos gates nao sao aplicados.'
Require-Pattern 'software-lifecycle.ps1' 'Concurrent lifecycle update detected' 'O estado nao usa controlo de concorrencia otimista.'
Require-Pattern 'software-lifecycle.ps1' 'State catalogVersion.*does not match manifest' 'A validacao nao deteta catalogVersion corrompida.'
Require-Pattern 'software-lifecycle.ps1' 'Assert-ApplicabilityDecisions' 'O routing nao bloqueia saidas com opcionais por decidir.'
Require-Pattern 'software-lifecycle.ps1' 'AcceptanceCriteria' 'O lifecycle nao preserva criterios de aceitacao da slice.'
Require-Pattern 'software-lifecycle.ps1' 'Required progress:' 'O estado nao distingue progresso obrigatorio de opcionais.'
Require-Pattern 'software-lifecycle.ps1' 'Active/latest slice:' 'O estado nao apresenta a fatia ativa e os seus criterios.'
Require-Pattern 'software-lifecycle.ps1' 'Gate command first:' 'O estado nao orienta a passagem do gate antes de selecoes bloqueadas.'
Require-Pattern 'README.md' 'DOR-01 a DOR-12.*passou' 'O README nao bloqueia a etapa 2 ate a definicao do produto passar.'
Require-Pattern 'AGENTS.md' 'PRODUCT_DEFINITION\.md.*Gate A.*GO' 'As instrucoes duradouras nao aplicam o Gate A antes da etapa 2.'
Require-Pattern 'PRODUCT_DEFINITION.md' 'DOR-12' 'A definicao do produto nao contem a checklist completa do Gate A.'
Require-Pattern 'PRODUCT_DEFINITION.md' 'Decis.o do Gate A: GO' 'A definicao do produto nao especifica a decisao GO.'
Require-Pattern 'AGENTS.md' 'Test-ProductDefinitionGate\.ps1' 'As instrucoes duradouras nao executam o gate da definicao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/REQUIREMENTS_SPECIFICATION\.md' 'O prompt 03 nao exige uma especificacao versionada canonica.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/APPLICATION_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de aplicacoes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/PAGE_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de paginas/ecras.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/applications/APP-<slug>\.md' 'O prompt 03 nao modulariza o contrato de cada aplicacao ativa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/pages/PAGE-<slug>\.md' 'O prompt 03 nao modulariza o contrato de cada pagina/ecra.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'contrato detalhado dos artefactos' 'O prompt 03 nao carrega explicitamente o contrato complementar.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)Fase 0.*Fase 1.*Fase 2.*Fase 3.*Fase 4.*Fase 5.*Fase 6' 'O prompt 03 nao orienta o Codex por fases verificaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Não tentes gerar todo o catálogo num único passe' 'O prompt 03 nao obriga a elaboracao incremental por jornada.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Limites de autoridade' 'O prompt 03 nao define autonomia e fronteiras da tarefa.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' '(?s)PERM-###.*INT-###.*NFR-###.*SEC-###' 'O contrato do prompt 03 nao separa permissoes, integracoes e qualidades com IDs estaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' '(?s)APP-###.*PAGE-###' 'O contrato do prompt 03 nao identifica aplicacoes e paginas/ecras com IDs estaveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' 'capacidade . aplica..o' 'O contrato do prompt 03 nao exige a matriz de aplicabilidade por aplicacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' '(?s)inicial/primeira utiliza..o.*loading/skeleton/progresso.*vazio/sem resultados.*parcial/stale.*conflito/concorr.ncia' 'O contrato do prompt 03 nao obriga a decidir os estados materiais de cada pagina.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' 'Action ID.*PAGE/APP.*FR/BR.*DATA.*PERM.*AC' 'O contrato do prompt 03 nao rastreia cada acao de pagina ate requisito, dados, permissao e aceitacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' '(?s)PAGE.*APP/superf.cie.*25 -> 13\|15\|17 -> 26' 'O contrato do prompt 03 nao prepara as fatias de pagina para os prompts downstream.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-contrato-detalhado-de-requisitos.txt' '(?s)Estado de evidência.*Estado do requisito.*Evidência de implementação' 'O contrato do prompt 03 mistura evidencia, aprovacao e implementacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'AC-<REQ>-##' 'O prompt 03 nao exige cenarios de aceitacao identificados por requisito.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Relat.rio de cobertura' 'O prompt 03 nao exige prova quantitativa de completude.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'duas implementa..es semanticamente incompat.veis' 'O prompt 03 nao testa requisitos contra ambiguidade semantica.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'Gate A como `PENDENTE`' 'O prompt 03 pode aprovar indevidamente o Gate A.'
Require-Pattern 'PRODUCT_DEFINITION.md' 'contratos `APP/PAGE`.*fatia downstream' 'O Gate A nao exige cobertura detalhada por aplicacao e pagina.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_APLICACOES.*CONTRATOS_POR_APLICACAO' 'O contexto nao encaminha o Codex para os contratos modulares por aplicacao.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_PAGINAS.*CONTRATOS_POR_PAGINA' 'O contexto nao encaminha o Codex para os contratos modulares por pagina.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)página Clientes.*todas as aplicações' 'O EVAL-11 nao testa ambiguidade concreta por pagina e aplicacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'GO.*REWORK.*NO-GO' 'O prompt 04 nao produz uma decisao completa do Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'DOR-01 a DOR-12' 'O prompt 04 nao audita todos os criterios de passagem.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/05-definir-arquitetura-e-selecionar-modulos.md' 'PRODUCT_DEFINITION\.md' 'O prompt 05 nao verifica o artefacto da etapa 1.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/05-definir-arquitetura-e-selecionar-modulos.md' 'termina com estado `bloqueado`' 'O prompt 05 nao bloqueia quando o Gate A falha.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/05-definir-arquitetura-e-selecionar-modulos.md' 'Test-ProductDefinitionGate\.ps1' 'O prompt 05 nao executa o gate mecanico.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'Copia .*PRODUCT_DEFINITION\.md' 'O prompt 07 nao copia a definicao aprovada para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'scripts/Test-ProductDefinitionGate\.ps1' 'O prompt 07 nao copia o gate mecanico para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' '\.agents/skills/build-professional-web-software' 'O prompt 07 nao copia a skill para a nova aplicacao.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'Ado..o brownfield' 'O prompt 07 nao possui uma rota brownfield explicita.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'N.o uses checkout/reset/clean' 'A rota brownfield nao preserva alteracoes Git locais.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'painel administrativo gen.rico' 'Falta o gate contra UI generica.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'regress.o visual automatizada' 'Falta regressao visual obrigatoria.'
Require-Pattern 'PRODUCT_EXCELLENCE.md' 'checks autom.ticos de acessibilidade em cada pull request' 'Falta acessibilidade continua.'
Require-Pattern 'prompts/09-entrega-e-distribuicao/55-configurar-ci-cd-e-ambientes-de-deploy.md' 'diff visual' 'O CI nao publica/compara o diff visual.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/63-executar-revisao-final-independente.md' 'read-only' 'Falta revisao final read-only.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/64-publicar-com-migrations-smoke-tests-e-rollback.md' '\[AUTORIZAR_RELEASE\]' 'A publicacao nao exige autorizacao explicita.'
Require-Pattern 'prompts/11-aceitacao-e-manutencao/64-publicar-com-migrations-smoke-tests-e-rollback.md' '\[CANDIDATE_SHA\].*\[ARTIFACT_DIGEST\]' 'A publicacao nao fixa candidate SHA e digest.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-13' 'O piloto nao contem os 13 casos.'
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
    if ($LASTEXITCODE -ne 0) {
        Add-Failure 'O gate de readiness rejeitou a fixture de piloto valida.'
    }

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
    'prompts/08-qualidade-e-hardening/55-validar-cache',
    'prompts/08-qualidade-e-hardening/56-validar-seo',
    'prompts/09-entrega-e-distribuicao/57-configurar-ci',
    'prompts/09-entrega-e-distribuicao/60-publicar'
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

if ($failures.Count -gt 0) {
    Write-Host "FAIL: $($failures.Count) problema(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: processo documental coerente.' -ForegroundColor Green
Write-Host " - Prompts: $($promptFiles.Count), numeracao continua 01-73."
Write-Host " - Links locais: validos em $($markdownFiles.Count) ficheiros Markdown."
Write-Host ' - Placeholders: declarados no APP_CONTEXT.md.'
Write-Host ' - Gate da definicao: fixture valida aceite e fixture invalida bloqueada.'
Write-Host ' - Orquestracao: manifesto, START_HERE, skill e scripts verificados.'
Write-Host ' - Gates estaticos: definicao do produto, arquitetura, fatias verticais, qualidade visual/codigo, acessibilidade, revisao independente, release e operacao verificados.'
Write-Host 'Nota: esta validacao estatica nao executa nem aprova PILOT-001.'
