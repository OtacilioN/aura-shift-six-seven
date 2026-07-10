# Flutter com Flame para o jogo mobile

Adotamos Flutter e Dart como estrutura multiplataforma e Flame para a cena 2D porque a maior parte do produto é UI, localização, acessibilidade, economia, anúncios e arquivos, enquanto a interação animada central cabe no escopo do Flame. Essa divisão preserva integração oficial do Google Mobile Ads e futura compilação iOS; aceitamos validar áudio em camadas e pseudo-rig em uma fatia vertical. Após o congelamento do MVP, Rive ficou restrito a eventual atualização posterior; Godot ou Defold permanecem apenas como alternativas se um requisito crítico da stack escolhida falhar.

## Considered Options

- **Godot:** melhor editor de animação e áudio, mas maior risco no plugin comunitário de AdMob.
- **Defold:** pacote menor, porém mais trabalho manual para UI e RTL.
- **Unity:** tecnicamente completo, mas desproporcional ao produto.
- **React Native + Skia:** viável, porém fragmenta engine, áudio e anúncios entre mais integrações.
