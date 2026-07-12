# Aura Shift: Six Seven — Manifesto de Assets Visuais

> Contrato `asset-manifest-v1`. Este documento define o inventário e a entrega.
> O candidato técnico imutável está em `assets/manifests/art-manifest-v1.json`.
> A decisão humana de 10 de julho de 2026 gerou
> `assets/manifests/art-approved-manifest-v1.json`, consumido pelo runtime; a
> validação em aparelho permanece separada.

## Estado e escopo

O manifesto cobre a cena Flame, o pseudo-rig do Mascote, 18 Aparências de Item, cinco Transformações, três identidades de Ramo, Aura, fundos, Selos 67 e emblemas de eventos do MVP Android v1.0. Componentes de UI, fontes, ícones funcionais e materiais da Google Play pertencem a inventários próprios.

Os IDs são estáveis e independem do nome exibido ao jogador. Renomear conteúdo cultural não renomeia arquivos integrados.

## Convenções

- nomes em `snake_case`, ASCII e minúsculos;
- prefixos: `chr_`, `skin_`, `form_`, `branch_`, `vfx_`, `bg_`, `seal_`, `evt_`;
- lados sempre `_l` e `_r`, do ponto de vista do Mascote;
- variantes: `_base`, `_accent`, `_glow`, `_reduced`, `_thumb`;
- nenhuma dimensão, pivô ou ordem de camada é inferida do nome;
- `manifestId` permanece estável; revisão visual incrementa `revision` no metadado.

Estrutura prevista:

```text
assets/
  art/
    character/
    skins/
    forms/
    branches/
    backgrounds/
    vfx/
    seals/
    events/
  atlases/
  manifests/art-manifest-v1.json
sources/art/
provenance/art/
```

`sources/` e `provenance/` pertencem ao pacote de produção e não precisam entrar no aplicativo.

## Sistema de coordenadas

- composição de referência: `1080 × 1920 px`, retrato;
- palco lógico do Mascote: `1024 × 1024 px`, origem no canto superior esquerdo;
- ponto lógico do chão: `(512, 900)`;
- escala no runtime: uniforme; nunca esticar eixos separadamente;
- pivôs de runtime: normalizados em `[0,1]` sobre o arquivo recortado e registrados no JSON;
- encaixes: coordenadas normalizadas no palco lógico, transformadas pelo componente-pai;
- pixel snapping: desligado para rig e VFX, permitido em miniaturas estáticas;
- sangria mínima para filtro: `8 px` em sprites 1× e `16 px` em fontes master 2×.

### Pivôs canônicos

| Componente | Pivô normalizado | Encaixe no palco | Observação |
| --- | --- | --- | --- |
| corpo | `(0.50, 0.86)` | `(512, 900)` | raiz do rig |
| braço esquerdo | `(0.82, 0.18)` | ombro L `(365, 438)` | fica atrás da mão |
| braço direito | `(0.18, 0.18)` | ombro R `(659, 438)` | fica atrás da mão |
| mão esquerda | `(0.72, 0.72)` | punho L do braço | desenho próprio |
| mão direita | `(0.28, 0.72)` | punho R do braço | desenho próprio |
| rosto | `(0.50, 0.50)` | face `(512, 340)` | olhos e boca separados |
| slot `CHEST` | `(0.50, 0.50)` | `(512, 520)` | não herda rotação das mãos |
| slot `SHOULDER` | `(0.50, 0.50)` | ombro declarado L/R | subslot declarado no metadado |
| slot `FACE_SIDE` | `(0.50, 0.50)` | face lateral `(512, 340)` | offset L/R declarado |
| slot `FACE_WEAR` | `(0.50, 0.50)` | olhos `FACE_EYES` | acompanha bob, lean e rotação; fica sob as mãos |
| slot `BODY_WEAR` | `(0.50, 0.72)` | corpo `(512, 620)` | roupa frontal; fica sobre o corpo e sob as mãos |
| slot `HEAD_BACK` | `(0.50, 0.82)` | `(512, 228)` | sempre atrás do rosto/mãos |
| slot `HEAD_WEAR` | `(0.50, 0.82)` | topo frontal `(512, 228)` | acompanha a cabeça e fica sob as mãos |
| slot `HIP` | `(0.50, 0.50)` | `(512, 675)` | offset L/R declarado |
| slot `ANKLES` | `(0.50, 0.76)` | `(512, 825)` | componentes L/R próprios |
| slot `HAND_PROP` | `(0.50, 0.50)` | território da mão declarada | composto sobre as mãos |
| slot `HANDS_WEAR` | `(0.50, 0.56)` | centros/pulsos atuais do par | arte neutra na Coleção; runtime articulado sobre as mãos |
| slot `BODY_BACK` | `(0.50, 0.72)` | `(512, 620)` | atrás do corpo |
| slot `GROUND_BACK` | `(0.50, 0.50)` | `(512, 865)` | atrás dos pés |
| slot `GROUND_PROP` | `(0.77, 0.88)` | chão direito `(790, 800)` | world-space e atrás do Mascote |
| slot `SCENE_FRAME` | `(0.50, 0.50)` | `(512, 540)` | atrás do palco e fora da UI |
| slot `AURA_BACK` | `(0.50, 0.58)` | `(512, 560)` | Convergências; atrás do rig |

O artista pode recortar transparência, desde que o pivô exportado preserve estes encaixes. Alterar um pivô canônico exige revisão de todas as skins daquele slot.

## Ordem de camadas

Do fundo para a frente:

1. `BG-GRADE`;
2. `BG-FAR`;
3. `BG-MID`;
4. `SLOT-SCENE-FRAME`;
5. `VFX-AURA-BACK` e `SLOT-AURA-BACK`;
6. `SLOT-GROUND-BACK` e `SLOT-GROUND-PROP-BACK`;
7. `SLOT-BODY-BACK`, `SLOT-HEAD-BACK` e `SLOT-SHOULDER-BACK`;
8. `CHR-ARM-BACK`;
9. `CHR-BODY` e `CHR-FACE`;
10. `SLOT-BODY-WEAR`, `SLOT-CHEST`, `SLOT-SHOULDER-FRONT`, `SLOT-HIP`, `SLOT-ANKLES`, `SLOT-FACE-SIDE`, `SLOT-FACE-WEAR` e `SLOT-HEAD-WEAR`;
11. `CHR-HANDS`;
12. `SLOT-HAND-PROP-FRONT` e `SLOT-HANDS-WEAR-FRONT`;
13. `VFX-AURA-FRONT`;
14. feedback de contato;
15. overlays de evento sem texto;
16. UI Flutter.

Nenhum asset de arte pode ultrapassar a UI Flutter por z-order.

## Formatos e exportação

| Categoria | Fonte editável | Runtime | Cor | Regras |
| --- | --- | --- | --- | --- |
| rig e skins | SVG, PSD ou KRA em camadas | WebP lossless; PNG se houver artefato | sRGB, alpha reto | 2× master; atlas após validação |
| fundos | PSD/KRA/SVG | WebP lossy qualidade 82–88 | sRGB | sem texto; separar planos |
| VFX estruturado | SVG/PNG + metadado | WebP lossless/PNG | sRGB | emissores no runtime, não vídeo |
| thumbnails e Selos | SVG | WebP lossless | sRGB | legíveis em 48 px |
| concept sheets | PDF/PNG | fora do app | sRGB | inclui escala de cinza e reduced |

Não usar GIF, vídeo, Lottie, Rive, spritesheet com frame rate embutido ou SVG no runtime antes da prova técnica. Atlases usam padding de `4 px`, extrusão de borda de `2 px`, máximo `2048 × 2048` por página e metadado JSON versionado. Se o suporte de WebP lossless/alpha do pipeline escolhido falhar, PNG é o fallback sem mudar IDs.

### Dimensões de produção

| Família | Master | Runtime-alvo 1× | Miniatura |
| --- | ---: | ---: | ---: |
| corpo | `1024 × 1024` | até `512 × 512` | `256 × 256` composta |
| mão individual | `512 × 512` | até `256 × 256` | não aplicável |
| rosto/expressão | `256 × 256` | até `128 × 128` | não aplicável |
| skin por slot | `1024 × 1024` no palco | recorte até `512 × 512` | `256 × 256` composta |
| camada de Transformação | `2160 × 2160` | até `1080 × 1080` | `256 × 256` |
| plano de fundo | `2160 × 3840` | `1080 × 1920` | `270 × 480` |
| partícula | `128 × 128` | `32–64 px` | não aplicável |
| Selo 67 | SVG `512 × 512` | `128 × 128` | `48 × 48` |
| emblema de evento | SVG `512 × 512` | `192 × 192` | `64 × 64` |

O runtime pode carregar resolução menor por perfil de memória. Masters nunca são redimensionados destrutivamente.

## Inventário do Mascote

| IDs | Quantidade | Camadas/estados | Alternativa reduzida |
| --- | ---: | --- | --- |
| `chr_body_base` | 1 | massa, contorno, sombra | igual; sem squash |
| `chr_arm_l`, `chr_arm_r` | 2 | massa e contorno | poses Six/Seven por rotação curta |
| `chr_hand_l`, `chr_hand_r` | 2 | massa, contorno, brilho | troca estática ou crossfade de 100 ms |
| `chr_eye_*` | 5 pares | neutro, foco, satisfação, surpresa, celebração | troca por crossfade |
| `chr_mouth_*` | 5 | mesmos estados | troca por crossfade |
| `chr_shadow` | 1 | elipse suave | opacidade fixa, sem escala |
| `chr_silhouette_test` | 1 | arte QA, fora do runtime | não aplicável |

Os braços e mãos são arquivos independentes. Nenhum item pode exigir novo corpo ou nova animação do Ciclo.

## Inventário das Aparências

Cada linha representa uma aparência composta por até `base`, `accent` e `glow`, mais thumbnail. O conceito visual final vem do catálogo cultural, mas o slot e o território abaixo são contratos de produção.

| ID de conteúdo | ID de asset | Slot | Território/complexidade | Reduced |
| --- | --- | --- | --- | --- |
| `ITEM-A-01` | `skin_item_a_01` | `CHEST` | botão físico de quatro furos costurado no peito | halo e costuras estáticos |
| `ITEM-A-02` | `skin_item_a_02` | `HIP` | recibo térmico luminoso no bolso direito | picote e carimbo abstratos estáticos |
| `ITEM-A-03` | `skin_item_a_03` | `FACE_WEAR` | óculos de QA frontais com duas lentes, ponte e hastes | reflexos fixos sem varredura |
| `ITEM-A-04` | `skin_item_a_04` | `BODY_WEAR` | jaqueta aberta com lapelas, bolsos e zíper bipartido | sem pulso no zíper |
| `ITEM-A-05` | `skin_item_a_05` | `HEAD_WEAR` | coroa de hotfix vestível com três pontas e placas remendadas | placas e rebites estáticos |
| `ITEM-B-01` | `skin_item_b_01` | `GROUND_PROP` | despertador clássico/digital 6:70 no chão à direita | sinos e visor estáticos |
| `ITEM-B-02` | `skin_item_b_02` | `ANKLES` | par completo de tênis com rastro atrasado | sem alternância dos ecos |
| `ITEM-B-03` | `skin_item_b_03` | `HAND_PROP` | anel físico lateral com gema e ponto orbital | ponto junto da gema |
| `ITEM-B-04` | `skin_item_b_04` | `HANDS_WEAR` | botões táteis e braceletes articulados nas duas mãos | ligação sem pulso viajante |
| `ITEM-B-05` | `skin_item_b_05` | `SCENE_FRAME` | extrato astral em gráfico abstrato de barras | barras e curva estáticas |
| `ITEM-C-01` | `skin_item_c_01` | `CHEST` | crachá de glitch homologado no peito | recortes estáticos |
| `ITEM-C-02` | `skin_item_c_02` | `HIP` | decimal e dígitos segmentados fugindo para o bolso | pose de meia-fuga estática |
| `ITEM-C-03` | `skin_item_c_03` | `BODY_BACK` | capa vestida com gola, duas caudas e costuras digitais | caudas e blocos estáticos |
| `ITEM-C-04` | `skin_item_c_04` | `GROUND_PROP` | roteador físico com duas antenas no chão à direita | LEDs e ondas estáticos |
| `ITEM-C-05` | `skin_item_c_05` | `SCENE_FRAME` | moldura quebrada, `404` vetorial e horizonte ausente | profundidade achatada |
| `ITEM-CONV-01` | `skin_item_conv_01` | `AURA_BACK` | três participantes e fitas entrelaçadas num nó | sem pulsos em trânsito |
| `ITEM-CONV-02` | `skin_item_conv_02` | `AURA_BACK` | três fluxos exaustos estabilizando em um núcleo | fluxos e núcleo estáticos |
| `ITEM-CONV-03` | `skin_item_conv_03` | `AURA_BACK` | parafuso lateral com rosca e três linhas presas à cabeça | camadas achatadas |

As três camadas visuais cobrem a variação de Marcos de Nível: `base` no desbloqueio, `accent` a partir do nível 10 e `glow` a partir do nível 25. O manifesto registra um `milestoneProfile` por ID com os tratamentos canônicos de `CONTENT-CATALOG.md` nos níveis `10`, `25`, `50`, `100` e múltiplos posteriores; `50/100+` reutilizam geometria, material e overlays paramétricos, sem sprites exclusivos por nível. Essa apresentação não altera o Efeito de Item e pode ser escondida.

## Inventário das Transformações e fundos

| Transformação | Assets obrigatórios | Fundo | Reduced |
| --- | --- | --- | --- |
| base | não aplicável | `bg_base_far/mid/near/grade` | `bg_base_reduced` |
| `FORM-01` | `form_01_outline`, `form_01_glow`, `form_01_thumb` | reutiliza `bg_base_far/mid/near` + `bg_form_01_grade` | contorno estático + `bg_form_01_reduced` |
| `FORM-02` | `form_02_afterimage`, `form_02_trail`, `form_02_thumb` | `bg_form_02_far/mid/near/grade` | contorno duplo + `bg_*_reduced` |
| `FORM-03` | `form_03_weather_symbols`, `form_03_ambient`, `form_03_thumb` | `bg_form_03_far/mid/near/grade` | sem chuva + `bg_*_reduced` |
| `FORM-04` | `form_04_skyline`, `form_04_pulse`, `form_04_thumb` | `bg_form_04_far/mid/near/grade` | barras estáticas + `bg_*_reduced` |
| `FORM-05` | `form_05_halo`, `form_05_ground_link`, `form_05_horizon_link`, `form_05_thumb` | `bg_form_05_far/mid/near/grade` | halo/elos estáticos + `bg_*_reduced` |

O inventário normal possui quatro planos-base, um grade próprio de `FORM-01` e quatro planos para cada uma de `FORM-02..05`, totalizando 21 planos declarados sem duplicar o palco-base. As seis variantes reduzidas (`base` + cinco Formas) achatam `far/mid/near` em uma composição estática. Grades podem ser shader/tint quando a prova técnica confirmar equivalência; caso contrário, permanecem assets explícitos com o mesmo ID.

## Ramos, Aura, Selos e eventos

| Família | IDs | Qtde. | Uso |
| --- | --- | ---: | --- |
| Ramo A — Poise | `branch_a_node`, `branch_a_edge`, `branch_a_backplate`, `branch_a_thumb` | 4 | Árvore, Coleção, concept |
| Ramo B — Motion | `branch_b_node`, `branch_b_edge`, `branch_b_backplate`, `branch_b_thumb` | 4 | Árvore, Coleção, concept |
| Ramo C — Signal | `branch_c_node`, `branch_c_edge`, `branch_c_backplate`, `branch_c_thumb` | 4 | Árvore, Coleção, concept |
| Convergência | `branch_conv_node`, `branch_conv_edge`, `branch_conv_backplate` | 3 | objetivos opcionais |
| Aura | `vfx_ribbon`, `vfx_spark`, `vfx_orb`, `vfx_contact`, `vfx_trail` | 5 | emissores e rastros |
| Selo | `seal_67_core`, `seal_67_ring`, `seal_67_cardinal`, `seal_67_thumb_mask` | 4 | composição procedural por magnitude |
| Eventos | `evt_purchase`, `evt_milestone`, `evt_transform`, `evt_achievement`, `evt_ascension`, `evt_67` | 6 | overlays sem texto |

Selos por magnitude são compostos no runtime com `core`, até quatro `ring` e marcas `cardinal`; a magnitude textual vem da UI. Não criar arquivo único para cada `67 × 1000ⁿ`.

## Metadado obrigatório

Cada entrada de `art-manifest-v1.json` contém:

```json
{
  "manifestId": "skin_item_a_01",
  "revision": 1,
  "runtimePath": "art/skins/skin_item_a_01.webp",
  "sourcePath": "sources/art/skins/skin_item_a_01.kra",
  "sizePx": [512, 512],
  "pivot": [0.5, 0.5],
  "slot": "CHEST",
  "zLayer": "SLOT-CHEST",
  "milestoneProfile": "item_a_01_v1",
  "reducedId": "skin_item_a_01_reduced",
  "licenseRecord": "provenance/art/skin_item_a_01.md",
  "sha256": "TO_BE_FILLED_AT_EXPORT"
}
```

`TO_BE_FILLED_AT_EXPORT` é aceitável somente no planejamento. Nenhum arquivo entra no build candidato com hash, fonte, licença ou revisão ausentes.

## Orçamentos de runtime

- máximo de `2048 × 2048` por página de atlas;
- máximo de duas páginas residentes para rig/skins e uma para VFX na cena Jogar;
- fundos carregados apenas para a Transformação ativa; anterior pode permanecer durante crossfade e deve ser liberado depois;
- máximo normal de 80 partículas simultâneas e reduzido de 12, conforme a bíblia de motion;
- nenhum asset individual de runtime acima de `1 MiB` comprimido sem exceção documentada;
- alvo inicial do pacote de arte da cena: até `24 MiB` comprimidos no AAB; validar por ABI/densidade no build real;
- 60 fps como alvo e 30 fps como piso degradado no aparelho modesto da matriz.

Os números são gates de produção, não garantia de memória decodificada. A fatia vertical mede RAM, upload de textura e jank antes da produção integral.

## Checklist de aceite por asset

- ID, revisão, origem, licença e hash preenchidos;
- fonte editável com camadas nomeadas;
- runtime e thumbnail exportados em sRGB;
- pivô e encaixe testados em Six, Seven e celebração 67;
- composição testada com slots conflitantes e todas as Transformações;
- leitura em 10%, escala de cinza e simulação cromática;
- ausência de texto essencial, marca ou semelhança não autorizada;
- variante reduzida existente ou justificativa “estático por natureza”;
- sem halo de alpha, seam de atlas ou recorte na safe area;
- orçamento de arquivo e perfil de desempenho aprovados.

## Gate de estabilidade

O inventário é estável quando todos os IDs desta versão existem no manifesto de produção, mesmo que um asset ainda esteja em estado `concept`, `production`, `review` ou `approved`. O build candidato exige todos em `approved`. Acrescentar conteúdo ao inventário antes do lançamento requer Substituição de Escopo; corrigir ou revisar um asset conserva o ID e incrementa `revision`.
