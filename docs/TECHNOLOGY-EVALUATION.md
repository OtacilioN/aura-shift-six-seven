# Aura Shift: Six Seven — Avaliação de Tecnologia

> Snapshot da decisão em 10 de julho de 2026.

## Critérios

- velocidade para uma dupla indie;
- cena 2D modular;
- interface rica e retrato;
- oito idiomas e árabe RTL;
- acessibilidade;
- AdMob recompensado;
- save local e Backup Manual;
- Android API 36 e páginas de 16 KB;
- futura publicação iOS;
- áudio em camadas;
- licença comercial e manutenção.

## Resultado

| Opção | Pontos fortes | Riscos decisivos | Resultado |
| --- | --- | --- | --- |
| Flutter + Flame | UI, RTL, acessibilidade, AdMob oficial, Android/iOS e cena 2D suficiente | rig e áudio avançado exigem validação | Escolhida |
| Godot | editor 2D, rig, partículas e áudio excelentes | AdMob depende de plugin comunitário | Alternativa se a animação dominar o produto |
| Defold | runtime pequeno, build rápido e boa portabilidade | UI e RTL mais manuais | Plano B focado em tamanho |
| Unity | ferramentas maduras e integrações robustas | complexidade e runtime desproporcionais | Não escolhida |
| React Native + Skia | UI conhecida e canvas poderoso | stack fragmentada e AdMob por wrapper não oficial | Não escolhida |

## Por que Flutter + Flame

O Aura Shift: Six Seven possui uma cena animada central, mas grande parte do produto é composta por Loja, árvore de progressão, Coleção, Ajustes, localização, números, anúncios, arquivos e acessibilidade. Flutter é mais forte nessa superfície dominante, enquanto Flame cobre o loop 2D necessário sem impor um motor maior.

A integração Flutter de anúncios recompensados é documentada diretamente pelo Google em Android e iOS. Isso reduz risco na única fonte de monetização definida.

## Rive

Rive não integra o MVP Android v1.0. O Mascote e suas 18 Aparências de Item precisam funcionar com o pseudo-rig Flame. Rive somente pode voltar a ser avaliado depois da primeira publicação, por nova decisão de escopo.

## Condições de reavaliação

A escolha poderá ser reaberta se a prova técnica demonstrar que:

- o pseudo-rig Flame não sustenta os 18 Itens e cinco Transformações;
- o áudio em camadas apresenta drift inaceitável sem alternativa simples;
- um requisito crítico de Android ou iOS não é atendido;
- uma dependência essencial viola licença, 16 KB ou estabilidade;
- outra opção reduz comprovadamente prazo e risco sem sacrificar AdMob ou RTL.
