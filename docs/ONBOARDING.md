# Aura Shift: Six Seven — Onboarding e Primeira Sessão

> Status: fluxo, estados, recuperação, copy-fonte e critérios de UX aprovados em `ux-flow-v1`; integração visual segue `motion-v1` e os catálogos localizados.

## Princípios

- começar jogando, não lendo;
- ensinar somente o conceito necessário naquele momento;
- usar economia e recompensas reais;
- nunca bloquear a Área de Aura por uma compra opcional;
- permitir dispensar e rever orientações;
- não apresentar anúncios antes de demonstrar o valor normal do jogo.

## Fluxo

### 1. Entrada

O locale é detectado, com seletor acessível antes do tutorial. A área Jogar aparece diretamente, com Mascote, Aura e Área de Aura.

Se o catálogo do locale falhar, a abertura usa `en-US` completo e nunca mistura idiomas na mesma tela. Trocar idioma reconstrói a semântica, preserva a Fase vigente e devolve foco ao seletor.

### 2. Primeiro Ciclo Six-Seven

Uma instrução curta solicita dois toques. A Fase Six responde sem Aura; a Fase Seven conclui o ciclo e concede a primeira unidade real. Não existe demonstração simulada.

### 3. Consentimento de Analytics

Depois de a primeira Aura ser creditada e exibida, o jogo apresenta o único convite automático de Consentimento de Analytics. “Permitir” e “Agora não” possuem peso visual equivalente; dispensar equivale a recusar. Nenhuma ação anterior é enviada retroativamente.

Aceitar habilita somente a Telemetria de Produto futura. Recusar não altera o tutorial e não provoca outro convite automático; a escolha pode ser revista voluntariamente em Ajustes.

Fechar equivale a “Agora não”. Ao fechar, aceitar ou recusar, foco retorna à Área de Aura e o estado econômico/tutorial permanece exatamente o anterior à folha. A coleta nunca recebe o primeiro Ciclo retroativamente.

### 4. Primeira Técnica

O jogador continua livremente. Quando puder pagar a primeira Técnica Six-Seven pela progressão normal, a Loja recebe destaque discreto. Entrar e comprar é orientado, mas não obrigatório para continuar jogando.

### 5. Primeiro Item de Aura

Depois da primeira Técnica, a orientação apresenta simultaneamente os três Itens-raiz economicamente equivalentes. O jogador escolhe iniciar o Ramo A, B ou C de acordo com tema e aparência; nenhum deles possui vantagem numérica inicial. A compra continua opcional, embora o balanceamento a torne normalmente acessível em cerca de dois minutos.

### 6. Produção Passiva

Ao adquirir o primeiro Item, uma explicação curta apresenta a taxa passiva e esclarece que ela funciona sem toques. Esse evento conclui o Tutorial Contextual.

### 7. Primeira Transformação

A Transformação surge pela Aura Total aproximadamente aos cinco minutos. Ela não depende de uma etapa artificial do tutorial.

## Liberdade e recuperação

- destaques não bloqueiam toque, Loja ou navegação;
- o jogador pode dispensar cada orientação;
- Ajustes permite rever o tutorial;
- orientações ignoradas reaparecem apenas em contexto apropriado, sem insistência constante;
- o estado do tutorial é salvo localmente e incluído no Backup Manual;
- a preferência de Analytics pertence ao aparelho e não é incluída no Backup Manual.

O estado persistido distingue `não iniciado`, `primeiro toque/Fase Six`, `primeira Aura`, `consentimento decidido`, `Técnica orientada`, `Item orientado` e `concluído`. Reabrir retoma o primeiro estado ainda aplicável, sem repetir crédito, compra ou consentimento. Orientação que deixou de ser aplicável por progresso posterior é marcada como concluída, não exibida fora de contexto.

“Rever tutorial” usa coach marks e exemplos sobre o estado atual. Não redefine a fase, não concede Aura, não recompra Técnica/Item, não reabre consentimentos e não altera a habilitação de anúncios.

## Estados de falha e cancelamento

| Momento | Falha/cancelamento | Comportamento |
| --- | --- | --- |
| carregamento inicial | asset visual ausente | usa alternativa estática; Área de Aura continua operável |
| Fase Six | app vai ao fundo | salva a fase; próxima ativação conclui Seven |
| crédito da primeira Aura | persistência falha | não abre consentimento; recupera transação sem duplicar |
| Consentimento de Analytics | fechar/voltar | equivale a “Agora não”; tutorial retoma |
| destaque da Loja | jogador ignora ou troca de área | destaque não bloqueia; reaparece só em contexto pagável |
| escolha do Item-raiz | sai da Loja | nenhuma pré-seleção; os três continuam equivalentes |
| explicação passiva | dispensar | tutorial conclui; explicação pode ser revista em Ajustes |

## Critérios mensuráveis

- o primeiro controle de jogo recebe foco sem passar por slideshow;
- os dois toques reais permanecem possíveis com uma mão e com TalkBack;
- nenhum coach mark cobre mais da metade útil da Área de Aura ou bloqueia a barra inferior;
- ações e textos continuam acessíveis a `320dp`, escala `200%`, pseudo-localização `+35%`, japonês e árabe RTL;
- Six e Seven são distinguíveis com som e vibração desligados e em Movimento Reduzido;
- cada interrupção retorna foco, fase e estado econômico ao ponto correto;
- rever, dispensar, fechar e reabrir não duplicam evento econômico nem antecipam anúncios.

## Publicidade

Nenhum Anúncio Recompensado é oferecido enquanto o tutorial estiver ativo. A habilitação exige conclusão do fluxo e compras normais de ao menos uma Técnica Six-Seven e um Item de Aura. Dispensar orientações não substitui as compras. Retornos anteriores concedem somente a recompensa-base.

## Copy canônica

IDs, texto-fonte `en-US`, variantes curtas, placeholders e contexto estão congelados em `COPY-DECK.md`; os oito catálogos ficam em `localization/`. O onboarding usa `tutorial_*`, `analytics_*` e as ações comuns, sempre curto, literal e compreensível sem conhecer previamente o meme. Alterar significado ou placeholder reabre revisão e paridade dos oito locales.
