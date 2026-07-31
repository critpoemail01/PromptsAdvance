# Completar requisitos após o refinamento visual

## Objetivo

Repete de forma dirigida o método do prompt 03 depois de uma superfície ter
sido refinada pelos prompts 13, 15 ou 17. Incorpora nos requisitos o que foi
aprendido com a jornada renderizada, os estados reais e a crítica de produto,
sem transformar preferências visuais ou detalhes acidentais da implementação
em requisitos aprovados.

Este passo corre antes do prompt 26 ou 28 da mesma vertical slice e pode ser
repetido para cada superfície selecionada.

## Entradas obrigatórias

- artefactos canónicos e vistas derivadas produzidos pelo prompt 03;
- vertical slice ativa, requisitos, aceitação e exclusões registadas;
- resultado do prompt 13, 15 ou 17 aplicável e evidência renderizada;
- `PRODUCT_QUALITY_BASELINE.md`, benchmark, crítica e findings atuais;
- catálogo de componentes/estados, navegação e estratégia mobile aplicáveis;
- `IMPLEMENTATION_STATUS.md`, `APP_CONTEXT.md` e `HELP_AND_ACADEMY.md`.

## Limites

- Lê integralmente o prompt 03 e preserva o seu contrato de IDs e paridade.
- Não implementes UI, backend ou testes nesta tarefa.
- Não atualizes baselines visuais nem aproves usabilidade sem a evidência e a
  autorização exigidas.
- Não copies identidade, código, assets ou trade dress das referências.
- Não substituas critérios funcionais por descrições estéticas como “moderno”
  ou “premium”.
- Não apagues nem recicles IDs existentes.

## Execução

1. Compara a jornada, página e estados renderizados com `PAGE/FNC/REQ/AC` da
   slice ativa e identifica divergências observáveis.
2. Classifica cada descoberta como `requisito em falta`, `aceitação incompleta`,
   `decisão visual`, `finding de usabilidade`, `restrição técnica`, `hipótese`
   ou `fora do âmbito`.
3. Completa, quando comprovado, navegação, hierarquia funcional, ações, conteúdo,
   validação, loading, vazio, erro, sucesso, permissão, sessão, offline,
   concorrência, recuperação, responsividade, teclado, foco e acessibilidade.
4. Atualiza ajuda contextual e Academia apenas quando a matriz
   `APP/PAGE/FNC/HLP/VID/CRS`, idiomas, fallback e owner estiverem aprovados.
5. Reconcilia a especificação detalhada, contratos `APP/PAGE`, checklist do
   programador, `ALL_FUNCTIONALITIES.md`, catálogos e relatório de cobertura.
6. Regista findings que pertencem ao layout ou à implementação nos respetivos
   prompts; não os escondas através de um requisito inventado.
7. Revê adversarialmente o delta contra scope creep, IDs duplicados, estados
   omitidos, acessibilidade não verificável e decisões visuais sem fonte.

## Critério de conclusão

Conclui apenas quando:

- os requisitos da slice refletem a experiência observada sem copiar a UI;
- cada alteração tem fonte, owner, aceitação e prova esperada;
- todas as vistas derivadas permanecem em paridade;
- findings de design e implementação estão encaminhados ao prompt correto;
- `IMPLEMENTATION_STATUS.md` conserva resultado, evidência e trabalho restante.

Entrega primeiro o delta funcional e de experiência que ficou pronto para os
prompts 26 ou 28, seguido dos bloqueios e decisões ainda pendentes.
