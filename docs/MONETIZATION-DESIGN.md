# Aura Shift: Six Seven — Design de Monetização

> Status: modelo e integração implementados; mensagem UMP europeia publicada,
> tratamento `TEEN` e anúncios não personalizados configurados. A veiculação
> real depende das revisões da conta e do app pelo AdMob.

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

A rede configurada é o Google AdMob, com inventário oficial de teste em builds
debug/profile. Releases usam unidades próprias por padrão; um bundle destinado
exclusivamente ao teste fechado pode usar o inventário oficial de teste com
`--dart-define=ADMOB_TEST_MODE=true`. Esse modo mantém o App ID próprio no
manifesto, para continuar exercitando a mensagem UMP do Aura Shift, e troca
somente os blocos recompensados pelos IDs de demonstração do Google. Ele não
gera receita e nunca deve ser usado em uma versão promovida à produção.

Nenhuma oferta publicitária é apresentada durante o Tutorial Contextual.

## Habilitação

Anúncios somente são habilitados depois que o tutorial termina e o jogador compra normalmente uma Técnica Six-Seven e um Item de Aura. Pular orientações não substitui essas condições. Antes da habilitação, retornos oferecem somente o resgate-base, e o Complemento de Aura não aparece. A primeira oferta explica benefício, natureza opcional e alternativa sem anúncio.

## Compras dentro do aplicativo

O lançamento não inclui compras dentro do aplicativo. Não serão vendidos Aura, multiplicadores, níveis, melhoramentos, Ascensões ou remoção de anúncios. Cosméticos ou um pacote de apoiador somente poderão ser reavaliados depois que retenção, economia e aceitação da monetização inicial forem validadas.

## Ponto 1 — Bônus de Retorno

Após uma ausência superior a dez minutos, o jogador escolhe entre:

- resgatar a Produção Offline proporcional, limitada a quatro horas; ou
- assistir a um Anúncio Recompensado para resgatar a mesma recompensa-base com 20% adicional.

O tempo excedente às quatro horas não entra no cálculo. A recompensa-base permanece resgatável sem anúncio.

A Recompensa de Retorno é persistida antes da tela e permanece sem crédito até a escolha. Resgatar a base a credita e encerra a oferta. Se o jogador optar pelo anúncio, base e 20% são creditados somente após a conclusão válida. Falha ou cancelamento preservam a pendência para nova tentativa ou resgate-base, sem perda nem duplicação.

Uma Ascensão somente pode ser confirmada depois que a Recompensa de Retorno pendente for resgatada, com ou sem bônus. Recusar encerra apenas o bônus e nunca reduz ou reverte a base resgatada.

## Ponto 2 — Upgrade por Anúncio

Um item desbloqueado que já esteja no nível 1 pode receber um Upgrade por Anúncio, sem gastar Aura Disponível. A recompensa é calculada pelo nível atual: níveis 1–5 recebem `+1`, níveis 6–100 recebem `+5` e nível 101 ou maior recebe `+25`.

Ao iniciar o anúncio, uma cotação idempotente registra item, nível e quantidade de níveis. A conclusão válida só é aplicada se esse item ainda estiver no nível cotado; ela não altera Aura Disponível, Aura Total ou Aura da Jornada. Falha, cancelamento ou mudança que invalide a cotação não concede nível nem consome a sequência.

Regras de frequência:

- cada sequência aceita no máximo três anúncios concluídos em itens distintos;
- um item já usado na sequência não pode receber novo Upgrade por Anúncio antes do cooldown;
- após o terceiro anúncio, a Loja fica em cooldown global de 15 minutos;
- Bônus de Retorno permanece fora dessa regra;
- cancelamento, indisponibilidade ou erro não consomem a sequência;
- a Loja informa quando o item precisa do primeiro nível, já foi usado na sequência ou quando falta tempo de cooldown.

O Upgrade por Anúncio não ignora Patamares de Aura, Pré-requisitos de Item ou outras condições de desbloqueio. Os modos normais `×1`, `×10` e `MÁX` continuam com seus custos próprios.

## Indisponibilidade de anúncios

Sem conexão ou inventário publicitário, as ofertas ficam inativas sem interromper o jogador. A recompensa-base do retorno e toda compra realizada integralmente com Aura permanecem disponíveis. Falhas não consomem cota, Aura ou qualquer outro progresso.

## Tratamento etário e consentimento

Todas as solicitações usam tratamento `TEEN`, desativando personalização e remarketing mesmo para adultos. A UMP avalia consentimento aplicável antes de qualquer pedido de anúncio. Se anúncios não puderem ser solicitados, as ofertas permanecem inativas e o jogo continua normalmente.

A Play Age Signals é isolada do sistema publicitário e não fornece dados para marketing, perfilamento ou analytics. O jogo não coleta data de nascimento e não oferece loot boxes.

## Pendências externas e operacionais

- aprovação da conta AdMob e vinculação do app à página pública da Play Store;
- revisão de prontidão do app e rastreamento do `app-ads.txt` pelo AdMob;
- validação visual em aparelho Android e monitoramento de falta de inventário;
- revalidação de políticas e territórios antes de cada publicação.
