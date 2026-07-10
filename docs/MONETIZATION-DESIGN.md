# Aura Shift: Six Seven — Design de Monetização

> Status: modelo, tratamento etário e consentimento aprovados; configuração territorial e revalidação das políticas vigentes permanecem pré-requisitos de lançamento.

## Princípios

- a partida nunca é interrompida por publicidade;
- todo anúncio entrega um benefício conhecido antes da exibição;
- assistir é uma escolha explícita, não condição para acessar a recompensa-base;
- falhas de disponibilidade ou reprodução não prejudicam o jogador;
- anúncios complementam a economia, mas não substituem a progressão normal.

## Formato de lançamento

Todos os anúncios são recompensados e voluntários. O jogo não utiliza:

- banners;
- intersticiais automáticos;
- anúncios ao abrir ou retomar o aplicativo;
- anúncios disparados por navegação, conclusão de ciclos ou compras.

A intenção inicial é utilizar a rede de anúncios do Google, sujeita à validação técnica, regulatória e comercial na fase apropriada.

Nenhuma oferta publicitária é apresentada durante o Tutorial Contextual.

## Habilitação

Anúncios somente são habilitados depois que o tutorial termina e o jogador compra normalmente uma Técnica Six-Seven e um Item de Aura. Pular orientações não substitui essas condições. Antes da habilitação, retornos creditam somente a base, e o Complemento de Aura não aparece. A primeira oferta explica benefício, natureza opcional e alternativa sem anúncio.

## Compras dentro do aplicativo

O lançamento não inclui compras dentro do aplicativo. Não serão vendidos Aura, multiplicadores, níveis, melhoramentos, Ascensões ou remoção de anúncios. Cosméticos ou um pacote de apoiador somente poderão ser reavaliados depois que retenção, economia e aceitação da monetização inicial forem validadas.

## Ponto 1 — Bônus de Retorno

Após uma ausência superior a oito horas, o jogador escolhe entre:

- resgatar a Produção Offline limitada a oito horas; ou
- assistir a um Anúncio Recompensado e acrescentar 20% à mesma recompensa-base.

O tempo excedente às oito horas não entra no cálculo. A recompensa-base permanece resgatável sem anúncio.

A Recompensa de Retorno é persistida antes da tela. Se o jogador optar pelo anúncio, a base é creditada e salva antes da solicitação; os 20% são concedidos separadamente após a conclusão válida. Falha ou cancelamento permite nova tentativa do bônus sem perder ou duplicar a base. Escolher apenas a base encerra a oferta daquela ausência.

Uma Ascensão somente pode ser confirmada depois que a base pendente tiver sido creditada e o jogador tiver aceitado ou recusado explicitamente a oportunidade de bônus. Recusar encerra apenas o bônus e nunca reduz ou reverte a base.

## Ponto 2 — Complemento de Aura

Uma compra desbloqueada pode oferecer o complemento quando o jogador possui pelo menos 70% e menos de 100% do preço. O anúncio cobre exatamente o valor faltante, limitado a 30%; a Aura Disponível do jogador é consumida normalmente.

A elegibilidade exata usa `7 × preço ≤ 10 × saldo < 10 × preço`. Ao iniciar o anúncio, uma cotação idempotente registra item, nível, preço, saldo comprometido e falta coberta. Uma conclusão válida consome o saldo cotado e quita diretamente a falta; produção posterior à cotação permanece no saldo. Falha, cancelamento ou mudança que invalide a compra não consome Aura nem cota.

O valor coberto liquida diretamente a compra. Ele não é creditado como Aura Disponível, Aura Total ou Aura da Jornada e, portanto, não acelera Transformações ou a recompensa de Ascensão.

Regras de frequência:

- no máximo três Complementos concluídos em qualquer janela móvel de 24 horas;
- sem cooldown entre os três usos;
- Bônus de Retorno fora dessa cota;
- cancelamento, indisponibilidade ou erro não consomem a cota;
- quantidade restante apresentada discretamente na Loja.

O complemento não ignora Patamares de Aura, Pré-requisitos de Item ou outras condições de desbloqueio.

O Complemento de Aura pode concluir somente uma aquisição inicial ou o próximo nível selecionado em `×1`. Ele nunca se aplica aos modos `×10` ou `MÁX`.

## Indisponibilidade de anúncios

Sem conexão ou inventário publicitário, as ofertas ficam inativas sem interromper o jogador. A recompensa-base do retorno e toda compra realizada integralmente com Aura permanecem disponíveis. Falhas não consomem cota, Aura ou qualquer outro progresso.

## Tratamento etário e consentimento

Todas as solicitações usam tratamento `TEEN`, desativando personalização e remarketing mesmo para adultos. A UMP avalia consentimento aplicável antes de qualquer pedido de anúncio. Se anúncios não puderem ser solicitados, as ofertas permanecem inativas e o jogo continua normalmente.

A Play Age Signals é isolada do sistema publicitário e não fornece dados para marketing, perfilamento ou analytics. O jogo não coleta data de nascimento e não oferece loot boxes.

## Questões pendentes

- fluxos de consentimento, privacidade e configuração etária por território;
- comportamento quando não houver inventário de anúncios;
- eventos analíticos e limites de otimização ética;
- validação atualizada das políticas da Google Play e da rede de anúncios antes da implementação.
