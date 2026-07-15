# Redesign visual dos 18 Itens de Aura

Rodada concluída em 11 de julho de 2026 com um agente responsável por cada
item. Cada frente trabalhou exclusivamente no item atribuído; a integração e a
revisão cruzada foram feitas depois, sobre o conjunto completo.

| Item | Leitura principal | Colocação final | Efeito próprio |
| --- | --- | --- | --- |
| `ITEM-A-01` | botão físico de quatro furos | peito esquerdo | pulso das costuras |
| `ITEM-A-02` | recibo térmico luminoso | bolso direito | varredura do recibo |
| `ITEM-A-03` | óculos escuros angulares | sobre os olhos | reflexos diagonais e glow inferior |
| `ITEM-A-04` | jaqueta aberta com zíper | sobre o torso, sob as mãos | faísca no zíper |
| `ITEM-A-05` | coroa de três pontas remendada | sobre a cabeça | sequência dos patches |
| `ITEM-B-01` | despertador clássico/digital `6:70` | chão direito, atrás do Mascote | toque e vibração dos sinos |
| `ITEM-B-02` | par completo de tênis | sobre os pés | afterimages de lag |
| `ITEM-B-03` | anel físico com gema | lateral alta, acompanhando o personagem | ponto de resto orbital |
| `ITEM-B-04` | dois botões, braceletes e soquetes | articulado nas duas mãos | cabo seguro fora do rosto |
| `ITEM-B-05` | extrato com barras e curva | moldura lateral | tick do gráfico |
| `ITEM-C-01` | crachá de certificação com glitch | peito esquerdo | separação de canais |
| `ITEM-C-02` | decimal segmentado em fuga | bolso direito | deriva do decimal |
| `ITEM-C-03` | capa com gola e duas caudas | atrás do corpo | fluxo dos blocos de cache |
| `ITEM-C-04` | roteador físico com antenas | chão direito, atrás do Mascote | procura de sinal |
| `ITEM-C-05` | moldura quebrada com `404` vetorial | fundo da cena | falha do horizonte |
| `ITEM-CONV-01` | três participantes e fitas entrelaçadas | aura traseira | sincronização da reunião |
| `ITEM-CONV-02` | três fluxos exaustos em um núcleo | aura traseira | convergência espectral |
| `ITEM-CONV-03` | parafuso grande com três conexões | aura traseira direita | torque canônico |

## Integração

- As 18 aparências possuem 18 perfis e 18 efeitos distintos em
  `lib/game/item_visual_effects.dart`.
- `FACE_WEAR`, `BODY_WEAR`, `HEAD_WEAR`, `CHEST`, `HIP` e `ANKLES` acompanham
  bob, lean e rotação e são compostos sob as mãos.
- `HAND_PROP` e `HANDS_WEAR` ficam sobre as mãos; o item B-04 usa centros e
  pulsos atuais do rig, sem reaproveitar a pose neutra na cena.
- `GROUND_PROP`, `SCENE_FRAME` e `AURA_BACK` permanecem world-space e atrás do
  Mascote.
- Cada relatório individual neste diretório mantém conceito, posição, leitura
  em 48 px, efeito e critérios de aceite do respectivo item.

## Evidência automatizada

- geração: `222` entradas `art-v1`, `1.614.304` bytes WebP de runtime;
- validação determinística: `PASS`, `18` gates;
- promoção: `219` assets de arte e `44` assets de áudio;
- formato Dart: `23` arquivos, zero mudanças pendentes;
- `dart analyze` e `flutter analyze --no-pub`: zero issues.

## Cobertura adicionada, com execução pendente no sandbox

- testes de contrato para 18 perfis únicos, slots world/wear, ordem sob/sobre
  mãos e rota B-04 fora do corredor da cabeça;
- smoke tests das 18 aparências tanto animadas quanto em movimento reduzido;
  goldens são opt-in por `ITEM_SCENE_GOLDENS=true`.

O runner Flutter e o rebuild do APK ainda dependem, neste ambiente, de socket
local e da distribuição Gradle. A restrição do sandbox impediu executar esses
dois gates nesta rodada; ela não foi convertida em aprovação simulada.
