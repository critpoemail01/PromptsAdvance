# Protocolo de ajuda contextual, vídeos e Academia

Este protocolo aplica-se apenas quando a definição aprovada incluir ajuda
contextual, documentação de utilização, vídeos de tarefas ou uma Academia. Não
torna essa capacidade obrigatória para todas as aplicações e não substitui os
requisitos, o `PRODUCT_EXCELLENCE.md`, acessibilidade, privacidade, segurança ou
autorização para publicar num serviço externo.

## 1. Decidir aplicabilidade e responsabilidade

No prompt 03, regista a capacidade como `não aplicável`, `planeada` ou `em
âmbito`. Para `em âmbito`, identifica:

- utilizadores, perfis e jornadas que necessitam de ajuda;
- superfícies, módulos, páginas, funcionalidades e operações cobertas;
- idiomas do artigo, áudio, captions e transcrição;
- owner de produto, owner editorial, tradutor/revisor e aprovador do vídeo;
- fornecedor de vídeo, canal/conta e visibilidade pretendida;
- critérios de cobertura, atualização e despublicação.

Não assumes que “conteúdo bilingue” significa automaticamente vídeo bilingue.
Regista separadamente idiomas de texto, narração, captions e transcrição. Uma
caption automática pode ser rascunho, nunca prova final de correção.

## 2. Inventário e matriz canónica

Deriva o inventário do comportamento real, dos requisitos aprovados e dos IDs
estáveis `APP`, `PAGE`, `FNC`, `RF-P`, `JRN` e `AC`. Para cada unidade de ajuda,
conserva em `requirements/REQUIREMENTS_TRACEABILITY.md` a matriz:

| APP/PAGE/FNC | Perfil | Rota/contexto | Tarefa e resultado | Pré-condições/permissões | Estados/erros | Artigos por idioma aprovado | Vídeo | Ajuda contextual | Curso/aula | Estado | Evidência |
|---|---|---|---|---|---|---|---|---|---|---|---|

Usa IDs estáveis `HLP-*`, `VID-*` e `CRS-*`. A rota observada ajuda a resolver
contexto, mas não é a identidade canónica: uma alteração de URL não pode ligar
silenciosamente um artigo à funcionalidade errada. Cada linha liga aos
requisitos e critérios de aceitação da tarefa funcional correspondente.

O inventário cobre, quando aplicável, consultar, criar, editar, eliminar,
aprovar, imprimir, importar/exportar e recuperar de erros. Não reduz percursos
com permissões, confirmações, efeitos persistidos ou sucesso parcial a uma ação
isolada.

## 3. Contrato dos conteúdos bilingues

Cada artigo contém:

- título e objetivo em linguagem do utilizador;
- perfil, pré-condições e permissões;
- passos numerados que correspondem à UI atual;
- alertas, consequências, confirmação e resultado final;
- erros frequentes, recuperação e canal de suporte;
- ligação ao vídeo e às funcionalidades relacionadas;
- versão da aplicação, data de validação, owner e próxima revisão.

Os idiomas aprovados — por exemplo, PT e EN no perfil descrito — exprimem a
mesma obrigação e resultado, usam os termos visíveis na aplicação e passam
revisão humana adequada ao domínio. Não traduzas nomes de controlos de forma
diferente da UI nem declares um idioma concluído apenas porque existem chaves
de recursos.

## 4. Perfil de produção dos vídeos

Por omissão, usa este perfil até existir uma decisão aprovada diferente:

- captura da aplicação real num ambiente de demonstração autorizado;
- 1920×1080, browser, zoom e enquadramento constantes;
- dados fictícios coerentes e identificáveis, sem dados pessoais ou segredos;
- voz inglesa natural e consistente, cursor visível e cliques percetíveis;
- narração sincronizada, sem tempos mortos, menus cortados ou passos omitidos;
- introdução e encerramento curtos e consistentes com a marca;
- duração preferencial de 1–4 minutos;
- uma tarefa atómica completa: estado inicial, execução, confirmação e
  resultado final, incluindo um alerta ou recuperação quando material;
- captions e transcrição revistas; captions automáticas são apenas provisórias.

Não graves a versão final enquanto a jornada, o texto da UI e os critérios de
aceitação estiverem instáveis. Uma gravação aprovada fica ligada à versão ou
intervalo compatível da aplicação e deve regressar a `desatualizada` quando uma
alteração material invalidar passos, permissões, termos ou resultado.

## 5. Arquitetura da ajuda e da Academia

A decisão arquitetural define, sem antecipar serviços desnecessários:

- registo central de artigos, vídeos e cursos por `APP/PAGE/FNC`;
- resolução por rota/contexto e fallback seguro quando não existir conteúdo;
- armazenamento em configuração versionada ou dados administráveis, com
  ownership, versionamento, cache e invalidação explícitos;
- pesquisa, filtros, links estáveis e comportamento offline/degradado;
- autorização de conteúdo interno e separação entre ajuda pública, autenticada
  e administrativa;
- painel “Como funciona?” com um ou dois vídeos gerais e lista das
  funcionalidades, sem instrumentação visual espalhada pelas páginas;
- abertura do vídeo no painel, artigo relacionado e foco/teclado preservados;
- cursos, ordem, pré-requisitos e progresso, quando a Academia estiver em
  âmbito;
- semântica de progresso explícita e idempotente; um evento do player não prova
  sozinho aprendizagem nem pode atribuir conclusão ao utilizador errado.

Integrações YouTube ou equivalentes tratam o player como dependência externa:
domínios/CSP, cookies e consentimento, indisponibilidade, bloqueadores,
thumbnails, API/quotas, OAuth/segredos, retenção, telemetria e fallback textual
devem estar decididos e testados. Um vídeo `não listado` não é controlo de
acesso: quem possuir o link pode voltar a partilhá-lo.

## 6. Implementar por cortes verticais

Primeiro implementa uma única unidade completa e representativa:

```text
FNC -> artigo nos idiomas aprovados -> vídeo aprovado -> contexto -> aula/curso
    -> permissões/estados -> testes -> evidência
```

O shell global, o registo central, a pesquisa e a infraestrutura da Academia
formam um lote transversal do prompt 25. A associação e o conteúdo de uma
página ou funcionalidade são refinados e implementados nos prompts 27/29 e
testados nos prompts 28/30. Só propaga o padrão depois de validar a primeira
unidade em browser, idiomas, acessibilidade e ambiente representativo.

## 7. Publicação externa

Produz e valida localmente antes do upload. Publicar ou alterar um vídeo,
playlist ou canal exige autorização explícita que identifique o fornecedor,
conta/canal, itens, visibilidade e lote. Sem essa autorização, conserva os
ficheiros e metadados preparados e termina `parcial`, sem simular IDs externos.

Depois da aprovação de cada vídeo:

1. publica-o com título, descrição, idioma, captions e visibilidade aprovados;
2. regista ID/URL, canal, playlist, data, versão e aprovador;
3. associa o ID ao `VID-*`, artigo e aula corretos;
4. executa smoke test do embed e do fallback;
5. confirma que não foram expostos dados, URLs internas ou informação sensível.

## 8. Definition of Done por unidade

Uma linha da matriz só fica `concluída` quando:

- artigo e vídeo correspondem exatamente à UI e versão atuais;
- não faltam passos, permissões, alertas, confirmação ou resultado;
- todos os idiomas aprovados têm paridade semântica e revisão registada;
- áudio, captions, transcrição, resolução, ritmo e identidade passam o perfil;
- dados demonstrados são seguros e reproduzíveis;
- rota/contexto resolve o `APP/PAGE/FNC` correto e o fallback funciona;
- player, pesquisa, links, ajuda contextual, curso e progresso aplicáveis passam;
- teclado, foco, controlos, captions e transcrição passam a avaliação aplicável;
- falha/bloqueio do fornecedor não elimina o artigo nem bloqueia a tarefa base;
- UI, API, build e testes afetados continuam verdes;
- owner, data de revisão e regra de invalidação estão registados.

## 9. Routing no lifecycle

| Momento | Responsabilidade |
|---|---|
| Prompt 03 | aplicabilidade, inventário, matriz, requisitos, idiomas e critérios |
| Prompt 04 | Gate A da cobertura, owners e decisões materiais |
| Prompts 05/06/10/11 | arquitetura, ameaças, configuração, contratos e dependência externa |
| Prompt 25 | shell/registo/pesquisa/Ajuda/Academia transversal |
| Prompts 26–30 | implementação e testes por requisito, página e funcionalidade |
| Prompt 34 | recursos, fallback e revisão nos idiomas aprovados |
| Prompts 41/42 | dados, tracking, acesso, CSP, OAuth, segredos e abuso |
| Prompt 46 | player, captions, transcrição, teclado e tecnologias de apoio |
| Prompt 55 | cobertura integrada, fornecedor indisponível, idiomas e regressões |
| Prompt 64 | conteúdo final sobre UI estável, upload autorizado e manutenção |
| Prompt 65 | reconciliação da matriz e aceitação da candidata exata |

## Referências e exemplo fornecido

- Exemplo de formato fornecido: https://youtu.be/RN8mc3k_N7M
- https://support.google.com/youtube/answer/157177
- https://support.google.com/youtube/answer/6373554
- https://support.google.com/youtube/answer/171780
- https://developers.google.com/youtube/iframe_api_reference
- https://www.w3.org/WAI/media/av/
- https://www.w3.org/WAI/WCAG22/Understanding/captions-prerecorded.html
