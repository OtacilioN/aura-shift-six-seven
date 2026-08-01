# Aura Shift: Six Seven — Design de Salvamento

> Status: estratégia e contrato econômico `arith-v1` aprovados; contêiner
> versionado de Saved Games implementado, com ativação manual ainda pendente no
> Play Console.

## Objetivos

- preservar automaticamente o progresso entre sessões;
- manter a experiência principal independente de conexão;
- permitir recuperação automática pelo perfil Gamer autenticado;
- impedir que falhas de sincronização ou restauração destruam o estado válido;
- permitir evolução compatível do formato ao longo das versões.

## Salvamento ativo

O progresso é salvo imediatamente no armazenamento local. Quando o Google Play
Games estiver autenticado e Saved Games estiver habilitado no Console, o mesmo
estado é sincronizado automaticamente entre aparelhos.

Cada perfil Gamer mantém uma única jornada no slot `aura_shift_primary`. Não
existem perfis internos, espaços paralelos ou seletor de slots.

O estado persistente deve abranger, no mínimo:

- Aura Disponível, Aura Total e Aura da Jornada;
- versão do contrato aritmético e Resto de Produção inteiro;
- caches inteiros derivados `P20` da Potência de Ciclo e `T20` da Produção Passiva, além da quantidade de Ascensões, da Aura de Ascensão acumulada `L` e do Multiplicador derivado `A` em centésimos;
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

Aura Disponível, Aura Total, Aura da Jornada, `L`, níveis e demais inteiros econômicos arbitrariamente grandes são serializados como texto decimal integral. O Resto de Produção satisfaz `0 ≤ R < 10.000.000` e permanece em fechamento, sincronização, restauração e Ascensão. `P20`, `T20` e `A(L)` são derivados verificáveis e reconciliáveis a partir de níveis, parâmetros e `L`. `F_registrado` é um snapshot canônico congelado até materializar a Recompensa de Retorno e nunca é recalculado com estado ou parâmetros posteriores. Taxas decimais pós-multiplicador nunca são fonte canônica.

Saves `balance-v0.1` sem `L` permanecem migráveis. A migração para `balance-v0.2` deriva `L` uma única vez da contagem de Ascensões e do multiplicador anterior. `balance-v0.3` também aceita saves `balance-v0.2` e recalcula os efeitos de Técnica. Ao migrar para `balance-v0.4`, saves `balance-v0.2` e `balance-v0.3` preservam saldo, Aura Total, Resto, níveis, coleção, snapshot offline e o `L` de Aura efetivamente Ascendida; o Multiplicador é reconciliado pela curva nova, sem aumentar `L` artificialmente.

Uma Ascensão deve ser uma transação atômica do save. O novo total inteiro do Multiplicador de Ascensão, a contagem de Ascensões, o zero da Aura da Jornada e todos os estados econômicos reiniciados precisam pertencer à mesma gravação válida. Uma falha não pode produzir metade da transação.

Recompensas de Retorno e cotações de Complemento de Aura carregam identificador e estados idempotentes. Base offline, bônus, saldo comprometido e falta coberta são representados exatamente conforme `ECONOMIC-ARITHMETIC.md`; repetir uma conclusão já aplicada não pode criar novo crédito ou nova compra.

## Sincronização pelo perfil Gamer

O save local é envolvido em um envelope versionado, determinístico e validado
por SHA-256. A sincronização automática usa o slot único
`aura_shift_primary`; falhas mantêm alterações pendentes e nunca impedem a
partida offline. Conflitos equivalentes, ancestrais ou dominantes podem ser
resolvidos automaticamente; conflitos ambíguos exigem escolha entre estados
completos. Consulte `docs/play-games/cloud-save.md`.

## Limitações assumidas

- sem autenticação ou antes de Saved Games ser habilitado no Play Console, a
  recuperação após limpeza de dados ou desinstalação não é garantida;
- sincronização depende do perfil Gamer e de eventual conectividade, mas a
  sessão permanece offline-first;
- SHA-256 detecta corrupção acidental, não prova autoria nem impede edição
  intencional no cliente.

## Compartilhamento, corrupção e manipulação

São problemas diferentes:

- **Corrupção acidental:** pode ser detectada de forma confiável por validação estrutural, versão e verificação de integridade.
- **Associação:** o remoto pertence ao Player ID autenticado; troca de perfil
  nunca mistura silenciosamente duas jornadas.
- **Manipulação intencional:** o hash local detecta corrupção, mas uma pessoa
  determinada pode alterar o estado ou o próprio cliente.

O vínculo ao perfil Gamer permite restauração legítima em outro aparelho, mas
não transforma o cliente em autoridade competitiva nem cria uma assinatura
secreta verificável.

Enquanto a economia permanecer no cliente, o produto valida corrupção,
dificulta adulteração casual e aceita que proteção absoluta não existe.
Placares e qualquer futura economia de valor real não podem confiar nesses
números locais como única fonte de verdade.

## Decisões pendentes

- ativação e publicação de Saved Games no Play Console;
- validação em faixa de teste com reinstalação e dois aparelhos;
- estratégia para uma futura versão iOS.
