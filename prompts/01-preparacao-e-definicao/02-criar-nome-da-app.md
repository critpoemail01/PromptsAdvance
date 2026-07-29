# Criar e validar o nome da aplicação

## Objetivo

A partir da oportunidade selecionada, propõe um nome distintivo, memorável e utilizável internacionalmente para `[DESCRIÇÃO_DA_APP]`, com público `[PÚBLICO]`, mercados `[MERCADOS]` e posicionamento `[POSICIONAMENTO]`. Faz triagem de disponibilidade; não declares aprovação jurídica.

## Pré-condição

Confirma em `PRODUCT_DEFINITION.md` e `IMPLEMENTATION_STATUS.md` que o prompt 01 terminou com decisão `avançar`, uma única oportunidade selecionada, problema, público e MVP preliminar rastreáveis. Se a decisão for `não avançar`, `não avançar ainda` ou se existirem várias oportunidades sem seleção do responsável de produto, termina `bloqueado`; não escolhas uma ideia dentro deste prompt.

## Processo

1. Extrai 5–8 atributos da marca, tom, palavras proibidas e pronúncias/idiomas relevantes.
2. Gera pelo menos 40 candidatos por técnicas diferentes: compostos, evocativos, neologismos e nomes descritivos curtos.
3. Elimina nomes:
   - difíceis de pronunciar/escrever;
   - genéricos, enganosos ou demasiado próximos de concorrentes;
   - com conotações negativas nos idiomas-alvo;
   - dependentes de hífen, número ou grafia confusa.
4. Cria uma shortlist de 8–12 nomes e pesquisa, com data:
   - motores de pesquisa e lojas de apps;
   - domínio principal e 2 alternativas relevantes;
   - handles sociais prioritários;
   - WIPO Global Brand Database e bases nacionais/regionais aplicáveis;
   - registos empresariais quando relevantes.
5. A indisponibilidade num único registrar não prova que um domínio está registado; confirma através de RDAP/WHOIS e não compres nada.
6. Pontua distinção, clareza, sonoridade, extensão internacional, SEO semântico, disponibilidade e risco de confusão.

## Limites da triagem

- Disponibilidade de domínio, handle, loja e marca é um retrato datado e pode mudar imediatamente.
- Ausência de resultado numa pesquisa não prova inexistência de direitos anteriores, marcas semelhantes ou conflitos por classe/mercado.
- Não reserves domínios/handles, não cries contas e não submetas pedidos de marca.
- Para a recomendação final, exige pelo menos RDAP/WHOIS, pesquisa web/lojas e bases de marcas relevantes; classifica o restante como não verificado.

## Entrega

Apresenta:

- shortlist pontuada com significado e racional;
- evidência e data das verificações;
- fontes, jurisdições, classes consideradas e verificações não executadas;
- top 3 com tagline curta;
- recomendação principal e duas reservas;
- riscos linguísticos, de domínio e marca;
- próximos passos: teste com utilizadores e validação por profissional de propriedade intelectual.

Não uses “marca disponível” ou “nome seguro” como conclusão; escreve “não encontrei conflito na triagem efetuada” quando for esse o caso.

Depois da decisão do responsável de produto, regista em `PRODUCT_DEFINITION.md` o nome público aprovado para trabalho, o nome técnico provisório, o posicionamento, os riscos e as validações ainda necessárias. Atualiza o prompt 02 em `IMPLEMENTATION_STATUS.md`, mas mantém o Gate A `PENDENTE`; a aprovação do nome não aprova a definição completa.

## Referências oficiais

- https://www.wipo.int/en/web/global-brand-database
- https://lookup.icann.org/en
- https://www.euipo.europa.eu/en/trade-marks
