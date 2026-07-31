# Validar localização e formatação cultural

## Aplicabilidade

Executa este prompt quando o produto suporta mais de uma língua/cultura ou quando `[MERCADOS_ALVO]` exige formatos diferentes.

## Objetivo

Garante que SSR, Web/PWA, MAUI, API, emails e conteúdo partilhado apresentam `[CULTURAS_SUPORTADAS]` de forma consistente, acessível e sem strings de produto hardcoded.

## Critérios de sucesso

- A cultura é selecionada e persistida por uma regra documentada e segura.
- Recursos, validação, erros e navegação têm cobertura nas culturas suportadas.
- Datas, horas, números, moeda, pluralização e ordenação usam a cultura correta.
- SSR envia idioma/direção corretos e mantém URLs/SEO coerentes.
- Layouts toleram expansão de texto e RTL quando aplicável.

## Processo

1. Lê a documentação de localização do boilerplate, resources, middleware, componentes, emails e testes.
2. Inventaria strings visíveis e chaves em falta/órfãs.
3. Define fallback, cultura neutra, origem da preferência e comportamento entre SSR, Web e MAUI.
4. Não traduzas conteúdo jurídico ou especializado como se estivesse aprovado; usa placeholders/revisão humana.
5. Identifica conteúdo de produto, suporte e marketing que exige tradução/revisão humana; não declares uma língua concluída apenas porque todas as chaves têm valor.
6. Quando ajuda/Academia estiver ativa, reconcilia cada `HLP/VID/CRS`: artigo,
   termos da UI, narração, captions e transcrição têm idiomas e revisores
   explícitos. Caption automática permanece provisória até revisão.

## Implementação e validação

- Reutiliza a infraestrutura de resources existente.
- Evita concatenar fragmentos traduzidos e não usa texto como chave estável.
- Localiza validação e `ProblemDetails` apenas quando o contrato o permite.
- Mantém logs técnicos pesquisáveis sem misturar conteúdo pessoal.
- Testa culturas suportadas e uma cultura não suportada, timezone relevante, limites numéricos e texto longo.
- Renderiza páginas/ecrãs críticos, verifica clipping, direção, foco e metadata.
- Executa build/test e pesquisa strings visíveis hardcoded.
- Compara passos, alertas, erros e resultado entre idiomas e a UI real; um texto
  traduzido não pode instruir uma ação diferente nem ocultar uma permissão.

## Entrega

Apresenta culturas, estratégia/fallback, cobertura técnica de recursos, estado de revisão humana por tipo de conteúdo, ficheiros, testes/resultados, capturas relevantes e traduções ainda provisórias.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/fundamentals/localization?view=aspnetcore-10.0
- https://learn.microsoft.com/dotnet/core/extensions/localization
- https://www.w3.org/International/questions/qa-html-language-declarations
