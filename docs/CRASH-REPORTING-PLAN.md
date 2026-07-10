# Aura Shift: Six Seven — Plano de Relatórios de Falha

> Status: estratégia de autorização por ocorrência, copy `diagnostic_*` e Crash Insights desativado aprovados; operação no console será validada na integração.

## Objetivo

Obter evidências técnicas suficientes para corrigir falhas graves sem transformar diagnóstico em transmissão automática. O lançamento usa Firebase Crashlytics para falhas fatais e ANRs, mantendo o relatório no aparelho até uma autorização específica do jogador.

## Modelo aprovado

1. A transmissão automática do Crashlytics permanece desativada por configuração nativa; o SDK ainda pode capturar a falha localmente.
2. Uma falha fatal ou ANR pode gerar um Relatório de Diagnóstico local.
3. Na abertura seguinte, o jogo verifica se existem relatórios pendentes.
4. A interface informa finalidade, categorias de dados e quantidade pendente.
5. “Enviar” autoriza somente o lote apresentado.
6. “Não enviar” ou dispensar apaga o lote local.
7. Nenhuma opção altera economia, progresso ou disponibilidade do jogo.
8. Uma nova falha exige uma nova escolha.

Se o envio autorizado ocorrer sem conexão, ele pode aguardar conectividade para transmitir o mesmo lote. A autorização não liga a transmissão automática nem vale para relatórios posteriores.

## Escopo dos relatórios

O lançamento admite os dados técnicos produzidos normalmente pelo Crashlytics, sujeitos à verificação da versão integrada:

- stack traces e threads;
- horário da falha;
- identificadores e versão do aplicativo;
- sistema operacional e versão;
- modelo, CPU, memória e armazenamento do aparelho;
- estado de root ou jailbreak informado pelo SDK;
- identificadores técnicos de instalação e sessão;
- breadcrumbs de Analytics somente quando o Consentimento de Analytics já estiver ativo.

O lançamento proíbe:

- `User ID` ou identidade criada pelo jogo;
- chaves e logs personalizados;
- mensagens arbitrárias ou texto livre;
- registro manual de exceções não fatais;
- conteúdo do save ou Backup Manual;
- valores exatos de Aura ou preços;
- Play Age Signals;
- habilitação silenciosa de Analytics.

## Casos com múltiplos relatórios

A API do Crashlytics pode tratar relatórios não enviados como um conjunto. Para não prometer granularidade inexistente, a interface informa quando há mais de um relatório e pede autorização para o lote pendente. O produto deve evitar acumulação apresentando a escolha imediatamente na primeira abertura estável depois da falha.

## Relação com Analytics

As permissões são separadas:

- sem Consentimento de Analytics, nenhum evento de produto deve ser habilitado para enriquecer o diagnóstico;
- com Analytics ativo, breadcrumbs automáticos ou de eventos permitidos podem acompanhar o relatório;
- a oferta de diagnóstico deve informar essa possibilidade;
- enviar ou apagar o relatório não modifica a preferência de Analytics.

## Experiência da oferta

A mensagem deve ser curta, localizada nos oito idiomas e acessível. Estrutura conceitual:

- **Título:** o jogo encontrou uma falha;
- **Finalidade:** ajudar a localizar e corrigir o problema;
- **Escopo:** quantidade e categorias de dados técnicos;
- **Escolhas equivalentes:** enviar ou não enviar;
- **Detalhes:** link para explicação e política de privacidade.

Não usar urgência artificial, botão de recusa escondido, recompensa, culpa ou afirmação de anonimato absoluto.

## Retenção e declarações

Na consulta de 10 de julho de 2026, o Firebase informa retenção de stack traces, dados de minidump processados e identificadores associados por 90 dias antes de iniciar a remoção dos sistemas ativos e de backup. Antes do teste fechado e da produção, a equipe de agentes deve verificar novamente:

- dados realmente coletados pela versão integrada;
- retenção vigente;
- configuração do console;
- política de privacidade;
- formulário Data safety;
- termos aplicáveis do Firebase.

## Crash Insights

O compartilhamento Crash Insights permanece desativado no lançamento. A decisão impede a comparação dos stack traces anonimizados do projeto com dados de outros aplicativos Firebase, mas não desativa a recepção nem a análise dos Relatórios de Diagnóstico autorizados do próprio jogo.

A configuração vive no console e deve integrar o checklist de teste fechado e produção. Uma mudança futura exige nova decisão documentada e revisão da política de privacidade.

## Validação

1. Instalação limpa não transmite relatório.
2. Falha de teste gera pendência local sem tráfego para o Crashlytics.
3. “Não enviar” e dispensa apagam a pendência.
4. “Enviar” transmite somente o lote informado.
5. Uma nova falha volta a pedir autorização.
6. Aceite offline não cria relatórios adicionais nem habilita coleta futura.
7. Payload não contém campos proibidos.
8. Analytics desativado não produz breadcrumbs de produto.
9. Analytics ativado inclui, no máximo, breadcrumbs da taxonomia permitida.
10. Backup Manual não contém relatório nem decisão de diagnóstico.
11. Os oito idiomas apresentam escolhas equivalentes, legíveis e sem coerção.
12. Métricas de estabilidade são rotuladas como cobertura autorizada incompleta.
13. Crash Insights aparece desativado no console e relatórios próprios continuam funcionais.

## Pendências

- redigir e localizar o texto exato;
- confirmar comportamento de fila quando a autorização ocorre offline;
- definir rotina de triagem, prioridade e encerramento de falhas;
- definir mecanismo de contato de suporte separado de relatórios automáticos.

## Referências atuais

- [Crashlytics para Flutter — personalização e opt-in](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)
- [FirebaseCrashlytics — relatórios não enviados](https://firebase.google.com/docs/reference/android/com/google/firebase/crashlytics/FirebaseCrashlytics)
- [Privacidade e retenção do Firebase](https://firebase.google.com/support/privacy)
- [Métricas crash-free e limites do opt-in](https://firebase.google.com/docs/crashlytics/crash-free-metrics)

As referências devem ser verificadas novamente com as versões utilizadas na implementação.
