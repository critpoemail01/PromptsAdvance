# AdvanceAppFlow — começar ou continuar uma aplicação Advance

O processo executa um prompt de cada vez. Quando um prompt termina, apresenta
o resultado, o que foi alcançado e o que ainda falta implementar. Depois para.
Só avança quando o programador diz `próximo`.

## Nova aplicação

No Codex:

```text
Usa $advance-app-start.
Inicia uma nova iniciativa chamada "nome-da-iniciativa".
O responsável de produto é "nome-do-responsável".
Usa o BoilerPlateAdvance em "/caminho/absoluto/BoilerPlateAdvance".
Executa apenas o prompt 01 e para no fim.
```

Ou por PowerShell:

```powershell
.\software-lifecycle.ps1 start `
  -Name nome-da-iniciativa `
  -Owner "Nome do responsável" `
  -BoilerplatePath C:\Caminho\BoilerPlateAdvance
```

O processo é criado fora do catálogo e do boilerplate, sem criar repositório
remoto, fazer commit/push ou publicar.

## Aplicação já desenvolvida

```text
Continua o projeto Advance em C:\Work\aplicacao
```

O comando subjacente é:

```powershell
.\software-lifecycle.ps1 continue -ProjectPath "C:\Work\aplicacao"
```

O lifecycle fica isolado da aplicação e não altera `.git`, histórico, branches,
remotes ou alterações locais durante a adoção. O código existente é analisado
como evidência; não é considerado automaticamente prova de que um prompt já foi
concluído.

Antes de executar um prompt numa aplicação existente, o Codex informa a
sobreposição detetada. Se o prompt já tiver histórico, mostra o resultado
anterior, a evidência e as pendências. Só o repete após confirmação e depois de
o programador indicar o objetivo da repetição.

## Executar o prompt atual

```powershell
.\software-lifecycle.ps1 status -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 validate -ProcessRoot C:\Caminho\Processo
.\software-lifecycle.ps1 next -ProcessRoot C:\Caminho\Processo
```

`NEXT_TASK.md` contém apenas o prompt atual e o contexto material. No fim,
regista um resultado completo:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot C:\Caminho\Processo `
  -PromptId 03 -Result completed `
  -Evidence "requirements/traceability.md" `
  -Summary "Requisitos detalhados de todas as páginas e funcionalidades"
```

Ou um resultado incompleto:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot C:\Caminho\Processo `
  -PromptId 03 -Result partial `
  -Evidence "requirements/traceability.md" `
  -Summary "Requisitos web concluídos" `
  -RemainingWork "Inventariar a aplicação nativa",`
                 "Validar permissões com o responsável"
```

O fecho apresenta sempre:

- `Resultado`: completed, partial, blocked ou not applicable;
- `Alcançado`: o que foi implementado/validado;
- `Falta para terminar`: lista concreta ou `nada`;
- `Evidência`: ficheiros e verificações essenciais;
- `Decisão`: próximo, repetir, corrigir ou ignorar e avançar.

## Escolher o que acontece depois

Próximo prompt:

```powershell
.\software-lifecycle.ps1 advance -ProcessRoot C:\Caminho\Processo
```

Aceitar um resultado parcial/bloqueado e avançar:

```powershell
.\software-lifecycle.ps1 advance -ProcessRoot C:\Caminho\Processo `
  -AcceptIncomplete -Objective "Aceite para esta iteração"
```

Pedir ou repetir um prompt:

```powershell
.\software-lifecycle.ps1 request -ProcessRoot C:\Caminho\Processo -PromptId 03
.\software-lifecycle.ps1 repeat -ProcessRoot C:\Caminho\Processo `
  -PromptId 03 -Objective "Revalidar depois da alteração de faturação" `
  -ConfirmRepeat
```

`request` não repete silenciosamente trabalho anterior. Primeiro informa; o
segundo comando confirma e fixa a razão da nova execução.

Dispensar, adiar ou marcar um prompt não crítico como não aplicável antes de o
executar:

```powershell
.\software-lifecycle.ps1 decide -ProcessRoot C:\Caminho\Processo `
  -PromptId 03 -Result deferred -Evidence "Requisitos detalhados na próxima iteração"
.\software-lifecycle.ps1 decide -ProcessRoot C:\Caminho\Processo `
  -PromptId 33 -Result not_applicable -Evidence "A aplicação não tem faturação"
.\software-lifecycle.ps1 decide -ProcessRoot C:\Caminho\Processo `
  -PromptId 48 -Result waived -Evidence "Publicidade excluída por decisão de produto"
```

As classes são `hard_required`, `recommended`, `conditional` e `optional`.
Prompts `hard_required` não aceitam estas decisões; o processo não os força a
correr, mas não pode declarar conclusão integral sem os executar.

## Meta de entrega

Assume sempre uma aplicação final destinada a produção; não escolhas entre MVP
e produção. Os perfis `fast`, `standard` e `deep` só ajustam a profundidade da
tarefa atual. O lifecycle pode continuar com decisões e lacunas registadas, mas
só termina como `production_ready` depois de concluir os prompts críticos,
resolver ou decidir os restantes e passar o Gate G10. Isto não constitui
autorização para executar o deploy.

## Várias aplicações na mesma máquina

Cada aplicação recebe automaticamente um bloco local exclusivo de dez portas.
Os prompts 07/10 e `corre a app` usam
`scripts/Manage-AdvanceLocalPorts.ps1`; API, SSR e Web recebem URLs próprios e
MAUI usa a API da mesma reserva. A atribuição `APP_LOCAL_PORTS.json` é local e
não deve ser commitada. Parar a aplicação mantém a reserva; só um pedido
explícito `release` a liberta.

## Qualidade e autorizações

Os gates de produto, arquitetura, layout, implementação e qualidade são
checklists consultivas no desenvolvimento normal. As lacunas são mostradas no
resultado, mas não anulam a decisão explícita do programador de avançar.

Continuam bloqueadas sem autorização exata:

- ações externas ou destrutivas;
- commit, push, criação/alteração de repositórios e GitHub;
- custos, faturação real, lojas e identidades externas;
- release e produção.

Produção exige a candidata e ambiente exatos, autorização explícita, smoke
tests, observabilidade e rollback. O piloto do catálogo avalia o processo; não
impede uma aplicação de começar o desenvolvimento local.

## Plugin Codex

```text
codex plugin marketplace add critpoemail01/AdvanceAppFlow
codex plugin add advance-app@promptsadvance
```

Após instalar ou atualizar, reinicia o Codex e abre uma tarefa nova para carregar
as skills `$advance-app-start` e `$advance-app-continue`.
