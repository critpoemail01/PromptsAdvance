# Criar o sistema visual, ícone e assets da aplicação

## Objetivo

Cria uma identidade visual coerente para `[NOME_DA_APP]`, com proposta `[PROPOSTA_DE_VALOR]`, público `[PÚBLICO]` e atributos `[ATRIBUTOS]`. Entrega conceitos e assets prontos para web/PWA e .NET MAUI, preservando acessibilidade e requisitos das plataformas.

## Antes de criar

1. Audita o design system, tokens, favicon, manifest PWA, `MauiIcon`, splash screens e assets atuais.
2. Aplica o `PRODUCT_EXCELLENCE.md` e compara identidades de produtos maduros, sistemas oficiais de ícones e referências premium autorizadas através da matriz de benchmark.
3. Confirma se existem referências visuais autorizadas. Usa-as como direção, nunca para copiar marcas, ícones ou personagens.
4. Define um brief: mensagem, tom, cores permitidas/proibidas, concorrentes e contextos de uso.

Se o brief, nome ou referências licenciadas forem insuficientes para uma decisão duradoura, apresenta direções e protótipos, mas não substituas os assets oficiais do projeto.

## Execução

1. Propõe 3 direções visuais distintas e escolhe uma com critérios explícitos.
2. Cria um símbolo simples, reconhecível em tamanho pequeno e sem texto minúsculo.
3. Define:
   - paleta com tokens e contraste WCAG 2.2 AA;
   - tipografia e alternativas seguras;
   - variantes principal, monocromática, negativo e high-contrast;
   - regras de margem, tamanho mínimo e usos incorretos.
4. Produz um master vetorial original e derivados. Usa geração de imagem apenas para exploração ou assets raster; cria/revê SVG e outros masters vetoriais como artefactos editáveis, sem depender de um bitmap convertido automaticamente:
   - favicon e ícones PWA declarados no manifest;
   - `apple-touch-icon` e imagens sociais quando aplicável;
   - `MauiIcon` com background/foreground e camada monocromática para Android;
   - assets adequados a iOS, Android e Windows sem cantos/máscaras incorporados indevidamente.
5. Atualiza apenas referências reais do projeto. Mantém nomes de ficheiro válidos para Android e verifica que o build MAUI gera os recursos.

## Limites

- Não uses logos, fontes ou imagens sem licença comprovada.
- Não rasterizes o único master.
- Não afirmes conformidade de loja apenas por o build passar.
- Não alteres UI alheia ao sistema visual.
- Não escolhas autonomamente uma direção definitiva quando o brief não permitir distingui-la das alternativas.

## Validação

Inspeciona os ícones a 16, 32, 48, 128, 256 e 512 px, fundos claro/escuro, máscaras Android, PWA instalada e plataformas MAUI disponíveis. Executa o build web e, se o workload existir, o target MAUI relevante. Regista plataformas não validadas.

## Entrega

Apresenta brief utilizado, benchmark, direções, direção escolhida ou decisão pendente, racional, formatos master/derivados, paleta/tipografia, inventário de assets e caminhos, validações visuais/técnicas, licenças e limitações.

## Referências oficiais

- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://learn.microsoft.com/dotnet/maui/user-interface/images/app-icons?view=net-maui-10.0
- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- https://www.w3.org/TR/WCAG22/
