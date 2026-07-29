# Melhorar a experiência nativa de Client.Maui

## Objetivo

Melhora, dentro da `[VERTICAL_SLICE_ATUAL]`, o cliente .NET MAUI/Blazor Hybrid para `[PLATAFORMAS_MAUI]` e a jornada selecionada. Exige comportamento, backend/dados, permissões e estados reais da fatia. Partilha UI e serviços onde isso reduz duplicação sem sacrificar safe areas, navegação, ciclo de vida, permissões e expectativas nativas.

## Entradas e rota de validação

Define `[PLATAFORMA_PRIMARIA]`, `[PLATAFORMAS_MAUI]`, versões mínimas, `[JORNADAS_PRIORITARIAS]` e dispositivos/emuladores autorizados. Usa primeiro a infraestrutura nativa existente no repositório; se não houver automação UI, documenta uma matriz manual reproduzível ou propõe Appium/testes equivalentes sem instalar tooling novo por iniciativa própria.

## Critérios de sucesso

- A aplicação respeita safe areas, barras do sistema, orientação e tamanhos de janela suportados.
- Interações, navegação, back, teclado virtual e targets táteis são previsíveis.
- Loading, vazio, erro, offline, sessão expirada e permissões negadas estão tratados.
- Deep links e retomada do ciclo de vida preservam estado de forma segura.
- Pelo menos a plataforma primária é compilada e exercitada num emulador/dispositivo; as restantes ficam claramente classificadas.
- A experiência segue linguagem e controlos próprios do domínio/plataforma e não uma réplica genérica da Web.

## Descoberta

1. Confirma plataformas ativas, workloads disponíveis, shell/navigation, `Client.Core`, handlers, serviços nativos, permissions e recursos.
2. Testa o estado atual em emulador/dispositivo autorizado e regista diferenças face à Web.
3. Aplica o `PRODUCT_EXCELLENCE.md` com aplicações móveis profissionais comparáveis e as guidelines oficiais da plataforma primária. Prioriza padrões nativos observáveis sobre a aparência da versão Web ou de um tema genérico.
4. Mapeia `jornada → componentes partilhados → integrações nativas → estados do ciclo de vida`.
5. Não edites recursos ou configurações de plataformas não selecionadas.

## Implementação

- Adapta densidade, navegação, back, menus e diálogos às plataformas alvo.
- Trata safe areas, teclado virtual, orientation/window resize e acessibilidade nativa.
- Mantém chamadas externas, ficheiros, câmara, notificações e permissões atrás de abstrações testáveis.
- Pede permissões no contexto da ação, explica recusa e permite recuperação sem loop.
- Trata suspensão/retoma, conectividade, expiração de sessão e operações interrompidas.
- Não inventa IDs, certificados, perfis de assinatura ou metadados de loja.
- Evita forks completos de UI: cria variantes pequenas e justificadas.

## Validação

Executa build/test partilhados e compila MAUI apenas para workloads instalados. Exercita na plataforma primária instalação/arranque, navegação, back, suspensão/retoma, offline, teclado, orientação e permissões. Executa avaliação automática disponível e inspeção manual de acessibilidade nativa. Mantém referências visuais aprovadas por dispositivo/tema/estado e compara-as de forma reproduzível quando a infraestrutura da plataforma o permitir; alterações exigem revisão humana. Regista dispositivo, SO e método de teste. Verifica logs sem dados sensíveis, consumo básico de memória e ausência de dependências obrigatórias de serviços opcionais.

## Entrega

Apresenta plataformas testadas, benchmark nativo e padrões adotados, jornadas, diferenças nativas intencionais, componentes partilhados, evidência em emulador/dispositivo, comandos/resultados, licenças e bloqueios externos.

## Referências oficiais

- https://learn.microsoft.com/dotnet/maui/what-is-maui?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/platform-integration/?view=net-maui-10.0
- https://learn.microsoft.com/dotnet/maui/fundamentals/app-lifecycle?view=net-maui-10.0
