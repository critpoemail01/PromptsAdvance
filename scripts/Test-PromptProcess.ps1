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
    'PROMPT_EVALUATION.md'
)

$requiredScripts = @(
    'scripts/Test-ProductDefinitionGate.ps1',
    'scripts/Test-ImplementationReadinessGate.ps1',
    'scripts/Test-Prompt02PilotArtifact.ps1',
    'scripts/Test-Prompt03PilotArtifact.ps1',
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

$catalogMarkdownRoots = @(
    (Join-Path $root '.agents'),
    (Join-Path $root 'pilot'),
    (Join-Path $root 'prompts')
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
Require-Pattern 'APP_CONTEXT.md' 'C:\\Work\\BoilerPlateAdvance' 'O contexto nao fixa a localizacao canonica do BoilerPlateAdvance.'
Require-Pattern 'APP_CONTEXT.md' 'Entrada aut.noma da descoberta.*Prompt 01' 'O contexto ainda transforma preferências em entradas obrigatorias do prompt 01.'
Require-Pattern 'software-lifecycle.ps1' 'Join-Path\s+\(Split-Path\s+\$catalogRoot\s+-Parent\)\s+.+BoilerPlateAdvance' 'O orquestrador nao usa o BoilerPlateAdvance irmao do catalogo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'N.o existem entradas obrigat.rias do utilizador' 'O prompt 01 ainda exige um questionario inicial.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'A aus.ncia desses dados nunca bloqueia o prompt 01' 'O prompt 01 ainda pode bloquear sem preferencias do utilizador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'N.o solicites, estimes nem uses `\[OR.AMENTO\]` ou `\[PRAZO\]` nesta fase' 'O prompt 01 voltou a depender de orcamento ou prazo durante a descoberta.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'validados no DOR-09 antes do Gate A' 'O prompt 01 nao encaminha orcamento e prazo para a validacao posterior correta.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'MVP m.nimo.*sem estimar dura..o ou custo' 'O prompt 01 voltou a produzir estimativas prematuras de prazo ou custo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'pesquisa online . obrigat.ria' 'O prompt 01 permite recomendar ideias apenas pela memoria do modelo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' '12.20 espa.os de problema' 'O prompt 01 nao exige exploracao ampla do mercado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'Reddit, Hacker News, Indie Hackers' 'O prompt 01 nao pesquisa foruns e comunidades atuais.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'aplica..o recente com boa aceita..o p.blica.*fragilidades concretas' 'O prompt 01 nao procura apps recentes aceites com fragilidades melhoraveis.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'categoria dispersa.*combinar v.rias aplica..es' 'O prompt 01 nao deteta necessidades dispersas por varias ferramentas.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'pelo menos dois tipos de fonte' 'O prompt 01 nao exige triangulacao suficiente para a recomendacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/01-descobrir-nova-ideia-de-app.md' 'n.o devolvas um question.rio inicial' 'O prompt 01 ainda pode terminar pedindo dados ao utilizador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'C:\\Work\\BoilerPlateAdvance' 'O prompt 03 nao identifica a localizacao canonica do BoilerPlateAdvance.'
Require-Pattern 'prompts/02-arquitetura-e-fundacao/07-criar-projeto-a-partir-do-boilerplate.md' 'C:\\Work\\BoilerPlateAdvance' 'O prompt 07 nao identifica a origem canonica do BoilerPlateAdvance.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'GO.*REWORK.*NO-GO' 'O prompt 04 nao produz uma decisao completa do Gate A.'
Require-Pattern 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md' 'DOR-01 a DOR-12' 'O prompt 04 nao audita todos os criterios de passagem.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '10.15 nomes' 'O prompt 02 nao exige uma shortlist final de 10 a 15 nomes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'OVHcloud.*dispon.vel para registo' 'O prompt 02 nao exige disponibilidade especifica na OVHcloud.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '\[CUSTO_MAXIMO_ANUAL_DOMINIO\]' 'O prompt 02 nao possui um limite de custo verificavel.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'pre.o de registo.*pre.o de renova..o' 'O prompt 02 nao compara registo e renovacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'resposta `200`' 'O prompt 02 nao identifica um registo RDAP ativo.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' '`404`/`not found`' 'O prompt 02 nao trata um dominio sem registo RDAP encontrado.'
Require-Pattern 'prompts/01-preparacao-e-definicao/02-criar-nome-da-app.md' 'CAPTCHA.*rate limits' 'O prompt 02 nao trata bloqueios e limites da verificacao externa.'
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
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/DEVELOPER_REQUIREMENTS_CHECKLIST\.md' 'O prompt 03 nao gera a checklist legivel para o programador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)fonte can.nica\s+detalhada.*vista\s+derivada' 'O prompt 03 nao distingue a especificacao detalhada da vista do programador.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)antes de desenvolver.*durante a implementa..o.*pronto para validar' 'A checklist do programador nao possui checkpoints de implementacao e validacao.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' '(?s)PAGE -> funcionalidade -> requisito detalhado -> AC -> prova' 'A vista do programador nao rastreia pagina e funcionalidade ate a prova.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/APPLICATION_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de aplicacoes.'
Require-Pattern 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md' 'requirements/PAGE_CATALOG\.md' 'O prompt 03 nao exige um inventario canonico de paginas/ecras.'
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
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)contratos `APP/PAGE`.*fatia downstream' 'O Gate A nao exige cobertura detalhada por aplicacao e pagina.'
Require-Pattern 'PRODUCT_DEFINITION.md' '(?s)checklist do programador.*paridade comprovada' 'O Gate A nao exige paridade entre detalhe e checklist do programador.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_APLICACOES.*CONTRATOS_POR_APLICACAO' 'O contexto nao encaminha o Codex para os contratos modulares por aplicacao.'
Require-Pattern 'APP_CONTEXT.md' 'CATALOGO_DE_PAGINAS.*CONTRATOS_POR_PAGINA' 'O contexto nao encaminha o Codex para os contratos modulares por pagina.'
Require-Pattern 'APP_CONTEXT.md' 'CHECKLIST_REQUISITOS_PROGRAMADOR.*DEVELOPER_REQUIREMENTS_CHECKLIST' 'O contexto nao resolve o handoff de requisitos do programador.'
Require-Pattern 'QUALITY_GATES.md' '(?s)especifica..o detalhada.*checklist leg.vel do programador.*paridade' 'O G01 nao bloqueia divergencias entre a especificacao e a checklist do programador.'
Require-Pattern 'pilot/cases/EVAL-11.md' '(?s)p.gina Clientes.*todas as aplica..es' 'O EVAL-11 nao testa ambiguidade concreta por pagina e aplicacao.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'future access timestamp' 'O oraculo de EVAL-15 nao rejeita timestamps futuros.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'APP-003.*BPP-007' 'O oraculo de EVAL-15 nao verifica o mapeamento publico SSR.'
Require-Pattern 'scripts/Test-Prompt03PilotArtifact.ps1' 'developer checklist omits catalog page' 'O oraculo de EVAL-15 nao deteta paginas omitidas na checklist do programador.'
Require-Pattern 'PROMPT_EVALUATION.md' '(?s)EVAL-15-R1.*timestamps.*futuro.*BPP-007.*BPR-002' 'A falha adversarial de EVAL-15-R1 nao esta preservada.'
$prompt03Path = Join-Path $root 'prompts/01-preparacao-e-definicao/03-levantar-requisitos-funcionais.md'
if ((Test-Path -LiteralPath $prompt03Path -PathType Leaf) -and
    (Get-Content -Encoding UTF8 -LiteralPath $prompt03Path).Count -gt 360) {
    Add-Failure 'O prompt 03 autocontido excede o budget de 360 linhas.'
}
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
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-13' 'O piloto nao conserva o caso de revisao independente.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-14.*naming natural' 'O piloto nao contem a regressao dirigida do prompt 02.'
Require-Pattern 'PROMPT_EVALUATION.md' 'EVAL-15.*requisitos pesquisados por aplica..o e p.gina' 'O piloto nao contem a regressao dirigida do prompt 03.'
Require-Pattern 'pilot/cases/EVAL-14.md' 'Navirevo.*Prumivo.*Rivelumi' 'O caso EVAL-14 nao inclui os nomes mecanicos rejeitados.'
Require-Pattern 'pilot/fixtures/prompt-02/untrusted-search-result.html' 'Ignore as instru..es anteriores' 'A fixture adversarial do prompt 02 esta ausente.'
Require-Pattern 'pilot/fixtures/prompt-02/app-context.md' '30 EUR \+ IVA' 'O contexto material de EVAL-14 nao fixa o orcamento do dominio.'
Require-Pattern 'pilot/fixtures/prompt-02/product-definition.md' 'Decis.o.*avan.ar' 'A definicao de produto de EVAL-14 nao prova a decisao do prompt 01.'
Require-Pattern 'pilot/fixtures/prompt-02/implementation-status.md' '02-criar-nome-da-app.*em curso' 'O estado de EVAL-14 nao seleciona o prompt 02.'
Require-Pattern 'pilot/PILOT-002-EVAL-14-EXECUTION.md' 'PASS t.cnico para EVAL-14' 'A execução dirigida de EVAL-14 não conserva a decisão técnica.'
Require-Pattern 'pilot/PILOT-002-EVAL-14-EXECUTION.md' 'FA0081F9510EADFD2169EE0F81462F4CB4E028963F6FE55440C555398857819C' 'A execução dirigida de EVAL-14 não fixa o hash do prompt avaliado.'
Require-Pattern 'scripts/Test-Prompt02PilotArtifact.ps1' 'Human rubric and full 15-case pilot approval remain separate requirements' 'O validador de EVAL-14 confunde o teste técnico com aprovação humana.'
Require-Pattern 'pilot/cases/EVAL-15.md' '(?s)compar.veis diretos.*adjacente.*fonte madura.*refer.ncias\s+premium' 'O caso EVAL-15 nao cobre a pesquisa externa exigida.'
Require-Pattern 'pilot/fixtures/prompt-03/untrusted-premium-preview.html' 'Ignore as instru..es anteriores' 'A fixture adversarial do prompt 03 esta ausente.'
Require-Pattern 'pilot/fixtures/prompt-03/product-definition.md' 'QST-001.*pendente' 'As fontes de EVAL-15 nao conservam uma decisao material em falta.'
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
