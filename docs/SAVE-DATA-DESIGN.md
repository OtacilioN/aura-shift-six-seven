# Aura Shift: Six Seven — Design de Salvamento

> Status: estratégia e contrato econômico `arith-v1` aprovados; contêiner, versionamento geral e mecanismos de integridade serão definidos na fase técnica.

## Objetivos

- preservar automaticamente o progresso entre sessões;
- manter a experiência principal independente de conta e conexão;
- permitir recuperação voluntária sem infraestrutura de nuvem;
- impedir que falhas de exportação ou importação destruam o estado válido;
- permitir evolução compatível do formato ao longo das versões.

## Salvamento ativo

O progresso é salvo automaticamente no armazenamento local. O lançamento não utiliza conta, backup em nuvem ou sincronização automática entre aparelhos.

Cada instalação mantém uma única jornada ativa. Não existem perfis ou espaços paralelos. A importação substitui essa jornada após confirmação; o jogador pode guardar múltiplos arquivos externamente, mas eles não são slots gerenciados pelo jogo.

O estado persistente deve abranger, no mínimo:

- Aura Disponível, Aura Total e Aura da Jornada;
- versão do contrato aritmético e Resto de Produção inteiro;
- caches inteiros derivados `P20` da Potência de Ciclo e `T20` da Produção Passiva, além da quantidade de Ascensões e do Multiplicador `A` em centésimos;
- Técnicas Six-Seven, Itens de Aura, níveis e desbloqueios;
- Patamares, ramos, conquistas e Transformações de Aura;
- Aparências de Item e personalização vigente;
- Coleção Visual permanente e estado econômico separado de cada aparência;
- Marcos 67 alcançados e celebrações ainda pendentes;
- Selos 67 permanentes por magnitude;
- Conquistas locais desbloqueadas;
- fase atual do Ciclo Six-Seven;
- limites temporais de Complemento de Aura;
- referências necessárias para Produção Offline;
- snapshot canônico `F_registrado=T20×A` da Taxa Offline Registrada no momento em que o jogo deixa o primeiro plano;
- estado idempotente da Recompensa de Retorno, incluindo base e Bônus de Retorno;
- condições persistentes de habilitação da monetização;
- referências temporais necessárias para preservar cotas publicitárias diante de mudanças de relógio;
- configurações e idioma escolhido.

Aura Disponível, Aura Total, Aura da Jornada, níveis e demais inteiros econômicos arbitrariamente grandes são serializados como texto decimal integral. O Resto de Produção satisfaz `0 ≤ R < 10.000.000` e permanece em fechamento, exportação, importação e Ascensão. `P20` e `T20` são caches inteiros verificáveis e reconciliáveis a partir de níveis e parâmetros. `F_registrado` é um snapshot canônico congelado até materializar a Recompensa de Retorno e nunca é recalculado com estado ou parâmetros posteriores. Taxas decimais pós-multiplicador nunca são fonte canônica.

Uma Ascensão deve ser uma transação atômica do save. O novo total inteiro do Multiplicador de Ascensão, a contagem de Ascensões, o zero da Aura da Jornada e todos os estados econômicos reiniciados precisam pertencer à mesma gravação válida. Uma falha não pode produzir metade da transação.

Recompensas de Retorno e cotações de Complemento de Aura carregam identificador e estados idempotentes. Base offline, bônus, saldo comprometido e falta coberta são representados exatamente conforme `ECONOMIC-ARITHMETIC.md`; repetir uma conclusão já aplicada não pode criar novo crédito ou nova compra.

## Exportação manual

O jogador pode exportar um Backup Manual para um arquivo e escolher onde armazená-lo ou compartilhá-lo usando os recursos do aparelho. A exportação não modifica o salvamento ativo e não depende de internet.

O arquivo deve carregar metadados suficientes para apresentar sua data, versão e resumo antes de uma restauração. O mecanismo de integridade será definido tecnicamente sem prometer inviolabilidade absoluta em um jogo offline.

## Importação manual

O fluxo de importação deve:

1. ler o arquivo sem alterar o estado ativo;
2. validar integridade e compatibilidade;
3. apresentar data, versão e resumo do progresso encontrado;
4. explicar que o estado atual será substituído;
5. exigir confirmação explícita;
6. gravar a restauração de forma segura;
7. manter o progresso anterior intacto se qualquer etapa falhar.

## Limitações assumidas

- o jogador é responsável por guardar o arquivo exportado;
- sem Backup Manual externo, perda do aparelho, limpeza de dados ou desinstalação pode apagar o progresso;
- não existe resolução automática de conflitos entre dispositivos;
- proteção contra edição intencional de saves será moderada e compatível com a natureza offline-first.

## Compartilhamento, corrupção e manipulação

São problemas diferentes:

- **Corrupção acidental:** pode ser detectada de forma confiável por validação estrutural, versão e verificação de integridade.
- **Compartilhamento:** um arquivo portátil pode ser copiado e publicado. Sem identidade de jogador ou vínculo de servidor, o jogo não consegue provar quem o criou.
- **Manipulação intencional:** assinatura ou ofuscação local dificulta edições casuais, mas uma pessoa determinada pode extrair segredos incluídos no aplicativo, alterar o arquivo ou modificar o próprio cliente.

Vincular o backup a uma chave exclusiva do aparelho impediria sua restauração legítima em outro dispositivo. Vinculá-lo a uma conta ou assinatura emitida por servidor contrariaria o escopo atual sem conta e offline-first. Portanto, impedir compartilhamento ou fraude de forma forte exigiria abrir mão de alguma decisão já tomada.

Enquanto o jogo for individual, sem compras de progresso, competição ou ranking confiável, o save local é tratado como estado controlado pelo jogador: o produto valida corrupção, dificulta adulteração casual e aceita que proteção absoluta não existe. Backups permanecem portáteis entre instalações compatíveis e não são vinculados ao aparelho. Qualquer futura função competitiva ou economia de valor real não poderá confiar nesses números locais como fonte de verdade.

## Decisões pendentes

- eventos e frequência exata de salvamento automático;
- formato e versionamento do arquivo;
- verificação de integridade e eventual confidencialidade;
- tamanho máximo e política de compatibilidade entre versões;
- tratamento de backups originados em Android quando a versão de iOS existir.
