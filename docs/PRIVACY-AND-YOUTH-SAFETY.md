# Aura Shift: Six Seven — Privacidade e Proteção Etária

> Status: estratégia inicial aprovada em 10 de julho de 2026; políticas e leis devem ser verificadas novamente antes do teste fechado e da produção.

## Público e postura

O jogo atende prioritariamente pessoas de 13 a 24 anos e não é direcionado a menores de 13. Como parte do público possui entre 13 e 17 anos, o lançamento adota o mesmo tratamento publicitário restritivo para todos, evitando perfil etário próprio e reduzindo variações de comportamento difíceis de auditar.

## Publicidade

Todas as solicitações do Google Mobile Ads usam tratamento `TEEN`:

- anúncios personalizados desativados;
- remarketing desativado;
- proteções de conteúdo publicitário para adolescentes;
- nenhuma tentativa de inferir idade por comportamento;
- nenhuma coleta direta de data de nascimento.

Essa decisão pode reduzir receita publicitária, mas simplifica privacidade e consistência. Anúncios continuam voluntários e recompensados.

## Consentimento

A UMP, ou outra CMP certificada e aprovada, deve avaliar a possibilidade de solicitar anúncios antes do primeiro pedido. O jogo nunca bloqueia sua experiência quando:

- não há consentimento;
- a CMP não permite a solicitação;
- não existe conexão ou inventário;
- ocorre erro de SDK.

As alternativas sem anúncio permanecem disponíveis.

## Play Age Signals

Para cumprir requisitos aplicáveis no Brasil, o jogo planeja integrar a Play Age Signals API na versão mínima recomendada pela documentação vigente. Seus sinais:

- somente podem apoiar experiências adequadas à idade;
- não podem orientar anúncios, marketing, perfilamento ou analytics;
- não entram no save, Backup Manual ou logs de produto;
- não são usados para criar uma identidade do jogador.

O conteúdo-base é apropriado ao público declarado e não depende de personalização etária para funcionar.

## Analytics

O lançamento pode usar Firebase Analytics exclusivamente como Telemetria de Produto opt-in. Em cada nova instalação, a coleta começa desativada e somente pode ser habilitada depois de uma escolha explícita. Recusar não altera a experiência, a economia ou o acesso a anúncios recompensados.

O único convite automático ocorre depois que o jogador conclui o primeiro Ciclo Six-Seven e vê sua primeira Aura. O jogo não transmite esse ciclo nem outros fatos anteriores retroativamente. “Permitir” e “Agora não” possuem peso equivalente; dispensar mantém a coleta desligada. Depois de recusar, o jogador somente encontra a opção em Configurações, sem nova insistência automática.

As proteções obrigatórias são:

- Consentimento de Analytics separado do fluxo de consentimento publicitário;
- controle em Configurações para interromper coletas futuras;
- nenhum `User ID`, e-mail, conta, nome, data de nascimento ou propriedade personalizada identificável;
- coleta do Android Advertising ID e personalização publicitária desativadas;
- nenhum uso ou envio de Play Age Signals;
- nenhum conteúdo do save, Backup Manual, texto livre ou valor exato de Aura;
- medidas econômicas e temporais somente em faixas documentadas;
- consentimento local ao aparelho, excluído do Backup Manual.

O Firebase ainda pode processar automaticamente dados técnicos, identificadores de instância e informações como endereço IP depois do opt-in. A política de privacidade e o formulário Data safety devem refletir o comportamento real do SDK, sem prometer anonimato absoluto. Desativar a opção impede coletas futuras; a interface não deve prometer apagar retroativamente dados que já tenham sido transmitidos.

Como a amostra será composta por jogadores que aceitaram a coleta, suas métricas não devem ser apresentadas como representação estatística automática de toda a base.

Os dados detalhados de usuários e eventos usam retenção de dois meses no GA4. A renovação do prazo por nova atividade fica desativada e o lançamento não exporta eventos para BigQuery ou outro armazenamento externo. Relatórios agregados padrão que o GA4 mantenha nativamente podem continuar disponíveis, sem criação de cópia paralela pelo projeto.

## Diagnóstico de falhas

O Firebase Crashlytics é configurado com transmissão automática desativada. Falhas fatais e ANRs podem produzir um Relatório de Diagnóstico local, mas sua saída do aparelho depende de uma Autorização de Diagnóstico específica na abertura seguinte.

A oferta deve:

- explicar que o envio é opcional e serve para corrigir falhas;
- informar quantos relatórios estão pendentes;
- resumir as categorias de dados técnicos incluídas;
- esclarecer que, se o Analytics já tiver sido aceito, breadcrumbs permitidos podem acompanhar o diagnóstico;
- oferecer “Enviar” e “Não enviar” com peso visual equivalente;
- apagar o lote local quando o jogador recusar ou dispensar;
- não conceder recompensa nem persistir autorização para falhas futuras.

O lançamento não define `User ID`, chaves ou logs personalizados, não registra manualmente exceções não fatais e não inclui save, Backup Manual, Aura exata ou Play Age Signals. Autorizar um relatório não habilita Analytics.

Segundo a documentação consultada em 10 de julho de 2026, o Crashlytics pode processar stack traces, horário da falha, versão do aplicativo, sistema e modelo do aparelho, estado de root, arquitetura, memória, armazenamento e identificadores de instalação. A retenção publicada é de 90 dias antes do início do processo de remoção dos sistemas ativos e de backup. Esses dados e prazos devem ser conferidos novamente antes da publicação.

O compartilhamento Crash Insights permanece desativado no lançamento. Com isso, o projeto abre mão da comparação de stack traces anonimizados com outros aplicativos, mas continua recebendo os Relatórios de Diagnóstico do próprio Aura Shift: Six Seven que forem autorizados.

## Loot boxes e economia

O jogo não possui loot boxes, recompensas aleatórias pagas, itens negociáveis ou Aura convertível em dinheiro. Bônus de Retorno e Complemento de Aura são determinísticos, informados antecipadamente e dependem de escolha voluntária.

## Política de privacidade e Data safety

Antes do teste fechado, o projeto deve possuir:

- política pública em URL estável;
- acesso à política dentro de Ajustes;
- descrição clara de anúncios e SDKs;
- formulário Data safety coerente com cada dependência;
- declaração “Contém anúncios”;
- contato de privacidade e suporte;
- processo de atualização quando SDKs mudarem.

Mesmo com saves locais e sem conta, o Google Mobile Ads pode processar dados técnicos. Portanto, o jogo não deve declarar ausência total de coleta sem conferir a documentação vigente do SDK.

## Pipeline de revisão

Agentes independentes devem revisar:

- política de privacidade contra a lista real de SDKs;
- Data safety contra documentação oficial de cada fornecedor;
- consentimento em regiões aplicáveis;
- tratamento `TEEN` em todas as solicitações;
- ausência de uso proibido de Age Signals;
- anúncios mais maduros que o conteúdo;
- funcionamento integral sem anúncios.
- ausência de eventos de analytics antes do opt-in e depois do opt-out;
- lista permitida de eventos, parâmetros e faixas;
- ausência de Advertising ID, `User ID`, Play Age Signals e valores econômicos exatos;
- coerência entre consentimento, política, Data safety e configuração real do Firebase.
- momento do convite, ausência de envio retroativo e ausência de nova insistência após recusa;
- retenção de dois meses, redefinição por atividade desativada e ausência de exportações;
- transmissão do Crashlytics desativada por configuração nativa;
- ausência de transmissão antes da Autorização de Diagnóstico;
- exclusão local após recusa ou dispensa;
- ausência de `User ID`, logs, chaves e exceções não fatais personalizados;
- conteúdo e quantidade informados quando breadcrumbs ou múltiplos relatórios estiverem pendentes.
- Crash Insights desativado no console sem afetar os relatórios próprios.

## Referências atuais

- [AdMob — tratamento etário](https://support.google.com/admob/answer/6219315?hl=en)
- [AdMob — consentimento europeu](https://support.google.com/admob/answer/13554020?hl=en-GB)
- [Google Play — requisitos do ECA Digital no Brasil](https://support.google.com/googleplay/android-developer/answer/6223646?hl=pt-BR)
- [Play Age Signals — termos e uso](https://developer.android.com/google/play/age-signals/overview)
- [Firebase Analytics — início no Flutter](https://firebase.google.com/docs/analytics/flutter/get-started)
- [Firebase Analytics — eventos](https://firebase.google.com/docs/analytics/flutter/events)
- [Firebase Analytics — controle de coleta e Advertising ID](https://firebase.google.com/docs/analytics/android/configure-data-collection)
- [Firebase — privacidade e segurança](https://firebase.google.com/support/privacy)
- [Firebase Analytics — User ID](https://firebase.google.com/docs/analytics/userid)
- [Google Analytics — retenção de dados](https://support.google.com/analytics/answer/7667196?hl=pt-BR)
- [Firebase Crashlytics — personalização e opt-in no Flutter](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)
- [Firebase Crashlytics — API Android para relatórios pendentes](https://firebase.google.com/docs/reference/android/com/google/firebase/crashlytics/FirebaseCrashlytics)
- [Google Play — User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Google Play — Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

Este documento é planejamento de produto e não substitui aconselhamento jurídico.
