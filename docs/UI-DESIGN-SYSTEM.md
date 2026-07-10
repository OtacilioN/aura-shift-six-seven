# Aura Shift: Six Seven — Sistema Visual de UI

> Status: `ui-system-v1` aprovado e reconciliado com P11. Implementação deve reproduzir tokens, fontes e critérios; qualquer troca tipográfica reabre reflow, nunca hierarquia ou comportamento.

## Direção

O sistema combina uma base noturna de alto contraste com sinais luminosos de Aura. A interface deve parecer um instrumento compacto para uma economia absurda em escala, não um painel corporativo nem uma coleção de cards genéricos. O Mascote e a arte ocupam o palco; UI usa planos sólidos, contornos precisos e brilho localizado para manter legibilidade em movimento.

A marca usa o título **Aura Shift: Six Seven** e a tagline **Two taps. Infinite aura.** quando houver contexto de marca. A UI funcional consome as chaves congeladas de `COPY-DECK.md` e os catálogos localizados; IDs neutros nunca são exibidos ao jogador.

## Princípios funcionais

1. **Estado antes de decoração:** bloqueio, seleção, risco e progresso usam texto, ícone e forma, nunca somente cor.
2. **Aura em foco:** um valor principal por tela; detalhes exatos ficam a uma ativação.
3. **Uma mão:** ação recorrente na metade inferior; confirmação irreversível em folha com verbo explícito.
4. **Escala extrema:** largura de um número nunca determina regra econômica ou tamanho de controle.
5. **Bidi real:** RTL espelha composição, não os tokens econômicos LTR.
6. **Sensorialmente substituível:** brilho, movimento, áudio e haptics reforçam; texto e forma confirmam.

## Tokens de cor

### Base e conteúdo

| Token | Valor | Uso |
| --- | --- | --- |
| `canvas` | `#090B1A` | fundo-base e cena noturna |
| `surface-1` | `#141936` | barras, cards e folhas |
| `surface-2` | `#202750` | seleção elevada e campos |
| `surface-scrim` | `#090B1ACC` | bloqueio atrás de modal |
| `text-primary-dark` | `#F7F5FF` | texto principal em fundo escuro |
| `text-secondary-dark` | `#C9C7D8` | texto secundário em fundo escuro |
| `text-disabled-dark` | `#8C8A9D` | estado indisponível acompanhado de rótulo |
| `paper` | `#F7F5FF` | superfície clara excepcional e foreground luminoso |
| `ink` | `#090B1A` | texto sobre preenchimentos claros |
| `divider` | `#4C5276` | divisores e bordas inativas |

Texto normal usa `text-primary-dark` ou `ink`. `text-secondary-dark` fica restrito a corpo não essencial com ao menos `16sp`; `text-disabled-dark` nunca comunica sozinho o motivo de bloqueio.

### Aura e identidade

| Token | Valor | Uso |
| --- | --- | --- |
| `aura-violet` | `#8B7CFF` | halo e progresso de transformação |
| `aura-cyan` | `#43E6FF` | ação primária e confirmação energética |
| `aura-magenta` | `#FF4FA3` | acento de celebração |
| `aura-gold` | `#FFD166` | Marcos 67 e valores especiais não monetários |

Gradientes são decorativos e não recebem texto pequeno. A ação primária usa preenchimento sólido `aura-cyan` com `ink`, não gradiente.

### Ramos e Convergência

| Identidade | Cor principal / apoio | Forma redundante |
| --- | --- | --- |
| Ramo A / Poise | `#43E6FF` / `#3478F6` | linha refletida e marcador losango |
| Ramo B / Motion | `#FF4FA3` / `#FF7A66` | pulso ondulado e marcador círculo |
| Ramo C / Signal | `#FFD166` / `#52E0A4` | sinal segmentado e marcador triângulo |
| Spectrum / Convergência | sequência A+B+C em segmentos, nunca mistura como texto | nó hexagonal com três entradas |

As cores de ramo não significam sucesso, erro, aviso ou seleção. Em monocromia, cada rota continua distinguível por forma, rótulo e padrão de conexão.

### Estados funcionais

| Token | Valor | Emprego redundante |
| --- | --- | --- |
| `status-success` | `#B7F171` | ícone check + verbo concluído |
| `status-warning` | `#FFE59A` | ícone alerta + explicação |
| `status-error` | `#FFB4AB` | octógono/ícone erro + mensagem |
| `status-info` | `#B9C3FF` | ícone informação + título |
| `focus` | `#F7F5FF` | anel externo de foco |

Status usa foreground `ink` quando preenchido e `text-primary-dark` quando apenas contornado. Nenhuma cor de status substitui o texto.

### Contraste obrigatório

- texto normal: mínimo `4,5:1` contra o fundo efetivo;
- texto grande, ícones essenciais e bordas de controles: mínimo `3:1`;
- foco visível e diferença entre estados adjacentes: mínimo `3:1`;
- texto desabilitado pode não atingir contraste de conteúdo ativo, mas o motivo do bloqueio deve aparecer em texto com `4,5:1`;
- qualquer alteração de paleta deve ser medida em captura composta, incluindo brilho, arte e scrim, não apenas nos hex isolados.

Na paleta `ui-system-v1`, medições sRGB de referência são: `text-primary-dark/canvas 18,11:1`, `text-primary-dark/surface-1 15,92:1`, `text-secondary-dark/surface-1 10,35:1`, `aura-cyan/surface-1 11,46:1` e `ink/aura-cyan 13,03:1`. Esses valores validam os pares-base, mas não substituem a medição da tela composta.

Ao ativar Aumentar contraste, superfícies translúcidas tornam-se opacas, texto secundário adota o tratamento principal quando a composição exigir, brilho atrás de conteúdo é removido e bordas de controles passam a `2dp`. A opção preserva as identidades de Ramo por forma/rótulo e nunca altera estado, hierarquia ou economia.

## Tipografia

As famílias de distribuição são:

- Latin (`en-US`, `pt-BR`, `es-419`, `fr-FR`, `de-DE`, `id`): **Noto Sans** para corpo; **M PLUS Rounded 1c** para display e `67`;
- japonês (`ja-JP`): **Noto Sans JP** para corpo; **M PLUS Rounded 1c** para display;
- árabe (`ar`): **Noto Sans Arabic** para corpo; **Noto Kufi Arabic** para display;
- números econômicos: a família do locale com `fontFeatures: tabularFigures` quando suportado; dígitos e sufixos permanecem ASCII.

As fontes devem ser empacotadas, versionadas e ter licença registrada no inventário de assets. Fallback do sistema só ocorre depois das famílias acima e não pode alterar o significado de símbolos.

### Escala

| Estilo | Base | Peso | Altura de linha | Uso |
| --- | ---: | ---: | ---: | --- |
| `display-aura` | `40sp` | 700 | `44sp` | Aura principal, uma linha quando possível |
| `display-67` | `52sp` | 800 | `56sp` | Marco 67, nunca corpo |
| `title-1` | `28sp` | 700 | `34sp` | título de raiz |
| `title-2` | `22sp` | 700 | `28sp` | folha e seção |
| `body` | `16sp` | 450 | `24sp` | texto principal |
| `body-strong` | `16sp` | 700 | `24sp` | label e valor |
| `caption` | `14sp` | 500 | `20sp` | contexto secundário |
| `button` | `16sp` | 700 | `20sp` | ações |

O aplicativo respeita escala de texto do sistema até `200%`. `display-aura` pode reduzir para `32sp` apenas pela responsividade do componente, nunca pela preferência do jogador, e deve quebrar ou compactar conforme `number-format-v1`. Corpo funcional nunca fica abaixo de `14sp` na escala `100%`.

Não há caixa alta obrigatória. Árabe e japonês não recebem tracking latino. Botões acomodam duas linhas antes de crescer verticalmente.

## Espaçamento, forma e elevação

- unidade-base: `4dp`;
- escala: `4, 8, 12, 16, 24, 32, 48, 64dp`;
- margem lateral: `16dp` em 320–599dp, `24dp` a partir de 600dp;
- distância mínima entre alvos independentes: `8dp` quando os próprios alvos não formarem um controle segmentado;
- raio: `12dp` em controles, `16dp` em cards, `24dp` no topo de folhas;
- borda padrão: `1dp`; selecionado e foco interno: `2dp`;
- sombras são discretas e nunca a única separação. Planos usam contraste de superfície e contorno.

## Grid e responsividade

O grid-base tem quatro colunas em 320–599dp e oito colunas a partir de 600dp. A composição retrato ocupa no máximo `520dp` de largura para Jogar; Loja e Coleção podem ocupar até `720dp` centralizados em telas grandes.

Breakpoints são guiados por espaço, não por aparelho:

- `compact`: 320–399dp — uma coluna, ações empilhadas;
- `standard`: 400–599dp — uma coluna com pares curtos;
- `expanded`: ≥600dp — painel e detalhe lado a lado quando não prejudicar ordem de leitura.

Orientação horizontal não possui composição dedicada no MVP. Se o sistema a impuser, a tela mantém o fluxo retrato centralizado/rolável, sem cortar ações.

## Iconografia

- grade óptica de `24dp`, traço de `2dp`, cantos arredondados e preenchimento somente para estado selecionado;
- ícones vêm sempre com rótulo na navegação e em ações não universais;
- setas direcionais espelham em RTL; play, pause, check, áudio e símbolos matemáticos não espelham;
- cadeado sempre acompanha a lista do requisito ausente;
- Aura, saldo, taxa, Ciclo, Item, Aparência e Efeito usam glifos distintos;
- nenhum ícone cultural vira símbolo funcional permanente sem validação no dossiê cultural e em `CONTENT-CATALOG.md`.

## Estados universais de componentes

Todo componente interativo implementa: `rest`, `pressed`, `focused`, `selected`, `disabled`, `loading`, `success` e `error` quando aplicável.

- `pressed`: mudança de superfície/contorno imediata, sem reduzir alvo;
- `focused`: anel externo `2dp`, offset `2dp`, contraste mínimo `3:1`;
- `selected`: preenchimento/contorno, ícone e semântica `selected`;
- `disabled`: ação não dispara; label permanece legível e motivo fica associado;
- `loading`: preserva largura e label; desabilita repetição; indicador recebe rótulo quando durar mais de 1s;
- `success/error`: não substituem o estado persistido nem desaparecem antes de serem percebidos por tecnologia assistiva.

## Componentes

### Barra inferior

- altura mínima `64dp` + safe area;
- quatro destinos de largura equivalente, alvo mínimo `48×48dp`;
- ícone `24dp`, rótulo `12–14sp` escalável; a `200%`, rótulo pode usar duas linhas e a barra cresce;
- seleção usa indicador sólido, label, peso e semântica, não apenas cor;
- ordem LTR: Jogar, Loja, Coleção, Ajustes; em `ar`, ordem visual espelhada com percurso lógico RTL.

### Botões

- primário: `aura-cyan` + `ink`, altura mínima `52dp`;
- secundário: transparente + borda `text-primary-dark`, altura mínima `52dp`;
- terciário: texto/ícone, alvo mínimo `48dp`;
- destrutivo: `status-error` + `ink`, sempre com verbo explícito;
- pares de consentimento usam o mesmo nível visual, largura e ordem não manipulativa;
- ação fixa nunca cobre o último item rolável.

### Cards econômicos

Ordem interna constante:

1. família + nome/ID + nível;
2. efeito atual → projetado;
3. próximo Marco de Nível;
4. requisitos ou falta exata;
5. preço e quantidade (`×1`, `×10`, `MÁX`);
6. ação.

Colisões compactas exibem diferença canônica. O card nunca aumenta casas locais para “resolver” igualdade aparente.

### Nó da Árvore

- mínimo visual `56×56dp`, alvo `64×64dp`;
- rótulo curto visível e nome completo no detalhe;
- bloqueado: cadeado + contorno tracejado + lista de requisitos;
- adquirido: nível e marca de estado; não usa check de conclusão definitiva porque níveis continuam;
- Convergência: hexágono e três conectores;
- linha de conexão tem espessura mínima `3dp` e padrão distinto por ramo.

### Indicador de progresso

- altura visual mínima `8dp`; não é controle;
- sempre acompanhado de rótulo textual com atual/meta ou requisito;
- padrão reduzido remove brilho animado e preserva preenchimento estático;
- TalkBack anuncia valor somente ao receber foco ou cruzar marco relevante, nunca a cada tick.

### Folhas, diálogos e banners

- folha inferior para detalhe, seleção e ação reversível; ocupa até 90% da altura e rola internamente;
- diálogo central apenas para falha bloqueadora do save ou confirmação irreversível curta;
- banner inline para offline, anúncio indisponível e confirmação não crítica;
- foco inicial no título/resumo; ação destrutiva nunca recebe foco automático;
- fechar retorna foco ao controle de origem.

### Toast e live region

Toast não carrega informação essencial isolada. Eventos persistentes usam banner, card ou histórico. Anúncios assistivos:

- Fase Six: “Fase Six”; Fase Seven: “Ciclo concluído, {Aura} concedida”;
- saldo passivo não é anunciado a cada atualização;
- sequência de créditos visuais é agrupada no máximo uma vez a cada `2s`, exceto compra, marco, erro e recompensa explicitamente acionada;
- mensagens críticas usam live region assertiva; progresso e confirmações comuns usam polite.

## Navegação por foco e TalkBack

- percurso segue topo → conteúdo → ação fixa → barra inferior;
- elementos decorativos e partículas são excluídos da árvore semântica;
- cards complexos são grupos com resumo e ações filhas; não expõem cada fragmento visual;
- Área de Aura é um controle único com fase, recompensa vigente e dica de ação;
- viewport da Árvore oferece lista semântica equivalente ordenada por Patamar, ramo e profundidade; pan/zoom não é obrigatório;
- arrastar sliders possui botões semânticos de incrementar/decrementar;
- ação customizada não substitui uma ação visível;
- foco não muda por produção passiva, chegada de anúncio, atualização de custo ou celebração enfileirada.

## Números extremos — receita obrigatória

Todo valor econômico consome `number-format-v1` e produz quatro saídas:

1. `compactVisual`: até três algarismos significativos, sufixos K–Dc ou científica;
2. `fullLocalized`: inteiro agrupado ou decimal terminante exato;
3. `copyCanonical`: ASCII sem agrupamento, taxa com ponto;
4. `semanticLocalized`: coeficiente, magnitude, unidade e natureza do valor.

O componente reserva largura por hierarquia, não pelo maior valor possível. Overflow permitido:

- contador principal: compacta, depois quebra label/valor; nunca elide o valor;
- card: valor quebra abaixo do label;
- detalhe completo: segmenta/virtualiza e informa contagem de dígitos;
- árabe: token inteiro recebe isolamento LTR; sinais, expoente e sufixo não se separam.

Fixtures mínimas: `0`, `999`, `1K`, `1.99K`, `999K`, `1M`, `1Dc`, `1e36`, expoente com 120+ dígitos, taxa `0.75`, taxa `10.5045`, saldo/preço visualmente iguais e diferença exata.

## Motion, flash, partículas e haptics

- transições funcionais padrão: `120–240ms`; celebrações podem durar mais conforme a bíblia de motion;
- Movimento Reduzido remove squash, zoom, parallax, câmera, tremor e deslocamento amplo; usa crossfade de `100–200ms` ou estado estático;
- nenhum efeito excede três flashes em qualquer janela de um segundo; nenhuma alternância luminosa de tela inteira é permitida;
- Reduzir flashes e partículas produz zero flash deliberado, remove pulsos de luminância e reduz partículas ao teto definido em `ACCESSIBILITY.md`;
- Six e Seven continuam distinguíveis por pose/forma e texto/estado sem áudio ou vibração;
- haptics são independentes e nunca carregam informação exclusiva;
- consentimentos e erros interrompem; celebrações são enfileiradas e dispensáveis sem perder registro.

## RTL e expansão de texto

- componentes usam `start/end`, nunca `left/right`, salvo movimento físico canônico das mãos;
- navegação, listas, folhas, breadcrumbs, setas e relações da Árvore espelham;
- gráficos econômicos e progressão temporal mantêm sua semântica documentada; tokens econômicos são LTR isolados;
- labels permitem `+35%` de pseudo-expansão em Latin e altura dinâmica;
- alemão testa compostos longos; japonês testa quebras sem espaços; árabe testa shaping, diacríticos, bidi misto e ordem de leitura;
- truncamento com reticências só é permitido para texto repetível cujo nome completo esteja no mesmo contexto acionável; requisito, erro, consentimento, valor e ação nunca são truncados sem alternativa imediata.

## Receitas de telas-chave em alta fidelidade

### Jogar

- `canvas` ocupa a cena; topo usa gradiente escurecido somente para separar indicadores;
- Aura principal em `display-aura/text-primary-dark`; taxas em `caption/text-secondary-dark` com ícones distintos;
- Área de Aura não tem moldura de botão; um contorno ambiente discreto e feedback no ponto tocado definem sua superfície;
- barra inferior em `surface-1`; destino ativo usa cápsula `surface-2` + `aura-cyan`.

### Loja/Árvore

- cards em `surface-1`, selecionado em `surface-2`; ação primária ciano;
- abas Técnicas/Árvore formam controle segmentado de altura `48dp`;
- conexões de ramo usam cor + padrão; nó selecionado recebe anel `paper`, não cor funcional;
- resumo do nó é folha `surface-1` com barra de ação fixa.

### Coleção

- palco do Mascote usa `canvas`; controles ficam em `surface-1` abaixo, sem cobrir silhueta;
- estado de aparência e efeito econômico são badges textuais separados;
- itens bloqueados usam silhueta neutra; Conquista Secreta não revela arte ou texto final.

### Ajustes/consentimentos

- lista em `canvas`, grupos em `surface-1`, divisores `divider`;
- switches têm rótulo, descrição e estado textual; não usam somente posição/cor;
- consentimentos usam folha clara ou escura consistente, ações equivalentes e link de detalhes antes das ações.

## Checklist de implementação por componente

Para entrar no catálogo, cada componente deve ter:

1. token e anatomia documentados;
2. estados universalmente aplicáveis;
3. semântica TalkBack e ordem de foco;
4. versão LTR e RTL;
5. escala textual `100%`, `130%`, `150%` e `200%`;
6. fixture pseudo-localizada `+35%`, japonês e árabe;
7. contraste medido em estados normal, pressionado, selecionado, desabilitado e foco;
8. versão com movimento, flashes, som e vibração desativados;
9. loading, vazio, erro, cancelamento e retomada quando assíncrono;
10. fixtures de `number-format-v1` quando exibir economia.

## Critérios de aceite de `ui-system-v1`

- tokens cobrem as quatro áreas e todos os fluxos de `UX-WIREFRAMES.md`;
- nenhuma cor de ramo é reutilizada como único sinal funcional;
- contraste atende WCAG 2.2 AA nos limiares documentados;
- nenhum controle essencial mede menos de `48×48dp` e ações primárias medem ao menos `52dp` de altura;
- foco é sempre visível, previsível e com contraste mínimo `3:1`;
- layout funciona a `320dp`, texto `200%`, pseudo-localização, `ja-JP` e `ar` RTL sem perder ação/informação;
- números extremos e comparação exata passam pelas fixtures de `number-format-v1`;
- TalkBack alcança todos os estados e ações sem depender de canvas, pan, cor, som, vibração ou movimento;
- desativar canais sensoriais não muda economia nem oculta resultado;
- ajustes de P11 podem trocar métricas/fallbacks somente depois de repetir toda a matriz acima.
