# Concluir e validar o layout de Client.Maui

## Objetivo

Depois de todas as jornadas MAUI `Must` terem sido implementadas e testadas por fatias verticais, fecha a UI contra `[MATRIZ_DE_REQUISITOS_MAUI]` e entrega as plataformas selecionadas prontas para preparação de distribuição. Não confundas build bem-sucedido com validação em runtime.

## Pré-requisito

Define `[PLATAFORMA_PRINCIPAL]`, versões mínimas e dispositivos/emuladores autorizados. A matriz deve provar que as jornadas `Must` estão funcionalmente integradas e distinguir testes automatizados, runtime observado e plataformas sem workload/dispositivo. Se faltar uma jornada `Must`, termina `bloqueado`.

## Critérios de conclusão

- Jornadas e ecrãs no âmbito têm todos os estados e navegação definidos.
- Safe areas, back, teclado, orientação, resize e permissões funcionam nas plataformas testadas.
- Componentes partilhados não introduzem comportamento web inadequado.
- Deep links, suspensão/retoma, offline e sessão expirada recuperam de forma segura.
- Cada plataforma alvo está `validada`, `bloqueada` ou `não aplicável`, com evidência.

## Execução

1. Cria a matriz `plataforma × jornada × estado × resultado × evidência`.
2. Confirma requisitos, IDs e configurações sem alterar assinatura ou lojas.
3. Compara runtime e estados com os princípios nativos aprovados no benchmark do `PRODUCT_EXCELLENCE.md`, não com uma simples réplica da Web.
4. Testa por risco: arranque, login, navegação, dados, operações destrutivas, permissões, notificações/deep links quando ativos e recuperação.
5. Corrige bloqueios, perda de estado/dados, acessibilidade, adaptação de plataforma e acabamento por esta ordem.
6. Pesquisa referências antes de remover recursos, handlers ou variantes.

## Validação obrigatória

Executa testes partilhados e builds das plataformas cujos workloads estão disponíveis. Faz runtime em emulador/dispositivo para pelo menos a plataforma principal, incluindo instalação limpa, upgrade local quando possível, orientação, suspensão/retoma, rede lenta/offline e permissões negadas. Executa avaliação de acessibilidade disponível, inspeção manual e comparação das referências visuais aprovadas para estados estáveis. Regista limitações de plataformas não testadas; não simules evidência.

## Entrega

Apresenta matriz final, plataforma principal, versões/dispositivos e método de teste, correções, evidências, comandos/resultados, divergências justificadas face à Web e itens encaminhados para assinatura/distribuição. Não declares “pronto para loja” sem executar o prompt específico de distribuição.

## Referências oficiais

- https://learn.microsoft.com/dotnet/maui/deployment/?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/fundamentals/app-lifecycle?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/user-interface/visual-states?view=net-maui-10.0
