# Validar SignalR e funcionalidades em tempo real

## Aplicabilidade

Executa quando SignalR é necessário para `[CASOS_DE_USO_TEMPO_REAL]`.

## Objetivo

Valida ligações, hubs, grupos, autorização, reconexão e escala do SignalR existente, garantindo que tempo real melhora a experiência sem ser a única fonte de verdade.

## Critérios de sucesso

- Métodos e eventos têm contratos, autorização e limites definidos.
- Reconnect, perda de mensagens, duplicação e ordem são tratados pela UI.
- Grupos e routing não permitem fuga de dados entre tenants/utilizadores.
- A aplicação recupera através da API/estado persistido quando a ligação falha.
- Telemetria e health permitem diagnosticar ligações e falhas.

## Processo

1. Inventaria hubs, clientes SSR/Web/MAUI, Azure SignalR opcional, grupos, claims e mensagens.
2. Mapeia cada evento ao estado persistido e à estratégia de reconciliação.
3. Define limites de payload, frequência, compatibilidade e backpressure.
4. Modela ameaças de ligação não autorizada, group injection, spam e dados sensíveis.

## Implementação e validação

- Autoriza no hub e em cada operação sensível; não confia no grupo pedido pelo cliente.
- Mantém payloads mínimos e versionáveis.
- Implementa reconexão limitada com jitter e atualização do estado após reconectar.
- Evita usar SignalR para transferências grandes ou comandos sem confirmação persistida.
- Não assumes entrega, ordem ou unicidade das mensagens; a API/estado persistido é a fonte de verdade e o cliente reconcilia após lacunas.
- Testa dois utilizadores/tenants, reconnect, token expirado, servidor reiniciado, mensagem duplicada/fora de ordem e serviço opcional ausente.
- Executa testes de integração e browser, build e medição básica de carga.

## Entrega

Apresenta mapa de hubs/eventos, semântica de entrega assumida, autorização, fonte de verdade/estratégia de reconciliação, testes/resultados, limites, telemetria e riscos de escala.

## Referências oficiais

- https://learn.microsoft.com/aspnet/core/signalr/introduction?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/signalr/security?view=aspnetcore-10.0
- https://learn.microsoft.com/aspnet/core/signalr/scale?view=aspnetcore-10.0
