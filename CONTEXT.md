# Aura Shift: Six Seven

Glossário canônico do universo e da experiência do jogo, usado para manter consistência entre game design, conteúdo e produto.

## Language

**Jogador-alvo**:
Pessoa de 13 a 24 anos familiarizada com memes e jogos casuais, com público secundário de até 34 anos. O produto não é direcionado a menores de 13 anos.
_Evitar_: criança, público infantil

**Aura**:
Recurso central produzido pelo jogador e por seus melhoramentos.
_Evitar_: ponto, moeda premium

**Aura Disponível**:
Parcela da Aura que o jogador ainda pode gastar na Loja.
_Evitar_: pontuação, Aura Total

**Aura Total**:
Toda a Aura já produzida ao longo da jornada; nunca diminui e representa o progresso permanente do jogador.
_Evitar_: saldo, Aura Disponível

**Resto de Produção**:
Quanta acumulados que ainda não completaram uma Aura inteira e, por isso, ainda não foram reconhecidos nem atribuídos a qualquer contador ou jornada. O resto é compartilhado pelas fontes de produção, persiste sem ser gastável e nunca é descartado por atualização, fechamento ou Ascensão.
_Evitar_: Aura Disponível fracionária, arredondamento visual, bônus oculto

**Produção de Aura**:
Ritmo em que Aura é gerada por ações do jogador ou de forma passiva.
_Evitar_: pontuação por segundo

**Produção Ativa**:
Aura gerada pela conclusão de Ciclos Six-Seven durante uma sessão de interação.
_Evitar_: Produção Passiva, Aura por toque

**Ciclo Six-Seven**:
Unidade básica da interação ativa, concluída por dois toques válidos consecutivos e recompensada com Aura somente ao final.
_Evitar_: clique, clique duplo, ciclo de clique

**Fase Six**:
Primeira metade do Ciclo Six-Seven, na qual as mãos mudam de posição e o jogador recebe feedback imediato, mas ainda não recebe Aura.
_Evitar_: primeiro clique

**Fase Seven**:
Segunda metade do Ciclo Six-Seven, na qual as mãos se invertem, o ciclo é concluído e a Aura é concedida.
_Evitar_: segundo clique

**Produção Passiva**:
Aura gerada sem a conclusão de Ciclos Six-Seven, inclusive durante uma ausência dentro das regras de Produção Offline.
_Evitar_: Aura grátis, produção ativa

**Produção Offline**:
Produção Passiva acumulada enquanto o jogo está fechado, limitada ao equivalente a quatro horas por ausência.
_Evitar_: recompensa diária, produção ativa

**Taxa Offline Registrada**:
Produção Passiva final salva quando o jogo entra em segundo plano e usada, sem evolução composta, para calcular a ausência seguinte.
_Evitar_: taxa atualizada retroativamente, Produção Ativa

**Bônus de Retorno**:
Adicional opcional de 20% sobre a Produção Offline proporcional, limitada a quatro horas, oferecido quando o jogador retorna após mais de dez minutos e assiste a um Anúncio Recompensado.
_Evitar_: produção extra ilimitada, bônus diário

**Recompensa de Retorno**:
Transação persistente de uma ausência superior a dez minutos que reúne a Produção Offline base proporcional e, quando elegível, a oportunidade única de Bônus de Retorno. A base permanece pendente até o jogador escolher resgatá-la ou concluir o anúncio.
_Evitar_: recompensa diária, crédito repetível

**Anúncio Recompensado**:
Anúncio iniciado voluntariamente pelo jogador em troca de um benefício apresentado antes da exibição.
_Evitar_: anúncio obrigatório, anúncio interrompendo a partida

**Potência de Ciclo**:
Quantidade exata de Aura gerada quando a Fase Seven conclui um Ciclo Six-Seven. Unidades completas são creditadas imediatamente, e quanta insuficientes para uma unidade permanecem no Resto de Produção.
_Evitar_: Aura por clique, força do clique, Aura por toque

**Técnica Six-Seven**:
Melhoramento ativo que aumenta a Potência de Ciclo ao aperfeiçoar tematicamente o movimento do personagem. As seis Técnicas ocupam o tronco central da Árvore de Aura, sem constituir um Ramo de Aura e sem exigir aquisição ou nível de outra Técnica. `TECH-01` existe desde o início; as demais são desbloqueadas permanentemente em `1K`, `1M`, `1B`, `1T` e `1Qa` de Aura Total e possuem custo-base equivalente a `6,7%` do respectivo Patamar.
_Evitar_: upgrade de clique, item ativo, ramo de Técnica, sequência obrigatória de Técnicas

**Item de Aura**:
Melhoramento passivo ligado à presença do personagem e responsável por aumentar sua Produção Passiva.
_Evitar_: cosmético, item ativo

**Nível de Melhoramento**:
Grau de evolução permanente de uma Técnica Six-Seven ou de um Item de Aura já adquirido.
_Evitar_: cópia, quantidade possuída

**Custo Geométrico**:
Regra em que o preço do próximo Nível de Melhoramento é o custo-base da entrada multiplicado pela razão universal `1,15` (`23/20`) elevada ao nível atual, com teto inteiro aplicado uma única vez. Cada entrada possui custo-base próprio, mas nenhuma razão escondida.
_Evitar_: custo linear, preço abreviado, multiplicação simples do lote

**Orçamento de Gate**:
Soma exata dos Custos Geométricos necessários para elevar um predecessor do nível `0` ao nível exigido pelo próximo nó da Árvore de Aura. É uma âncora de balanceamento do caminho e não substitui o Patamar de Aura nem inclui o custo de comprar o nó seguinte.
_Evitar_: preço do Patamar, custo do desbloqueio, requisito de Aura Total

**Orçamento de Amplitude**:
Soma exata de todos os Custos Geométricos necessários para construir, desde o início da jornada, os três caminhos até os níveis exigidos por um Item de Convergência. Exclui o custo da própria Convergência e permite medir quanto a rota ampla já investiu antes da recompensa opcional.
_Evitar_: Orçamento de Gate, preço da Convergência, custo de um único ramo

**Contribuição de Melhoramento**:
Parcela aditiva que os níveis de uma Técnica Six-Seven somam à Potência de Ciclo ou que os níveis de um Item de Aura somam à Produção Passiva antes da aplicação única do Multiplicador de Ascensão.
_Evitar_: multiplicador global, Efeito de Item visual, produção composta

**Contribuição-base**:
Quantidade fixa que cada nível de uma entrada acrescenta antes dos Marcos de Nível. Para Itens de Aura, sua unidade é `Aura/s por nível`; ela não representa a produção final do item, que também depende do nível, dos Marcos e do Multiplicador de Ascensão.
_Evitar_: produção final, ganho por compra em lote, multiplicador do item

**Marco de Nível**:
Nível predeterminado que duplica cumulativamente a Contribuição de Melhoramento completa daquela entrada, criando um salto econômico sem alterar custos já pagos ou outras entradas. O calendário universal usa níveis 10, 25, 50, 100 e cada múltiplo de 100 posterior.
_Evitar_: Transformação de Aura, Patamar de Aura, multiplicador global

**Pré-requisito de Item**:
Condição que exige níveis mínimos em um ou mais Itens de Aura para permitir o desbloqueio de outro Item de Aura. Quando mais de uma entrada é listada, todas precisam ser satisfeitas.
_Evitar_: preço, nível do jogador

**Árvore de Aura**:
Rede unificada de progressão da Loja que organiza as Técnicas Six-Seven como tronco central dos Patamares e os Itens de Aura em três ramos temáticos conectados por Pré-requisitos de Item, com Convergências opcionais. Reunir conteúdos do mesmo Patamar não cria dependência econômica.
_Evitar_: lista de itens, sequência linear, quarta ramificação

**Patamar de Aura**:
Estágio permanente liberado por Aura Total na escada `1K`, `1M`, `1B`, `1T` e `1Qa`. Cada Patamar desbloqueia uma Transformação de Aura, a Técnica correspondente e os Itens de Aura aplicáveis na Árvore; esses conteúdos não dependem da aquisição uns dos outros. O último Patamar também disponibiliza a primeira Ascensão.
_Evitar_: tier, nível do jogador

**Ramo de Aura**:
Caminho temático de cinco Itens de Aura dentro da Árvore de Aura. Depois do Item-raiz, os quatro itens seguintes exigem o predecessor nos níveis 10, 25, 50 e 100, respectivamente, além do Patamar de Aura aplicável.
_Evitar_: classe, sequência obrigatória

**Espelhamento Econômico**:
Regra do MVP segundo a qual Itens A, B e C de mesma profundidade possuem custo-base, contribuição-base, razão e Marcos de Nível idênticos. Os ramos diferem por tema, aparência e ordem de coleção, nunca por vantagem escondida.
_Evitar_: ramo correto, bônus temático, escolha irreversível

**Item-raiz**:
Primeiro Item de Aura de um Ramo de Aura. Os três Itens-raiz do MVP ficam disponíveis depois da primeira Técnica Six-Seven e começam economicamente equivalentes, permitindo que a escolha inicial seja feita por identidade e direção futura, não por uma armadilha numérica.
_Evitar_: item obrigatório, Item de Convergência, melhor escolha escondida

**Item de Convergência**:
Item de Aura opcional cujo desbloqueio exige simultaneamente progresso nos três Ramos de Aura. Convergências recompensam investimento amplo, mas não bloqueiam ramos, Patamares de Aura ou Ascensão.
_Evitar_: item final obrigatório, requisito de Ascensão, item de ramo único

**Ascensão de Aura**:
Reinício voluntário disponibilizado pela primeira vez em `1Qa` de Aura Total, que preserva o progresso permanente e concede um benefício duradouro em troca de reiniciar a economia corrente. O nome-fonte final é `Aura Ascension`.
_Evitar_: reset obrigatório, apagar progresso, prestígio

**Multiplicador de Ascensão**:
Benefício permanente derivado de toda Aura Ascendida e aplicado à produção das jornadas seguintes. Sua base é `1×`; em `balance-v0.4`, passar de `n×` para `(n+1)×` custa `n² Qa`, e o total em centésimos é o maior `A` cujo requisito `ceil(1Qa×(A−100)×A×(2A−100)/6.000.000)` não supera o acumulado `L`. A mesma Aura Ascendida produz o mesmo total independentemente de quantas Ascensões a consolidaram.
_Evitar_: bônus temporário, multiplicador de anúncio

**Aura Ascendida**:
Acumulado permanente `L` de toda Aura da Jornada consolidada ao confirmar Ascensões anteriores. Compras reduzem somente a Aura Disponível e não diminuem a Aura da Jornada nem a Aura Ascendida. O termo não representa saldo destruído ou moeda removida pela Ascensão.
_Evitar_: saldo consumido, moeda destruída, Aura Disponível, Aura Total

**Aura da Jornada**:
Aura produzida desde o início do jogo ou desde a Ascensão de Aura mais recente. Ao Ascender, ela é consolidada como Aura Ascendida e acrescentada ao acumulado permanente usado para derivar o Multiplicador. É necessário acumular ao menos `1Qa` em cada jornada para Ascender novamente.
_Evitar_: Aura Total, Aura Disponível

**Upgrade por Anúncio**:
Benefício opcional de Anúncio Recompensado para um item desbloqueado já no nível 1: concede `+1` nos níveis 1–5, `+5` nos níveis 6–100 e `+25` a partir do nível 101, sem gastar Aura. Três itens distintos podem receber o benefício antes de um cooldown global de 15 minutos.
_Evitar_: desconto de compra, Aura grátis, dois anúncios seguidos no mesmo item

**Mascote**:
Personagem fixo e original que representa o jogador, reconhecível pela silhueta estilizada e pelas mãos exageradamente grandes.
_Evitar_: avatar, pessoa real, personagem de meme

**Efeito de Item**:
Contribuição permanente de um Item de Aura adquirido para a Produção Passiva, independente de sua aparência estar visível.
_Evitar_: item equipado, bônus cosmético

**Aparência de Item**:
Representação visual desbloqueada por um Item de Aura e escolhida livremente para personalizar o Mascote sem alterar o Efeito de Item.
_Evitar_: equipamento obrigatório, skin com vantagem

**Coleção Visual**:
Conjunto permanente de Aparências de Item e suas variações já desbloqueadas, preservado entre Ascensões de Aura.
_Evitar_: inventário econômico, Itens de Aura ativos

**Transformação de Aura**:
Estado visual permanente do Mascote e de sua cena, desbloqueado por um marco de Aura Total e preservado após Ascensões de Aura.
_Evitar_: Aparência de Item, bônus temporário, nível do item

**Área de Aura**:
Superfície ampla da região central em que qualquer toque fora dos controles avança a fase atual do Ciclo Six-Seven.
_Evitar_: botão de clique, mão clicável, alvo

**Sincronização do Progresso**:
Salvamento automático do estado completo no slot canônico do Google Play Games, mantendo a persistência local imediata e o jogo offline.
_Evitar_: arquivo exportável, merge campo a campo, soma de recursos

**Notação Compacta de Aura**:
Representação universal truncada de grandes valores com até três algarismos significativos, sufixos fixos de K a Dc e notação científica a partir de `10³⁶`.
_Evitar_: sufixos traduzidos, m minúsculo, b minúsculo

**Jogo de Tendência**:
Produto concebido para aproveitar diretamente a relevância atual de um meme, aceitando perder apelo quando essa tendência saturar.
_Evitar_: jogo evergreen, franquia permanente, plataforma de memes

**Janela do Meme**:
Período limitado em que a referência Six-Seven ainda possui reconhecimento e força suficientes para impulsionar descoberta e interesse.
_Evitar_: vida útil permanente, roadmap infinito

**MVP Android v1.0**:
Escopo fechado da primeira publicação na Google Play, composto somente pelos sistemas, conteúdos e requisitos enumerados no documento de escopo. As quantidades de conteúdo aprovadas são exatas para essa versão, não pisos expansíveis antes do lançamento.
_Evitar_: protótipo incompleto, backlog aberto, versão iOS, conteúdo adicional

**Substituição de Escopo**:
Troca explicitamente aprovada em que uma nova entrega pré-lançamento somente entra após remover ou reduzir outra de custo e risco comparáveis, mantendo prazo e qualidade do MVP Android v1.0.
_Evitar_: aumento silencioso de escopo, corte silencioso, ideia grátis

**Cadência de Referência**:
Ritmo de 1,5 Ciclo Six-Seven por segundo usado para calibrar marcos econômicos, sem funcionar como limite ou exigência para o jogador.
_Evitar_: velocidade obrigatória, limite de toque

**Perfil de Simulação**:
Agenda reprodutível que combina sessões diárias, duração e cadência para testar a economia. Os perfis canônicos são Muito ativo, Referência, Casual e Passivo; eles descrevem cenários de balanceamento, não categorias atribuídas a jogadores reais.
_Evitar_: segmentação de usuário, dificuldade, perfil publicitário

**Bootstrap de Jornada**:
Trecho mínimo usado apenas pelo Perfil Passivo no início e depois de cada Ascensão, com Cadência de Referência até adquirir `TECH-01` no nível 1 e um Item-raiz no nível 1. Evita estagnação matemática sem criar automação ou benefício no jogo real.
_Evitar_: tutorial repetido, autoclick, reconstrução automática

**Evento Econômico Relevante**:
Compra, Marco de Nível, desbloqueio, Transformação, Convergência ou Ascensão que comunique avanço de produção ou acesso ao jogador.
_Evitar_: animação puramente ociosa, tick de produção, impressão de número

**Compra útil**:
Próximo nível desbloqueado escolhido pela heurística declarada da simulação por aumentar produção ou avançar um requisito. Sua espera acumula tempo aberto entre sessões até a compra ou substituição legítima por outra candidata.
_Evitar_: qualquer item visível, compra automática do jogador, oferta publicitária

**Cadeia de Reconstrução**:
Conjunto mínimo de itens, ancestrais e níveis necessários para readquirir, em cada ramo elegível, a maior profundidade possuída antes da Ascensão, incluindo Convergências antes possuídas na estratégia Ampla.
_Evitar_: catálogo inteiro, Técnicas Six-Seven, Patamares permanentes

**Reconstrução Econômica**:
Primeiro checkpoint pós-Ascensão em que a Cadeia de Reconstrução foi readquirida e Potência de Ciclo e Produção Passiva igualam ou superam separadamente os valores imediatamente anteriores ao reset.
_Evitar_: primeira compra, fim da jornada, Patamar permanente

**Gate de Balanceamento**:
Conjunto binário e versionado de critérios que uma versão econômica precisa satisfazer em toda a matriz de simulação. Uma falha reprova a versão em vez de ser compensada por médias ou anúncios.
_Evitar_: nota média, opinião isolada, meta exibida ao jogador

**Janela de Patamar**:
Faixa-alvo de tempo de calendário em que um Perfil de Simulação deve alcançar determinado Patamar no cenário-base sem anúncios. Funciona como critério de balanceamento, nunca como cronômetro ou garantia individual.
_Evitar_: tempo obrigatório, bloqueio temporal, promessa ao jogador

**Retorno Projetado de 24 Horas**:
Heurística-base de simulação que divide a Aura adicional esperada nas próximas 24 horas pelo custo exato do próximo nível, usando a agenda do Perfil de Simulação. É ferramenta de balanceamento, não recomendação exibida ao jogador.
_Evitar_: preço, paywall, dica obrigatória, previsão individual

**Política de Ascensão da Simulação**:
Regra metodológica que determina quando um perfil simulado realiza a Ascensão. O baseline Ascende em `1Qa` de Aura da Jornada; sensibilidades esperam `2Qa`, `4Qa` ou `9Qa`. Não representa recomendação nem automação no jogo real.
_Evitar_: Ascensão automática, estratégia correta, tutorial obrigatório

**Livro-Razão de Aura**:
Regra canônica que determina quais eventos creditam ou debitam Aura Disponível, Aura Total e Aura da Jornada.
_Evitar_: saldo único, contagem visual

**Compra em Lote**:
Aquisição de vários Níveis de Melhoramento em uma única ação pelos modos `×10` ou `MÁX`, sempre usando o custo cumulativo real.
_Evitar_: desconto em massa, anúncio como financiamento de lote

**Marco 67**:
Conquista permanente disparada uma única vez quando a Aura Total cruza um valor da forma `67 × 1000ⁿ`.
_Evitar_: Aura Disponível igual a 67, texto abreviado, evento repetível

**Selo 67**:
Registro visual permanente concedido por um Marco 67 e associado à magnitude específica alcançada, sem efeito econômico.
_Evitar_: bônus de Aura, multiplicador, Item de Aura

**Conquista**:
Marco local permanente que reconhece uma ação ou situação do jogador por meio de um emblema e texto comemorativo, sem efeito econômico.
_Evitar_: missão, recompensa de Aura, conquista da Google Play

**Conquista Secreta**:
Conquista cujo nome e condição permanecem ocultos até ser desbloqueada.
_Evitar_: requisito obrigatório, conteúdo pago

**Tutorial Contextual**:
Orientação integrada à primeira partida que apresenta cada conceito somente quando ele se torna relevante, sem interromper o jogo com uma apresentação separada.
_Evitar_: slideshow, compra forçada, tutorial bloqueante

**Telemetria de Produto**:
Coleta opcional, consentida e minimizada de eventos técnicos e comportamentais usada para avaliar ativação, progressão, retenção e funcionamento do jogo. Seus dados detalhados permanecem por dois meses, sem renovação do prazo por nova atividade ou exportação externa. Não inclui o conteúdo do save, valores exatos de Aura, identidade declarada ou Play Age Signals.
_Evitar_: rastreamento obrigatório, perfil do jogador, vigilância, upload do save

**Consentimento de Analytics**:
Escolha explícita e específica do jogador que autoriza coletas futuras da Telemetria de Produto naquele aparelho, independente do consentimento necessário para anúncios. Seu único convite automático ocorre após o primeiro Ciclo Six-Seven conceder a primeira Aura; uma recusa somente pode ser revista voluntariamente em Configurações.
_Evitar_: consentimento presumido, consentimento publicitário, permissão herdada da Sincronização do Progresso

**Relatório de Diagnóstico**:
Registro técnico de uma falha fatal ou ANR mantido inicialmente no aparelho e enviado ao Firebase Crashlytics somente após autorização específica na abertura seguinte. Pode conter stack trace, versão, dados técnicos do aparelho, horário, identificadores de instalação e, quando analytics já estiver habilitado, breadcrumbs permitidos.
_Evitar_: ticket de suporte, conteúdo do save, envio automático, Telemetria de Produto

**Autorização de Diagnóstico**:
Escolha de uso único que permite enviar o lote de Relatórios de Diagnóstico pendentes e claramente informado naquele momento, sem habilitar relatórios futuros.
_Evitar_: Consentimento de Analytics, autorização permanente, aceite presumido

**Crash Insights**:
Recurso opcional do Firebase que compara stack traces anonimizados entre aplicativos para sugerir tendências comuns. Permanece desativado no lançamento sem impedir o recebimento dos Relatórios de Diagnóstico autorizados do Aura Shift: Six Seven.
_Evitar_: Crashlytics, relatório próprio, diagnóstico obrigatório
