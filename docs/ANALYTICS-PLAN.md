# Aura Shift: Six Seven — Plano de Analytics

> Status: estratégia de coleta, convite, retenção e copy `analytics_*` aprovados; faixas e metas numéricas serão fechadas na instrumentação.

## Objetivo

Usar Firebase Analytics para compreender, na parcela que consentir, se o jogador entende o Ciclo Six-Seven, alcança rapidamente sua primeira progressão, retorna, usa a economia como esperado e encontra falhas nos anúncios recompensados. Analytics não é autoridade econômica, mecanismo antifraude nem requisito para jogar.

## Princípios

- coleta desativada por padrão;
- opt-in explícito e reversível para coletas futuras;
- consentimento de analytics independente de publicidade;
- ausência de vantagem ou punição por aceitar ou recusar;
- minimização de eventos e parâmetros;
- nenhuma identidade declarada ou `User ID`;
- nenhum Android Advertising ID;
- nenhuma propriedade personalizada de usuário no lançamento;
- nenhum Play Age Signals;
- nenhum conteúdo do save, Backup Manual ou texto livre;
- valores econômicos e temporais somente em faixas;
- revisão da integração real antes da publicação.

O Firebase pode processar identificadores técnicos da instalação e endereço IP depois do consentimento. Por isso, “sem dados pessoais deliberadamente enviados” não significa anonimato absoluto e não deve ser apresentado dessa forma ao jogador.

## Fluxo de consentimento

1. Uma nova instalação inicia com coleta desativada.
2. O jogador conclui seu primeiro Ciclo Six-Seven real e recebe a primeira Aura.
3. Antes de continuar o restante do Tutorial Contextual, o jogo apresenta o único convite automático de analytics.
4. A explicação informa finalidade, caráter opcional e acesso posterior em Configurações.
5. “Permitir” e “Agora não” possuem peso visual equivalente; dispensar equivale a “Agora não”.
6. Aceitar habilita apenas coletas futuras, sem reconstruir ou transmitir ações anteriores.
7. Recusar mantém a coleta desativada, não muda a experiência e não provoca novos convites automáticos.
8. Configurações permite aceitar posteriormente ou interromper coletas futuras sem prometer exclusão retroativa no fornecedor.

O consentimento pertence ao aparelho e não acompanha exportação ou importação do Backup Manual.

## Retenção e exportação

A propriedade GA4 usa a menor opção disponível no plano padrão:

- retenção de dados detalhados de usuários e eventos por dois meses;
- redefinição do prazo por nova atividade desativada;
- nenhum export para BigQuery ou outro armazenamento externo;
- nenhuma cópia própria de eventos brutos.

Relatórios agregados padrão podem continuar disponíveis segundo as regras do GA4. Essa disponibilidade não autoriza criar um arquivo paralelo nem contornar a retenção aprovada. A configuração deve ser conferida no console antes do teste fechado e novamente antes da produção.

## Perguntas de produto

1. O jogador conclui o Tutorial Contextual?
2. Quanto do funil chega à primeira Técnica Six-Seven, primeiro Item de Aura e primeira Transformação?
3. Em que faixa de progresso ocorre a primeira Ascensão de Aura?
4. Jogadores retornam e resgatam a Recompensa de Retorno?
5. As duas ofertas de Anúncio Recompensado são compreendidas e tecnicamente concluídas?
6. Existem patamares em que a progressão opt-in aparenta estagnar?
7. Quais idiomas apresentam funis anormalmente diferentes e merecem QA?

## Taxonomia inicial permitida

| Evento | Finalidade | Parâmetros permitidos |
|---|---|---|
| `tutorial_completed` | ativação | versão do tutorial |
| `first_technique_purchased` | primeira progressão ativa | faixa de tempo desde a primeira abertura |
| `first_aura_item_purchased` | primeira progressão passiva | faixa de tempo desde a primeira abertura |
| `first_transformation_unlocked` | alcance do primeiro marco visual | faixa de tempo e identificador estável da Transformação |
| `ascension_completed` | profundidade de progressão | número da Ascensão em faixa; faixa de Aura da Jornada |
| `return_reward_claimed` | uso do retorno | variante `base` ou `bonus`; faixa de ausência |
| `rewarded_ad_offer_shown` | exposição voluntária | placement `return_bonus` ou `aura_complement` |
| `rewarded_ad_result` | confiabilidade e conclusão | placement; resultado enumerado |
| `progression_checkpoint_reached` | localizar estagnação | identificador de checkpoint previamente aprovado |

Nenhum evento pode receber Aura exata, custo exato, timestamp de progressão, conteúdo serializado, nome de item localizado ou mensagem arbitrária. Novos eventos e parâmetros exigem atualização desta lista antes de entrar no produto.

## Eventos automáticos

O Firebase Analytics pode registrar eventos e propriedades técnicas automaticamente quando habilitado. Antes da publicação, o pipeline deve inventariar o que a versão efetivamente integrada coleta, desativar recursos desnecessários, conferir o painel de depuração e alinhar política de privacidade e Data safety. Se a integração não respeitar a minimização aprovada, ela deve permanecer desativada ou ser removida.

## Relação com Crashlytics

Analytics e diagnóstico possuem autorizações independentes. Enviar um Relatório de Diagnóstico nunca habilita analytics. Quando o Consentimento de Analytics já estiver ativo, o Crashlytics pode anexar breadcrumbs produzidos por eventos automáticos e pela taxonomia permitida. Essa possibilidade deve ser informada na oferta de diagnóstico e auditada no payload real.

## Interpretação

- dashboards devem identificar os dados como “amostra opt-in”;
- diferenças entre locales são sinais para investigação, não prova automática de causalidade;
- métricas não substituem testes em aparelhos nem revisão qualitativa;
- decisões econômicas exigem verificar se a mudança melhora diversão e clareza, não apenas frequência de sessão;
- nenhum evento individual deve determinar punição, preço ou bloqueio para um jogador.

## Validação antes do lançamento

1. Instalação limpa sem consentimento produz zero evento de analytics.
2. Primeiro Ciclo e primeira Aura ocorrem antes do convite e não são enviados retroativamente.
3. Recusa ou dispensa mantém zero evento, não reaparece automaticamente e preserva todas as funções.
4. Aceite habilita somente eventos futuros permitidos e o tutorial continua normalmente.
5. Configurações permite aceitar depois de uma recusa ou executar opt-out.
6. Opt-out interrompe novos eventos.
7. Exportar e importar save não transfere consentimento.
8. Payloads não contêm Aura exata, save, texto livre, `User ID`, Advertising ID ou Play Age Signals.
9. Eventos automáticos e dados técnicos são inventariados e declarados.
10. Cada um dos oito locales exibe o consentimento sem truncamento, coerção ou diferença semântica.
11. A propriedade mostra retenção de dois meses e redefinição por atividade desativada.
12. BigQuery e demais exportações aparecem desconectados.
13. Nenhum processo do projeto armazena eventos brutos em paralelo.

## Pendências

- definir texto e localização do consentimento;
- escolher faixas de tempo, progressão e ausência;
- decidir metas e alertas por métrica;
- verificar quais breadcrumbs do Analytics efetivamente aparecem no Crashlytics.

## Referências atuais

- [Firebase Analytics para Flutter](https://firebase.google.com/docs/analytics/flutter/get-started)
- [Eventos do Firebase Analytics](https://firebase.google.com/docs/analytics/flutter/events)
- [Controle de coleta no Android](https://firebase.google.com/docs/analytics/android/configure-data-collection)
- [Retenção de dados do GA4](https://support.google.com/analytics/answer/7667196?hl=pt-BR)
- [Privacidade e segurança no Firebase](https://firebase.google.com/support/privacy)
- [Definição opcional de User ID](https://firebase.google.com/docs/analytics/userid)

As configurações, políticas e declarações devem ser verificadas novamente com as versões realmente usadas antes da publicação.
