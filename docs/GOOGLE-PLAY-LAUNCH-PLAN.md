# Aura Shift: Six Seven — Plano de Lançamento na Google Play

> Status: conta criada; trâmites conduzidos pelo usuário; checklist deve ser atualizado antes de cada marco.

## Situação da conta

- **Tipo:** pessoal.
- **Criação:** 10 de julho de 2026.
- **Responsável pelos trâmites:** usuário.

Como a conta pessoal foi criada depois de 13 de novembro de 2023, a regra atual exige teste fechado com pelo menos 12 testadores inscritos continuamente por 14 dias antes da solicitação de acesso à produção. A contagem somente começa quando houver uma build fechada válida e os testadores tiverem aderido.

## Sequência administrativa mínima

1. concluir verificação de identidade, contatos e aparelho Android exigidos para a conta;
2. configurar o jogo e suas declarações no Play Console;
3. publicar uma build em teste interno para validação rápida;
4. iniciar o teste fechado com margem acima do mínimo de 12 participantes;
5. manter ao menos 12 testadores inscritos continuamente por 14 dias e registrar feedback;
6. solicitar acesso à produção com evidências do teste e das correções;
7. responder a eventuais exigências adicionais;
8. enviar o pacote candidato à revisão de produção;
9. publicar assim que houver aprovação.

Testadores obrigatórios da loja não integram a equipe de produção. Agentes podem preparar roteiros, questionários, triagem e relatórios, mas não substituir adesões humanas exigidas pela plataforma.

## Escopo do pacote candidato

O pacote submetido à produção deve corresponder ao `MVP-SCOPE.md`. Conteúdo ou funcionalidades não enumerados não podem atrasar a candidatura; cortes de itens enumerados exigem nova aprovação do usuário. A publicação iOS e todo o backlog pós-lançamento ficam fora deste gate.

## Preparação documental prevista

- política de privacidade pública e acessível no jogo;
- formulário Data safety compatível com os SDKs usados;
- Firebase Analytics com retenção de dois meses, renovação por atividade desativada e nenhuma exportação externa;
- Crashlytics sem transmissão automática e Crash Insights desativado;
- declaração de anúncios;
- público-alvo e classificação de conteúdo;
- metadados e assets localizados da loja;
- evidências de teste e prontidão;
- dados de contato e suporte;
- documentação da origem e licença de assets gerados por IA.

## Baseline técnico

- Flutter e Dart;
- cena 2D construída com Flame;
- Android App Bundle;
- `compileSdk` e `targetSdk` 36 como baseline planejado;
- validação de páginas de memória de 16 KB em todas as bibliotecas nativas;
- Google Mobile Ads para Flutter com unidades de teste durante desenvolvimento;
- suporte futuro a iOS preservado na mesma base.

## Dependências publicitárias

O planejamento deve prever configuração e validação da conta de anúncios, consentimento aplicável por território, declarações de coleta do SDK e publicação do arquivo `app-ads.txt` quando exigido. Durante desenvolvimento e testes, somente anúncios de teste podem ser utilizados.

Todas as solicitações usarão tratamento `TEEN`, sem personalização ou remarketing. A UMP deve concluir sua avaliação antes de pedidos de anúncio. Para distribuição no Brasil, a integração e as declarações da Play Age Signals serão verificadas, sem reutilizar seus sinais em publicidade ou analytics.

## Referências oficiais atuais

- [Requisitos de teste para novas contas pessoais](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- [Tipos de conta de desenvolvedor](https://support.google.com/googleplay/android-developer/answer/13634885?hl=pt-BR)
- [Verificação de aparelho](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en)
- [Requisitos do Play Console](https://support.google.com/googleplay/android-developer/answer/10788890?hl=en)
- [User Data e política de privacidade](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Classificação de conteúdo](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en)
- [Política de anúncios recompensados](https://support.google.com/admob/answer/7313578?hl=en-GB)

Essas páginas são mutáveis e devem ser verificadas novamente perto do uso.
