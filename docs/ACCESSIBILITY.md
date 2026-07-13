# Aura Shift: Six Seven — Acessibilidade

> Status: `a11y-matrix-v1` aprovado para planejamento; critérios mensuráveis obrigatórios para implementação e lançamento.

## Baseline e escopo

O MVP adota WCAG 2.2 nível AA como baseline de interface, complementado por testes Android/TalkBack, entrada por toque, alternativas sensoriais e os oito idiomas. A conformidade só pode ser declarada sobre uma build testada; este documento define os gates que a build deverá passar.

Nenhuma opção de acessibilidade altera Aura, custos, produção, anúncios, desbloqueios ou recompensa. Informação essencial possui no mínimo dois modos entre texto, forma/ícone, cor, som, vibração e movimento, sendo obrigatório um equivalente visual textual ou semântico.

## Perfis de configuração

As opções são independentes:

- **Movimento:** `Seguir sistema` (padrão inicial), `Completo` ou `Reduzido`;
- **Flashes e partículas:** `Completo` ou `Reduzido`;
- **Contraste aumentado:** desativado ou ativado;
- **Música:** volume próprio e desligado;
- **Efeitos sonoros:** volume próprio e desligado;
- **Vibração:** ligada ou desligada;
- **Dicas extras para leitor de tela:** desativadas ou ativadas; acrescentam contexto opcional sem repetir nome, papel, estado ou valor;
- **Escala textual:** segue o aparelho; não existe controle que limite a escala do sistema.

Mudar uma opção atualiza a prévia imediatamente, persiste localmente e não requer reinício. Backup Manual inclui configurações gerais, mas preferências vinculadas à instalação ou ao sistema devem ser reconciliadas com segurança no aparelho de destino.

## Contraste e independência de cor

- texto normal: contraste mínimo `4,5:1` contra o fundo composto;
- texto grande — pelo menos `24sp` regular ou `18,5sp` em negrito —: mínimo `3:1`;
- ícones essenciais, bordas de controles, indicador de seleção e foco: mínimo `3:1` contra cores adjacentes;
- foco visível: anel de `2dp`, offset de `2dp`, área não obscurecida e contraste mínimo `3:1`;
- gráfico, barra e ramo: cor acompanhada de label, valor, forma ou padrão;
- estados sucesso, aviso, erro, selecionado, adquirido e bloqueado nunca são diferenciados somente por vermelho/verde ou cor de Ramo.

QA mede capturas reais com scrims, brilho, partículas e arte, nos estados claro/escuro que existirem. Simulação de protanopia, deuteranopia, tritanopia e monocromia deve preservar identificação de ações, Ramos e status.

Contraste aumentado troca superfícies translúcidas por equivalentes opacas, eleva texto secundário para o tratamento principal quando necessário, remove brilho atrás de conteúdo e usa bordas de `2dp` nos controles. Ele não reduz nenhum par abaixo dos limiares normais, não recolore Ramos como estados funcionais e não altera hierarquia ou economia.

## Texto, reflow e expansão

- suporte obrigatório à escala de fonte Android de `100%`, `130%`, `150%` e `200%`;
- a `320dp` de largura e `200%`, nenhuma ação, requisito, consentimento, erro ou valor essencial fica cortado ou sobreposto;
- não há rolagem horizontal da tela; exceções controladas são a viewport visual da Árvore e segmentos de números completos, sempre com rota linear/semântica equivalente;
- pseudo-localização Latin de `+35%`, texto com diacríticos e strings de ação de duas linhas integra o gate;
- `de-DE` testa compostos, `ja-JP` testa quebras sem espaço e altura de glifos, `ar` testa shaping, bidi misto e RTL;
- labels de botões crescem verticalmente até duas linhas; depois o layout empilha ações, sem reduzir fonte;
- texto essencial não está em imagem. Reticências só podem ocultar conteúdo repetível cujo texto completo esteja disponível no mesmo componente acionável.

## Toque e precisão motora

- todo alvo interativo mede no mínimo `48×48dp`, inclusive ícone, nó e botão de fechar;
- ações primárias medem no mínimo `52dp` de altura;
- alvos independentes mantêm `8dp` de separação quando não formarem um controle segmentado;
- a Área de Aura é ampla e aceita toque em qualquer ponto livre de controles; Mascote e mãos não são alvos;
- manter, arrastar ou tocar com um segundo dedo enquanto houver contato ativo não gera ações extras nem punição;
- não há limite mínimo de velocidade, erro de ritmo, gesto complexo obrigatório ou timeout para completar Fase Seven;
- ações destrutivas/irreversíveis exigem ativação explícita e confirmação; não dependem de swipe ou pressão prolongada.

Roteiro: executar Jogar, compra `×1`, equipar Aparência, alterar canal sensorial, exportar e cancelar importação usando apenas o polegar direito e depois o esquerdo em `360×800dp`, sem mudança de pega obrigatória para a ação recorrente.

## Foco, teclado e Switch Access

Embora o MVP seja touch-first, widgets Flutter devem preservar foco lógico:

- ordem: título/contexto → conteúdo → ação fixa → barra inferior;
- modal retém foco; fechar devolve ao controle de origem;
- foco nunca muda por produção passiva, atualização de preço, partículas ou celebração;
- ação destrutiva não recebe foco inicial;
- todos os controles são acionáveis por foco/Enter/Space ou ação equivalente do framework;
- pan/zoom da Árvore possui uma lista de nós equivalente, navegável sequencialmente;
- sliders oferecem incremento/decremento sem exigir arraste;
- nenhum foco fica oculto por barra, teclado, folha ou safe area.

O gate percorre as quatro áreas, todas as folhas e o fluxo de importação com teclado e Android Switch Access ou equivalente disponível no ambiente de teste.

## TalkBack e semântica

Versão-alvo: TalkBack estável atual nas versões Android da matriz de lançamento; versões exatas serão registradas no relatório de QA. Regras:

- cada controle expõe nome localizado, papel, estado, valor e dica somente quando necessária;
- ícone decorativo, partícula, brilho e duplicata visual ficam fora da árvore semântica;
- barra inferior expõe quatro destinos, posição e seleção;
- Área de Aura é um único controle: anuncia Fase Six/Seven, Potência vigente e que a ativação avança uma fase; duplo toque avança exatamente uma fase;
- Fase Six anuncia confirmação sem Aura; Fase Seven anuncia Ciclo concluído e Aura inteira creditada;
- saldo passivo não cria anúncio a cada tick; atualizações rotineiras são agrupadas no máximo uma vez a cada `2s` quando houver foco relevante;
- compra, bloqueio, erro, recompensa, Transformação e Ascensão anunciam resultado persistido, não apenas animação;
- números compactos anunciam coeficiente, magnitude matemática, unidade e natureza do valor; detalhe oferece inteiro/decimal exato e contagem de dígitos;
- cards econômicos são grupos com resumo; ações permanecem filhos acessíveis;
- cada nó anuncia Ramo, profundidade, nível, estado, produção e cada requisito pendente;
- Convergência anuncia os três requisitos separadamente;
- consentimentos anunciam título, finalidade, detalhes e duas escolhas de mesmo nível;
- mudança de idioma reconstrói a árvore semântica inteira no novo locale e mantém foco no seletor/resultado correspondente.

Roteiro TalkBack obrigatório, com tela oculta quando possível:

1. abrir e concluir um Ciclo Six-Seven;
2. abrir Detalhes de Aura, ouvir e copiar valor exato;
3. comprar uma Técnica e identificar a diferença atual/projetada;
4. percorrer a Árvore, um bloqueio duplo e uma Convergência;
5. equipar Aparência e distinguir Efeito ativo/inativo;
6. alterar idioma e opções sensoriais;
7. aceitar e recusar, em execuções separadas, Analytics e diagnóstico;
8. cancelar anúncio, importar arquivo inválido e retornar ao controle de origem;
9. revisar a prévia de Ascensão sem confirmá-la.

Nenhuma etapa pode encontrar elemento sem label, foco preso, ordem incoerente ou mutação econômica diferente da interação visual.

## Movimento

### Completo

- transições funcionais duram normalmente `120–240ms`;
- movimento não essencial pode durar até `700ms`; celebrações longas seguem sua duração própria, são dispensáveis e não bloqueiam registro;
- nenhum controle se move de posição entre toque e ativação;
- parallax, câmera, squash e zoom nunca carregam informação exclusiva.

### Reduzido

- remove squash, zoom, parallax, tremor, câmera, deslocamento amplo e aceleração intensa;
- deslocamento funcional residual fica em no máximo `8dp` e `200ms`; preferência é crossfade de `100–200ms` ou troca estática;
- Transformações, Marcos 67, compras, Conquistas e Ascensão usam título, ícone, contraste e resumo estático equivalente;
- Fases Six e Seven permanecem distintas por pose/forma/label, sem exigir deslocamento;
- não existe animação automática contínua decorativa, exceto indicador de progresso necessário e discreto;
- dispensar celebração leva imediatamente ao estado final persistido.

## Flash, pulso e partículas

- nenhum efeito pode exceder três flashes em qualquer janela de `1s`, seguindo o limiar de flash geral WCAG;
- a meta interna é no máximo dois pulsos luminosos por segundo; nenhum efeito pode alternar a tela inteira, nem usar flash vermelho saturado;
- uma região superior a `25%` do viewport não pode alternar luminância como flash;
- modo Completo permite no máximo `80` partículas simultâneas na cena Jogar e `40` em menus/folhas;
- modo Reduzido permite no máximo `12` partículas simultâneas, sem emissor contínuo, estrobo ou rastro pulsante;
- Reduzir flashes e partículas elimina flashes deliberados, pulsos fortes e variações rápidas de fundo; partículas restantes usam opacidade máxima `0,35` e movimento previsível;
- texto, foco e controle permanecem legíveis durante o pico de partículas, com os mesmos limiares de contraste.

QA analisa gravação a `60fps` das Fases Six/Seven em cadência máxima humana testada, compra em lote, Transformação, Ascensão e Marco 67 completo de `6,7s`, nos dois modos.

## Áudio, vibração e redundância

- música, efeitos e vibração têm controles independentes;
- desativar cada canal isoladamente e todos juntos não remove estado ou altera recompensa;
- Six e Seven possuem equivalentes visuais e semânticos distintos;
- erro, compra, Marco, Transformação e anúncio concluído possuem confirmação visual/textual;
- haptics não são exigidos para ritmo, timing ou escolha;
- nenhuma mensagem depende de direção estéreo, frequência ou percepção de tom;
- ao retornar de ligação/foco de áudio, volumes e camadas retomam sem disparar evento econômico ou feedback duplicado.

## Fluxos críticos acessíveis

- **Tutorial:** coach marks podem ser dispensados; TalkBack alcança o jogo abaixo; Consentimento de Analytics restaura o foco e o estado do tutorial.
- **Retorno offline:** duração, base proporcional, limite de quatro horas, bônus, alternativas de resgate e estado pendente ou concluído são lidos separadamente; nenhum valor é anunciado como creditado antes da escolha.
- **Anúncio:** benefício é conhecido antes; indisponibilidade não abre loop de erro; cancelamento retorna à ação.
- **Ascensão:** grupos “recebe”, “reinicia” e “permanece” usam headings; confirmar anuncia irreversibilidade e multiplicador resultante.
- **Backup:** picker cancelado não é erro; prévia válida é lida antes da substituição; falha mantém progresso e foco.
- **Consentimentos:** escolhas equivalentes, fechar = recusar quando documentado, sem dark pattern ou tempo limite.
- **Diagnóstico:** quantidade e categorias de dados são legíveis; envio não se confunde com Analytics.
- **Erros/retomadas:** mensagem identifica estado preservado e próxima ação; foco retorna ao ponto de interrupção.

## Matriz dos oito idiomas

Cada roteiro é executado em `en-US`, `pt-BR`, `es-419`, `fr-FR`, `de-DE`, `id`, `ja-JP` e `ar` com:

| Eixo | Casos obrigatórios |
| --- | --- |
| largura/escala | `320dp` e `360dp`; texto `100%`, `150%`, `200%` |
| direção | LTR nos sete locales; RTL completo e bidi misto em `ar` |
| conteúdo | tutorial, Loja/Árvore, consentimentos, erros, backup, Ascensão |
| números | `0`, `999`, `1K`, `999K`, `1Dc`, `1e36`, expoente extremo, taxa com quatro casas, colisão compacta |
| canais | som off, vibração off, ambos off, movimento reduzido, flashes reduzidos, todos reduzidos |
| entrada | toque, TalkBack, foco/teclado e Switch Access quando disponível |

Árabe valida tokens econômicos isolados LTR sem impedir espelhamento da composição. Leitura assistiva é localizada e não soletra somente `K`, `Qa` ou `e36`.

## Matriz de aparelhos e evidência

O gate mínimo de desenvolvimento e release cobre:

- aparelho Android físico compacto/modesto, `320–360dp`, API mínima suportada;
- aparelho Android físico de referência na API-alvo;
- tela Android grande ou emulador ≥`600dp`;
- densidades e safe areas distintas;
- TalkBack e tamanho de fonte/display do sistema registrados;
- captura de contraste, vídeo de motion/flash, árvore semântica, checklist de foco e resultado por locale.

O relatório registra build, aparelho, Android, TalkBack, locale, escala, opções sensoriais, roteiro, resultado e evidência. Emulação não substitui todos os testes físicos de toque, áudio e vibração.

## Gates de aceite

Uma build reprova acessibilidade se qualquer item abaixo falhar:

1. contraste abaixo dos limiares ou estado dependente somente de cor;
2. alvo abaixo de `48×48dp`, foco invisível/preso ou ação essencial inalcançável;
3. corte/sobreposição essencial em `320dp` e `200%`;
4. rótulo, papel, estado ou ordem TalkBack ausente/incorreto;
5. economia ou acesso diferente com um canal sensorial desativado;
6. mais de três flashes por segundo, alternância full-screen ou versão reduzida incompleta;
7. RTL que inverte token econômico, ordem semântica ou ação;
8. número compacto sem detalhe/cópia/leitura assistiva coerentes;
9. fluxo crítico sem cancelamento, erro e retorno de foco seguros;
10. diferença funcional entre os oito idiomas que não seja transcriação aprovada.

## Riscos residuais

- TalkBack, políticas Android e comportamento de plugins podem mudar e exigem revalidação perto do release;
- fontes localizadas podem alterar métricas depois de P11; toda troca reabre o gate de reflow;
- arte, VFX e anúncios de terceiros precisam ser medidos na composição final, não apenas isoladamente;
- o limite documental de partículas não substitui teste de desempenho e fotossensibilidade em hardware real.
