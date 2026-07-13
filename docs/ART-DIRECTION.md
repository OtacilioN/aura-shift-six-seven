# Aura Shift: Six Seven — Direção de Arte

> Status: direção visual `art-v1` fechada para produção do MVP; execução e aprovação dos assets finais permanecem no desenvolvimento.

## Norte visual

O universo usa a linguagem **recorte elétrico**: massas 2D arredondadas, contorno escuro de espessura constante, recortes internos simples e energia desenhada como fitas de luz quebradas em segmentos. A cena deve parecer elástica e contemporânea, com profundidade construída por sobreposição, sombra deslocada e brilho controlado — nunca por realismo, textura fotográfica ou excesso de detalhe.

Três princípios controlam toda decisão:

1. **Silhueta antes de acabamento:** Mascote, mãos, Ramos e Transformações precisam ser reconhecidos em miniatura e em escala de cinza.
2. **Energia com estrutura:** Aura usa arcos, fitas e pontos direcionais; ruído aleatório não substitui composição.
3. **Espetáculo honesto:** intensidade celebra cadência e eventos, mas jamais representa combo, raridade ou ganho econômico inexistente.

## Referências permitidas e proibidas

São permitidas referências abstratas a recortes de papel, adesivos serigráficos, brinquedos de borracha, luz de pista, equalizadores e cartazes geométricos. Referências servem para estudar contraste, ritmo, forma e acabamento, não para reproduzir personagens, poses, interfaces, logos ou composições.

São proibidos:

- semelhança intencional com pessoa real, mascote, personagem ou meme existente;
- mãos, gestos ou poses identificáveis de uma obra ou pessoa específica;
- logos, marcas, trade dress, capas, samples visuais ou tipografia proprietária não licenciada;
- estética de criptomoeda, cassino, loot box, raridade por cor ou recompensa monetária;
- neon cyberpunk genérico como linguagem dominante, pixel art nostálgica ou render 3D pintado por cima;
- texto essencial incorporado a ilustrações;
- imagem gerada sem registro de ferramenta, licença, prompt, revisão de originalidade e reconstrução editável.

## Paleta de arte

Esta paleta governa Mascote, fundos e efeitos. Tokens funcionais de interface pertencem ao sistema visual de UI e não devem transformar cor de Ramo em “sucesso”, “erro” ou “alerta”.

| Token de arte | Hex | Uso |
| --- | --- | --- |
| `INK-900` | `#090B1A` | contorno, fundo profundo |
| `INK-700` | `#141936` | massa escura e sombra |
| `PAPER-050` | `#F7F5FF` | olho, brilho e contraste claro |
| `AURA-VIOLET` | `#8B7CFF` | Aura-base e elo entre sistemas |
| `AURA-CYAN` | `#43E6FF` | energia fria e Ramo A |
| `AURA-MAGENTA` | `#FF4FA3` | energia quente e Ramo B |
| `AURA-GOLD` | `#FFD166` | culminação e Ramo C |
| `AURA-MINT` | `#52E0A4` | contraste secundário do Ramo C |
| `AURA-CORAL` | `#FF7A66` | contraste secundário do Ramo B |
| `AURA-BLUE` | `#3478F6` | contraste secundário do Ramo A |

Brilhos não usam branco puro em áreas grandes. Contornos permanecem `INK-900` ou equivalentes com contraste. Cor nunca é o único identificador: cada família possui geometria e ritmo próprios.

## Progressão cromática

| Estado | Distribuição | Leitura de forma |
| --- | --- | --- |
| Base, antes de `1K` | 75% ink, 20% violeta, 5% paper | sombra curta e borda interna discreta |
| `FORM-01`, `1K` | violeta + ciano | contorno externo claro e duas partículas lentas |
| `FORM-02`, `1M` | violeta + ciano + magenta | segunda silhueta deslocada e rastro curto |
| `FORM-03`, `1B` | ciano + magenta equilibrados, ouro pontual | campo neon e símbolos diagonais abstratos |
| `FORM-04`, `1T` | magenta + ouro, ink mais profundo | barras de skyline e onda de horizonte |
| `FORM-05`, `1Qa` | núcleo paper, espectro completo com ouro dominante | halo aberto conectando piso e horizonte |

A progressão amplia alcance, contraste e geometria, não apenas saturação. Em escala de cinza, cada etapa ainda precisa ser distinguível por contorno, duplicação de silhueta, padrão diagonal, barras de horizonte e composição conectada final.

## Character sheet textual do Mascote

O personagem atual é o **Rua Pixel kid**, desenhado proceduralmente em Canvas: boné `67`, camiseta `SIX SEVEN`, tênis grandes, cabelo, lágrimas azuis e mãos articuladas voltadas para cima. Ele é a única referência visual vigente para roupas, props e efeitos de cena; o antigo mascote abstrato não faz parte do produto.

### Proporções canônicas

- altura total em pose neutra: `8 unidades`;
- corpo: `6,2 u` de altura por `4,6 u` de largura máxima;
- cada mão: `2,8 u` de altura por `2,4 u` de largura, aproximadamente 35% da altura total;
- braço visível: faixa curva de no máximo `1,8 u`; pode comprimir atrás da mão;
- pés: `1,1 u × 1,6 u`, separados por `0,35 u`;
- olhos: eixo central em 32% da altura do corpo;
- linha de ombros/pivôs dos braços: 43% da altura do corpo.

As mãos continuam sendo o maior detalhe externo da silhueta em todas as Transformações e com qualquer Aparência equipada.

### Vistas e expressões obrigatórias

O Canvas precisa preservar uma leitura clara em neutro, Six e Seven, inclusive em miniatura. Expressão, cabelo, lágrimas, roupa e mãos pertencem ao mesmo desenho procedural; não há sheet raster separado nem sincronização labial.

### Mãos

As mãos seguem o mesmo traço do Rua Pixel kid e preservam a leitura de palmas voltadas para cima. Six e Seven são posições de altura e inclinação, não gestos numéricos ou de linguagem de sinais.

- **Pose neutra:** mãos na altura média, palmas em três-quartos para a câmera.
- **Fase Six:** mão esquerda alta e 8° para dentro; mão direita baixa e 10° para fora.
- **Fase Seven:** espelho de altura, mas não espelho do desenho interno; a mão direita fica alta.
- **Celebração 67:** ambas enquadram um espaço central vazio sem formar números com os dedos.

Cada mão possui desenho próprio, não uma reflexão automática, para preservar polegares e leitura. A arte não exige acertar uma mão: a Área de Aura continua ampla.

## Identidade visual dos Ramos

Os nomes culturais revisados em 11 de julho de 2026 adotam humor sistêmico; os IDs e slots continuam sendo as chaves estáveis de integração.

| Ramo | Território | Geometria | Paleta | Movimento sugerido | Aplicação de skins |
| --- | --- | --- | --- | --- | --- |
| `A` — Poise | presença quieta, linha e controle | linhas limpas, reflexos, arcos abertos e peso assimétrico | ciano + azul | entrada curta, suspensão e assentamento firme | peito, ombro, rosto, costas e cabeça |
| `B` — Motion | pulso, piso e movimento abstrato | ondas achatadas, fitas, ecos e barras de horizonte | magenta + coral | elasticidade, deslocamento e eco amortecido | quadril, tornozelos, piso, torso e fundo |
| `C` — Signal | repetição, estática e horizonte digital | recortes de canal, scanlines largas, antenas curvas e molduras abertas | ouro + menta | loop, deriva orbital e glitch de baixa frequência | peito, rosto, costas, cabeça e cena |

Em miniatura, Poise recorta, Motion reverbera e Signal enquadra. Itens da mesma profundidade usam área ocupada e complexidade equivalentes para não sugerir vantagem econômica. Convergências combinam exatamente uma forma primária de cada Ramo em um nó tripartido, sem criar um quarto Ramo.

## Concept sheets das Transformações

### `FORM-01` — First Glow (`1K`)

- **Silhueta:** contorno externo claro 8% mais largo, sem alterar as mãos.
- **Aura:** brilho violeta-ciano e exatamente duas partículas lentas.
- **Fundo:** gradiente profundo local, sem novo plano de cenário.
- **Pose/rosto:** postura mais aberta; expressão satisfeita.
- **Transição:** contorno expande e assenta em `450 ms`.
- **Reduzida:** crossfade de `200 ms` para contorno estático; sem expansão.

### `FORM-02` — Afterimage (`1M`)

- **Silhueta:** segunda silhueta limpa deslocada atrás do corpo, sem duplicar a leitura das mãos.
- **Aura:** rastro curto em dois tons, sem anel ou contagem pulsante.
- **Fundo:** duas faixas tonais desfocadas.
- **Pose/rosto:** leve inclinação do tronco; foco.
- **Transição:** duplicata desloca, alinha e assenta em `650 ms`.
- **Reduzida:** contorno duplo estático aparece em crossfade de até `200 ms`.

### `FORM-03` — Neon Weather (`1B`)

- **Silhueta:** luz ambiente recorta o corpo sem ampliar mãos ou cabeça.
- **Aura:** símbolos geométricos abstratos descem em diagonal lenta, sem texto ou ícone reconhecível.
- **Fundo:** campo neon em dois tons com contraste controlado.
- **Pose/rosto:** braços mais afastados do tronco; surpresa controlada.
- **Transição:** uma frente diagonal atravessa a cena e estabiliza em `900 ms`.
- **Reduzida:** troca estática de fundo em crossfade de até `200 ms`, sem chuva contínua.

### `FORM-04` — Skyline Pulse (`1T`)

- **Silhueta:** o Mascote parece maior somente pela luz externa; escala do rig não muda.
- **Aura:** uma onda larga liga o Mascote ao horizonte.
- **Fundo:** barras abstratas em três planos, compatíveis com Creative Astral Statement sem duplicá-lo.
- **Pose/rosto:** eixo central firme; foco.
- **Transição:** um pulso único percorre os planos e assenta em `1.100 ms`.
- **Reduzida:** barras estáticas entram em crossfade de até `200 ms`; sem zoom ou parallax.

### `FORM-05` — Aura Zenith (`1Qa`)

- **Silhueta:** halo aberto, piso e horizonte se conectam sem encobrir as mãos.
- **Aura:** núcleo paper e espectro dos três Ramos em camadas estáticas legíveis.
- **Fundo:** horizonte completo com abertura central; não é portal nem sinal de reset.
- **Pose/rosto:** celebração contida; mãos continuam dominantes.
- **Transição:** halo, piso e horizonte conectam em três estágios, total `1.500 ms`; não simula o reinício econômico.
- **Reduzida:** estado final e emblema entram em crossfade de até `200 ms`.

## Aura, partículas e fundos

Aura possui três famílias: `ribbon` (fita direcional), `spark` (losango curto) e `orb` (ponto circular com cauda). Cada emissão usa no máximo duas famílias. Partículas evitam estrelas, notas, moedas e gemas que poderiam sugerir outra recompensa.

O fundo da cena é construído em `BG-FAR`, `BG-MID`, `BG-NEAR` e `BG-GRADE`. A Área de Aura mantém uma zona de leitura de 60% da largura central sem elementos de alto contraste atrás do rosto ou das mãos. Fundos não contêm texto, logos nem informação econômica.

O modo reduzido troca emissores contínuos por estados estáticos ou emissões pontuais de baixa densidade. Limites, tempos e interrupções estão em `MOTION-VFX-BIBLE.md`.

## Selos 67

Todos os Selos 67 usam a mesma matriz hexagonal arredondada e um recorte central `67`; a magnitude aparece como texto de interface separado e localizável. Cada magnitude adiciona um anel externo, até quatro anéis visíveis; magnitudes posteriores substituem anéis adicionais por marcas cardinais para não exigir assets infinitos.

O Selo não usa cor de raridade nem brilho de moeda. A miniatura funciona em `48 × 48 px`, monocromática e sem animação. A celebração usa uma composição temporária maior, mas a peça colecionável é estática.

## Aparências de Item e slots

As 18 Aparências usam 12 dos 16 slots compatíveis do catálogo. Um item declara um único slot primário, mas todos os itens possuídos podem ser exibidos ao mesmo tempo. Conflitos de território são resolvidos pelo compositor com subposições e escalas estáveis, nunca pelo Efeito de Item nem pela remoção automática de outra Aparência. `AURA_BACK` é reservado às Convergências, que formam uma composição tripla quando coexistem. Slots vestíveis acompanham bob, lean e rotação; props de chão e molduras permanecem world-space.

| Slot | Camada | Envelope máximo no rig | Regra |
| --- | --- | --- | --- |
| `CHEST` | frente do torso | 42% × 24% | não encostar nos pivôs dos braços |
| `SHOULDER` | frente/atrás do ombro declarado | 38% × 28% | não cobrir a mão alta |
| `FACE_SIDE` | lateral do rosto | 60% × 20% | olhos mantêm 70% de área visível |
| `FACE_WEAR` | sobre o rosto, sob as mãos | 60% × 22% | duas lentes/peças preservam olhos e expressão |
| `BODY_WEAR` | sobre o corpo, sob as mãos | 70% × 62% | roupa acompanha o torso sem cobrir gestos |
| `HEAD_BACK` | atrás do topo | 82% × 30% | não cobrir olhos nem sugerir gesto |
| `HEAD_WEAR` | sobre o topo, sob as mãos | 82% × 30% | objeto parece apoiado na cabeça |
| `HIP` | frente/lateral inferior | 42% × 24% | não alterar leitura dos pés |
| `ANKLES` | sobre pés/tornozelos | 82% × 20% | par L/R próprio; sem exigir novo ciclo |
| `HAND_PROP` | sobre a mão declarada | 42% × 38% | acompanha o referencial do personagem |
| `HANDS_WEAR` | sobre as duas mãos | 88% × 48% | deriva centros e pulsos do rig atual |
| `BODY_BACK` | atrás do corpo e mãos | 110% × 70% | não ultrapassar zona segura superior |
| `GROUND_BACK` | atrás dos pés | 120% × 30% | decorativo, sem colisão ou alvo |
| `GROUND_PROP` | chão, atrás do Mascote | 42% × 42% | world-space; apoio visível e sem cobrir o personagem |
| `SCENE_FRAME` | atrás do palco central | 132% × 86% | nunca enquadrar ou cobrir UI |
| `AURA_BACK` | entre fundo e rig | 126% × 82% | exclusivo das Convergências |

Variações visuais de marco permitidas no MVP usam o mesmo arquivo-base com até três camadas alternáveis: `BASE`, `ACCENT` e `GLOW`. Não existem sprites exclusivos para níveis ilimitados. A Coleção mostra claramente aparência preservada e Efeito de Item inativo após Ascensão.

## Composição e internacionalização

A referência é vertical `1080 × 1920`, com safe area variável. Mascote e palco ocupam uma área lógica quadrada central; indicadores ficam acima e navegação abaixo. Telas largas centralizam a cena, sem criar layout horizontal próprio.

Texto essencial é renderizado por UI, nunca rasterizado na arte. Molduras são neutras quanto à direção; setas ou progressões direcionais pertencem aos componentes e podem espelhar em RTL. O número `67` é um token econômico/cultural em dígitos ASCII e não é desenhado dentro de fundos ou skins.

## Produção e integração

O inventário, convenções de nomes, dimensões, pivôs, camadas, formatos, variantes reduzidas e critérios de aceite estão em `ASSET-MANIFEST.md`. O pseudo-rig do personagem é procedural em Canvas dentro da cena Flame; Rive, sprites `chr_*`, 3D e animação quadro a quadro por combinação permanecem fora do MVP.

Cada asset final passa por:

1. teste de silhueta a 10%;
2. teste em escala de cinza e simulação de deficiências de visão cromática;
3. composição com todas as classes de slot;
4. revisão de originalidade e proveniência;
5. teste de orçamento em aparelho Android modesto;
6. comparação com a alternativa reduzida.

## Decisões fechadas e risco residual

`art-v1` fecha linguagem, paleta de arte, Mascote, mãos, territórios Poise/Motion/Signal, cinco Transformações, Aura, fundos, Selos, slots e contrato de exportação. Os conceitos das 18 Aparências vêm de `CONTENT-CATALOG.md` e respeitam os envelopes deste documento.

Riscos residuais a validar na fatia vertical: sobreposição de combinações extremas de skins, legibilidade do pseudo-rig Canvas a oito contatos por janela móvel de um segundo, custo de partículas em aparelhos modestos e contraste conjunto entre arte e UI final.
