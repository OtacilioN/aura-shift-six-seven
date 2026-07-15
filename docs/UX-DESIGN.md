# Aura Shift: Six Seven — Direção de UX

> Status: arquitetura `ux-flow-v1`, navegação, estados, sistema visual, copy-fonte e critérios de acessibilidade aprovados para planejamento; QA localizado e assets finais permanecem no desenvolvimento.

## Princípios

- a interação central deve ser compreendida sem tutorial longo;
- ações recorrentes devem funcionar confortavelmente com uma mão;
- o primeiro toque de cada ciclo nunca pode parecer ignorado;
- personalização não pode impor perda econômica;
- anúncios nunca podem interromper a interação principal;
- precisão motora não deve determinar acesso à produção-base;
- conexão e autenticação não devem impedir acesso à experiência principal.

## Contratos de experiência

- `UX-WIREFRAMES.md` define o mapa, os wireframes retrato, as máquinas de estado, cancelamentos, falhas e retomadas;
- `UI-DESIGN-SYSTEM.md` define tokens, tipografia, grid, componentes, RTL, números extremos e estados visuais;
- `ACCESSIBILITY.md` define a matriz mensurável `a11y-matrix-v1` para contraste, escala, toque, foco, TalkBack e modos reduzidos;
- `number-format-v1` continua sendo a única fonte da apresentação econômica; UI nunca infere valor pelo token compacto.

As quatro áreas são as únicas raízes. Detalhes, anúncios, consentimentos, diagnóstico, retorno offline, Ascensão, backup e erros usam folhas, diálogos ou subtelas do contexto que os abriu e nunca criam uma quinta área.

## Estados de conectividade

A experiência principal permanece funcional offline e sem login. Ofertas de Anúncio Recompensado ficam discretamente indisponíveis quando não houver conexão ou inventário, sem modal de erro recorrente e sem bloquear a alternativa-base.

O lançamento salva o progresso somente no aparelho. Não há conta, backup em nuvem ou sincronização automática. O jogador pode exportar um Backup Manual para arquivo e importá-lo posteriormente. Antes da restauração, a interface apresenta data, versão e resumo do backup e exige confirmação de que o progresso atual será substituído. Qualquer falha de validação mantém o estado ativo intacto.

## Retorno ao jogo

A tela de retorno aparece após ausência superior a dez minutos e apresenta a duração real da ausência e a Produção Offline proporcional, limitada a quatro horas. Quando a ausência ultrapassa o limite, a folha explica explicitamente que somente quatro horas foram creditadas. Ela oferece resgatar a base ou assistir voluntariamente a um anúncio para resgatar a mesma base com Bônus de Retorno de 20%. Nenhum valor é creditado antes da escolha. Escolher a base encerra a oferta; concluir validamente o anúncio credita a base e o adicional. Em caso de falha, a interface permite tentar novamente ou continuar somente com a base. Reabrir o aplicativo recupera a pendência sem repetir créditos.

Na abertura, fluxos persistentes são reconstruídos em ordem segura: recuperação do save, Recompensa de Retorno e bônus já escolhido, diagnóstico, tutorial/consentimento disparado, confirmação de Ascensão ainda válida e, por último, celebrações. Consentimentos e erros pausam apresentações; celebrações ficam enfileiradas e podem ser dispensadas sem perder registros.

## Seleção de idioma

Na primeira abertura, o jogo acompanha o idioma do aparelho quando suportado e usa inglês como fallback. Um seletor fica acessível antes do tutorial e em Ajustes. As opções aparecem em seus nomes nativos; `Português (Brasil)` recebe a bandeira do Brasil como apoio, mas nenhuma opção depende exclusivamente de uma bandeira. A troca é aplicada imediatamente e salva localmente.

## Tutorial Contextual

A primeira abertura entra diretamente em Jogar e pede dois toques na Área de Aura. O ciclo é real e concede a primeira Aura. Novas orientações aparecem somente quando o conteúdo se torna relevante: primeira Técnica acessível, primeiro Item e Produção Passiva. A primeira Transformação acontece pelas regras econômicas normais.

Imediatamente depois de a primeira Aura aparecer, uma folha curta apresenta o único convite automático de Consentimento de Analytics. “Permitir” e “Agora não” recebem o mesmo destaque; fechar equivale a “Agora não”. A coleta permanece desligada até um aceite e nenhuma ação anterior é enviada. Qualquer escolha devolve o jogador ao tutorial no mesmo estado.

O tutorial termina após a aquisição do primeiro Item. Destaques não bloqueiam toque ou navegação, podem ser dispensados e podem ser revistos em Ajustes. Nenhum anúncio aparece durante o fluxo.

Monetização só é habilitada após o tutorial e depois de uma Técnica e um Item comprados normalmente. A primeira oferta explica a escolha e sua alternativa sem anúncio. Pular coach marks não antecipa anúncios.

## Composição principal

A interface é vertical e se divide conceitualmente em três regiões:

1. **Superior:** indicadores de Aura e progressão.
2. **Central:** Mascote, efeitos e Área de Aura.
3. **Inferior:** navegação e acesso às ações recorrentes.

Telas mais largas adaptam e centralizam essa composição. Uma interface horizontal alternativa não pertence ao escopo inicial.

O layout de referência é `360×800dp` e permanece utilizável desde `320×568dp`, respeitando safe areas e escala textual de `200%`. A barra inferior mede no mínimo `64dp` mais safe area. Ações recorrentes ficam na metade inferior; barras de ação fixas reservam espaço no conteúdo e nunca cobrem a última linha.

## Navegação inferior

### Jogar

Contém Mascote, Área de Aura, contadores, progressão imediata e acesso a um painel de detalhes econômicos. O cartão `Próximos passos` resume o próximo Patamar, o desbloqueio mais próximo da Loja e o Marco de Item mais próximo. Sua folha expandida centraliza os requisitos e abre diretamente o nó correspondente na Árvore de Aura, sem criar uma quinta área.

### Loja

Contém uma única Árvore de Aura visual, sem aba ou lista separada de Técnicas. As seis Técnicas Six-Seven formam o tronco central distribuído pelos Patamares; Poise, Motion e Signal permanecem os únicos três Ramos de Aura, e as Convergências ocupam uma camada compartilhada. Cada nó abre detalhe, requisitos, compras `×1`, `×10` e `MÁX` e Complemento de Aura elegível. O detalhe informa o próximo Marco de Nível e compara a contribuição atual com a projetada após o salto.

Se valores distintos de uma comparação produzirem o mesmo texto compacto, a interface não aumenta arbitrariamente as casas: ela calcula a diferença exatamente. Para saldo insuficiente, a ação mostra `Faltam {diferença} Aura`; para contribuição atual contra projetada, mostra `+{diferença} Aura/ciclo` ou `+{diferença} Aura/s`. O rótulo curto pode seguir `number-format-v1`; um detalhe acionável e a leitura assistiva oferecem a representação completa. Quando elegível, o Complemento de Aura reutiliza exatamente a falta, sem sugerir que os dois valores abreviados eram economicamente iguais.

Quando uma Compra em Lote atravessa um ou mais Marcos de Nível, o nível, o novo efeito e todos os fatores alcançados são aplicados imediatamente. A interface apresenta uma única celebração consolidada para evitar uma sequência de modais; o feedback usa componentes compartilhados e não exige nova arte exclusiva em marcos ilimitados.

A Árvore de Aura mostra as Técnicas intercaladas no eixo central e os três ramos simétricos em trilhas Poise, Motion e Signal, organizados em faixas de Patamar. Motion compartilha o alinhamento central em estágios alternados, mas forma uma trilha distinta por rótulo, cor e forma. Faixa, halo e proximidade expressam liberação conjunta por Aura Total, nunca Pré-requisito: Técnicas continuam independentes umas das outras e dos Itens do mesmo Patamar. Conectores de Pré-requisito são reservados às relações econômicas reais, inclusive `TECH-01` no nível `1` para os três Itens-raiz. Um bloqueio informa separadamente o Patamar de Aura, o item predecessor e o nível ainda necessário. Convergências exibem os três requisitos lado a lado; elas parecem objetivos extras, não um corredor obrigatório para Ascensão.

### Coleção

Contém personalização do Mascote por Aparências, Transformações de Aura, 13 Conquistas e Selos 67. Um seletor interno `2×2`, com contagens, mantém cada seção em sua própria rolagem e torna Conquistas encontráveis sem exigir atravessar Aparências e Transformações. Esses sistemas compartilham a superfície, mas mantêm identidades e contagens separadas. Um editor completo de avatar não pertence a esta entrega.

### Ajustes

Contém idioma, música, efeitos sonoros, vibração, opções de acessibilidade, Backup Manual, privacidade, analytics e créditos. Depois de uma recusa, Analytics só pode ser ativado voluntariamente nessa área; o jogo não repete o convite.

As quatro áreas ficam na barra inferior e são acessíveis com uma mão. O painel de detalhes da Aura aparece sobre Jogar e não constitui uma área adicional.

Voltar fecha primeiro diálogo, folha, detalhe ou subtela antes de sair. Trocar de área preserva rolagem, filtro, nó selecionado e fase vigente. Em árabe, a composição e a ordem espacial são espelhadas, enquanto cada token econômico permanece isolado como LTR.

O mapa completo é:

- **Jogar:** indicadores, Área de Aura, Próximos passos, Detalhes de Aura e acesso contextual à Ascensão;
- **Loja:** uma única Árvore de Aura com Técnicas no tronco central, Ramos e Convergências; detalhe, requisitos e compra permanecem dentro da Loja;
- **Coleção:** Aparências, Transformações, Conquistas e Selos 67 com estado econômico separado;
- **Ajustes:** idioma, canais sensoriais, acessibilidade, Backup Manual, privacidade, tutorial, créditos e licenças.

## Retorno após falha

Quando existir um Relatório de Diagnóstico local da execução anterior, a abertura seguinte apresenta uma oferta curta antes de devolver o controle normal. “Enviar” e “Não enviar” possuem o mesmo peso visual, não oferecem recompensa e não alteram o progresso. Dispensar equivale a não enviar.

Se houver mais de um relatório pendente, a quantidade é mostrada e a decisão vale para o lote informado. Aceitar autoriza o envio desse lote quando houver conexão, sem autorizar falhas futuras. Recusar apaga o lote. A mensagem não exibe stack trace ou detalhes técnicos intimidadores, mas permite abrir uma explicação acessível das categorias de dados incluídas.

Se o envio autorizado aguardar conexão, a UI mostra esse estado sem bloquear o jogo. Foco retorna ao controle anterior depois de enviar, recusar, dispensar ou resolver um erro.

## Exibição de Aura

Os indicadores principais seguem `number-format-v1`: usam Notação Compacta de Aura com até três algarismos significativos truncados, dígitos ASCII, sufixos universais e separadores localizados. Uma área de detalhes oferece inteiros canônicos segmentados e taxas decimais exatas, contagem de dígitos quando aplicável, cópia exata e contexto para Aura Disponível, Aura Total, Aura da Jornada, Potência de Ciclo e Produção Passiva. Em árabe, o token econômico é isolado como LTR dentro da composição RTL.

Marcos 67 são detectados pelo valor exato da Aura Total. Se um crédito atravessar mais de um, as celebrações são apresentadas em sequência sem bloquear o registro dos demais.

Cada celebração destaca `67`, executa um movimento especial e intensifica a cena por `6,7 segundos`, sem bloquear permanentemente a interação. Um Selo 67 é adicionado à coleção da magnitude. O fluxo possui alternativa reduzida para configurações sensoriais e não comunica ganho econômico.

## Área de Aura

A Área de Aura ocupa a região central livre de controles. Qualquer toque válido nela avança a fase atual do Ciclo Six-Seven. Não é necessário acertar o Mascote, suas mãos ou lados alternados.

Cada toque válido produz:

- feedback no ponto de contato;
- resposta visual do Mascote;
- resposta sonora e tátil conforme as configurações do jogador;
- mudança da Fase Six para a Fase Seven, ou conclusão do ciclo.

Música, efeitos sonoros e vibração podem ser configurados independentemente. A ausência de um canal nunca remove informação essencial nem altera recompensas.

Toques em navegação, Loja, botões ou outros controles não avançam o ciclo. A fase vigente permanece salva quando o jogador interrompe a interação.

## Velocidade e ritmo

Não existe combo econômico, erro de ritmo, barra de energia ou punição por lentidão. Cada ciclo concluído gera a Potência de Ciclo vigente; o feedback numérico comunica as unidades inteiras creditadas, enquanto qualquer fração permanece preservada. Tocar mais rápido aumenta naturalmente a quantidade de ciclos por tempo, enquanto o feedback audiovisual ganha intensidade sem mudar o valor da recompensa. Ao parar, a intensidade diminui suavemente e nenhum progresso é perdido.

## Semântica de toque

Cada novo contato válido avança uma fase exatamente uma vez. Somente um contato físico é aceito por vez. Enquanto qualquer dedo estiver pressionado, contatos adicionais são ignorados; Six e Seven exigem dois toques sequenciais.

Manter um dedo pressionado ou arrastá-lo não repete fases. Contatos simultâneos ignorados não emitem crédito, marcador, áudio ou vibração. O MVP não detecta, acusa nem pune autoclickers; sua única limitação de entrada é o teto técnico abaixo, que não pode justificar perda perceptível de toques humanos legítimos.

O jogo processa até oito novos contatos válidos em qualquer janela móvel de `1.000ms`. Somente o excedente pode ser descartado, sem mensagem de trapaça, punição ou perda do estado anterior. A regra limita a entrada a no máximo quatro Ciclos/s e vale também para a ação semântica da Área de Aura.

## Acessibilidade

A redução de movimento acompanha o sistema por padrão, com substituição manual em Ajustes. Ela remove squash, zoom, tremor, parallax, câmera e gestos intensos, usando crossfade de `100–200ms` ou estado estático para Transformações e Marcos 67. Opções independentes reduzem flashes/partículas, aumentam contraste e habilitam dicas extras para leitor de tela.

Informação essencial usa canais redundantes e nunca depende apenas de cor, áudio, vibração ou movimento. Textos respeitam escala do aparelho em layouts adaptáveis; controles e valores recebem rótulos acessíveis; alvos recorrentes evitam precisão fina. Nenhuma opção modifica a economia.

O baseline mensurável usa WCAG 2.2 AA: `4,5:1` para texto normal, `3:1` para texto grande, ícones, controles e foco, alvos mínimos `48×48dp`, foco de `2dp` com contraste `3:1`, reflow em `320dp` a `200%` e TalkBack em todos os fluxos críticos. Movimento Reduzido remove squash, zoom, parallax, câmera e tremor; Reduzir flashes elimina flashes deliberados e limita partículas conforme `ACCESSIBILITY.md`.

A Árvore possui uma rota linear semântica equivalente ao pan visual. A Área de Aura é um único controle TalkBack; cada ativação avança exatamente uma fase. Atualizações passivas não roubam foco nem produzem anúncios contínuos.

## Fluxo de Ascensão

O painel de Ascensão torna-se visível em `1Qa` de Aura Total. A confirmação permanece desabilitada enquanto a Aura da Jornada atual for menor que `1Qa` e mostra o valor restante.

Se existir uma Recompensa de Retorno pendente, a confirmação de Ascensão permanece desabilitada até o jogador resgatar a base ou concluir a alternativa com bônus. Recusar o bônus e resgatar a base não reduz sua recompensa.

Quando elegível, a prévia apresenta:

- Aura da Jornada usada no cálculo;
- ganho permanente projetado a partir do acumulado de Aura sacrificada, com precisão de `0,01×`;
- Multiplicador de Ascensão atual e resultante;
- Aura Disponível, Aura da Jornada, Técnicas, Itens, níveis e efeitos que serão reiniciados;
- Aura Total, Patamares, Transformações, Conquistas e Coleção Visual preservados.

A ação exige uma confirmação explícita final, não possui anúncio nem pagamento e somente encerra quando bônus e reinício foram persistidos como uma única transação.

## Integração e validações de desenvolvimento

- copy-fonte e catálogos estão versionados em `COPY-DECK.md` e `localization/`;
- conceitos, slots e composição estão em `CONTENT-CATALOG.md`, `ART-DIRECTION.md` e `ASSET-MANIFEST.md`;
- timings, VFX, áudio e haptics estão em `MOTION-VFX-BIBLE.md`, `AUDIO-DIRECTION.md` e `AUDIO-INVENTORY.md`;
- a implementação ainda deve validar tokens, fontes empacotadas, TalkBack, reflow, matriz de aparelhos e os assets/masters reais. Essas são evidências de build, não decisões de UX em aberto.
