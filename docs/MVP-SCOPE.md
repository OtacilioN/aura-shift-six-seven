# Aura Shift: Six Seven — Escopo do MVP Android v1.0

> Status: congelado em 10 de julho de 2026 para a primeira publicação na Google Play.

## Objetivo

Definir uma fronteira verificável para lançar o jogo sem ampliar silenciosamente prazo, conteúdo ou dependências. O MVP não é um protótipo descartável: é a primeira versão pública completa dentro do escopo enumerado abaixo.

## Incluído

### Núcleo e economia

- Ciclo Six-Seven com Fases Six e Seven;
- Produção Ativa, Passiva e Offline limitada a quatro horas;
- Recompensa de Retorno após mais de dez minutos, com resgate-base proporcional ou Bônus de Retorno opcional de 20%;
- Aura Disponível, Aura Total e Aura da Jornada;
- Notação Compacta de Aura e Marcos 67;
- Ascensão de Aura e Multiplicador de Ascensão;
- níveis ilimitados segundo as curvas aprovadas.

### Loja e conteúdo

- exatamente 18 Itens de Aura;
- exatamente três Ramos de Aura com cinco itens próprios em cada;
- exatamente três Itens de Convergência;
- exatamente seis Técnicas Six-Seven;
- exatamente cinco Transformações de Aura;
- exatamente 13 Conquistas, sendo seis visíveis e sete secretas;
- Selos 67 gerados pelas magnitudes alcançadas;
- compras `×1`, `×10` e `MÁX`;
- Patamares de Aura, Pré-requisitos de Item e Complemento de Aura.

### Experiência e apresentação

- Mascote original em camadas Flame, com mãos grandes e movimento alternado;
- 18 Aparências de Item associadas ao catálogo;
- Coleção Visual e personalização independente dos efeitos econômicos;
- música instrumental original em camadas;
- efeitos sonoros, haptics e celebrações;
- quatro áreas: Jogar, Loja, Coleção e Ajustes;
- Tutorial Contextual e primeira sessão documentada;
- feedback reduzido equivalente para preferências sensoriais.

### Plataforma e qualidade

- Android App Bundle produzido com Flutter, Dart e Flame;
- oito locales: `en-US`, `pt-BR`, `es-419`, `fr-FR`, `de-DE`, `id`, `ja-JP` e `ar`;
- suporte RTL completo para árabe;
- pacote de acessibilidade aprovado;
- save local automático e Backup Manual;
- experiência principal offline e sem conta;
- Google Mobile Ads exclusivamente recompensado nos placements Bônus de Retorno e Complemento de Aura;
- tratamento publicitário `TEEN`, consentimento aplicável e Play Age Signals isolado;
- Firebase Analytics opt-in e minimizado;
- Crashlytics com Autorização de Diagnóstico por ocorrência e Crash Insights desativado;
- política de privacidade, Data safety, licenças, metadados e assets da Google Play;
- compatibilidade planejada com API 36 e páginas de memória de 16 KB.

## Fora do MVP

- publicação na App Store;
- conteúdo acima das quantidades fixadas;
- Rive;
- conta, login, nuvem ou sincronização automática;
- multiplayer, rankings ou recursos sociais;
- Google Play Games;
- compras dentro do aplicativo, moeda premium, passe, loot boxes, assinatura ou remoção de anúncios;
- missões diárias, temporadas ou eventos ao vivo;
- notificações locais ou push;
- qualquer outra funcionalidade não enumerada como incluída.

A arquitetura continua preservando futura compilação iOS, mas nenhum trabalho específico de publicação, assinatura ou QA da App Store pertence ao MVP.

## Controle de mudanças

Uma ideia nova antes da primeira publicação possui três destinos possíveis:

1. **Atualização posterior:** registrada sem compromisso de implementação.
2. **Substituição de Escopo:** entra somente após remover ou reduzir algo de custo e risco comparáveis, com aprovação explícita do usuário.
3. **Rejeitada:** não integra o produto planejado.

Nenhum agente pode ampliar ou reduzir o escopo por conta própria. Toda Substituição de Escopo deve registrar motivação, estimativa comparativa, documentos afetados e aceite do usuário.

Correções de defeitos, requisitos de acessibilidade, segurança, privacidade, políticas da loja e conformidade técnica são obrigações de qualidade, não funcionalidades opcionais usadas como moeda de troca.

## Definição de pronto

O MVP somente está pronto para candidatura à produção quando:

1. todos os itens incluídos possuem evidência de implementação e teste;
2. a economia passa pelas simulações e tolerâncias aprovadas;
3. a fatia vertical e a matriz de aparelhos não revelam bloqueador aberto;
4. os oito idiomas passam pelo pipeline multiagente e QA de layout;
5. acessibilidade e alternativas reduzidas funcionam;
6. anúncios, consentimentos, Analytics e diagnóstico respeitam suas regras;
7. save, Backup Manual, migração e retomada não perdem progresso;
8. o AAB candidato passa nas verificações de API, 16 KB, desempenho e políticas;
9. o teste fechado obrigatório é concluído e seus problemas bloqueadores são resolvidos;
10. o usuário aprova explicitamente a submissão.

## Pós-lançamento

O escopo congelado não cria obrigação de roadmap. Qualquer atualização depende da recepção, estabilidade, Janela do Meme e nova decisão. A futura publicação iOS será planejada como uma etapa própria.
