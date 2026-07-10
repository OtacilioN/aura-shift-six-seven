# Aura Shift: Six Seven — Requisitos

> Status: baseline funcional, contratos econômicos e planejamento criativo P01–P11 documentados; assets, masters, validações de execução e revalidações pré-lançamento permanecem pendentes.

## Convenções

- **DEVE** indica requisito obrigatório.
- **NÃO DEVE** indica comportamento proibido.
- **PODE** indica comportamento permitido, mas não obrigatório em todas as ocorrências.
- Cada requisito possui um identificador estável para referência futura em design, produção e testes.

## Produto e público

- **REQ-PROD-001:** o produto DEVE ser planejado inicialmente para distribuição na Google Play.
- **REQ-PROD-002:** o planejamento DEVE preservar a possibilidade de distribuição posterior na App Store.
- **REQ-PROD-003:** o jogo DEVE atender prioritariamente jogadores de 13 a 24 anos e NÃO DEVE ser direcionado a menores de 13 anos.
- **REQ-PROD-004:** o Aura Shift: Six Seven DEVE ser tratado como um Jogo de Tendência ligado diretamente ao meme Six-Seven.
- **REQ-PROD-005:** decisões de escopo DEVEM considerar a Janela do Meme como restrição estratégica.
- **REQ-PROD-006:** o produto NÃO DEVE exigir uma estratégia de marca evergreen.
- **REQ-PROD-007:** uma futura adaptação para outro meme DEVE ser planejada como um jogo separado, não como descaracterização obrigatória do Aura Shift: Six Seven.
- **REQ-PROD-008:** o planejamento DEVE assumir produção somente pelo usuário e pelo Codex, com apoio de subagentes especializados.
- **REQ-PROD-009:** o projeto NÃO DEVE depender de contratação externa para cumprir o escopo de lançamento.
- **REQ-PROD-010:** quando escopo e Janela do Meme entrarem em conflito, o planejamento DEVE propor cortes explícitos antes de aceitar atraso silencioso.
- **REQ-PROD-011:** o lançamento DEVE ocorrer assim que o produto estiver pronto e os requisitos aplicáveis da Google Play estiverem satisfeitos.
- **REQ-PROD-012:** saturação hipotética do meme em curto prazo NÃO DEVE, isoladamente, reduzir os oito idiomas ou eliminar requisitos já confirmados.

## MVP Android v1.0

- **REQ-MVP-001:** a primeira publicação na Google Play DEVE respeitar o escopo fechado do MVP Android v1.0.
- **REQ-MVP-002:** o MVP DEVE incluir Ciclo Six-Seven, Produção Ativa, Produção Passiva e Produção Offline.
- **REQ-MVP-003:** o MVP DEVE incluir exatamente 18 Itens de Aura, seis Técnicas Six-Seven, cinco Transformações de Aura e 13 Conquistas.
- **REQ-MVP-004:** os 18 Itens de Aura DEVEM compreender exatamente 15 itens próprios distribuídos entre três Ramos de Aura e três Itens de Convergência.
- **REQ-MVP-005:** o MVP DEVE incluir compras `×1`, `×10` e `MÁX`, Árvore de Aura, Pré-requisitos de Item e Complemento de Aura.
- **REQ-MVP-006:** o MVP DEVE incluir Ascensão de Aura, Marcos 67, Selos 67, Coleção Visual e personalização do Mascote.
- **REQ-MVP-007:** o MVP DEVE incluir música original, efeitos sonoros e respostas táteis conforme as preferências do jogador.
- **REQ-MVP-008:** o MVP DEVE incluir as áreas Jogar, Loja, Coleção e Ajustes.
- **REQ-MVP-009:** o MVP DEVE incluir os oito idiomas aprovados, árabe RTL e os requisitos de acessibilidade documentados.
- **REQ-MVP-010:** o MVP DEVE incluir save local, Backup Manual, os dois placements de Anúncio Recompensado, Analytics opt-in e Relatórios de Diagnóstico autorizados.
- **REQ-MVP-011:** a publicação iOS NÃO DEVE integrar o escopo do MVP, embora a arquitetura DEVA preservar sua possibilidade futura.
- **REQ-MVP-012:** o MVP NÃO DEVE incluir conteúdo além das quantidades exatas aprovadas.
- **REQ-MVP-013:** o MVP NÃO DEVE incluir conta, nuvem, multiplayer, rankings, recursos sociais ou integração Google Play Games.
- **REQ-MVP-014:** o MVP NÃO DEVE incluir compras dentro do aplicativo, passe, loot boxes, assinatura ou compra para remover anúncios.
- **REQ-MVP-015:** o MVP NÃO DEVE incluir missões diárias, temporadas, eventos ao vivo ou notificações locais ou push.
- **REQ-MVP-016:** o MVP NÃO DEVE usar Rive.
- **REQ-MVP-017:** uma nova funcionalidade pré-lançamento somente PODE entrar por Substituição de Escopo aprovada pelo usuário e registrada na documentação.
- **REQ-MVP-018:** cortes de requisitos aprovados NÃO DEVEM ocorrer silenciosamente; qualquer redução exige nova decisão explícita do usuário.
- **REQ-MVP-019:** correções, acessibilidade, segurança, conformidade de plataforma e defeitos de qualidade NÃO DEVEM ser classificados como aumento opcional de escopo.
- **REQ-MVP-020:** ideias fora do MVP PODEM ser registradas para avaliação posterior, mas NÃO DEVEM gerar compromisso de atualização.

## Processo de revisão

- **REQ-REV-001:** revisões de produção DEVEM usar agentes distintos para criação e avaliação sempre que a independência melhorar a confiabilidade.
- **REQ-REV-002:** cada pipeline DEVE possuir objetivo, critérios de aceite, evidências e responsável por consolidar divergências.
- **REQ-REV-003:** conteúdo de maior risco PODE receber uma etapa adversarial adicional antes do aceite final.
- **REQ-REV-004:** agentes NÃO DEVEM declarar validação humana, jurídica ou de plataforma que não ocorreu.
- **REQ-REV-005:** a decisão final de produto DEVE permanecer com o usuário.

## Distribuição Google Play

- **REQ-PLAY-001:** o planejamento DEVE considerar a conta pessoal Google Play Console criada em 10 de julho de 2026.
- **REQ-PLAY-002:** antes de solicitar acesso à produção, o projeto DEVE cumprir o teste fechado atualmente exigido para essa conta: pelo menos 12 testadores inscritos continuamente por 14 dias.
- **REQ-PLAY-003:** o usuário DEVE conduzir verificações de identidade, aparelho, conta, testadores e declarações no Play Console.
- **REQ-PLAY-004:** agentes PODEM preparar materiais e auditar evidências, mas NÃO DEVEM ser apresentados como substitutos dos testadores ou verificações exigidos pela plataforma.
- **REQ-PLAY-005:** requisitos da plataforma DEVEM ser revistos novamente antes do primeiro teste fechado e antes da submissão à produção.

## Tecnologia e plataformas

- **REQ-TECH-001:** o aplicativo DEVE usar Flutter e Dart como base multiplataforma.
- **REQ-TECH-002:** a cena Jogar DEVE usar Flame para loop, componentes, entrada, animações, partículas e renderização 2D.
- **REQ-TECH-003:** navegação, Loja, Coleção, Ajustes, localização, RTL, acessibilidade, diálogos e arquivos DEVEM permanecer prioritariamente em widgets Flutter.
- **REQ-TECH-004:** a integração publicitária DEVE usar o plugin Google Mobile Ads para Flutter mantido e documentado pelo Google.
- **REQ-TECH-005:** o áudio PODE usar `flame_audio`, condicionado à validação de múltiplas camadas, latência e retomada do aplicativo.
- **REQ-TECH-006:** Rive NÃO DEVE integrar o MVP Android v1.0.
- **REQ-TECH-007:** o movimento inicial do Mascote DEVE poder ser produzido com componentes e camadas Flame sem rig externo.
- **REQ-TECH-008:** o pacote Android DEVE ser produzido como Android App Bundle compatível com API 36.
- **REQ-TECH-009:** o AAB final e todas as bibliotecas nativas DEVEM ser validados para páginas de memória de 16 KB.
- **REQ-TECH-010:** a arquitetura DEVE preservar futura compilação para iOS sem reescrita do domínio ou da interface principal.
- **REQ-TECH-011:** plugins e ferramentas DEVEM ter versão fixada, licença registrada e compatibilidade revalidada antes da publicação.

## Localização

- **REQ-L10N-001:** inglês dos Estados Unidos (`en-US`) DEVE ser o idioma-fonte.
- **REQ-L10N-002:** o lançamento DEVE oferecer `en-US`, `pt-BR`, `es-419`, `fr-FR`, `de-DE`, `id`, `ja-JP` e `ar`.
- **REQ-L10N-003:** interface, conteúdo de jogo e metadados da loja DEVEM possuir versões correspondentes nos oito idiomas.
- **REQ-L10N-004:** nomes, humor, memes e referências culturais DEVEM passar por transcriação e revisão independente por agentes especializados antes da publicação.
- **REQ-L10N-005:** a saída inicial de um agente tradutor NÃO DEVE ser publicada como versão final sem uma segunda revisão independente.
- **REQ-L10N-006:** o layout DEVE suportar expansão e contração de texto sem cortar informação essencial.
- **REQ-L10N-007:** a interface DEVE suportar direção da direita para a esquerda no locale árabe.
- **REQ-L10N-008:** datas, separadores e leitura assistiva de valores DEVEM respeitar o locale; dígitos, sufixos e expoentes de tokens econômicos seguem as exceções normativas de `number-format-v1`.
- **REQ-L10N-009:** texto essencial NÃO DEVE ser incorporado diretamente em imagens sem alternativa localizada.
- **REQ-L10N-010:** na primeira abertura, o jogo DEVE usar o idioma do aparelho quando ele pertencer à lista suportada.
- **REQ-L10N-011:** quando o idioma do aparelho não for suportado, o jogo DEVE usar `en-US` como fallback.
- **REQ-L10N-012:** um seletor de idioma DEVE permanecer acessível antes do tutorial e nas Configurações.
- **REQ-L10N-013:** cada opção DEVE apresentar o nome do idioma no próprio idioma.
- **REQ-L10N-014:** `Português (Brasil)` DEVE apresentar a bandeira do Brasil como apoio visual.
- **REQ-L10N-015:** bandeiras NÃO DEVEM ser o único identificador textual de um idioma.
- **REQ-L10N-016:** a troca de idioma DEVE ser aplicada sem exigir nova instalação e persistida no salvamento local.
- **REQ-L10N-017:** cada idioma DEVE ter uma etapa de tradução e outra de revisão executadas por agentes diferentes.
- **REQ-L10N-018:** o processo DEVE incluir retrotradução ou comparação semântica independente para textos críticos.
- **REQ-L10N-019:** cada locale DEVE passar por revisão cultural de memes, tom e naturalidade.
- **REQ-L10N-020:** placeholders, plurais, números extremos, truncamento e direção de texto DEVEM passar por QA específico em cada locale.
- **REQ-L10N-021:** materiais e metadados do produto NÃO DEVEM afirmar que houve revisão humana nativa quando ela não ocorreu.
- **REQ-L10N-022:** problemas linguísticos reportados após o lançamento DEVEM poder ser corrigidos sem alterar o estado econômico do jogo.
- **REQ-L10N-023:** tokens econômicos DEVEM usar os dígitos ASCII `0–9` em todos os oito locales, preservando `67` sem transliteração visual.
- **REQ-L10N-024:** em interfaces RTL, cada token econômico completo DEVE possuir isolamento LTR sem impedir o espelhamento da composição ao redor.
- **REQ-L10N-025:** tecnologia assistiva DEVE comunicar coeficiente, magnitude matemática, unidade e natureza de saldo ou taxa em linguagem localizada.

## Disponibilidade offline

- **REQ-OFF-001:** a experiência principal DEVE funcionar sem conexão com a internet.
- **REQ-OFF-002:** o jogador NÃO DEVE precisar autenticar-se para iniciar ou continuar uma sessão local.
- **REQ-OFF-003:** Ciclo Six-Seven, Produção Passiva, Loja, Árvore de Aura, personalização e Ascensão DEVEM permanecer disponíveis offline.
- **REQ-OFF-004:** anúncios recompensados PODEM ficar indisponíveis quando não houver conexão ou inventário publicitário.
- **REQ-OFF-005:** indisponibilidade de anúncio NÃO DEVE bloquear recompensa-base, compra normal ou função principal.
- **REQ-OFF-006:** verificações de integridade NÃO DEVEM exigir conexão contínua nem impedir sessões offline legítimas.
- **REQ-OFF-007:** o tempo considerado para Produção Offline DEVE permanecer entre zero e oito horas.
- **REQ-OFF-008:** uma ausência cujo intervalo seja considerado incoerente DEVE conceder zero Produção Offline e estabelecer uma nova referência temporal.
- **REQ-OFF-009:** uma ausência com intervalo incoerente NÃO DEVE oferecer Bônus de Retorno.
- **REQ-OFF-010:** mudança de relógio NÃO DEVE causar banimento, remoção de progresso ou bloqueio da experiência principal.
- **REQ-OFF-011:** voltar o relógio NÃO DEVE renovar ou ampliar a cota de Complementos de Aura.
- **REQ-OFF-012:** tolerâncias para viagem, fuso e correções legítimas DEVEM ser definidas e testadas antes do lançamento.

## Salvamento

- **REQ-SAVE-001:** o jogo DEVE salvar o progresso automaticamente no armazenamento local do aparelho.
- **REQ-SAVE-002:** o jogador NÃO DEVE precisar criar ou vincular uma conta.
- **REQ-SAVE-003:** o lançamento NÃO DEVE incluir backup em nuvem.
- **REQ-SAVE-004:** o lançamento NÃO DEVE prometer recuperação ou sincronização entre aparelhos.
- **REQ-SAVE-005:** qualquer ação dentro do jogo que apague o salvamento local DEVE apresentar confirmação explícita e irreversível.
- **REQ-SAVE-006:** evoluções futuras do formato de salvamento DEVEM preservar dados locais válidos de versões anteriores sempre que tecnicamente possível.
- **REQ-SAVE-007:** o lançamento DEVE permitir exportar voluntariamente um Backup Manual para arquivo.
- **REQ-SAVE-008:** o lançamento DEVE permitir importar um Backup Manual válido sem conta ou servidor.
- **REQ-SAVE-009:** antes de substituir o progresso atual, a importação DEVE apresentar data, versão e um resumo do backup.
- **REQ-SAVE-010:** importar um Backup Manual DEVE exigir confirmação explícita de substituição do progresso atual.
- **REQ-SAVE-011:** o jogo DEVE validar integridade e compatibilidade do arquivo antes de alterar o progresso local.
- **REQ-SAVE-012:** um arquivo inválido, corrompido ou incompatível NÃO DEVE alterar o progresso local.
- **REQ-SAVE-013:** exportação ou importação com erro NÃO DEVE exigir conexão nem danificar o salvamento ativo.
- **REQ-SAVE-014:** cada instalação DEVE manter exatamente um salvamento ativo.
- **REQ-SAVE-015:** o lançamento NÃO DEVE oferecer perfis ou espaços paralelos de jornada.
- **REQ-SAVE-016:** importar um Backup Manual válido DEVE substituir o único salvamento ativo somente após confirmação.
- **REQ-SAVE-017:** a redefinição voluntária do progresso DEVE ficar protegida por confirmação explícita de irreversibilidade.
- **REQ-SAVE-018:** um Backup Manual válido DEVE poder ser importado em outra instalação compatível sem vínculo de conta ou aparelho.
- **REQ-SAVE-019:** o jogo DEVE validar estrutura, versão e integridade antes de aceitar um Backup Manual.
- **REQ-SAVE-020:** mecanismos locais de integridade DEVEM ser tratados como resistência a adulteração casual, não como prova de propriedade ou inviolabilidade.
- **REQ-SAVE-021:** o lançamento NÃO DEVE prometer impedir compartilhamento ou manipulação intencional de saves.
- **REQ-SAVE-022:** futuras funções competitivas, rankings confiáveis ou economias com valor real NÃO DEVEM tratar o salvamento local como fonte de verdade.

## Mascote

- **REQ-CHAR-001:** o jogador DEVE ser representado por um único Mascote-base.
- **REQ-CHAR-002:** o Mascote DEVE possuir design original e NÃO DEVE reproduzir uma pessoa real ou personagem existente.
- **REQ-CHAR-003:** mãos exageradamente grandes DEVEM ser uma característica reconhecível de sua silhueta.
- **REQ-CHAR-004:** o design-base DEVE preservar sua leitura visual nos diferentes idiomas e mercados de lançamento.
- **REQ-CHAR-005:** o Mascote DEVE apresentar evolução visual vinculada à Aura Total.
- **REQ-CHAR-006:** todo Item de Aura adquirido DEVE manter seu Efeito de Item independentemente de estar visível no Mascote.
- **REQ-CHAR-007:** adquirir um Item de Aura DEVE desbloquear ao menos uma Aparência de Item correspondente.
- **REQ-CHAR-008:** exibir, trocar ou esconder uma Aparência de Item NÃO DEVE alterar a Produção Passiva.
- **REQ-CHAR-009:** o jogador DEVE poder escolher Aparências de Item em espaços visuais compatíveis; a lista de espaços será definida na direção de arte.
- **REQ-CHAR-010:** marcos selecionados de Nível de Melhoramento PODEM desbloquear variações adicionais da Aparência de Item.
- **REQ-CHAR-011:** Aparências e variações desbloqueadas DEVEM integrar uma Coleção Visual permanente.
- **REQ-CHAR-012:** a interface DEVE distinguir uma Aparência preservada de um Efeito de Item atualmente ativo.

## Direção visual

- **REQ-ART-001:** o lançamento DEVE apresentar o Mascote em 2D estilizado.
- **REQ-ART-002:** corpo, mãos, Aparências de Item, efeitos de Aura e fundo DEVEM ser planejados como camadas modulares.
- **REQ-ART-003:** as variações do Mascote DEVEM reutilizar um rig-base compatível com o Ciclo Six-Seven.
- **REQ-ART-004:** adicionar uma Aparência de Item NÃO DEVE exigir a recriação integral das animações-base.
- **REQ-ART-005:** o lançamento NÃO DEVE depender de um modelo 3D do Mascote.
- **REQ-ART-006:** Transformações de Aura PODEM combinar mudanças de paleta, partículas, iluminação, rastros e fundo.

## Direção de áudio

- **REQ-AUDIO-001:** a trilha principal DEVE ser instrumental e original.
- **REQ-AUDIO-002:** um Agente de Referência PODE consultar a obra associada ao meme para extrair características abstratas.
- **REQ-AUDIO-003:** a análise de referência NÃO DEVE transcrever ou transferir letra, melodia, progressão harmônica, arranjo, sample ou sequência reconhecível.
- **REQ-AUDIO-004:** o Agente Compositor DEVE receber somente um briefing sanitizado e NÃO DEVE acessar a obra original durante a composição.
- **REQ-AUDIO-005:** a gravação original NÃO DEVE ser usada como entrada de geração ou edição da nova trilha.
- **REQ-AUDIO-006:** a composição NÃO DEVE usar vocais, letra, samples ou imitações de vozes da referência.
- **REQ-AUDIO-007:** agentes independentes DEVEM comparar o resultado final à referência e rejeitar versões reconhecivelmente próximas.
- **REQ-AUDIO-008:** prompts, versões, arquivos-fonte, ferramenta e licença comercial aplicável DEVEM ser registrados.
- **REQ-AUDIO-009:** um asset de áudio NÃO DEVE ser publicado sem direitos comerciais compatíveis com a distribuição do jogo.
- **REQ-AUDIO-010:** a identidade musical DEVE combinar influências abstratas de funk brasileiro, brega funk de Recife, phonk e trap.
- **REQ-AUDIO-011:** a trilha NÃO DEVE imitar um artista, faixa, beat ou timbre-assinatura específico desses gêneros.
- **REQ-AUDIO-012:** o loop principal DEVE usar andamento entre `132–138 BPM` e compasso `4/4`.
- **REQ-AUDIO-013:** acentos originais PODEM sugerir agrupamentos de `6 + 7` sem reproduzir uma sequência reconhecível da referência.
- **REQ-AUDIO-014:** a trilha DEVE possuir camadas de base, groove e hype capazes de responder à intensidade dos ciclos.
- **REQ-AUDIO-015:** Loja e menus DEVEM reutilizar variações filtradas da mesma identidade sonora.
- **REQ-AUDIO-016:** a Fase Six DEVE usar som de movimento, impacto leve e vibração suave.
- **REQ-AUDIO-017:** a Fase Seven DEVE usar resposta complementar mais forte, vibração média e confirmação sonora da Aura concedida.
- **REQ-AUDIO-018:** cada fase DEVE possuir entre quatro e seis variações de efeito para reduzir repetição perceptível.
- **REQ-AUDIO-019:** sequências rápidas PODEM elevar sutilmente intensidade e tonalidade sem criar aumento contínuo de volume.
- **REQ-AUDIO-020:** música, efeitos sonoros e vibração DEVEM possuir controles independentes.
- **REQ-AUDIO-021:** desativar qualquer canal de feedback NÃO DEVE modificar recompensa ou progressão.

## Experiência e layout

- **REQ-UX-001:** a composição principal DEVE ser projetada em orientação vertical.
- **REQ-UX-002:** indicadores de progressão DEVEM ocupar prioritariamente a região superior da composição.
- **REQ-UX-003:** o Mascote e a interação central DEVEM ocupar prioritariamente a região central.
- **REQ-UX-004:** a navegação principal DEVE permanecer acessível na região inferior.
- **REQ-UX-005:** as ações recorrentes DEVEM ser utilizáveis confortavelmente com uma mão.
- **REQ-UX-006:** o primeiro lançamento NÃO DEVE exigir uma segunda composição horizontal dedicada.
- **REQ-UX-007:** a região central DEVE oferecer uma Área de Aura ampla para a interação ativa.
- **REQ-UX-008:** qualquer toque na Área de Aura que não pertença a um controle DEVE avançar a fase atual do Ciclo Six-Seven.
- **REQ-UX-009:** o jogador NÃO DEVE precisar tocar diretamente no Mascote, nas mãos ou em lados alternados.
- **REQ-UX-010:** o ponto tocado e o Mascote DEVEM fornecer resposta visual ao toque válido.
- **REQ-UX-011:** toques em regiões ocupadas por controles NÃO DEVEM avançar o Ciclo Six-Seven.
- **REQ-UX-012:** a navegação inferior DEVE possuir exatamente quatro áreas principais: Jogar, Loja, Coleção e Ajustes.
- **REQ-UX-013:** Jogar DEVE reunir Mascote, Área de Aura, indicadores e acesso aos detalhes econômicos.
- **REQ-UX-014:** Loja DEVE reunir Técnicas Six-Seven e Árvore de Aura.
- **REQ-UX-015:** Coleção DEVE reunir personalização, Transformações de Aura, Conquistas e Selos 67.
- **REQ-UX-016:** Ajustes DEVE reunir idioma, música, efeitos, vibração, acessibilidade, Backup Manual, privacidade e créditos.
- **REQ-UX-017:** detalhes de Aura DEVEM abrir como painel associado a Jogar e NÃO DEVEM criar uma quinta área principal.
- **REQ-UX-018:** Árvore de Aura, detalhes de nó, requisitos, compras e Complemento de Aura DEVEM permanecer dentro da área Loja e NÃO DEVEM criar uma raiz adicional.
- **REQ-UX-019:** o layout DEVE permanecer operável a partir de `320×568dp`, incluindo safe areas e barras do sistema.
- **REQ-UX-020:** em `360×800dp`, Jogar, compra recorrente, personalização e controles sensoriais DEVEM poder ser operados com uma mão sem mudança obrigatória de pega.
- **REQ-UX-021:** ações recorrentes DEVEM ficar na metade inferior ou possuir alternativa equivalente ao alcance do polegar; conteúdo rolável DEVE reservar espaço para barras de ação fixas.
- **REQ-UX-022:** voltar DEVE fechar primeiro diálogo, folha, detalhe e subtela, nessa ordem, antes de sair da raiz ou do aplicativo.
- **REQ-UX-023:** trocar de área DEVE preservar fase do Ciclo, rolagem, filtro e nó selecionado enquanto o estado continuar válido.
- **REQ-UX-024:** fluxos de tutorial, retorno offline, anúncio, Ascensão, Backup Manual, consentimento, diagnóstico e erro DEVEM possuir sucesso, bloqueio, falha, cancelamento e reabertura definidos em `ux-flow-v1`.
- **REQ-UX-025:** reabrir o aplicativo DEVE reconstruir fluxos persistentes por prioridade segura, sem duplicar crédito, compra, consentimento, relatório ou Ascensão.
- **REQ-UX-026:** erros e consentimentos DEVEM ter prioridade sobre celebrações; apresentações adiadas DEVEM permanecer enfileiradas sem perder o registro do evento.
- **REQ-UX-027:** fechar um modal ou concluir uma subtela DEVE devolver foco ao controle de origem ou ao próximo estado persistente válido.
- **REQ-UX-028:** pan ou zoom visual da Árvore NÃO DEVE ser a única forma de alcançar um nó; uma rota linear e semântica equivalente DEVE existir.
- **REQ-UX-029:** Convergências DEVEM expor os três requisitos separadamente e NÃO DEVEM comunicar obrigatoriedade para Patamar ou Ascensão.
- **REQ-UX-030:** qualquer ação assíncrona econômica DEVE bloquear ativações repetidas até produzir resultado persistido, falha segura ou cancelamento.

## Sistema visual de UI — `ui-system-v1`

- **REQ-UI-001:** as quatro áreas e seus fluxos DEVEM consumir os tokens, componentes e estados de `UI-DESIGN-SYSTEM.md`.
- **REQ-UI-002:** todo componente interativo DEVE definir estados normal, pressionado, focado, selecionado, desabilitado e carregando, além de sucesso e erro quando aplicáveis.
- **REQ-UI-003:** a UI DEVE usar ícone, forma, padrão ou texto junto de qualquer cor que comunique Ramo, status, bloqueio, seleção ou risco.
- **REQ-UI-004:** cores de Ramo NÃO DEVEM ser reutilizadas como único significado de sucesso, erro, aviso ou seleção funcional.
- **REQ-UI-005:** a barra inferior DEVE manter ícone e rótulo textual nos quatro destinos e crescer verticalmente quando a escala textual exigir.
- **REQ-UI-006:** botões primários e destrutivos DEVEM usar verbos explícitos; ações irreversíveis NÃO DEVEM depender apenas de cor, ícone ou posição.
- **REQ-UI-007:** pares de escolha em consentimentos DEVEM possuir o mesmo nível hierárquico, área de toque e legibilidade.
- **REQ-UI-008:** cada valor econômico exibido DEVE derivar de uma saída visual compacta, uma representação completa localizada, uma cópia canônica ASCII e uma semântica assistiva localizada coerentes com `number-format-v1`.
- **REQ-UI-009:** nenhum componente DEVE aumentar casas, arredondar ou interpretar um token compacto localmente para decidir compra, bloqueio, diferença ou marco.
- **REQ-UI-010:** os layouts DEVEM usar propriedades direcionais de início/fim e espelhar composição, navegação e relações em RTL sem espelhar tokens econômicos LTR.
- **REQ-UI-011:** fontes dos scripts Latin, japonês e árabe DEVEM ser empacotadas, versionadas, ter licença registrada e passar no gate de reflow dos oito locales.
- **REQ-UI-012:** alterações de P11 em fonte, fallback ou métrica DEVEM repetir os testes de contraste, escala, RTL, foco e truncamento de `ui-system-v1`.

## Acessibilidade

- **REQ-A11Y-001:** a preferência inicial de redução de movimento DEVE acompanhar a configuração do aparelho quando disponível.
- **REQ-A11Y-002:** Ajustes DEVE permitir alterar redução de movimento independentemente da configuração do aparelho.
- **REQ-A11Y-003:** reduzir movimento DEVE remover tremor, parallax e movimentos intensos e substituí-los por transições suaves.
- **REQ-A11Y-004:** reduzir flashes DEVE limitar pulsos fortes e impedir sequências luminosas rápidas.
- **REQ-A11Y-005:** Transformações de Aura e Marcos 67 DEVEM possuir apresentações reduzidas equivalentes.
- **REQ-A11Y-006:** informação essencial NÃO DEVE depender exclusivamente de cor, som, movimento ou vibração.
- **REQ-A11Y-007:** música, efeitos sonoros e vibração DEVEM possuir controles independentes.
- **REQ-A11Y-008:** texto DEVE respeitar a escala configurada no aparelho dentro de uma composição adaptável.
- **REQ-A11Y-009:** controles, indicadores e valores essenciais DEVEM possuir rótulos acessíveis.
- **REQ-A11Y-010:** alvos interativos DEVEM ser dimensionados para uso confortável sem precisão fina.
- **REQ-A11Y-011:** ativar opções de acessibilidade NÃO DEVE alterar recompensas, custos ou progressão.
- **REQ-A11Y-012:** feedback redundante DEVE preservar o significado quando um canal sensorial estiver desativado.
- **REQ-A11Y-013:** a interface DEVE usar WCAG 2.2 nível AA como baseline e passar os gates adicionais de `a11y-matrix-v1` antes do lançamento.
- **REQ-A11Y-014:** texto normal DEVE possuir contraste mínimo `4,5:1`; texto grande, ícones essenciais, bordas de controles e foco DEVEM possuir contraste mínimo `3:1` contra cores adjacentes.
- **REQ-A11Y-015:** nenhum alvo interativo PODE medir menos de `48×48dp`; ações primárias DEVEM possuir altura mínima de `52dp`.
- **REQ-A11Y-016:** alvos independentes DEVEM manter separação de `8dp` quando não formarem um controle segmentado.
- **REQ-A11Y-017:** foco visível DEVE usar indicador de pelo menos `2dp`, offset de `2dp`, contraste mínimo `3:1` e nunca permanecer encoberto por barra, teclado, folha ou safe area.
- **REQ-A11Y-018:** modais DEVEM reter foco durante sua abertura e devolvê-lo ao controle de origem ao fechar; produção passiva, atualizações de preço e celebrações NÃO DEVEM roubar foco.
- **REQ-A11Y-019:** a UI DEVE funcionar com escala textual de `100%`, `130%`, `150%` e `200%`, largura de `320dp` e pseudo-localização Latin de `+35%`, sem perda de ação ou informação essencial.
- **REQ-A11Y-020:** cada build candidata DEVE passar por QA de reflow e semântica em `en-US`, `pt-BR`, `es-419`, `fr-FR`, `de-DE`, `id`, `ja-JP` e `ar`.
- **REQ-A11Y-021:** a matriz DEVE incluir compostos longos em alemão, quebras sem espaços em japonês, shaping e bidi misto em árabe e números extremos de `number-format-v1`.
- **REQ-A11Y-022:** TalkBack DEVE alcançar e operar as quatro áreas, Área de Aura, rota linear da Árvore, detalhes econômicos, consentimentos, anúncios, Backup Manual, diagnóstico e prévia de Ascensão.
- **REQ-A11Y-023:** cada elemento acessível DEVE expor nome localizado, papel, estado e valor; partículas, brilho, duplicatas e decoração NÃO DEVEM poluir a árvore semântica.
- **REQ-A11Y-024:** a Área de Aura DEVE ser exposta como um único controle TalkBack cuja ativação avança exatamente uma fase e cuja resposta distingue Six de Seven.
- **REQ-A11Y-025:** atualizações rotineiras de Produção Passiva NÃO DEVEM gerar anúncio assistivo por tick; anúncios de saldo PODEM ser agrupados no máximo uma vez a cada `2s`, preservando eventos acionados e erros.
- **REQ-A11Y-026:** a Árvore DEVE oferecer ordem de foco por Patamar, Ramo e profundidade, e cada Convergência DEVE anunciar seus três requisitos separadamente.
- **REQ-A11Y-027:** Movimento Reduzido DEVE remover squash, zoom, parallax, câmera, tremor e deslocamento amplo; movimento funcional residual NÃO DEVE exceder `8dp` e `200ms`.
- **REQ-A11Y-028:** no modo reduzido, Transformações, Marcos 67, compras, Conquistas e Ascensão DEVEM usar crossfade de `100–200ms` ou estado estático com o mesmo texto e significado.
- **REQ-A11Y-029:** nenhum efeito PODE exceder três flashes em qualquer janela de um segundo, alternar a tela inteira ou usar flash vermelho saturado.
- **REQ-A11Y-030:** uma região superior a `25%` do viewport NÃO DEVE alternar luminância como flash.
- **REQ-A11Y-031:** a cena Jogar NÃO DEVE exceder `80` partículas simultâneas no modo completo nem `12` no reduzido; menus e folhas NÃO DEVEM exceder `40` no completo.
- **REQ-A11Y-032:** Reduzir flashes e partículas DEVE eliminar flashes deliberados, pulsos fortes e emissores contínuos, limitando a opacidade das partículas restantes a `0,35`.
- **REQ-A11Y-033:** os Ramos e estados funcionais DEVEM permanecer distinguíveis sob protanopia, deuteranopia, tritanopia e monocromia simuladas.
- **REQ-A11Y-034:** sliders DEVEM oferecer incremento/decremento sem arraste, e controles DEVEM permanecer acionáveis por foco, teclado e Switch Access ou equivalente do ambiente de teste.
- **REQ-A11Y-035:** a validação DEVE registrar build, aparelho, Android, versão do TalkBack, locale, escala, opções sensoriais, roteiro, resultado e evidência.
- **REQ-A11Y-036:** a build candidata DEVE incluir teste em aparelho físico compacto/modesto, aparelho físico de referência na API-alvo e tela grande ou emulador de pelo menos `600dp`.

## Interação ativa

- **REQ-CORE-001:** a produção ativa básica DEVE ocorrer por meio do Ciclo Six-Seven.
- **REQ-CORE-002:** um Ciclo Six-Seven DEVE exigir dois toques válidos consecutivos.
- **REQ-CORE-003:** a Fase Six DEVE responder imediatamente com feedback visual, sonoro e tátil, sem conceder Aura.
- **REQ-CORE-004:** a Fase Seven DEVE inverter a posição das mãos, concluir o ciclo e conceder Aura.
- **REQ-CORE-005:** a fase atual DEVE ser preservada quando o jogador interromper os toques.
- **REQ-CORE-006:** o ciclo NÃO DEVE impor limite de tempo ou punição por demora.
- **REQ-CORE-007:** interações com menus e botões NÃO DEVEM avançar o Ciclo Six-Seven.
- **REQ-CORE-008:** a recompensa ativa DEVE ser calculada pela Potência de Ciclo vigente.
- **REQ-CORE-009:** toda a produção exata da Potência de Ciclo DEVE ser gerada na Fase Seven.
- **REQ-CORE-010:** melhoramentos ativos NÃO DEVEM fazer a Fase Six conceder Aura.
- **REQ-CORE-011:** a Potência de Ciclo NÃO DEVE variar em função da velocidade dos toques.
- **REQ-CORE-012:** o lançamento NÃO DEVE conceder multiplicador econômico por combo ou sequência rápida.
- **REQ-CORE-013:** o Ciclo Six-Seven NÃO DEVE exigir precisão rítmica, energia ou resistência consumível.
- **REQ-CORE-014:** lentidão ou interrupção dos toques NÃO DEVE causar perda de Aura ou punição.
- **REQ-CORE-015:** sequências rápidas PODEM intensificar feedback audiovisual sem alterar a recompensa econômica.
- **REQ-CORE-016:** cada novo contato válido na Área de Aura DEVE avançar exatamente uma fase.
- **REQ-CORE-017:** o jogo DEVE aceitar até dois contatos simultâneos na Área de Aura.
- **REQ-CORE-018:** dois contatos válidos simultâneos DEVEM ser ordenados como Fase Six e Fase Seven.
- **REQ-CORE-019:** manter um contato pressionado NÃO DEVE repetir fases ou produzir Aura adicional.
- **REQ-CORE-020:** arrastar um contato já reconhecido NÃO DEVE gerar novos toques.
- **REQ-CORE-021:** contatos simultâneos além do segundo NÃO DEVEM avançar o Ciclo Six-Seven.
- **REQ-CORE-022:** o jogo DEVE processar até 20 novos contatos válidos por segundo na Área de Aura.
- **REQ-CORE-023:** contatos além desse limite PODEM ser ignorados para proteger desempenho e coerência visual.
- **REQ-CORE-024:** exceder o limite NÃO DEVE causar banimento, perda de progresso ou acusação de trapaça.
- **REQ-CORE-025:** o lançamento NÃO DEVE implementar detecção de autoclicker ou depender de servidor anti-cheat.
- **REQ-CORE-026:** o limite de entrada NÃO DEVE reduzir Produção Passiva nem alterar acessibilidade ou anúncios.
- **REQ-CORE-027:** na Fase Seven, unidades completas DEVEM ser creditadas e quanta insuficientes para uma unidade DEVEM permanecer no Resto de Produção.

## Cadência de progressão

- **REQ-PACE-001:** o balanceamento inicial DEVE tornar a primeira Técnica Six-Seven normalmente adquirível em aproximadamente 30 segundos.
- **REQ-PACE-002:** o balanceamento inicial DEVE tornar o primeiro Item de Aura normalmente adquirível em aproximadamente 2 minutos.
- **REQ-PACE-003:** o primeiro marco de Transformação de Aura DEVE ser normalmente alcançável em aproximadamente 5 minutos.
- **REQ-PACE-004:** a primeira sessão DEVE possuir uma saída natural entre aproximadamente 8 e 12 minutos.
- **REQ-PACE-005:** ao final da primeira sessão, o jogador DEVE possuir Produção Passiva ativa e visualizar um próximo objetivo.
- **REQ-PACE-006:** a primeira Ascensão DEVE ser balanceada para aproximadamente 2–3 dias de jogo muito ativo ou 5–7 dias de jogo casual.
- **REQ-PACE-007:** metas de tempo DEVEM ser tratadas como janelas de balanceamento e NÃO DEVEM bloquear progresso por cronômetros artificiais.
- **REQ-PACE-008:** a Cadência de Referência DEVE ser de 1,5 Ciclo Six-Seven por segundo, equivalente a três toques por segundo.
- **REQ-PACE-009:** simulações de balanceamento DEVEM incluir ao menos os perfis de 0,75, 1,5 e 3 ciclos por segundo, além de um perfil sem produção ativa.
- **REQ-PACE-010:** a Cadência de Referência NÃO DEVE limitar, acelerar artificialmente ou invalidar entradas reais.
- **REQ-PACE-011:** com investimento equilibrado, a Produção Ativa na Cadência de Referência DEVE corresponder a aproximadamente quatro vezes a Produção Passiva na primeira sessão.
- **REQ-PACE-012:** essa relação DEVE se aproximar de duas vezes no meio da jornada e de uma vez próximo da Ascensão.
- **REQ-PACE-013:** Produção Ativa e Produção Passiva DEVEM funcionar simultaneamente enquanto o jogo estiver aberto.
- **REQ-PACE-014:** escolhas de Ramos de Aura e distribuição de melhoramentos PODEM alterar a relação individual entre produção ativa e passiva.
- **REQ-PACE-015:** as Janelas de Patamar DEVEM medir tempo de calendário desde a primeira abertura, incluindo sessões e Produção Offline válida.
- **REQ-PACE-016:** o perfil Muito ativo DEVE alcançar `1K`, `1M`, `1B`, `1T` e `1Qa` nas janelas de `5–7min`, `20–30min`, `6–12h`, `24–36h` e `48–72h`.
- **REQ-PACE-017:** o perfil Referência DEVE alcançar `1K`, `1M`, `1B`, `1T` e `1Qa` nas janelas de `5–7min`, `6–10h`, `24–36h`, `72–96h` e `96–120h`.
- **REQ-PACE-018:** o perfil Casual DEVE alcançar `1K`, `1M`, `1B`, `1T` e `1Qa` nas janelas de `5–8min`, `10–14h`, `36–60h`, `84–120h` e `120–168h`.
- **REQ-PACE-019:** o perfil Passivo NÃO DEVE possuir Janela de Patamar obrigatória, mas DEVE demonstrar progresso monotônico e compras futuras alcançáveis.
- **REQ-PACE-020:** as Janelas de Patamar DEVEM ser avaliadas no cenário-base sem anúncios.
- **REQ-PACE-021:** anúncios NÃO DEVEM ser necessários para fazer um perfil canônico cumprir suas janelas.
- **REQ-PACE-022:** resultados de simulação DEVEM reportar separadamente tempo de calendário, tempo dentro do aplicativo e tempo de interação ativa.
- **REQ-PACE-023:** as Janelas de Patamar NÃO DEVEM produzir bloqueios, esperas artificiais ou garantias exibidas ao jogador.
- **REQ-PACE-024:** falhar uma janela em uma simulação DEVE provocar revisão de parâmetros ou da heurística declarada, não alteração silenciosa da meta.

## Perfis de simulação

- **REQ-SIM-001:** toda simulação oficial de economia DEVE identificar o Perfil de Simulação, a estratégia de compra e o cenário publicitário usados.
- **REQ-SIM-002:** o perfil Muito ativo DEVE executar quatro sessões uniformemente distribuídas por dia, com 30 minutos e `3 ciclos/s` em cada sessão.
- **REQ-SIM-003:** o perfil Referência DEVE executar três sessões uniformemente distribuídas por dia, com 15 minutos e `1,5 ciclo/s` em cada sessão.
- **REQ-SIM-004:** o perfil Casual DEVE executar duas sessões uniformemente distribuídas por dia, com 10 minutos e `0,75 ciclo/s` em cada sessão.
- **REQ-SIM-005:** o perfil Passivo DEVE realizar duas Aberturas Curtas de `60s` por dia e zero Ciclos Six-Seven depois de cada Bootstrap de Jornada.
- **REQ-SIM-006:** o onboarding inicial de todos os perfis DEVE usar a Cadência de Referência para preservar a calibração das âncoras iniciais.
- **REQ-SIM-007:** Produção Passiva DEVE permanecer ativa durante as sessões de todos os perfis.
- **REQ-SIM-008:** intervalos entre sessões DEVEM usar a Taxa Offline Registrada e aplicar o limite de oito horas por ausência.
- **REQ-SIM-009:** no perfil Casual, cada intervalo exato de 12 horas DEVE creditar no máximo oito horas offline.
- **REQ-SIM-010:** o cenário-base de balanceamento NÃO DEVE usar Bônus de Retorno nem Complemento de Aura.
- **REQ-SIM-011:** Bônus de Retorno e Complemento de Aura DEVEM ser avaliados em cenários de sensibilidade separados.
- **REQ-SIM-012:** o perfil Muito ativo DEVE alcançar a primeira disponibilidade de Ascensão em aproximadamente 2–3 dias.
- **REQ-SIM-013:** o perfil Casual DEVE alcançar a primeira disponibilidade de Ascensão em aproximadamente 5–7 dias.
- **REQ-SIM-014:** o perfil Passivo NÃO DEVE ser obrigado a cumprir a janela de Ascensão, mas NÃO DEVE entrar em estagnação permanente por falta de produção ativa.
- **REQ-SIM-015:** Perfis de Simulação NÃO DEVEM limitar, classificar ou alterar a experiência de jogadores reais.
- **REQ-SIM-016:** cada perfil comportamental DEVE ser cruzado com as estratégias especialista, dual e ampla da Árvore de Aura quando o estágio permitir.
- **REQ-SIM-017:** resultados DEVEM distinguir tempo de calendário, tempo em sessão e tempo de interação ativa.
- **REQ-SIM-018:** a heurística-base de compra DEVE maximizar `Aura adicional projetada nas próximas 24h ÷ custo exato`.
- **REQ-SIM-019:** o ganho ativo projetado DEVE usar a variação de Potência de Ciclo multiplicada pelos ciclos previstos na agenda das próximas 24 horas.
- **REQ-SIM-020:** o ganho passivo projetado DEVE usar a variação de Produção Passiva multiplicada pelos segundos em sessão e offline creditáveis nas próximas 24 horas.
- **REQ-SIM-021:** a avaliação de um nível que alcance Marco de Nível DEVE usar a diferença completa entre a contribuição anterior e posterior ao marco.
- **REQ-SIM-022:** somente compras desbloqueadas por Patamar e Pré-requisitos PODEM ser candidatas à pontuação-base.
- **REQ-SIM-023:** quando a melhor candidata ainda não puder ser paga, a simulação DEVE guardar Aura até alcançá-la, em vez de comprar uma alternativa inferior.
- **REQ-SIM-024:** a estratégia Especialista DEVE permitir Técnicas e somente o Ramo de Aura escolhido.
- **REQ-SIM-025:** a estratégia Dual DEVE permitir Técnicas e somente os dois Ramos de Aura escolhidos.
- **REQ-SIM-026:** a estratégia Ampla DEVE permitir Técnicas, os três Ramos de Aura e Convergências já desbloqueadas.
- **REQ-SIM-027:** pontuações com diferença relativa de até 1% DEVEM priorizar, nesta ordem, avanço do próximo Pré-requisito ou Marco de Nível, menor nível atual e ID estável.
- **REQ-SIM-028:** o cenário-base de compra NÃO DEVE considerar anúncios nem atribuir valor econômico futuro a um anúncio.
- **REQ-SIM-029:** compras somente DEVEM ocorrer enquanto o jogo estiver aberto; Produção Offline NÃO DEVE simular decisões de compra.
- **REQ-SIM-030:** a simulação econômica DEVE avaliar candidatos nível a nível, mesmo quando validar os controles `×10` e `MÁX` separadamente.
- **REQ-SIM-031:** uma sensibilidade DEVE comprar sempre a opção desbloqueada mais barata.
- **REQ-SIM-032:** outra sensibilidade DEVE perseguir o Marco de Nível ou Pré-requisito alcançável mais próximo.
- **REQ-SIM-033:** a economia NÃO DEVE ser aprovada somente com a heurística-base sem analisar o desvio produzido pelas duas sensibilidades.
- **REQ-SIM-034:** a Política de Ascensão da Simulação no baseline DEVE realizar cada Ascensão assim que a Aura da Jornada alcançar `1Qa`.
- **REQ-SIM-035:** sensibilidades de Ascensão DEVEM esperar, separadamente, `2Qa`, `4Qa` e `9Qa` de Aura da Jornada.
- **REQ-SIM-036:** cada política de Ascensão DEVE ser simulada por pelo menos três Ascensões consecutivas.
- **REQ-SIM-037:** a comparação DEVE reportar tempo de reconstrução, multiplicador acumulado, ganho de Aura por tempo, checkpoints de Aura da Jornada e Cadeias ou Convergências readquiridas em cada nova jornada.
- **REQ-SIM-038:** as políticas-base e sensibilidades de Ascensão NÃO DEVEM usar anúncios, salvo quando o cenário publicitário estiver explicitamente identificado.
- **REQ-SIM-039:** a Política de Ascensão da Simulação NÃO DEVE produzir Ascensão automática, recomendação de estratégia ou tratamento diferente para jogadores reais.
- **REQ-SIM-040:** relatórios DEVEM distinguir o benefício por Aura produzida do custo temporal de reconstruir a Loja em Ascensões frequentes.
- **REQ-SIM-041:** compras simuladas DEVEM ocorrer no primeiro timestamp econômico exato de pagabilidade, nunca no próximo tick arbitrário do executor.
- **REQ-SIM-042:** créditos ou desbloqueios no mesmo timestamp DEVEM ser processados antes da compra, e a heurística DEVE ser recalculada depois de cada mutação.
- **REQ-SIM-043:** no cenário Complemento, a oferta DEVE ser aplicada à candidata vigente da heurística declarada assim que elegível, sem trocar a política de compra nem guardar usos com conhecimento perfeito do futuro.
- **REQ-SIM-044:** no baseline em `1Qa`, a Ascensão DEVE ocorrer antes de compras daquele checkpoint, deixando a primeira compra de `TECH-06` para jornada posterior.
- **REQ-SIM-045:** para cadência racional `a/b`, o Ciclo simulado `k` DEVE ocorrer em `ceil(1.000×k×b/a)ms` desde o início da sessão, sem Ciclo em `t=0`.
- **REQ-SIM-046:** em timestamp com Ciclo, a simulação DEVE integrar primeiro a produção passiva, creditar depois a Potência de Ciclo e somente então executar a decisão de compra.
- **REQ-SIM-047:** o simulador econômico DEVE modelar apenas Ciclos completos e NÃO DEVE redefinir a regra de persistência das fases do produto.
- **REQ-SIM-048:** a Caçadora de meta DEVE partir da Aura Disponível e do Resto de Produção vigentes, congelar `P20`, `T20` e `A` e integrar a agenda real do perfil até o primeiro timestamp econômico com o aplicativo aberto em que o custo cumulativo da meta seria pagável, sem antecipar compras ou mutações intermediárias de produção; produção acumulada durante ausência somente fica disponível no retorno seguinte.
- **REQ-SIM-049:** ETAs iguais da Caçadora DEVEM desempatar por Pré-requisito, menor custo restante, menor nível e ID estável, nessa ordem.

## Gate de Balanceamento — `balance-gate-v1`

- **REQ-ACCEPT-001:** uma versão econômica somente DEVE ser aprovada quando todos os critérios obrigatórios de `BALANCE-ACCEPTANCE-CRITERIA.md` passarem; médias NÃO DEVEM compensar falhas.
- **REQ-ACCEPT-002:** todo relatório DEVE identificar as versões `balance`, `arith` e `balance-gate` utilizadas.
- **REQ-ACCEPT-003:** execuções idênticas com particionamentos temporais diferentes DEVEM possuir diferença absoluta `0` nos contadores, resto, níveis, compras, desbloqueios e limiares; agrupamento visual e timestamp de telemetria não integram essa igualdade.
- **REQ-ACCEPT-004:** no Baseline, todas as combinações de perfil ativo com Especialista, Dual e Ampla DEVEM cumprir integralmente as Janelas de Patamar.
- **REQ-ACCEPT-005:** Especialistas A/B/C e duais AB/AC/BC DEVEM produzir resultados idênticos depois da normalização de IDs.
- **REQ-ACCEPT-006:** em `1M`, `1B`, `1T` e `1Qa`, a razão entre maior e menor tempo das três estratégias NÃO DEVE exceder `1,25` para o mesmo perfil.
- **REQ-ACCEPT-007:** dominância DEVE usar Patamares na primeira jornada e, depois da Ascensão, Reconstrução Econômica e checkpoints de Aura da Jornada; nenhuma estratégia PODE dominar tempo, Potência de Ciclo e Produção Passiva em todos eles.
- **REQ-ACCEPT-008:** na primeira jornada canônica, a relação ativa/passiva DEVE ser exatamente `4×` na âncora inicial, `1,5×–2,5×` em `1B` e `0,75×–1,25×` em `0,9Qa` nos cenários definidos.
- **REQ-ACCEPT-009:** nos três perfis ativos, cada Convergência DEVE ser avaliada por pares Ampla idênticos, comparando a versão normal com outra em que somente aquela entrada esteja desabilitada; a razão dos tempos de calendário `t_habilitada/t_desabilitada` DEVE permanecer em `[0,80;1,30]` nos checkpoints `1M`, `1T` e Ascensão `4Qa`, respectivamente, e ausência do checkpoint até `30d` DEVE reprovar o par.
- **REQ-ACCEPT-010:** em todo Ponto decisório canônico elegível até o checkpoint do par, o Retorno Projetado de uma Convergência do nível atual ao próximo Marco sobre seu custo cumulativo NÃO DEVE exceder `1,25×` a melhor entrada comum elegível no mesmo timestamp.
- **REQ-ACCEPT-011:** toda a matriz DEVE passar sem anúncios antes que cenários publicitários sejam considerados.
- **REQ-ACCEPT-012:** aceleração por Retorno, Complemento e uso Máximo voluntário NÃO DEVE exceder, respectivamente, `20%`, `25%` e `35%` por checkpoint.
- **REQ-ACCEPT-013:** o Complemento DEVE alterar Aura Total e Aura da Jornada em exatamente zero e NÃO DEVE atravessar gates.
- **REQ-ACCEPT-014:** o perfil Passivo DEVE repetir o Bootstrap de Jornada depois de cada Ascensão somente até `TECH-01` L1 e um Item-raiz L1.
- **REQ-ACCEPT-015:** uma Abertura Curta do perfil Passivo DEVE durar `60s`, salvo a extensão estritamente necessária para concluir um Bootstrap.
- **REQ-ACCEPT-016:** qualquer sequência de três Aberturas Curtas do Passivo DEVE conter ao menos um Evento Econômico Relevante e nenhuma jornada PODE estagnar permanentemente.
- **REQ-ACCEPT-017:** o perfil Passivo NÃO DEVE receber Janela de Patamar obrigatória; tempo superior a `30 dias` até `1Qa` gera diagnóstico, não reprovação isolada.
- **REQ-ACCEPT-018:** concentração de gasto DEVE usar Patamares na primeira jornada e checkpoints de Aura da Jornada após Ascensão; nenhum ID não obrigatório DEVE absorver mais de `70%`, e o predecessor direto PODE chegar a `85%`.
- **REQ-ACCEPT-019:** com parâmetros nominais e sem anúncios, cada entrada econômica DEVE ser adquirida em ao menos uma execução até o fim da terceira Ascensão; `TECH-06` PODE surgir na primeira jornada de espera, mas somente depois da primeira Ascensão no baseline, e `ITEM-CONV-03` DEVE usar a política `4Qa`.
- **REQ-ACCEPT-020:** a primeira sessão NÃO DEVE possuir mais de `120s` entre Eventos Econômicos Relevantes.
- **REQ-ACCEPT-021:** o p95 de espera aberta acumulada pela mesma Compra útil NÃO DEVE exceder uma sessão do perfil, fechar o app NÃO DEVE reiniciar a medição, e a espera de calendário NÃO DEVE exceder dois retornos sem outro Evento Econômico Relevante.
- **REQ-ACCEPT-022:** Reconstrução Econômica DEVE exigir a Cadeia de Reconstrução restaurada e Potência de Ciclo e Produção Passiva iguais ou superiores ao estado pré-reset.
- **REQ-ACCEPT-023:** a primeira Reconstrução Econômica NÃO DEVE exceder `25%` da jornada anterior; cada reconstrução posterior NÃO DEVE exceder `90%` da anterior.
- **REQ-ACCEPT-024:** a primeira compra útil pós-Ascensão DEVE ocorrer em até `2min` de tempo aberto.
- **REQ-ACCEPT-025:** nos três perfis ativos, as heurísticas Mais barata e Caçadora de meta DEVEM permanecer na tolerância expandida documentada e NÃO DEVEM levar mais de `30%` além do Baseline até `1Qa`; o Passivo usa critérios próprios de liveness.
- **REQ-ACCEPT-026:** cada perturbação isolada aproximada de `±10%` em cada custo-base e Contribuição-base, quantizada validamente em `arith-v1`, DEVE ser cruzada com os três perfis ativos e as três estratégias e comparada ao nominal correspondente; ela NÃO DEVE alterar nenhum tempo de Patamar em mais de `20%`, estagnar ou criar dominância.
- **REQ-ACCEPT-027:** entre políticas `1Qa/2Qa/4Qa/9Qa`, a razão entre melhor e pior Aura por hora NÃO DEVE exceder `1,50` nos horizontes e perfis documentados.
- **REQ-ACCEPT-028:** nenhuma Política de Ascensão DEVE superar todas as demais em mais de `20%` simultaneamente em `7` e `30` dias e em todos os perfis ativos.
- **REQ-ACCEPT-029:** aos `10min`, os perfis ativos DEVEM ter `TECH-01` L1, um Item-raiz, `FORM-01` e um próximo objetivo visível; o Passivo DEVE ter concluído seu Bootstrap e possuir próximo objetivo visível.
- **REQ-ACCEPT-030:** o relatório DEVE cobrir checkpoints por Patamar, `7` e `30` dias e pelo menos três Ascensões, terminando explicitamente em `APROVADO` ou `REPROVADO`.
- **REQ-ACCEPT-031:** custos perturbados DEVEM usar `max(1,floor((p×C₀+5)/10))` e contribuições `max(1,floor((p×B20+5)/10))`, para `p∈{9,11}`.
- **REQ-ACCEPT-032:** a variação efetiva após quantização DEVE ser reportada e todo trio A/B/C DEVE ser perturbado conjuntamente.
- **REQ-ACCEPT-033:** a matriz DEVE ser executada em camadas ortogonais, sem exigir produto cartesiano entre heurística, anúncios, Ascensão, lote e perturbações.
- **REQ-ACCEPT-034:** equivalência de `×1`, `×10` e `MÁX` DEVE ser fixture ortogonal e NÃO DEVE criar uma nova estratégia comportamental.
- **REQ-ACCEPT-035:** provas de particionamento DEVEM usar passos de `1.000ms`, `100ms` e ao menos `32` sequências pseudoaleatórias de intervalos publicadas integralmente.
- **REQ-ACCEPT-036:** a matriz DEVE possuir uma camada contrafactual própria para cada Convergência nos três perfis ativos e estratégia Ampla; `ITEM-CONV-03` DEVE usar política de Ascensão `4Qa` nessa camada.

## Âncoras da primeira sessão

- **REQ-ANCHOR-001:** a Potência de Ciclo inicial DEVE ser exatamente `1 Aura` por Ciclo Six-Seven concluído.
- **REQ-ANCHOR-002:** `TECH-01` DEVE possuir custo-base de `45 Aura`.
- **REQ-ANCHOR-003:** cada nível de `TECH-01` DEVE possuir contribuição-base de `+1 Aura` por Ciclo Six-Seven antes dos Marcos de Nível.
- **REQ-ANCHOR-004:** `ITEM-A-01`, `ITEM-B-01` e `ITEM-C-01` DEVEM ser os três Itens-raiz disponíveis para a primeira escolha de ramo.
- **REQ-ANCHOR-005:** os três Itens-raiz DEVEM possuir custo-base idêntico de `270 Aura`.
- **REQ-ANCHOR-006:** cada nível de um Item-raiz DEVE possuir contribuição-base de `+0,75 Aura/s` antes dos Marcos de Nível.
- **REQ-ANCHOR-007:** comprar a primeira Técnica Six-Seven DEVE tornar visíveis e compráveis os três Itens-raiz, sujeitos ao preço normal.
- **REQ-ANCHOR-008:** o Tutorial Contextual DEVE permitir que o jogador escolha qualquer um dos três Itens-raiz como primeiro Item.
- **REQ-ANCHOR-009:** `FORM-01` DEVE ser desbloqueada ao alcançar `1.000 Aura Total`.
- **REQ-ANCHOR-010:** na Cadência de Referência, o caminho de comprar um nível de `TECH-01` e depois guardar para um Item-raiz DEVE resultar aproximadamente em Técnica aos 30 segundos, Item aos dois minutos e `FORM-01` em `5min03s`.
- **REQ-ANCHOR-011:** depois de um nível de `TECH-01` e um nível de Item-raiz, a Produção Ativa de referência DEVE ser `3 Aura/s` e a Produção Passiva DEVE ser `0,75 Aura/s`, resultando em relação `4×`.
- **REQ-ANCHOR-012:** os tempos derivados DEVEM considerar tempo de interação econômica, excluindo a permanência no convite de Consentimento de Analytics.
- **REQ-ANCHOR-013:** esses valores DEVEM funcionar como âncoras de simulação e NÃO DEVEM ser impostos por temporizadores ou bloqueios artificiais.

## Onboarding

- **REQ-ONB-001:** a primeira sessão DEVE abrir diretamente na área Jogar.
- **REQ-ONB-002:** o Tutorial Contextual DEVE solicitar dois toques na Área de Aura e usar um Ciclo Six-Seven real para conceder a primeira Aura.
- **REQ-ONB-003:** quando a primeira Técnica Six-Seven se tornar acessível, a Loja DEVE receber um destaque discreto.
- **REQ-ONB-004:** após a primeira Técnica, o tutorial DEVE apresentar o primeiro Item de Aura.
- **REQ-ONB-005:** adquirir o primeiro Item de Aura DEVE apresentar uma explicação curta da Produção Passiva e concluir o tutorial.
- **REQ-ONB-006:** a primeira Transformação de Aura DEVE ocorrer pela progressão normal, sem gatilho artificial de tutorial.
- **REQ-ONB-007:** compras orientadas pelo tutorial NÃO DEVEM ser obrigatórias para continuar tocando ou navegando.
- **REQ-ONB-008:** orientações DEVEM poder ser dispensadas e revistas posteriormente em Ajustes.
- **REQ-ONB-009:** nenhum Anúncio Recompensado DEVE ser oferecido enquanto o tutorial não estiver concluído.
- **REQ-ONB-010:** estado do tutorial DEVE distinguir ao menos entrada, Fase Six, primeira Aura, decisão de Analytics, Técnica orientada, Item orientado e conclusão.
- **REQ-ONB-011:** fechar ou perder o processo durante o tutorial DEVE retomar o primeiro estado ainda aplicável sem duplicar Aura, compra, consentimento ou evento.
- **REQ-ONB-012:** rever o tutorial NÃO DEVE redefinir a fase, conceder Aura, recomprar melhoramento, reabrir consentimento nem alterar a habilitação de anúncios.
- **REQ-ONB-013:** o Consentimento de Analytics DEVE devolver foco e controle ao mesmo ponto válido do tutorial depois de aceitar, recusar ou dispensar.
- **REQ-ONB-014:** coach marks NÃO DEVEM bloquear a barra inferior nem mais da metade útil da Área de Aura.

## Aura

- **REQ-AURA-001:** o jogo DEVE manter Aura Disponível e Aura Total como valores distintos.
- **REQ-AURA-002:** compras na Loja DEVEM consumir Aura Disponível.
- **REQ-AURA-003:** a Aura Total NÃO DEVE diminuir quando Aura Disponível for gasta.
- **REQ-AURA-004:** marcos e transformações permanentes NÃO DEVEM regredir em razão de uma compra.
- **REQ-AURA-005:** a Potência de Ciclo e a Produção Passiva DEVEM ser progressões independentes.
- **REQ-AURA-006:** Aura produzida por Ciclos Six-Seven DEVE aumentar Aura Disponível, Aura Total e Aura da Jornada pelo mesmo valor.
- **REQ-AURA-007:** Produção Passiva com o jogo aberto DEVE aumentar os três contadores pelo mesmo valor.
- **REQ-AURA-008:** Produção Offline DEVE aumentar os três contadores pelo mesmo valor.
- **REQ-AURA-009:** o Bônus de Retorno DEVE aumentar os três contadores pelo mesmo valor concedido.
- **REQ-AURA-010:** multiplicadores DEVEM ser aplicados antes do crédito nos três contadores.
- **REQ-AURA-011:** compras DEVEM reduzir somente Aura Disponível.
- **REQ-AURA-012:** o Complemento de Aura NÃO DEVE aumentar Aura Disponível, Aura Total ou Aura da Jornada.
- **REQ-AURA-013:** o valor coberto pelo Complemento de Aura DEVE ser aplicado diretamente à quitação da compra elegível.

## Exibição numérica

Esta seção materializa o contrato de apresentação `number-format-v1`, detalhado em `NUMBER-FORMATTING.md`, sem alterar `arith-v1`.

- **REQ-NUM-001:** contadores, níveis, preços e créditos inteiros entre zero e 999 DEVEM ser exibidos como inteiros sem sufixo.
- **REQ-NUM-002:** contadores de Aura, níveis, preços, créditos e taxas ou efeitos denominados em Aura, Aura/ciclo ou Aura/s, quando iguais ou superiores a mil, DEVEM utilizar Notação Compacta de Aura; multiplicadores e percentuais econômicos mantêm dígitos ASCII e bidi, mas NÃO recebem esses sufixos salvo regra própria explícita.
- **REQ-NUM-003:** a notação compacta DEVE usar os sufixos e a capitalização fixa da tabela `K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc`.
- **REQ-NUM-004:** a notação compacta DEVE preservar no máximo três algarismos significativos truncados.
- **REQ-NUM-005:** separadores decimais e de agrupamento DEVEM respeitar a localização vigente.
- **REQ-NUM-006:** o significado matemático de cada sufixo NÃO DEVE variar por idioma.
- **REQ-NUM-007:** valores além da tabela suportada de sufixos DEVEM usar notação científica.
- **REQ-NUM-008:** o jogador DEVE poder consultar uma representação não abreviada do valor em uma área de detalhes.
- **REQ-NUM-009:** Aura Disponível, Aura Total, Aura da Jornada, preços e recompensas concedidas DEVEM ser valores inteiros e não negativos.
- **REQ-NUM-010:** Produção Ativa, Passiva, Offline e Bônus de Retorno DEVEM acumular no Resto de Produção toda fração exata que ainda não complete uma unidade de Aura.
- **REQ-NUM-011:** o Resto de Produção compartilhado NÃO DEVE ser descartado entre atualizações válidas, fechamento, importação ou Ascensão.
- **REQ-NUM-012:** a Notação Compacta de Aura DEVE truncar a representação e NÃO DEVE arredondar o valor para cima.
- **REQ-NUM-013:** compras, desbloqueios e comparações DEVEM usar o valor econômico exato, nunca o texto abreviado.
- **REQ-NUM-014:** cálculos com multiplicadores DEVEM usar a aritmética inteira exata de `arith-v1` antes da concessão de unidades inteiras.
- **REQ-NUM-015:** a tabela compacta do MVP DEVE terminar em `Dc = 10³³` e a notação científica DEVE começar em `10³⁶`.
- **REQ-NUM-016:** coeficientes compactos DEVEM usar no máximo três algarismos significativos, com duas, uma ou zero casas conforme possuam um, dois ou três dígitos inteiros.
- **REQ-NUM-017:** casas excedentes DEVEM ser truncadas em direção a zero, nunca arredondadas.
- **REQ-NUM-018:** zeros decimais finais e separador decimal vazio DEVEM ser removidos da exibição.
- **REQ-NUM-019:** um valor NÃO DEVE ser promovido ao sufixo seguinte por formatação; `999.999` DEVE aparecer como `999K`.
- **REQ-NUM-020:** a notação científica DEVE usar coeficiente em `[1,10)`, até duas casas truncadas e expoente decimal integral.
- **REQ-NUM-021:** a representação não abreviada DEVE derivar diretamente da string decimal canônica e aplicar agrupamento somente na apresentação.
- **REQ-NUM-022:** números arbitrariamente longos DEVEM ser consultáveis por apresentação segmentada ou virtualizada, acompanhados da contagem de dígitos.
- **REQ-NUM-023:** a ação de copiar DEVE entregar o inteiro ASCII exato, sem separadores de agrupamento ou localização.
- **REQ-NUM-024:** números, sufixos e expoentes DEVEM usar isolamento bidirecional apropriado em interfaces RTL.
- **REQ-NUM-025:** tecnologia assistiva DEVE receber o significado matemático do valor compacto, sua unidade e natureza de saldo ou taxa, além de acesso ao inteiro completo ou decimal terminante exato na área de detalhes.
- **REQ-NUM-026:** formatação, truncamento ou localização NÃO DEVEM alterar Marcos 67, comparações, compras ou serialização econômica.
- **REQ-NUM-027:** Potência de Ciclo, Produção Passiva e efeitos produtivos não abreviados DEVEM ser derivados exatamente do denominador canônico `2000`, com até quatro casas necessárias e sem arredondamento.
- **REQ-NUM-028:** Potência de Ciclo, Produção Passiva e efeitos produtivos compactos DEVEM ser formatados diretamente do racional `N/2000` por divisões e comparações inteiras, sem `float` ou aproximação intermediária.
- **REQ-NUM-029:** uma taxa menor que mil DEVE exibir seu decimal terminante exato com até quatro casas necessárias; uma taxa a partir de mil DEVE usar as mesmas faixas de algarismos significativos, sufixos e truncamento dos inteiros.
- **REQ-NUM-030:** a ação de copiar uma taxa DEVE entregar seu decimal exato com ponto ASCII e sem agrupamento.
- **REQ-NUM-031:** todos os tokens econômicos DEVEM usar dígitos ASCII, separadores localizados e isolamento bidirecional conforme `number-format-v1`.
- **REQ-NUM-032:** se saldo e preço tiverem o mesmo token compacto, mas o saldo exato for insuficiente, a Loja DEVE calcular exatamente `preço−saldo` e informar a falta sem depender da comparação visual entre os tokens.
- **REQ-NUM-033:** a diferença visível PODE ser compactada, mas seu detalhe acionável e sua leitura assistiva DEVEM disponibilizar a representação decimal completa.
- **REQ-NUM-034:** quando um Complemento de Aura for elegível, seu valor faltante DEVE reutilizar a mesma diferença canônica calculada pela Loja, independentemente de o rótulo curto estar compactado.
- **REQ-NUM-035:** se contribuições atual e projetada forem distintas, mas tiverem o mesmo token compacto, a Loja DEVE calcular exatamente e informar sua diferença na unidade aplicável.
- **REQ-NUM-036:** todas as superfícies econômicas do MVP DEVEM consumir `number-format-v1`; formatadores locais ou variantes por tela NÃO DEVEM redefinir o contrato.

## Aritmética econômica exata — `arith-v1`

- **REQ-ARITH-001:** Aura Disponível, Aura Total, Aura da Jornada, preços, níveis e intermediários econômicos DEVEM usar inteiros não negativos de precisão arbitrária.
- **REQ-ARITH-002:** inteiros econômicos arbitrariamente grandes DEVEM ser serializados como texto decimal integral e NÃO DEVEM depender da precisão de números JSON.
- **REQ-ARITH-003:** a economia DEVE definir exatamente `10.000.000` quanta por Aura.
- **REQ-ARITH-004:** toda Contribuição-base DEVE possuir representação exata em vigésimos de sua unidade canônica, `Aura/ciclo por nível` ou `Aura/s por nível`, no contrato `arith-v1`.
- **REQ-ARITH-005:** o Multiplicador de Ascensão `A` DEVE permanecer um inteiro em centésimos.
- **REQ-ARITH-006:** o Resto de Produção `R` DEVE ser um único inteiro persistente com `0 ≤ R < 10.000.000`.
- **REQ-ARITH-007:** nenhum cálculo econômico canônico DEVE usar `float`, `double` ou arredondamento dependente de ponto flutuante.
- **REQ-ARITH-008:** para Potência bruta `P20` em vigésimos, um Ciclo concluído DEVE gerar `P20 × A × 5.000` quanta.
- **REQ-ARITH-009:** para Taxa Passiva bruta `T20`, um intervalo aberto `Δms` DEVE gerar `T20 × A × Δms × 5` quanta.
- **REQ-ARITH-010:** o jogo DEVE converter quanta em Aura inteira por `crédito=floor((R+q)/10.000.000)` e preservar o novo resto pelo módulo correspondente.
- **REQ-ARITH-011:** cada crédito inteiro de produção DEVE acrescentar o mesmo valor a Aura Disponível, Aura Total e Aura da Jornada.
- **REQ-ARITH-012:** frames NÃO DEVEM ser unidades de produção; intervalos abertos DEVEM usar milissegundos inteiros de relógio monotônico.
- **REQ-ARITH-013:** particionar um intervalo sem mudança de taxa NÃO DEVE alterar saldo, totais ou Resto de Produção.
- **REQ-ARITH-014:** antes de qualquer evento que altere uma taxa, o tempo pendente DEVE ser integrado usando o estado anterior.
- **REQ-ARITH-015:** o snapshot canônico da Taxa Offline Registrada DEVE ser `F_registrado=T20×A`, representando `F_registrado/2000 Aura/s`.
- **REQ-ARITH-016:** a duração offline válida DEVE usar milissegundos inteiros e ser limitada a `28.800.000ms`.
- **REQ-ARITH-017:** a produção offline exata DEVE ser `F_registrado × D_válido × 5` quanta.
- **REQ-ARITH-018:** o Bônus de Retorno DEVE ser exatamente `q_offline/5`, calculado antes da conversão em Aura inteira e sem reaplicar Ascensão.
- **REQ-ARITH-019:** custo, preço de lote e teto DEVEM usar somente aritmética inteira e a fórmula racional `23ⁿ/20ⁿ`.
- **REQ-ARITH-020:** a elegibilidade do Complemento DEVE usar `7×preço ≤ 10×saldo < 10×preço`, sem porcentagem em ponto flutuante.
- **REQ-ARITH-021:** uma cotação de Complemento DEVE registrar item, nível, preço, saldo comprometido e falta coberta; sucesso consome somente o saldo cotado e falha não consome saldo nem cota.
- **REQ-ARITH-022:** a parcela de Ascensão `U` DEVE ser o maior inteiro que satisfaz `U² × 10¹¹ ≤ Aura da Jornada`.
- **REQ-ARITH-023:** produção pendente DEVE ser integrada antes de calcular e confirmar uma Ascensão.
- **REQ-ARITH-024:** Aura Total e Resto de Produção DEVEM permanecer após Ascensão; Aura Disponível e Aura da Jornada DEVEM voltar a zero.
- **REQ-ARITH-025:** efeitos econômicos com o mesmo timestamp DEVEM possuir sequência determinística persistível.
- **REQ-ARITH-026:** eventos econômicos DEVEM integrar e creditar produção anterior, processar seus limiares, validar a ação, creditar a produção da própria ação, processar novos limiares, aplicar mutações não produtivas, recalcular taxas e persistir nessa ordem normativa.
- **REQ-ARITH-027:** Potência de Ciclo e Produção Passiva persistidas DEVEM ser tratadas como caches verificáveis; níveis, parâmetros, `A` e contadores são fontes canônicas.
- **REQ-ARITH-028:** nenhum intermediário econômico PODE sofrer overflow silencioso ou perda de precisão.
- **REQ-ARITH-029:** uma contribuição futura cujo denominador não seja representável por `arith-v1` DEVE versionar e migrar o contrato, nunca aproximá-lo silenciosamente.
- **REQ-ARITH-030:** simulações e implementação futura DEVEM passar todas as fixtures de `ECONOMIC-ARITHMETIC.md`.
- **REQ-ARITH-031:** quanta em `R` NÃO DEVEM pertencer a Aura Disponível, Aura Total ou Aura da Jornada até completarem uma unidade inteira.
- **REQ-ARITH-032:** invariância por particionamento DEVE abranger contadores, resto, desbloqueios e conjunto ordenado de limiares, sem exigir agrupamento visual ou timestamp de telemetria idêntico.
- **REQ-ARITH-033:** Marcos e Transformações DEVEM usar o limiar canônico como identidade; o checkpoint de atualização NÃO DEVE criar ocorrências distintas.
- **REQ-ARITH-034:** telemetria de produção DEVE atribuir quanta por fonte e NÃO DEVE atribuir arbitrariamente a uma única fonte a unidade completada pelo resto compartilhado.
- **REQ-ARITH-035:** Produção Offline base e Bônus de Retorno DEVEM processar no mesmo evento todos os Patamares, Transformações e Marcos cruzados por seus próprios créditos.
- **REQ-ARITH-036:** `P20` e `T20` PODEM ser caches derivados, mas `F_registrado=T20×A` DEVE ser um snapshot canônico congelado durante a ausência.
- **REQ-ARITH-037:** `F_registrado` NÃO DEVE ser recalculado usando níveis, parâmetros ou versão posteriores ao início da ausência.
- **REQ-ARITH-038:** o Bônus de Retorno somente DEVE ser elegível quando o intervalo for coerente e a ausência real exceder `28.800.000ms`.
- **REQ-ARITH-039:** uma Ascensão somente DEVE ser confirmável quando `J ≥ Jmín = 10¹⁵`, ainda que uma prévia possa ser calculada abaixo do limiar.

## Marcos 67

- **REQ-67-001:** o jogo DEVE definir Marcos 67 nos valores de Aura Total expressos por `67 × 1000ⁿ`, para todo inteiro `n ≥ 0` suportado pela economia.
- **REQ-67-002:** os primeiros Marcos 67 DEVEM corresponder a `67`, `67K`, `67M`, `67B` e `67T`.
- **REQ-67-003:** um Marco 67 DEVE ser disparado quando a Aura Total alcançar ou cruzar seu valor pela primeira vez.
- **REQ-67-004:** o cálculo DEVE usar o valor econômico exato e NÃO DEVE depender da Notação Compacta de Aura.
- **REQ-67-005:** cada Marco 67 DEVE ocorrer no máximo uma vez por salvamento.
- **REQ-67-006:** compras e Ascensões NÃO DEVEM reativar um Marco 67 já alcançado.
- **REQ-67-007:** um crédito que atravesse vários Marcos 67 DEVE registrar todos eles e enfileirar suas celebrações.
- **REQ-67-008:** Marcos 67 alcançados DEVEM permanecer no salvamento e no Backup Manual.
- **REQ-67-009:** cada Marco 67 DEVE apresentar uma animação especial das duas mãos e o número `67` em destaque.
- **REQ-67-010:** cada celebração DEVE possuir stinger musical original e padrão tátil exclusivos quando seus canais estiverem ativos.
- **REQ-67-011:** a intensidade visual especial DEVE permanecer por aproximadamente `6,7 segundos`.
- **REQ-67-012:** cada Marco 67 DEVE conceder um Selo 67 permanente associado à magnitude alcançada.
- **REQ-67-013:** Marcos e Selos 67 NÃO DEVEM conceder Aura, multiplicadores ou vantagem econômica.
- **REQ-67-014:** o jogo DEVE oferecer celebração reduzida e equivalente quando redução de movimento, som ou vibração estiver desativada.

## Conquistas

- **REQ-ACH-001:** o lançamento DEVE possuir exatamente 13 Conquistas locais.
- **REQ-ACH-002:** seis Conquistas DEVEM ser visíveis antes do desbloqueio.
- **REQ-ACH-003:** sete Conquistas DEVEM permanecer secretas até o desbloqueio.
- **REQ-ACH-004:** as Conquistas DEVEM cobrir Ciclos Six-Seven, Loja, Transformações, Ascensão, retorno e easter eggs.
- **REQ-ACH-005:** uma Conquista DEVE conceder somente emblema e texto comemorativo.
- **REQ-ACH-006:** Conquistas NÃO DEVEM conceder Aura, multiplicadores, itens ou outra vantagem econômica.
- **REQ-ACH-007:** Conquistas desbloqueadas NÃO DEVEM ser removidas por Ascensão.
- **REQ-ACH-008:** Conquistas DEVEM permanecer no salvamento local e no Backup Manual.
- **REQ-ACH-009:** o lançamento NÃO DEVE depender de conta ou integração com conquistas da Google Play.
- **REQ-ACH-010:** Selos 67 DEVEM permanecer em uma coleção distinta das Conquistas.

## Loja e melhoramentos

- **REQ-SHOP-001:** a Loja DEVE diferenciar Técnicas Six-Seven de Itens de Aura.
- **REQ-SHOP-002:** Técnicas Six-Seven DEVEM aumentar a Potência de Ciclo.
- **REQ-SHOP-003:** Itens de Aura DEVEM aumentar a Produção Passiva.
- **REQ-SHOP-004:** nomes ilustrativos usados antes da rodada de design cultural NÃO DEVEM ser considerados conteúdo final.
- **REQ-SHOP-005:** cada Item de Aura DEVE ser adquirido no máximo uma vez.
- **REQ-SHOP-006:** Itens de Aura adquiridos DEVEM aceitar Níveis de Melhoramento repetíveis.
- **REQ-SHOP-007:** Técnicas Six-Seven DEVEM aceitar Níveis de Melhoramento repetíveis.
- **REQ-SHOP-008:** cada Nível de Melhoramento DEVE aumentar o efeito numérico correspondente.
- **REQ-SHOP-009:** alterações visuais de um melhoramento DEVEM ocorrer em marcos selecionados, não obrigatoriamente em todos os níveis.
- **REQ-SHOP-010:** o catálogo do MVP DEVE oferecer exatamente as 18 entradas de Item de Aura aprovadas.
- **REQ-SHOP-011:** determinados Itens de Aura DEVEM permanecer bloqueados até que seus Pré-requisitos de Item sejam satisfeitos.
- **REQ-SHOP-012:** um Pré-requisito de Item DEVE indicar o item exigido e seu nível mínimo.
- **REQ-SHOP-013:** a Loja DEVE organizar os Itens de Aura em uma Árvore de Aura ramificada.
- **REQ-SHOP-014:** Patamares de Aura DEVEM ser desbloqueados por marcos de Aura Total.
- **REQ-SHOP-015:** um Patamar de Aura desbloqueado NÃO DEVE voltar a ser bloqueado quando Aura Disponível for gasta.
- **REQ-SHOP-016:** a Árvore de Aura DEVE oferecer Ramos de Aura que permitam escolhas de investimento.
- **REQ-SHOP-017:** Pré-requisitos de Item NÃO DEVEM formar dependências circulares.
- **REQ-SHOP-018:** o avanço para novos Patamares de Aura NÃO DEVE exigir que todos os itens anteriores sejam maximizados.
- **REQ-SHOP-019:** Técnicas Six-Seven e Itens de Aura NÃO DEVEM possuir um limite econômico planejado de Nível de Melhoramento.
- **REQ-SHOP-020:** a Loja DEVE oferecer modos de compra `×1`, `×10` e `MÁX` para níveis elegíveis.
- **REQ-SHOP-021:** `×10` DEVE cobrar a soma exata dos preços dos próximos dez níveis e somente concluir quando o total puder ser pago.
- **REQ-SHOP-022:** `MÁX` DEVE adquirir a maior quantidade inteira de níveis que a Aura Disponível puder pagar.
- **REQ-SHOP-023:** o custo de Compra em Lote NÃO DEVE ser calculado apenas pela multiplicação do preço do próximo nível.
- **REQ-SHOP-024:** o Complemento de Aura DEVE se aplicar somente a uma aquisição inicial ou ao próximo nível em `×1`.
- **REQ-SHOP-025:** o Complemento de Aura NÃO DEVE financiar compras `×10` ou `MÁX`.
- **REQ-SHOP-026:** múltiplos marcos atravessados por uma Compra em Lote DEVEM ter suas novidades apresentadas de forma consolidada.
- **REQ-SHOP-027:** o catálogo do MVP DEVE possuir exatamente 18 Itens de Aura.
- **REQ-SHOP-028:** a Árvore de Aura DEVE possuir exatamente três Ramos de Aura com cinco itens próprios em cada.
- **REQ-SHOP-029:** o catálogo DEVE possuir exatamente três Itens de Convergência com Pré-requisitos em mais de um ramo.
- **REQ-SHOP-030:** a progressão ativa do MVP DEVE possuir exatamente seis Técnicas Six-Seven.
- **REQ-SHOP-031:** a progressão visual do MVP DEVE possuir exatamente cinco Transformações de Aura.
- **REQ-SHOP-032:** conteúdo adicional NÃO DEVE ser incluído antes da primeira publicação; futuras atualizações exigem nova decisão de escopo.

## Curvas de melhoramento

- **REQ-CURVE-001:** o custo do próximo nível de cada Técnica Six-Seven e Item de Aura DEVE seguir um Custo Geométrico.
- **REQ-CURVE-002:** para uma entrada `i` no nível atual `n`, o preço-base DEVE seguir `Cᵢ(n) = ceil(Cᵢ,0 × (23/20)ⁿ)`.
- **REQ-CURVE-003:** cada custo-base `Cᵢ,0` DEVE ser um inteiro positivo e a razão universal DEVE permanecer exatamente `23/20`, equivalente a `1,15`.
- **REQ-CURVE-004:** a aquisição inicial DEVE corresponder à transição do nível econômico `0` para o nível `1`.
- **REQ-CURVE-005:** cada nível DEVE acrescentar uma Contribuição de Melhoramento aditiva antes de qualquer Marco de Nível.
- **REQ-CURVE-006:** um Marco de Nível DEVE multiplicar a contribuição completa somente da entrada que alcançou o marco.
- **REQ-CURVE-007:** Marcos de Nível NÃO DEVEM multiplicar diretamente outras Técnicas, outros Itens ou o Multiplicador de Ascensão.
- **REQ-CURVE-008:** a Potência de Ciclo antes da Ascensão DEVE ser a potência-base somada às Contribuições de Melhoramento de todas as Técnicas.
- **REQ-CURVE-009:** a Produção Passiva antes da Ascensão DEVE ser a soma das Contribuições de Melhoramento de todos os Itens de Aura.
- **REQ-CURVE-010:** o Multiplicador de Ascensão DEVE ser aplicado uma única vez após a soma correspondente de produção ativa ou passiva.
- **REQ-CURVE-011:** o custo de `×10` e `MÁX` DEVE ser obtido pela soma dos Custos Geométricos inteiros de cada nível comprado, sem aproximação pela fórmula fechada.
- **REQ-CURVE-012:** custo-base e contribuição-base DEVEM ser parâmetros explícitos por entrada; a razão e os Marcos de Nível DEVEM permanecer parâmetros globais simuláveis.
- **REQ-CURVE-013:** ganhos exponenciais puros por nível NÃO DEVEM substituir o modelo aditivo com Marcos de Nível.
- **REQ-CURVE-014:** custo, ganho e marcos exatos DEVEM ser validados nos quatro perfis de cadência e nos horizontes de minutos, horas e dias.
- **REQ-CURVE-015:** todas as Técnicas Six-Seven e Itens de Aura DEVEM usar Marcos de Nível em `10`, `25`, `50`, `100` e em cada múltiplo de `100` posterior.
- **REQ-CURVE-016:** cada Marco de Nível alcançado DEVE multiplicar por `2` a contribuição completa daquela entrada.
- **REQ-CURVE-017:** multiplicadores de Marcos de Nível DEVEM ser cumulativos entre si.
- **REQ-CURVE-018:** para uma entrada no nível `n`, o fator de marco DEVE ser `M(n) = 2^m(n)`, em que `m(n) = I(n≥10) + I(n≥25) + I(n≥50) + floor(n/100)`.
- **REQ-CURVE-019:** alcançar um Marco de Nível NÃO DEVE alterar a sequência de Custos Geométricos.
- **REQ-CURVE-020:** cada card de melhoramento DEVE informar o próximo Marco de Nível e a contribuição projetada depois de alcançá-lo.
- **REQ-CURVE-021:** uma Compra em Lote que atravesse vários Marcos de Nível DEVE aplicar todos os fatores alcançados.
- **REQ-CURVE-022:** uma Compra em Lote DEVE consolidar a celebração dos marcos atravessados sem ocultar o nível final e o novo efeito.
- **REQ-CURVE-023:** Marcos de Nível DEVEM usar feedback reutilizável e NÃO DEVEM exigir uma Aparência de Item exclusiva em cada ocorrência.
- **REQ-CURVE-024:** Marcos de Nível NÃO DEVEM conceder Aura diretamente.
- **REQ-CURVE-025:** as 18 entradas de Item de Aura e seis entradas de Técnica Six-Seven DEVEM usar a mesma razão de custo `23/20`.
- **REQ-CURVE-026:** o custo de um nível DEVE ser calculado diretamente a partir de `Cᵢ,0` e `n`, sem usar o preço arredondado anterior como entrada.
- **REQ-CURVE-027:** a potência racional DEVE ser calculada antes da aplicação única do teto inteiro, evitando drift por arredondamento iterativo.
- **REQ-CURVE-028:** diferenças de progressão entre entradas DEVEM ser expressas por custo-base, contribuição-base, desbloqueio e Pré-requisitos, não pela razão geométrica.
- **REQ-CURVE-029:** Ascensão de Aura e Marcos de Nível NÃO DEVEM alterar custos-base nem a razão geométrica.

## Escada de custos dos Ramos de Aura — `balance-v0.1`

- **REQ-COST-001:** o conjunto inicial de parâmetros de balanceamento DEVE ser identificado como `balance-v0.1` até sua primeira revisão documentada por simulação.
- **REQ-COST-002:** `ITEM-A/B/C-01` DEVEM possuir custo-base idêntico de `270 Aura`.
- **REQ-COST-003:** `ITEM-A/B/C-02` DEVEM possuir custo-base idêntico de `2.350 Aura`.
- **REQ-COST-004:** `ITEM-A/B/C-03` DEVEM possuir custo-base idêntico de `67.000 Aura`.
- **REQ-COST-005:** `ITEM-A/B/C-04` DEVEM possuir custo-base idêntico de `67.000 Aura`.
- **REQ-COST-006:** `ITEM-A/B/C-05` DEVEM possuir custo-base idêntico de `67.000.000.000 Aura`.
- **REQ-COST-007:** usando a fórmula exata de Custo Geométrico e um teto por nível, o Orçamento de Gate de um item com custo-base `270` até o nível `10` DEVE ser `5.487 Aura`.
- **REQ-COST-008:** usando a mesma regra, o Orçamento de Gate de um item com custo-base `2.350` até o nível `25` DEVE ser `500.078 Aura`.
- **REQ-COST-009:** usando a mesma regra, o Orçamento de Gate de um item com custo-base `67.000` até o nível `50` DEVE ser `483.587.018 Aura`.
- **REQ-COST-010:** usando a mesma regra, o Orçamento de Gate de um item com custo-base `67.000` até o nível `100` DEVE ser `524.526.228.030 Aura`.
- **REQ-COST-011:** para um item com custo-base `67.000`, a compra que leva do nível `99` ao `100` DEVE custar `68.416.522.780 Aura`, enquanto a compra do nível `100` ao `101` DEVE custar `78.679.001.197 Aura`.
- **REQ-COST-012:** o custo-base de `67.000.000.000 Aura` da profundidade `05` DEVE funcionar como handoff aproximado do investimento final exigido na profundidade `04`, sem ser confundido com um Orçamento de Gate adicional.
- **REQ-COST-013:** os valores de `REQ-COST-002` a `REQ-COST-012` DEVEM ser idênticos nos Ramos A, B e C e DEVEM possuir testes de invariância por profundidade.
- **REQ-COST-014:** o Patamar de Aura e o Pré-requisito de Item DEVEM continuar sendo verificados independentemente do preço; possuir Aura suficiente NÃO DEVE liberar uma compra antecipada.
- **REQ-COST-015:** qualquer alteração nessa escada DEVE decorrer de uma revisão identificada da simulação, registrar o motivo e atualizar conjuntamente requisitos, parâmetros, catálogo e fixtures numéricas.

## Escada de contribuições dos Ramos de Aura — `balance-v0.1`

- **REQ-CONTRIB-001:** a Contribuição-base de `ITEM-A/B/C-01` DEVE ser idêntica e igual a `+0,75 Aura/s` por nível.
- **REQ-CONTRIB-002:** a Contribuição-base de `ITEM-A/B/C-02` DEVE ser idêntica e igual a `+6,7 Aura/s` por nível.
- **REQ-CONTRIB-003:** a Contribuição-base de `ITEM-A/B/C-03` DEVE ser idêntica e igual a `+67 Aura/s` por nível.
- **REQ-CONTRIB-004:** a Contribuição-base de `ITEM-A/B/C-04` DEVE ser idêntica e igual a `+6.700 Aura/s` por nível.
- **REQ-CONTRIB-005:** a Contribuição-base de `ITEM-A/B/C-05` DEVE ser idêntica e igual a `+67.000.000 Aura/s` por nível.
- **REQ-CONTRIB-006:** os valores decimais `0,75` e `6,7` DEVEM ser tratados como valores exatos equivalentes a `3/4` e `67/10`, sem drift binário acumulado.
- **REQ-CONTRIB-007:** antes da Ascensão, a contribuição final de um item de nível `n` DEVE continuar seguindo `Eᵢ(n) = Bᵢ × n × M(n)`.
- **REQ-CONTRIB-008:** nos respectivos gates, uma entrada das profundidades `01`, `02`, `03` e `04` DEVE contribuir exatamente `15 Aura/s`, `670 Aura/s`, `26.800 Aura/s` e `10.720.000 Aura/s` antes da Ascensão.
- **REQ-CONTRIB-009:** como fixtures tardias, uma entrada da profundidade `05` DEVE contribuir `67.000.000 Aura/s` no nível `1`, `1.340.000.000 Aura/s` no nível `10`, `6.700.000.000 Aura/s` no nível `25`, `26.800.000.000 Aura/s` no nível `50` e `107.200.000.000 Aura/s` no nível `100`, antes da Ascensão.
- **REQ-CONTRIB-010:** as contribuições dos três ramos DEVEM permanecer economicamente invariantes em cada profundidade; tema, nome e aparência NÃO DEVEM alterar esses valores.
- **REQ-CONTRIB-011:** a escada DEVE ser validada contra todas as Janelas de Patamar, rotas e perfis antes de orientar implementação.
- **REQ-CONTRIB-012:** qualquer alteração nesses valores DEVE criar uma nova versão identificada de balanceamento e atualizar conjuntamente requisitos, parâmetros, catálogo e fixtures numéricas.

## Topologia da Árvore de Aura

- **REQ-TREE-001:** cada um dos Ramos A, B e C DEVE possuir exatamente cinco Itens de Aura ordenados de `01` a `05`.
- **REQ-TREE-002:** `ITEM-A-02`, `ITEM-B-02` e `ITEM-C-02` DEVEM exigir o respectivo Item-raiz no nível `10`.
- **REQ-TREE-003:** `ITEM-A-03`, `ITEM-B-03` e `ITEM-C-03` DEVEM exigir o respectivo item `02` no nível `25`.
- **REQ-TREE-004:** `ITEM-A-04`, `ITEM-B-04` e `ITEM-C-04` DEVEM exigir o respectivo item `03` no nível `50`.
- **REQ-TREE-005:** `ITEM-A-05`, `ITEM-B-05` e `ITEM-C-05` DEVEM exigir o respectivo item `04` no nível `100`.
- **REQ-TREE-006:** além do Pré-requisito de Item, cada nó DEVE exigir o Patamar de Aura correspondente ao seu estágio.
- **REQ-TREE-007:** `ITEM-CONV-01` DEVE exigir simultaneamente `ITEM-A-01`, `ITEM-B-01` e `ITEM-C-01` no nível `10`.
- **REQ-TREE-008:** `ITEM-CONV-02` DEVE exigir simultaneamente `ITEM-A-03`, `ITEM-B-03` e `ITEM-C-03` no nível `25`.
- **REQ-TREE-009:** `ITEM-CONV-03` DEVE exigir simultaneamente `ITEM-A-05`, `ITEM-B-05` e `ITEM-C-05` no nível `50`.
- **REQ-TREE-010:** todos os Pré-requisitos listados para uma Convergência DEVEM ser conjuntivos.
- **REQ-TREE-011:** Itens de Convergência NÃO DEVEM ser exigidos para desbloquear Itens dos Ramos A, B ou C.
- **REQ-TREE-012:** Itens de Convergência NÃO DEVEM ser exigidos para desbloquear Patamares de Aura ou realizar Ascensão de Aura.
- **REQ-TREE-013:** especialização em um único Ramo de Aura DEVE permanecer uma rota válida de progressão até a Ascensão.
- **REQ-TREE-014:** investir nos três ramos DEVE oferecer acesso às Convergências como recompensa adicional, não como correção de uma rota inválida.
- **REQ-TREE-015:** aquisição, níveis, efeitos e Pré-requisitos das Convergências DEVEM ser reiniciados pela Ascensão como os demais Itens de Aura.
- **REQ-TREE-016:** Patamares de Aura já desbloqueados DEVEM permanecer abertos depois da Ascensão, sem satisfazer automaticamente os Pré-requisitos de nível reiniciados.
- **REQ-TREE-017:** a interface DEVE diferenciar visualmente bloqueio por Patamar de Aura de bloqueio por Pré-requisito de Item.
- **REQ-TREE-018:** os Ramos A, B e C DEVEM aplicar Espelhamento Econômico no MVP.
- **REQ-TREE-019:** itens `A-n`, `B-n` e `C-n` de mesma profundidade `n` DEVEM possuir custo-base e contribuição-base idênticos.
- **REQ-TREE-020:** os três ramos DEVEM compartilhar a razão `23/20`, o calendário de Marcos de Nível e os multiplicadores já aprovados.
- **REQ-TREE-021:** nenhum ramo DEVE possuir modificador exclusivo de Produção Ativa, Produção Offline, Ascensão ou publicidade.
- **REQ-TREE-022:** escolher um Item-raiz NÃO DEVE bloquear aquisição futura dos outros ramos.
- **REQ-TREE-023:** nomes, temas, memes e Aparências de Item NÃO DEVEM alterar parâmetros econômicos por conta própria.
- **REQ-TREE-024:** Itens de Convergência PODEM possuir parâmetros próprios e NÃO DEVEM ser obrigados a espelhar itens de ramo.
- **REQ-TREE-025:** simulações Especialista A, B e C com o mesmo perfil e heurística DEVEM produzir resultados econômicos idênticos.
- **REQ-TREE-026:** qualquer divergência entre especialistas A, B e C DEVE ser tratada como erro de dados ou implementação.

## Economia das Convergências — `balance-v0.1`

- **REQ-CONVECO-001:** `ITEM-CONV-01` DEVE possuir custo-base de `6.700 Aura` e Contribuição-base de `7,5 Aura/s` por nível.
- **REQ-CONVECO-002:** `ITEM-CONV-02` DEVE possuir custo-base de `26.800.000 Aura` e Contribuição-base de `3.350 Aura/s` por nível.
- **REQ-CONVECO-003:** `ITEM-CONV-03` DEVE possuir custo-base de `670.000.000.000.000 Aura` e Contribuição-base de `13.400.000.000 Aura/s` por nível.
- **REQ-CONVECO-004:** o valor `7,5 Aura/s` DEVE ser tratado como o racional exato `15/2`, sem drift binário acumulado.
- **REQ-CONVECO-005:** no primeiro nível, cada Convergência DEVE acrescentar exatamente `1/6` da soma das contribuições dos três nós diretamente exigidos em seus níveis de requisito, antes da Ascensão.
- **REQ-CONVECO-006:** os Orçamentos de Amplitude exatos de `ITEM-CONV-01`, `ITEM-CONV-02` e `ITEM-CONV-03` DEVEM ser `16.461`, `44.288.124` e `1.452.336.002.684.412 Aura`, respectivamente.
- **REQ-CONVECO-007:** o custo-base de uma Convergência DEVE permanecer material e separado do Orçamento de Amplitude; satisfazer os requisitos NÃO DEVE conceder aquisição ou nível gratuito.
- **REQ-CONVECO-008:** no nível `10`, antes da Ascensão, `ITEM-CONV-01`, `ITEM-CONV-02` e `ITEM-CONV-03` DEVEM contribuir exatamente `150`, `67.000` e `268.000.000.000 Aura/s`.
- **REQ-CONVECO-009:** o custo cumulativo exato até o nível `10` DEVE ser `136.039`, `544.139.651` e `13.603.491.219.495.333 Aura`, respectivamente.
- **REQ-CONVECO-010:** as três Convergências DEVEM usar a razão `23/20`, os Marcos de Nível, as Compras em Lote e as regras de Complemento aplicáveis aos demais Itens de Aura.
- **REQ-CONVECO-011:** aquisição, níveis e efeito econômico das Convergências DEVEM ser reiniciados pela Ascensão, enquanto a Aparência de Item já colecionada PODE permanecer conforme a regra visual global.
- **REQ-CONVECO-012:** `ITEM-CONV-03` DEVE ser tratado como objetivo opcional de jornada longa; sua indisponibilidade econômica ao alcançar `1Qa` NÃO DEVE bloquear nem desaconselhar a Ascensão.
- **REQ-CONVECO-013:** qualquer alteração nesses parâmetros DEVE criar uma nova versão identificada de balanceamento e atualizar requisitos, catálogo, árvore, parâmetros e fixtures.

## Patamares e Transformações

- **REQ-TIER-001:** o MVP DEVE possuir cinco Patamares permanentes de Aura Total nos valores exatos `1K`, `1M`, `1B`, `1T` e `1Qa`.
- **REQ-TIER-002:** `K`, `M`, `B`, `T` e `Qa` DEVEM representar exatamente `10³`, `10⁶`, `10⁹`, `10¹²` e `10¹⁵`.
- **REQ-TIER-003:** o acesso inicial aos três Itens-raiz DEVE depender de `TECH-01` no nível `1`, sem limiar adicional de Aura Total.
- **REQ-TIER-004:** alcançar `1K` de Aura Total DEVE desbloquear `FORM-01`, o Patamar dos itens `02` e o Patamar de `ITEM-CONV-01`.
- **REQ-TIER-005:** alcançar `1M` de Aura Total DEVE desbloquear `FORM-02` e o Patamar dos itens `03`.
- **REQ-TIER-006:** alcançar `1B` de Aura Total DEVE desbloquear `FORM-03`, o Patamar dos itens `04` e o Patamar de `ITEM-CONV-02`.
- **REQ-TIER-007:** alcançar `1T` de Aura Total DEVE desbloquear `FORM-04` e o Patamar dos itens `05`.
- **REQ-TIER-008:** alcançar `1Qa` de Aura Total DEVE desbloquear `FORM-05`, o Patamar de `ITEM-CONV-03` e a disponibilidade da primeira Ascensão de Aura.
- **REQ-TIER-009:** desbloquear um Patamar NÃO DEVE satisfazer automaticamente os Pré-requisitos de nível dos seus itens.
- **REQ-TIER-010:** satisfazer Pré-requisitos de nível antes do Patamar NÃO DEVE liberar o item até a Aura Total correspondente ser alcançada.
- **REQ-TIER-011:** todos os Patamares e Transformações alcançados DEVEM permanecer desbloqueados após compras e Ascensões.
- **REQ-TIER-012:** um crédito que atravesse múltiplos Patamares DEVE registrar todos os desbloqueios elegíveis sem perda.
- **REQ-TIER-013:** múltiplos Patamares atravessados em um único crédito DEVEM ter suas apresentações enfileiradas ou consolidadas sem bloquear o estado econômico.
- **REQ-TIER-014:** importar um Backup Manual com Aura Total suficiente DEVE reconciliar deterministicamente todos os Patamares e Transformações correspondentes.
- **REQ-TIER-015:** a interface DEVE mostrar o próximo Patamar de Aura Total e os principais desbloqueios associados.

## Progressão das Técnicas

- **REQ-TECHPROG-001:** `TECH-01` DEVE permanecer desbloqueada desde o início da jornada inicial.
- **REQ-TECHPROG-002:** `TECH-02` DEVE ser desbloqueada permanentemente em `1K` de Aura Total.
- **REQ-TECHPROG-003:** `TECH-03` DEVE ser desbloqueada permanentemente em `1M` de Aura Total.
- **REQ-TECHPROG-004:** `TECH-04` DEVE ser desbloqueada permanentemente em `1B` de Aura Total.
- **REQ-TECHPROG-005:** `TECH-05` DEVE ser desbloqueada permanentemente em `1T` de Aura Total.
- **REQ-TECHPROG-006:** `TECH-06` DEVE ser desbloqueada permanentemente em `1Qa` de Aura Total.
- **REQ-TECHPROG-007:** uma Técnica NÃO DEVE exigir aquisição ou nível de outra Técnica como Pré-requisito.
- **REQ-TECHPROG-008:** alcançar o limiar DEVE tornar a Técnica correspondente visível e comprável, sujeita somente ao seu custo.
- **REQ-TECHPROG-009:** a Ascensão DEVE reiniciar os níveis de todas as Técnicas, mas NÃO DEVE revogar seus desbloqueios permanentes.
- **REQ-TECHPROG-010:** custos-base DEVEM continuar limitando a recompra de Técnicas tardias depois da Ascensão.
- **REQ-TECHPROG-011:** `TECH-06` DEVE permanecer desbloqueada depois da primeira Ascensão mesmo quando não tiver sido comprada antes do reinício.
- **REQ-TECHPROG-012:** cruzar vários limiares em um crédito DEVE registrar todos os desbloqueios de Técnica correspondentes.
- **REQ-TECHPROG-013:** importar um Backup Manual DEVE reconciliar Técnicas desbloqueadas com a Aura Total sem conceder níveis.
- **REQ-TECHPROG-014:** Transformações, nós da Árvore e Técnicas liberados no mesmo Patamar NÃO DEVEM depender da aquisição uns dos outros.
- **REQ-TECHPROG-015:** `TECH-01` DEVE manter o custo-base confirmado de `45 Aura`.
- **REQ-TECHPROG-016:** `TECH-02` DEVE possuir custo-base de `67 Aura`.
- **REQ-TECHPROG-017:** `TECH-03` DEVE possuir custo-base de `67.000 Aura`.
- **REQ-TECHPROG-018:** `TECH-04` DEVE possuir custo-base de `67.000.000 Aura`.
- **REQ-TECHPROG-019:** `TECH-05` DEVE possuir custo-base de `67.000.000.000 Aura`.
- **REQ-TECHPROG-020:** `TECH-06` DEVE possuir custo-base de `67.000.000.000.000 Aura`.
- **REQ-TECHPROG-021:** os custos-base de `TECH-02` a `TECH-06` DEVEM corresponder exatamente a `6,7%` dos Patamares `1K`, `1M`, `1B`, `1T` e `1Qa`, respectivamente.
- **REQ-TECHPROG-022:** todas as Técnicas DEVEM continuar usando a razão global `23/20`, o teto único por nível e os Marcos de Nível universais.
- **REQ-TECHPROG-023:** a permanência do desbloqueio após Ascensão NÃO DEVE eliminar o custo de recomprar níveis de uma Técnica.
- **REQ-TECHPROG-024:** qualquer alteração nessa escada DEVE criar uma nova versão identificada de balanceamento e atualizar requisitos, parâmetros, catálogo e simulação.
- **REQ-TECHPROG-025:** `TECH-01` DEVE manter a Contribuição-base de `+1 Aura/ciclo` por nível.
- **REQ-TECHPROG-026:** `TECH-02` DEVE possuir Contribuição-base de `+6,7 Aura/ciclo` por nível.
- **REQ-TECHPROG-027:** `TECH-03` DEVE possuir Contribuição-base de `+6.700 Aura/ciclo` por nível.
- **REQ-TECHPROG-028:** `TECH-04` DEVE possuir Contribuição-base de `+6.700.000 Aura/ciclo` por nível.
- **REQ-TECHPROG-029:** `TECH-05` DEVE possuir Contribuição-base de `+6.700.000.000 Aura/ciclo` por nível.
- **REQ-TECHPROG-030:** `TECH-06` DEVE possuir Contribuição-base de `+6.700.000.000.000 Aura/ciclo` por nível.
- **REQ-TECHPROG-031:** o valor decimal `6,7` DEVE ser tratado como o racional exato `67/10`, sem drift binário acumulado.
- **REQ-TECHPROG-032:** de `TECH-02` a `TECH-06`, custo-base e Contribuição-base DEVEM crescer juntos por `1.000×` entre entradas consecutivas.
- **REQ-TECHPROG-033:** de `TECH-02` a `TECH-06`, a razão `Contribuição-base ÷ custo-base` DEVE permanecer exatamente `1/10` antes da Cadência, dos Marcos e da Ascensão.
- **REQ-TECHPROG-034:** no nível `10`, antes da Ascensão, `TECH-01` a `TECH-06` DEVEM contribuir respectivamente `20`, `134`, `134.000`, `134.000.000`, `134.000.000.000` e `134.000.000.000.000 Aura/ciclo`.
- **REQ-TECHPROG-035:** a simulação DEVE validar a escada ativa em todas as Cadências e NÃO DEVE aceitar uma configuração na qual o toque torne a Produção Passiva irrelevante para todos os perfis.

## Conteúdo e linguagem cultural

- **REQ-CONTENT-001:** antes do fechamento do catálogo, o projeto DEVE realizar uma rodada dedicada à criação e nomenclatura de Técnicas Six-Seven e Itens de Aura.
- **REQ-CONTENT-002:** a rodada DEVE pesquisar o repertório contemporâneo relacionado a Aura, Six-Seven e memes adjacentes, incluindo “mewing”.
- **REQ-CONTENT-003:** o conteúdo final DEVE soar autêntico para o Jogador-alvo e NÃO DEVE adotar linguagem artificialmente juvenil ou evidentemente criada por alguém alheio ao repertório cultural.
- **REQ-CONTENT-004:** cada nome candidato DEVE ser avaliado quanto a clareza, graça, longevidade, localização e risco de propriedade intelectual.

## Produção passiva e offline

- **REQ-IDLE-001:** melhoramentos de Produção Passiva DEVEM gerar Aura sem exigir Ciclos Six-Seven.
- **REQ-IDLE-002:** a Produção Passiva DEVE continuar enquanto o jogo estiver fechado.
- **REQ-IDLE-003:** a Produção Offline DEVE ser limitada ao equivalente a oito horas por ausência.
- **REQ-IDLE-004:** após ausência de até oito horas, o resgate DEVE corresponder ao período efetivamente acumulado.
- **REQ-IDLE-005:** após ausência superior a oito horas, o jogador DEVE poder resgatar a produção-base limitada a oito horas sem assistir a anúncio.
- **REQ-IDLE-006:** após ausência superior a oito horas, o jogador DEVE poder optar por um Anúncio Recompensado para acrescentar 20% à produção-base limitada a oito horas.
- **REQ-IDLE-007:** o Bônus de Retorno NÃO DEVE ser calculado sobre o tempo excedente às oito horas.
- **REQ-IDLE-008:** o Anúncio Recompensado NÃO DEVE bloquear ou substituir o resgate da produção-base.
- **REQ-IDLE-009:** ao sair do primeiro plano, o jogo DEVE registrar a Produção Passiva final vigente como Taxa Offline Registrada.
- **REQ-IDLE-010:** a Taxa Offline Registrada DEVE incluir os efeitos de Itens de Aura e do Multiplicador de Ascensão vigentes na saída.
- **REQ-IDLE-011:** a Produção Offline DEVE ser calculada pela Taxa Offline Registrada multiplicada pelo tempo válido, limitado a oito horas.
- **REQ-IDLE-012:** frações resultantes da Produção Offline DEVEM ser preservadas pelo Resto de Produção compartilhado.
- **REQ-IDLE-013:** o jogo NÃO DEVE simular compras, níveis, desbloqueios ou composição de crescimento durante a ausência.
- **REQ-IDLE-014:** a Produção Ativa NÃO DEVE integrar a Produção Offline.
- **REQ-IDLE-015:** marcos e Transformações gerados pela recompensa offline DEVEM ser processados quando ela for creditada.
- **REQ-IDLE-016:** cada ausência elegível DEVE gerar uma Recompensa de Retorno persistente antes da apresentação de sua tela.
- **REQ-IDLE-017:** a Produção Offline base de uma Recompensa de Retorno DEVE ser creditada no máximo uma vez.
- **REQ-IDLE-018:** escolher o resgate sem anúncio DEVE creditar a base e encerrar a oportunidade de Bônus de Retorno daquela ausência.
- **REQ-IDLE-019:** ao escolher o anúncio, o jogo DEVE creditar e persistir a base antes de solicitar sua exibição.
- **REQ-IDLE-020:** o Bônus de Retorno DEVE ser creditado no máximo uma vez após a conclusão válida do anúncio.
- **REQ-IDLE-021:** falha ou cancelamento do anúncio NÃO DEVE reverter nem duplicar a base já creditada.
- **REQ-IDLE-022:** após falha ou cancelamento, o jogador DEVE poder tentar novamente o bônus enquanto não encerrar explicitamente a oferta.
- **REQ-IDLE-023:** fechar o aplicativo durante o fluxo NÃO DEVE perder ou duplicar a Recompensa de Retorno pendente.
- **REQ-IDLE-024:** antes de uma Ascensão, toda Recompensa de Retorno pendente DEVE ter sua produção-base creditada exatamente uma vez.
- **REQ-IDLE-025:** antes de uma Ascensão, uma oportunidade pendente de Bônus de Retorno DEVE ser aceita ou explicitamente recusada.
- **REQ-IDLE-026:** recusar o Bônus de Retorno antes da Ascensão NÃO DEVE remover, reduzir ou reverter a produção-base.

## Ascensão de Aura

- **REQ-ASC-001:** a primeira Ascensão de Aura DEVE ficar disponível ao alcançar exatamente `1Qa` (`10¹⁵`) de Aura Total.
- **REQ-ASC-002:** realizar uma Ascensão de Aura DEVE ser sempre voluntário.
- **REQ-ASC-003:** a Ascensão DEVE reiniciar a Aura Disponível.
- **REQ-ASC-004:** a Ascensão DEVE reiniciar a aquisição e os Níveis de Melhoramento de Itens de Aura.
- **REQ-ASC-005:** a Ascensão DEVE reiniciar os Níveis de Melhoramento de Técnicas Six-Seven.
- **REQ-ASC-006:** a Ascensão DEVE reiniciar os Pré-requisitos de Item dependentes dos níveis reiniciados.
- **REQ-ASC-007:** a Ascensão NÃO DEVE reduzir a Aura Total.
- **REQ-ASC-008:** Patamares de Aura liberados por Aura Total NÃO DEVEM voltar a ser bloqueados após uma Ascensão.
- **REQ-ASC-009:** conquistas e transformações visuais desbloqueadas NÃO DEVEM ser removidas por uma Ascensão.
- **REQ-ASC-010:** cada Ascensão DEVE conceder um Multiplicador de Ascensão permanente.
- **REQ-ASC-011:** antes da confirmação, o jogo DEVE apresentar o que será reiniciado, preservado e recebido.
- **REQ-ASC-012:** a Ascensão NÃO DEVE exigir anúncio ou pagamento.
- **REQ-ASC-013:** o jogo DEVE manter a Aura da Jornada separada da Aura Total e da Aura Disponível.
- **REQ-ASC-014:** a Aura da Jornada DEVE contabilizar a Aura produzida desde o início da jornada atual.
- **REQ-ASC-015:** realizar uma Ascensão DEVE reiniciar a Aura da Jornada.
- **REQ-ASC-016:** o Multiplicador de Ascensão concedido DEVE ser calculado a partir da Aura da Jornada, não diretamente da Aura Total.
- **REQ-ASC-017:** o cálculo DEVE aplicar retornos decrescentes à Aura da Jornada.
- **REQ-ASC-018:** a prévia de confirmação DEVE informar o ganho projetado do Multiplicador de Ascensão.
- **REQ-ASC-019:** Ascensões sucessivas sem nova produção relevante NÃO DEVEM repetir o ganho anterior.
- **REQ-ASC-020:** o Multiplicador de Ascensão DEVE ampliar a Potência de Ciclo.
- **REQ-ASC-021:** o Multiplicador de Ascensão DEVE ampliar a Produção Passiva.
- **REQ-ASC-022:** a Produção Offline DEVE usar a taxa passiva resultante da aplicação do Multiplicador de Ascensão.
- **REQ-ASC-023:** o Bônus de Retorno DEVE permanecer em 20% sobre a Produção Offline resultante e NÃO DEVE receber uma aplicação adicional exclusiva do Multiplicador de Ascensão.
- **REQ-ASC-024:** cada Ascensão DEVE conceder uma parcela de bônus permanente calculada pela Aura da Jornada.
- **REQ-ASC-025:** o Multiplicador de Ascensão total DEVE ser igual à base `1×` somada às parcelas obtidas em todas as Ascensões.
- **REQ-ASC-026:** parcelas de Ascensão NÃO DEVEM ser multiplicadas ou compostas entre si.
- **REQ-ASC-027:** o Multiplicador de Ascensão total DEVE ser aplicado uma única vez a cada cálculo de Produção Ativa ou Passiva.
- **REQ-ASC-028:** a Ascensão NÃO DEVE remover Aparências de Item ou variações já desbloqueadas.
- **REQ-ASC-029:** o visual equipado DEVE poder permanecer após a Ascensão.
- **REQ-ASC-030:** a Ascensão DEVE desativar o Efeito de Item reiniciado mesmo quando sua Aparência continuar equipada.
- **REQ-ASC-031:** readquirir um Item de Aura DEVE reativar seu Efeito de Item sem duplicar a Aparência correspondente.
- **REQ-ASC-032:** toda Ascensão, inclusive as posteriores à primeira, DEVE exigir pelo menos `1Qa` (`10¹⁵`) de Aura da Jornada.
- **REQ-ASC-033:** para Aura da Jornada `J`, a parcela concedida DEVE seguir `Δ = floor(100 × √(J ÷ 10¹⁵)) ÷ 100`.
- **REQ-ASC-034:** a parcela DEVE ser armazenada como o inteiro `U = floor(100 × √(J ÷ 10¹⁵))`, em que `100` unidades equivalem a `+1,00×`.
- **REQ-ASC-035:** o Multiplicador de Ascensão total DEVE ser armazenado em centésimos inteiros como `100 + ΣU`.
- **REQ-ASC-036:** a implementação NÃO DEVE depender de ponto flutuante para calcular, persistir ou comparar parcelas de Ascensão.
- **REQ-ASC-037:** uma jornada de exatamente `1Qa` DEVE conceder `+1,00×` e elevar o primeiro multiplicador total de `1×` para `2×`.
- **REQ-ASC-038:** jornadas de `2Qa`, `4Qa` e `9Qa` DEVEM conceder, respectivamente, `+1,41×`, `+2,00×` e `+3,00×`.
- **REQ-ASC-039:** a fórmula NÃO DEVE possuir limite superior artificial.
- **REQ-ASC-040:** quando a Aura da Jornada for inferior a `1Qa`, a confirmação DEVE permanecer indisponível e informar quanto falta.
- **REQ-ASC-041:** a prévia DEVE informar Aura da Jornada considerada, parcela projetada, multiplicador total resultante e todos os estados reiniciados ou preservados.
- **REQ-ASC-042:** confirmar uma Ascensão DEVE persistir atomicamente a nova parcela permanente e o reinício da Aura da Jornada e da economia corrente.
- **REQ-ASC-043:** falha durante a persistência NÃO DEVE conceder o bônus sem reiniciar a jornada nem reiniciar a jornada sem conceder o bônus.
- **REQ-ASC-044:** a confirmação de Ascensão DEVE permanecer indisponível enquanto uma oportunidade de Bônus de Retorno aguardar decisão, depois que a base já tiver sido garantida.

## Anúncios Recompensados

- **REQ-ADS-001:** anúncios associados a benefícios de jogo DEVEM ser voluntários.
- **REQ-ADS-002:** a Loja somente DEVE oferecer um Complemento de Aura quando o jogador possuir pelo menos 70% e menos de 100% do preço da compra.
- **REQ-ADS-003:** o Complemento de Aura DEVE cobrir somente o valor que falta para a compra elegível.
- **REQ-ADS-004:** o Complemento de Aura NÃO DEVE exceder 30% do preço da compra.
- **REQ-ADS-005:** ao concluir o anúncio, a compra DEVE consumir a Aura Disponível que o jogador possuía para realizá-la.
- **REQ-ADS-006:** o Complemento de Aura NÃO DEVE ignorar Patamares de Aura, Pré-requisitos de Item ou qualquer outra condição de desbloqueio.
- **REQ-ADS-007:** o Complemento de Aura NÃO DEVE ser oferecido quando o jogador puder pagar o preço integral.
- **REQ-ADS-008:** cancelar ou não concluir um Anúncio Recompensado NÃO DEVE concluir a compra nem consumir Aura.
- **REQ-ADS-009:** o jogador NÃO DEVE concluir mais de três Complementos de Aura em qualquer janela móvel de 24 horas.
- **REQ-ADS-010:** os três Complementos disponíveis NÃO DEVEM possuir intervalo obrigatório entre usos.
- **REQ-ADS-011:** o Bônus de Retorno NÃO DEVE consumir nem reduzir a cota de Complementos de Aura.
- **REQ-ADS-012:** anúncio cancelado, indisponível ou concluído com erro NÃO DEVE consumir a cota de Complementos de Aura.
- **REQ-ADS-013:** a oferta de Complemento de Aura NÃO DEVE abrir automaticamente nem interromper a tela principal.
- **REQ-ADS-014:** a Loja DEVE informar quantos Complementos de Aura ainda estão disponíveis na janela vigente.
- **REQ-ADS-015:** no lançamento, todo anúncio DEVE usar um formato recompensado e ser iniciado explicitamente pelo jogador.
- **REQ-ADS-016:** o jogo NÃO DEVE exibir banners publicitários.
- **REQ-ADS-017:** o jogo NÃO DEVE exibir anúncios intersticiais automáticos.
- **REQ-ADS-018:** abrir o jogo, navegar entre telas, concluir ciclos ou realizar compras NÃO DEVE disparar anúncios automaticamente.
- **REQ-ADS-019:** no lançamento, anúncios recompensados DEVEM ser oferecidos somente no Bônus de Retorno e no Complemento de Aura.
- **REQ-ADS-020:** anúncios recompensados NÃO DEVEM ser habilitados antes da conclusão do Tutorial Contextual.
- **REQ-ADS-021:** a habilitação DEVE exigir ao menos uma Técnica Six-Seven e um Item de Aura comprados normalmente, sem Complemento de Aura.
- **REQ-ADS-022:** o Complemento de Aura somente DEVE ser oferecido em compras posteriores às duas compras normais exigidas.
- **REQ-ADS-023:** uma Recompensa de Retorno anterior à habilitação de monetização DEVE creditar apenas a produção-base, sem oferta de Bônus de Retorno.
- **REQ-ADS-024:** dispensar ou pular orientações NÃO DEVE antecipar a habilitação de anúncios.
- **REQ-ADS-025:** a primeira oferta publicitária DEVE explicar o benefício, a natureza opcional e a alternativa sem anúncio.

## Privacidade e proteção etária

- **REQ-PRIV-001:** todas as solicitações de anúncio no lançamento DEVEM usar tratamento etário `TEEN`.
- **REQ-PRIV-002:** anúncios personalizados e remarketing DEVEM permanecer desativados para todos os jogadores.
- **REQ-PRIV-003:** o jogo NÃO DEVE solicitar data de nascimento nem criar perfil etário próprio.
- **REQ-PRIV-004:** a UMP ou CMP certificada aplicável DEVE concluir sua avaliação antes de qualquer solicitação publicitária.
- **REQ-PRIV-005:** ausência de consentimento ou permissão para solicitar anúncios NÃO DEVE bloquear a experiência ou recompensa-base.
- **REQ-PRIV-006:** a Play Age Signals API DEVE ser integrada quando aplicável aos requisitos de distribuição no Brasil.
- **REQ-PRIV-007:** dados da Play Age Signals NÃO DEVEM ser usados para publicidade, marketing, perfilamento ou analytics.
- **REQ-PRIV-008:** respostas de faixa etária NÃO DEVEM ser incluídas no salvamento ou Backup Manual.
- **REQ-PRIV-009:** o jogo NÃO DEVE possuir loot boxes ou recompensas aleatórias pagas.
- **REQ-PRIV-010:** a política de privacidade DEVE permanecer pública, acessível no jogo e coerente com os SDKs efetivamente incluídos.
- **REQ-PRIV-011:** o formulário Data safety DEVE declarar corretamente a coleta e o compartilhamento realizados pelo Google Mobile Ads e demais SDKs.

## Analytics

- **REQ-AN-001:** o lançamento DEVE usar Firebase Analytics somente para Telemetria de Produto minimizada.
- **REQ-AN-002:** a coleta do Firebase Analytics DEVE iniciar desativada em uma nova instalação.
- **REQ-AN-003:** nenhuma coleta de analytics DEVE ser habilitada antes de um Consentimento de Analytics explícito.
- **REQ-AN-004:** recusar analytics NÃO DEVE bloquear, limitar ou alterar a economia, anúncios, recompensas ou qualquer função do jogo.
- **REQ-AN-005:** o jogador DEVE poder interromper coletas futuras em Configurações.
- **REQ-AN-006:** o Consentimento de Analytics DEVE ser independente de consentimentos ou permissões publicitárias.
- **REQ-AN-007:** o projeto NÃO DEVE definir `User ID`, e-mail, conta, nome, data de nascimento ou outro identificador pessoal declarado no Firebase Analytics.
- **REQ-AN-008:** a coleta do Android Advertising ID pelo Firebase Analytics DEVE permanecer desativada.
- **REQ-AN-009:** a personalização de anúncios baseada em analytics DEVE permanecer desativada.
- **REQ-AN-010:** dados da Play Age Signals NÃO DEVEM ser enviados ao analytics nem usados para decidir sua coleta.
- **REQ-AN-011:** eventos e parâmetros de produto DEVEM pertencer a uma lista permitida e documentada.
- **REQ-AN-012:** o conteúdo do save, Backup Manual, valores exatos de Aura, timestamps exatos de progressão e texto livre NÃO DEVEM ser enviados ao analytics.
- **REQ-AN-013:** quando uma medida econômica ou temporal for necessária, ela DEVE usar uma faixa pré-definida em vez do valor exato.
- **REQ-AN-014:** a política de privacidade e o formulário Data safety DEVEM reconhecer os identificadores técnicos e demais dados processados automaticamente pelo Firebase após o consentimento.
- **REQ-AN-015:** o estado do Consentimento de Analytics DEVE ser uma preferência local do aparelho e NÃO DEVE acompanhar o Backup Manual.
- **REQ-AN-016:** a integração DEVE ser testada para comprovar ausência de eventos antes do consentimento e depois de sua revogação.
- **REQ-AN-017:** resultados analíticos DEVEM ser interpretados como dados da parcela opt-in, sem presumir que representem todos os jogadores.
- **REQ-AN-018:** o único convite automático de Consentimento de Analytics DEVE ocorrer depois da conclusão do primeiro Ciclo Six-Seven real.
- **REQ-AN-019:** a primeira Aura DEVE ser creditada e exibida antes que o convite apareça.
- **REQ-AN-020:** o jogo NÃO DEVE transmitir retroativamente o primeiro ciclo, a primeira Aura ou qualquer comportamento anterior ao aceite.
- **REQ-AN-021:** o convite DEVE oferecer “Permitir” e “Agora não” com peso visual equivalente.
- **REQ-AN-022:** dispensar o convite DEVE equivaler a “Agora não” e manter a coleta desativada.
- **REQ-AN-023:** após recusa ou dispensa, o jogo NÃO DEVE apresentar novamente o convite de forma automática.
- **REQ-AN-024:** após recusa, a ativação voluntária DEVE permanecer disponível somente em Configurações.
- **REQ-AN-025:** aceitar, recusar ou dispensar NÃO DEVE bloquear nem alterar a sequência do Tutorial Contextual.
- **REQ-AN-026:** o convite DEVE permanecer separado de consentimento publicitário e Autorização de Diagnóstico.
- **REQ-AN-027:** o convite e seus detalhes DEVEM ser localizados e testados nos oito idiomas de lançamento.
- **REQ-AN-028:** a propriedade GA4 do lançamento DEVE configurar retenção de dados detalhados de usuários e eventos em dois meses.
- **REQ-AN-029:** a opção de redefinir a retenção com cada nova atividade DEVE permanecer desativada.
- **REQ-AN-030:** dados de Analytics NÃO DEVEM ser exportados para BigQuery, Cloud Storage, data warehouse ou outro armazenamento externo no lançamento.
- **REQ-AN-031:** o projeto NÃO DEVE manter cópias paralelas de eventos brutos fora da retenção configurada no GA4.
- **REQ-AN-032:** relatórios agregados padrão PODEM ser usados conforme a disponibilidade nativa do GA4.
- **REQ-AN-033:** retenção, redefinição por atividade e ausência de exportação DEVEM integrar o checklist do console antes do teste fechado e da produção.

## Relatórios de falha

- **REQ-CRASH-001:** o lançamento DEVE usar Firebase Crashlytics para Relatórios de Diagnóstico de falhas fatais e ANRs.
- **REQ-CRASH-002:** a transmissão automática do Crashlytics DEVE iniciar desativada por configuração nativa anterior à execução do aplicativo, embora o SDK possa manter o diagnóstico pendente localmente.
- **REQ-CRASH-003:** o aplicativo NÃO DEVE habilitar transmissão automática futura ao enviar um relatório autorizado.
- **REQ-CRASH-004:** Relatórios de Diagnóstico pendentes DEVEM permanecer somente no aparelho até uma Autorização de Diagnóstico.
- **REQ-CRASH-005:** após detectar uma falha anterior, a abertura seguinte DEVE oferecer as opções de enviar ou não enviar o relatório pendente.
- **REQ-CRASH-006:** quando houver mais de um relatório pendente, a interface DEVE informar a quantidade e a autorização DEVE abranger somente o lote apresentado.
- **REQ-CRASH-007:** aceitar DEVE enviar somente o lote pendente apresentado, inclusive posteriormente quando a conexão retornar.
- **REQ-CRASH-008:** recusar ou dispensar a oferta DEVE apagar os relatórios pendentes sem enviá-los.
- **REQ-CRASH-009:** uma Autorização de Diagnóstico NÃO DEVE permanecer válida para falhas futuras.
- **REQ-CRASH-010:** enviar, recusar ou dispensar Relatórios de Diagnóstico NÃO DEVE conceder recompensa, remover progresso ou alterar a experiência econômica.
- **REQ-CRASH-011:** o projeto NÃO DEVE definir `User ID`, chaves personalizadas, logs personalizados ou valores de texto livre no Crashlytics no lançamento.
- **REQ-CRASH-012:** o projeto NÃO DEVE registrar manualmente exceções não fatais no Crashlytics no lançamento.
- **REQ-CRASH-013:** Relatórios de Diagnóstico NÃO DEVEM incluir conteúdo do save, Backup Manual, Aura exata ou Play Age Signals.
- **REQ-CRASH-014:** quando o Consentimento de Analytics estiver ativo, somente breadcrumbs produzidos pela taxonomia de analytics aprovada PODEM acompanhar o relatório, e essa possibilidade DEVE ser informada.
- **REQ-CRASH-015:** autorizar diagnóstico NÃO DEVE habilitar Analytics nem alterar o Consentimento de Analytics.
- **REQ-CRASH-016:** relatórios pendentes e Autorizações de Diagnóstico NÃO DEVEM integrar o save nem o Backup Manual.
- **REQ-CRASH-017:** política de privacidade e Data safety DEVEM declarar os dados técnicos, identificadores e retenção efetivamente usados pelo Crashlytics.
- **REQ-CRASH-018:** a integração DEVE provar que nenhum relatório é transmitido antes da autorização e que a recusa executa a exclusão local.
- **REQ-CRASH-019:** métricas do Crashlytics DEVEM ser interpretadas como cobertura autorizada e NÃO DEVEM ser tratadas como retrato completo de estabilidade.
- **REQ-CRASH-020:** o compartilhamento agregado Crash Insights DEVE permanecer desativado no lançamento.
- **REQ-CRASH-021:** desativar Crash Insights NÃO DEVE impedir o recebimento e a análise dos Relatórios de Diagnóstico autorizados do próprio jogo.
- **REQ-CRASH-022:** o pipeline de publicação DEVE conferir a configuração de Crash Insights no console antes de cada lançamento.

## Monetização

- **REQ-MON-001:** o lançamento NÃO DEVE incluir compras dentro do aplicativo.
- **REQ-MON-002:** Aura, multiplicadores, níveis, melhoramentos e Ascensões NÃO DEVEM ser vendidos por dinheiro real no lançamento.
- **REQ-MON-003:** o lançamento NÃO DEVE incluir uma compra para remover anúncios, pois nenhum anúncio é imposto ao jogador.
