# Aura Shift: Six Seven — Glossário e memória de tradução `l10n-v1`

> Gerado dos oito catálogos versionados. Catálogos são a memória de tradução executável; esta tabela é a referência humana de termos de sistema.

## Termos canônicos

| ID | Intenção | `en-US` | `pt-BR` | `es-419` | `fr-FR` | `de-DE` | `id` | `ja-JP` | `ar` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `app_title` | marca; não transcriar | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven | Aura Shift: Six Seven |
| `app_tagline` | transcriar gesto + escala | Two taps. Infinite aura. | Dois toques. Aura infinita. | Dos toques. Aura infinita. | Deux touchers. Une Aura infinie. | Zweimal tippen. Unendliche Aura. | Dua ketukan. Aura tanpa batas. | 2回タップ。オーラは無限。 | نقرتان. هالة بلا حدود. |
| `play_available_aura` | saldo gastável | Available Aura | Aura Disponível | Aura Disponible | Aura disponible | Verfügbare Aura | Aura Tersedia | 使用可能オーラ | الهالة المتاحة |
| `play_total_aura` | progresso vitalício | Total Aura | Aura Total | Aura Total | Aura totale | Gesamt-Aura | Aura Total | 累計オーラ | إجمالي الهالة |
| `play_journey_aura` | desde a última Ascensão | Journey Aura | Aura da Jornada | Aura de la Jornada | Aura de parcours | Durchlauf-Aura | Aura Perjalanan | 旅のオーラ | هالة الرحلة |
| `play_cycle_power` | ganho somente na Seven | Cycle Power | Potência de Ciclo | Potencia de Ciclo | Puissance de Cycle | Zykluskraft | Daya Siklus | サイクルパワー | قوة الدورة |
| `play_passive_rate` | taxa sem Ciclo | Passive Production | Produção Passiva | Producción Pasiva | Production passive | Passive Produktion | Produksi Pasif | パッシブ生産 | الإنتاج التلقائي |
| `play_phase_six` | fase; preservar Six | Six | Six | Six | Six | Six | Six | Six | Six |
| `play_phase_seven` | fase; preservar Seven | Seven | Seven | Seven | Seven | Seven | Seven | Seven | Seven |
| `shop_techniques` | melhoramentos ativos | Techniques | Técnicas | Técnicas | Techniques | Techniken | Teknik | テクニック | التقنيات |
| `shop_aura_tree` | rede de itens passivos | Aura Tree | Árvore de Aura | Árbol de Aura | Arbre d’Aura | Aura-Baum | Pohon Aura | オーラツリー | شجرة الهالة |
| `collection_appearances` | visual sem vantagem | Appearances | Aparências | Apariencias | Apparences | Erscheinungsbilder | Tampilan | 外見 | المظاهر |
| `collection_transformations` | estado permanente da cena | Transformations | Transformações | Transformaciones | Transformations | Transformationen | Transformasi | 変身 | التحولات |
| `collection_achievements` | comemorativo local | Achievements | Conquistas | Logros | Succès | Erfolge | Pencapaian | 実績 | الإنجازات |
| `collection_seals` | coleção separada | 67 Seals | Selos 67 | Sellos 67 | Sceaux 67 | 67-Siegel | Segel 67 | 67のシール | أختام 67 |
| `ascension_title` | reset voluntário + ganho permanente | Aura Ascension | Ascensão de Aura | Ascensión de Aura | Ascension d’Aura | Aura-Aufstieg | Ascensi Aura | オーラ・アセンション | ارتقاء الهالة |
| `cloud_save_title` | sincronização de progresso via Google Play Games | Progress sync | Sincronização do progresso | Sincronización del progreso | Synchronisation de la progression | Fortschritt synchronisieren | Sinkronisasi progres | 進行状況の同期 | مزامنة التقدم |
| `settings_accessibility` | grupo de ajustes | Accessibility | Acessibilidade | Accesibilidad | Accessibilité | Barrierefreiheit | Aksesibilitas | アクセシビリティ | إمكانية الوصول |
| `content.branch_a.name` | território Poise | Poise | Postura | Porte | Prestance | Haltung | Ketenangan | 静謐 | اتزان |
| `content.branch_b.name` | território Motion | Motion | Movimento | Movimiento | Mouvement | Bewegung | Gerak | 躍動 | حركة |
| `content.branch_c.name` | território Signal | Signal | Sinal | Señal | Signal | Signal | Sinyal | シグナル | إشارة |
| `content.signal_67.name` | assinatura de marco | Signal 67 | Sinal 67 | Señal 67 | Signal 67 | Signal 67 | Sinyal 67 | シグナル67 | إشارة 67 |

## Tokens invariáveis

- IDs, placeholders e chaves ICU nunca são traduzidos.
- `Aura Shift: Six Seven`, `Six`, `Seven`, dígitos ASCII, `67`, sufixos K–Dc, expoentes e operadores econômicos permanecem canônicos.
- `Aura` pode receber flexão/artigo ao redor, mas o token econômico formatado chega inteiro do formatter.
- Em árabe, tokens econômicos recebem isolamento LTR na UI; os JSONs não armazenam marcas bidi invisíveis.
- Nomes culturais podem ser transcriados, mas IDs, função, intensidade e risco precisam permanecer equivalentes.

## Atualização simultânea

1. alterar `COPY-DECK.md`, `CONTENT-CATALOG.md` ou `ACHIEVEMENTS.md`;
2. regenerar `en-US` e `en-XA`;
3. bloquear merge enquanto qualquer locale tiver chave ou placeholder divergente;
4. traduzir, revisar por outro agente e comparar semanticamente textos críticos;
5. regenerar este glossário e executar `scripts/validate_planning.py`;
6. durante o desenvolvimento, executar pseudo-localização, RTL, reflow e smoke test no build.

## Limites de validação

A revisão documental não equivale a revisão humana nativa nem a QA em tela. Naturalidade, fontes, shaping, truncamento, TalkBack e bidi precisam ser revalidados no build candidato; correções linguísticas não podem alterar IDs ou estado econômico.
