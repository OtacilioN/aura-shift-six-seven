# Aura Shift: Six Seven — Plano de Localização

> Status: `l10n-v1` fechado documentalmente com oito catálogos de 261 strings, glossário, pseudo-localização, tipografia e revisão cruzada; QA renderizado permanece gate de desenvolvimento.

## Idiomas de lançamento

| Idioma | Locale | Papel |
| --- | --- | --- |
| English (United States) | `en-US` | idioma-fonte |
| Português (Brasil) | `pt-BR` | lançamento |
| Español (Latinoamérica) | `es-419` | lançamento |
| Français (France) | `fr-FR` | lançamento |
| Deutsch | `de-DE` | lançamento |
| Bahasa Indonesia | `id` | lançamento |
| 日本語 | `ja-JP` | lançamento |
| العربية | `ar` | lançamento e RTL |

## Escopo

A localização abrange:

- toda a interface e acessibilidade textual;
- tutorial e primeira sessão;
- nomes e descrições de Técnicas Six-Seven e Itens de Aura;
- conquistas, transformações e mensagens de retorno;
- textos de anúncio recompensado, Consentimento de Analytics, Autorização de Diagnóstico e demais consentimentos;
- configurações, suporte e mensagens de erro;
- título, descrição, imagens textuais e demais metadados da loja;
- materiais de divulgação definidos para cada mercado.

## Princípios

- manter inglês dos Estados Unidos como fonte canônica;
- usar IDs estáveis em vez de texto-fonte como chave conceitual;
- separar texto de imagens e animações;
- prever expansão de texto e quebras controladas;
- respeitar plural, gênero, ordem de argumentos, números e datas de cada locale;
- preservar dígitos ASCII, K, M, B, T e demais sufixos dos tokens econômicos conforme `number-format-v1`;
- espelhar navegação e composição quando o locale exigir RTL;
- tratar humor e memes como transcriação, não tradução literal.

## Números econômicos e RTL

O contrato `number-format-v1`, detalhado em `NUMBER-FORMATTING.md`, é comum aos oito idiomas. Aura, preços, níveis, taxas, multiplicadores, percentuais econômicos e Marcos 67 usam dígitos ASCII `0–9`; sufixos e expoentes também permanecem ASCII. Essa exceção intencional preserva a identidade de `67`, a comparação entre idiomas e a cópia canônica.

Separadores decimais e de agrupamento são localizados somente na apresentação. A cópia de inteiros não contém agrupamento; a cópia de taxas usa ponto ASCII e o decimal terminante exato. Em árabe, cada token econômico completo recebe isolamento LTR, enquanto navegação, ordem dos componentes e textos ao redor continuam RTL. A tecnologia assistiva anuncia coeficiente, magnitude matemática, unidade e natureza de saldo ou taxa em árabe localizado, não apenas soletra o sufixo visual.

Datas e demais textos numéricos não econômicos seguem as convenções normais do locale. Fixtures de QA devem cobrir números abaixo de mil, todas as trocas de sufixo, `10³⁶`, taxas `N/2000`, colisões visuais de saldo/preço e contribuição atual/projetada, cópia ASCII e composição RTL.

## Detecção e seleção

Na primeira abertura, o jogo seleciona o locale do aparelho quando ele estiver entre os oito suportados; caso contrário, usa `en-US`. O seletor permanece disponível antes do tutorial e nas Configurações, apresenta cada idioma em seu nome nativo e aplica a alteração imediatamente.

`Português (Brasil)` utiliza a bandeira do Brasil como apoio visual. Bandeiras não substituem rótulos textuais, pois diversos idiomas representam mais de um país ou região. A escolha vigente é persistida no salvamento local.

## Conteúdo cultural

Nomes, descrições e piadas devem ser criados ou adaptados por agentes com contexto explícito sobre a cultura do público, idealmente durante a rodada de design cultural. Uma referência pode ser substituída por equivalente local quando a tradução literal perder função, graça ou reconhecimento.

Agentes especializados produzem traduções e apoiam consistência, mas não substituem validação humana nativa nem parecer jurídico. O processo mitiga esse limite por independência entre tradução e revisão, retrotradução, pesquisa cultural e QA contextual.

### Decisões de P01–P04

- `Aura Shift: Six Seven` é marca invariável; stores podem acrescentar descrição localizada fora do título quando necessário.
- `Two taps. Infinite aura.` é tagline-fonte e deve ser transcriada preservando gesto, escala e concisão.
- `Six Seven` é pronunciado em duas unidades, nunca como o numeral composto `sixty-seven`; transliteração local pode apoiar leitura sem mudar a marca.
- Poise, Motion, Signal e Spectrum são territórios conceituais. Labels de ramo e nomes de itens podem ser transcriados por função.
- Mewing, looksmaxxing, rizz, sigma, skibidi e brainrot não entram nos catálogos; não procurar “equivalentes locais”.
- Referências recifenses pertencem à proveniência e direção sonora, sem sotaque escrito, caricatura ou tradução regionalizada artificial.
- Cada string cultural recebe nota de intenção, limite de caracteres, intensidade e alternativa neutra no copy deck de P10/P11.

## Garantia de qualidade

Cada idioma deve passar por:

1. revisão linguística no contexto da tela;
2. verificação de truncamento, sobreposição e fontes;
3. teste de placeholders, plurais e fixtures extremas de `number-format-v1`;
4. revisão cultural de nomes, memes e tom;
5. validação dos assets e metadados da loja;
6. teste RTL completo para árabe;
7. smoke test no pacote candidato à publicação.

### Processo assistido por agentes

Não haverá contratação de tradutores ou revisores nativos externos. Os oito idiomas permanecem no lançamento por meio deste fluxo:

1. congelar o texto-fonte em inglês e fornecer contexto de tela;
2. produzir a primeira versão com um agente especializado no locale;
3. usar outro agente para revisar significado, naturalidade e terminologia;
4. retrotraduzir ou comparar semanticamente textos críticos;
5. executar uma revisão separada de memes, tom e adequação cultural;
6. validar placeholders, plurais, fixtures de `number-format-v1`, fontes, truncamento e RTL;
7. consolidar correções e obter aprovação final da dupla;
8. monitorar feedback real e publicar correções rápidas quando necessário.

Esse processo não será descrito como revisão humana nativa. O risco cultural residual, especialmente em conteúdo altamente contextual, é aceito conscientemente e não reduz a lista dos oito idiomas nem cria, por si só, uma barreira de lançamento.

## Referências atuais da plataforma

- [Traduzir e localizar seu app — Google Play Console](https://support.google.com/googleplay/android-developer/answer/9844778?hl=pt-BR)
- [Suporte a diferentes idiomas e culturas — Android Developers](https://developer.android.com/training/basics/supporting-devices/languages?hl=pt-br)

Essas referências devem ser revistas perto da implementação e antes de cada lançamento relevante.

## Artefatos `l10n-v1`

- `localization/en-US.json`: 261 strings-fonte de UI, conteúdo e metadados;
- `localization/pt-BR.json`, `es-419.json`, `fr-FR.json`, `de-DE.json`, `id.json`, `ja-JP.json`, `ar.json`: catálogos revisados por agente diferente do tradutor;
- `localization/en-XA.json`: pseudo-locale com expansão para reflow;
- `LOCALIZATION-GLOSSARY.md`: termos canônicos, memória executável e processo de atualização;
- `COPY-DECK.md`: contexto, tipos de placeholder, plurais e variantes curtas;
- `UI-DESIGN-SYSTEM.md`: Noto/M PLUS por script, fallbacks, escala e RTL;
- `scripts/build_source_catalog.py`, `build_pseudolocale.py`, `build_localization_glossary.py` e `validate_planning.py`: geração e gates mecânicos.

## Gates de desenvolvimento e publicação

- executar os oito catálogos e `en-XA` nas telas reais, incluindo screenshots e materiais de campanha;
- validar licenças/versões das fontes, shaping árabe, quebras japonesas, expansão alemã e reflow até `200%`;
- testar placeholders, plurais, bidi, números extremos, TalkBack e metadados nos limites vigentes da loja;
- repetir smoke test por locale no build candidato e corrigir feedback sem alterar IDs/economia;
- não descrever a revisão multiagente como revisão humana nativa.
