# Validar uploads, imagens e armazenamento

## Aplicabilidade

Executa quando attachments, imagens de perfil ou outros ficheiros submetidos por utilizadores forem mantidos.

## Objetivo

Implementa uploads seguros para `[TIPOS_DE_FICHEIRO]`, usando a abstração de armazenamento e processamento de imagem existentes, com autorização, limites, validação e ciclo de vida definidos.

## Critérios de sucesso

- Tipo, tamanho, quantidade e ownership são validados no servidor.
- Nomes, caminhos e metadata do utilizador não controlam diretamente o armazenamento.
- Conteúdo ativo/perigoso é rejeitado ou tratado fora do contexto executável.
- Downloads exigem a autorização correta e usam headers seguros.
- Criação, substituição, remoção, retenção e órfãos têm comportamento testado.

## Processo

1. Inventaria endpoints, `IStorageService`, ImageMagick, stores, metadata, URLs e consumidores.
2. Define tipos permitidos a partir de requisitos; não confia apenas em extensão ou `Content-Type`.
3. Modela ameaças: path traversal, decompression bomb, polyglot, XSS, malware, overwrite, enumeração e DoS.
4. Define quotas, retenção, privacidade e necessidade de scanning.
5. Se malware scanning for obrigatório, define provider, estados de quarentena, timeout, falha e libertação antes de integrar; não declares um ficheiro seguro apenas por extensão/MIME ou re-encoding.

## Implementação e validação

- Gera identificadores no servidor e separa metadata de bytes.
- Faz streaming com limites e cancellation; evita carregar ficheiros arbitrários em memória.
- Re-encode imagens quando apropriado, remove metadata sensível e limita dimensões/pixels.
- Mantém ficheiros pendentes de scanning inacessíveis e trata scanner indisponível segundo uma política fail-closed/fail-open explicitamente aprovada.
- Serve conteúdo com `Content-Disposition`, `Content-Type`, cache e CSP adequados ao caso.
- Torna operações consistentes entre base de dados e storage, com limpeza recuperável de órfãos.
- Testa ficheiros válidos, vazios, grandes, tipo falso, nome malicioso, imagem extrema, acesso cruzado, repetição e storage indisponível.

## Entrega

Apresenta política, modelo de autorização, storage, scanning/quarentena quando aplicável, ficheiros, testes/resultados, limites, tratamento de órfãos e controlos ainda dependentes de infraestrutura.

## Referências oficiais

- https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload
- https://learn.microsoft.com/aspnet/core/mvc/models/file-uploads?view=aspnetcore-10.0
- https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
