# Aura Shift: Six Seven — Segurança e Integridade

> Status: modelo de confiança inicial aprovado; controles concretos serão especificados na fase técnica e revistos antes do lançamento.

## Fronteira de confiança

O aparelho e o jogador controlam o ambiente em que a experiência principal e o salvamento são executados. Sem conta ou servidor autoritativo, dados locais não constituem prova confiável de identidade, propriedade ou conquista legítima.

## Objetivos

- impedir que corrupção acidental destrua um save válido;
- rejeitar arquivos estruturalmente inválidos ou incompatíveis;
- dificultar edição casual sem prejudicar portabilidade;
- limitar abuso de relógio e cotas de maneira proporcional;
- manter sessões offline legítimas disponíveis;
- não apresentar segurança local como inviolável.

## Fora do escopo inicial

- impedir que um cliente modificado adultere o próprio save;
- garantir que o jogador não modificou o próprio save ou cliente;
- banir jogadores por alterações locais;
- sustentar rankings competitivos a partir de dados locais;
- proteger uma economia com valor real sem autoridade remota.
- detectar ou punir autoclickers.

## Riscos principais

### Corrupção do estado

Falhas de gravação, arquivos incompletos ou versões incompatíveis podem impedir leitura ou causar perda. O planejamento exige validação antes da substituição, gravação segura e preservação do estado anterior quando uma operação falhar.

### Associação do save

O remoto é associado ao Player ID do perfil Gamer, nunca ao nome visível.
Trocar de conta não autoriza copiar silenciosamente a jornada anterior para a
nova conta. Essa associação ajuda a evitar mistura acidental, mas não prova que
o cliente não foi modificado.

### Manipulação do save ou aplicativo

Assinatura e ofuscação local elevam o esforço, mas segredos distribuídos no aplicativo podem ser extraídos e o cliente pode ser alterado. O objetivo é resistência casual, não autoridade criptográfica absoluta.

### Manipulação do relógio

Produção Offline e janelas de anúncios dependem de tempo. O limite de quatro horas reduz o impacto econômico; a Recompensa de Retorno só é apresentada após ausência superior a dez minutos. Quando o intervalo for incoerente, o jogo concede zero Produção Offline e não oferece Bônus de Retorno apenas naquela ausência, estabelece uma nova referência e mantém todo o restante funcionando. Não existem banimento, perda de save ou punição permanente; voltar o relógio também não renova a cota de Complementos de Aura. Tolerâncias para viagens e correções legítimas serão validadas antes do lançamento.

### Recompensas publicitárias

Em um cliente modificado, cotas ou recompensas locais podem ser falsificadas. Validação forte exigiria serviço remoto; a versão inicial aceita esse risco porque a progressão é individual e não possui valor real negociável.

## Controles planejados

- formato de save versionado;
- validação estrutural e limites plausíveis;
- verificação de integridade contra corrupção e edição casual;
- conflito ambíguo com comparação e confirmação;
- gravações recuperáveis que preservem o último estado válido;
- tratamento moderado de mudanças de relógio;
- separação futura entre estado local e qualquer dado competitivo autoritativo.
- descarte técnico do nono toque em qualquer janela móvel de um segundo, sem punição ou alegação de fraude.

## Gatilhos para reavaliar a arquitetura

Um backend autoritativo deve ser reavaliado antes de introduzir:

- rankings ou disputas com expectativa de justiça;
- troca de itens ou progresso entre jogadores;
- compras de moeda, poder ou progresso;
- recompensas externas ou prêmios;
- contas e sincronização automática entre plataformas;
- eventos comunitários cujo resultado dependa de produção agregada confiável.
