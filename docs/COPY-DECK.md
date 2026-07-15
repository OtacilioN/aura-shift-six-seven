# Aura Shift: Six Seven — Copy deck canônico `copy-v1`

> Status: fonte `en-US` revisada em 11 de julho de 2026; nomes de conteúdo cultural usam os IDs estáveis definidos em `CONTENT-CATALOG.md`. Revisão em tela permanece parte do desenvolvimento.

## Contrato

- `en-US` é a única fonte de tradução. Outros idiomas não servem de ponte.
- IDs são estáveis, em `lower_snake_case`, e não mudam quando a frase muda.
- `{placeholder}` representa argumento tipado; plural usa ICU MessageFormat.
- Tokens econômicos chegam formatados por `number-format-v1`, nunca são concatenados por partes traduzidas.
- `short` é usado somente quando a largura não comporta a versão normal; acessibilidade recebe sempre a versão completa.
- Nenhum texto essencial pode existir apenas em imagem, áudio, vibração ou animação.
- Title Case é reservado a títulos curtos. Botões usam sentence case.
- “Aura” e “Six-Seven” permanecem nomes de sistema. A marca usa a grafia definida em `BRAND-VOICE-GUIDE.md`.

## Placeholders tipados

| Placeholder | Tipo | Exemplo | Regra |
| --- | --- | --- | --- |
| `{amount}` | token econômico LTR isolável | `6.7K` | saída de `number-format-v1` |
| `{rate}` | taxa econômica | `67 Aura/s` | unidade incluída pelo formatter |
| `{level}` | inteiro ASCII | `25` | sem agrupamento |
| `{count}` | inteiro para plural | `2` | plural do locale |
| `{name}` | nome localizado de conteúdo | `Suspicious Button` | nunca interpolar ID técnico |
| `{date}` | data/hora local | `Jul 10, 2026, 2:30 PM` | formatter do locale |
| `{duration}` | duração localizada | `6 hr 7 min` | formatter do locale; não é token econômico |
| `{version}` | versão ASCII | `1.0.0` | LTR em RTL |
| `{multiplier}` | multiplicador econômico | `1.67×` | formatter canônico |

## Marca

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `app_title` | Aura Shift: Six Seven | Marca invariável nos oito idiomas |
| `app_tagline` | Two taps. Infinite aura. | Transcriar gesto, escala e concisão; não traduzir Six Seven como `sixty-seven` |

## Navegação e ações comuns

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `nav_play` | Play | Área principal |
| `nav_shop` | Shop | Inclui Técnicas e Árvore |
| `nav_collection` | Collection | Aparências, Transformações, Conquistas e Selos |
| `nav_settings` | Settings | Preferências e dados |
| `action_continue` | Continue | Ação neutra |
| `action_cancel` | Cancel | Cancela sem mutação |
| `action_close` | Close | Fecha superfície |
| `action_confirm` | Confirm | Confirma ação reversível |
| `action_try_again` | Try again | Repete operação segura |
| `action_not_now` | Not now | Recusa ou adia sem punição |
| `action_done` | Done | Encerra fluxo concluído |
| `action_learn_more` | Learn more | Abre detalhes acessíveis |
| `action_copy_exact` | Copy exact value | Copia representação canônica |
| `action_skip_animation` | Skip animation | Não pula registro/recompensa |

## Jogar, HUD e tutorial

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `play_available_aura` | Available Aura | Saldo gastável |
| `play_total_aura` | Total Aura | Progresso permanente |
| `play_journey_aura` | Journey Aura | Progresso desde a última Ascensão |
| `play_cycle_power` | Cycle Power | Resultado da Fase Seven |
| `play_passive_rate` | Passive Production | Taxa independente de toques |
| `play_phase_six` | Six | Rótulo visual/acessível da primeira fase |
| `play_phase_seven` | Seven | Rótulo visual/acessível da segunda fase |
| `play_cycle_gain` | +{amount} Aura | Feedback de ciclo concluído |
| `play_aura_details` | Aura details | Abre valores completos |
| `play_exact_value` | Exact value: {amount} Aura | Leitura e cópia de inteiro |
| `play_digits_count` | {count, plural, one {# digit} other {# digits}} | Apenas quando valor completo é muito longo |
| `progress_title` | Next steps | Resumo central de orientação |
| `progress_next_tier` | Next Aura tier | Próximo Patamar permanente |
| `progress_tier_unlocks` | Main unlocks | Conteúdo associado ao próximo Patamar |
| `progress_shop_unlocks` | Next Shop unlocks | Requisitos econômicos mais próximos |
| `progress_item_milestones` | Item milestones | Marcos de nível mais próximos |
| `progress_all_tiers` | All Aura tiers reached. | Estado terminal de Patamares |
| `progress_no_pending_unlocks` | All Shop items are unlocked. | Estado terminal de desbloqueios |
| `progress_no_item_milestones` | Buy an item level to start tracking its milestones. | Estado vazio antes da primeira compra |
| `tutorial_first_touch` | Tap anywhere in the Aura area. | Coach mark não bloqueante |
| `tutorial_second_touch` | One more tap. Complete the Six-Seven. | Segunda fase |
| `tutorial_cycle_complete` | Six-Seven complete. You made your first Aura. | Após crédito real |
| `tutorial_shop_ready` | Your first Technique is within reach. Check the Shop when you want. | Destaque discreto |
| `tutorial_choose_root` | Choose the style you like. All three paths start equally strong. | Escolha sem armadilha econômica |
| `tutorial_passive_unlocked` | Passive Production keeps making Aura without taps — even while you are away. | Final do tutorial |
| `tutorial_complete` | You are set. Farm Aura your way. | Encerramento |
| `tutorial_replay` | Replay tutorial | Ajustes |
| `tutorial_dismiss_hint` | Dismiss hint | Não conclui compra nem altera economia |

## Consentimento de analytics

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `analytics_title` | Help improve the game? | Único convite automático após primeira Aura |
| `analytics_body` | Share limited gameplay and technical events from now on. Your save, exact Aura values, name, age, and account are not collected. | Texto curto canônico |
| `analytics_allow` | Allow | Mesmo peso visual de recusa |
| `analytics_decline` | Not now | Fechar equivale a esta ação |
| `analytics_details_title` | Analytics details | Folha expandida |
| `analytics_details_body` | Collection starts only if you allow it. Earlier actions are not sent. You can turn it off later in Settings. Data is kept for two months and is not exported to another data warehouse. | Detalhes de consentimento |
| `analytics_setting` | Share product analytics | Toggle voluntário |
| `analytics_setting_off` | Analytics are off on this device. | Estado |
| `analytics_setting_on` | Future eligible events may be sent from this device. | Estado |

## Primeiro contato com anúncios recompensados

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `ads_first_offer_title` | Optional ad rewards | Explica a escolha antes do primeiro anúncio |
| `ads_first_offer_body` | Rewarded ads are optional. Watching one grants the reward shown; skipping it never blocks progress, and you can keep playing or buy upgrades with Aura. | Voluntariedade e alternativa sem anúncio |
| `ads_first_offer_continue` | Continue to ad | Confirma que a próxima ação abre o anúncio |
| `ads_first_offer_not_now` | Not now | Recusa sem punição |

## Diagnóstico após falha

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `diagnostic_title` | Send a crash report? | Sem recompensa |
| `diagnostic_body` | The game saved {count, plural, one {# technical report} other {# technical reports}} after the last problem. Send only this pending batch to help diagnose it? | Quantidade obrigatória |
| `diagnostic_send` | Send | Autorização de uso único |
| `diagnostic_delete` | Don't send | Apaga o lote; mesmo peso visual |
| `diagnostic_details_title` | What is included | Detalhes acessíveis |
| `diagnostic_details_body` | Reports may include the error trace, app version, device details, time, and an installation identifier. They never include your save, exact Aura values, or age signals. If analytics was already on, approved event breadcrumbs may be included. | Categorias, não stack trace |
| `diagnostic_queued` | Report queued. It will send when a connection is available. | Aceite offline |
| `diagnostic_deleted` | Pending reports deleted. | Confirmação sem dramatização |

## Loja, Técnicas e Árvore de Aura

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `shop_techniques` | Techniques | Subárea da Loja |
| `shop_aura_tree` | Aura Tree | Subárea da Loja |
| `shop_buy_one` | Buy ×1 | Modo de compra |
| `shop_buy_ten` | Buy ×10 | Modo de compra |
| `shop_buy_max` | Buy MAX | Modo de compra |
| `shop_level` | Level {level} | Nível atual |
| `shop_cost` | Cost: {amount} Aura | Custo cumulativo real do modo ativo |
| `shop_missing` | Need {amount} Aura | Diferença exata |
| `shop_current_effect` | Now: {rate} | Contribuição atual |
| `shop_next_effect` | After purchase: {rate} | Contribuição projetada |
| `shop_effect_gain` | +{rate} | Diferença exata entre estados |
| `shop_next_milestone` | Next milestone: level {level} | Marco universal |
| `shop_milestones_crossed` | {count, plural, one {Milestone reached} other {# milestones reached}} | Compra em lote consolidada |
| `shop_tier_required` | Reach {amount} Total Aura. | Bloqueio por Patamar |
| `shop_item_required` | Raise {name} to level {level}. | Bloqueio por predecessor |
| `shop_all_requirements` | Complete all listed requirements. | Convergência |
| `shop_unlocked` | Unlocked | Estado não comprado |
| `shop_owned` | Owned | Entrada com nível ≥ 1 |
| `shop_ad_topup_title` | Complete this purchase? | Complemento de Aura |
| `shop_ad_topup_body` | Watch an optional rewarded ad to cover the missing {amount} Aura for this purchase only. Or keep playing and buy it normally later. | Quita somente a falta da compra; não credita saldo; alternativa explícita |
| `shop_ad_topup_watch` | Watch ad | Início explícito |
| `shop_ad_topup_remaining` | {count, plural, one {# top-up available} other {# top-ups available}} in this window | Cota visível |
| `shop_ad_unavailable` | Rewarded ad unavailable. You can keep playing and buy normally. | Sem modal recorrente |
| `shop_ad_upgrade_title` | Ad upgrade | Título da opção voluntária por anúncio |
| `shop_ad_upgrade_watch` | Watch for +{levels} levels | Recompensa explícita antes do anúncio |
| `shop_ad_upgrade_locked` | Finish the tutorial and buy at least one Technique and one Item normally to unlock ad upgrades. | Entrada protegida por progresso normal |
| `shop_ad_upgrade_first_level` | Buy the first level to unlock ad upgrades for this item. | Evita usar anúncio como primeira compra |
| `shop_ad_upgrade_item_used` | This item already received an ad upgrade in this streak. Choose another item. | Um uso por item na sequência |
| `shop_ad_upgrade_cooldown` | You have completed 3 ads. More ad upgrades will be available in about {minutes} min. | Limite e espera visíveis |

## Coleção

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `collection_appearances` | Appearances | Cosméticos sem efeito econômico |
| `collection_transformations` | Transformations | Estados permanentes |
| `collection_achievements` | Achievements | 13 entradas |
| `collection_seals` | 67 Seals | Coleção separada |
| `collection_equip` | Use appearance | Ação cosmética |
| `collection_equipped` | In use | Estado |
| `collection_hide` | Hide appearance | Ação cosmética independente |
| `collection_hidden` | Appearance hidden | Estado cosmético; não descreve o Efeito de Item |
| `collection_effect_persists` | Item effects stay active with any appearance. | Garantia explícita quando o Efeito de Item está ativo; não usar após reset econômico |
| `collection_secret` | Secret achievement | Estado pré-desbloqueio |
| `collection_locked` | Locked | Conquista secreta ou linha nomeada “Item effect” após reset; o contexto acessível identifica o sistema bloqueado |
| `collection_achievement_unlocked` | Achievement unlocked: {name} | Celebração |
| `collection_transformation_unlocked` | Transformation unlocked: {name} | Celebração |
| `collection_seal_unlocked` | 67 milestone reached: {amount} Total Aura | Sem ganho econômico |

## Retorno, offline e anúncios

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `return_title` | Welcome back | Recompensa de ausência |
| `return_away_time` | Away for {duration} | Duração localizada |
| `return_credit_cap` | Offline Production is limited to 4 hours per absence. | Explica recompensa limitada após ausência longa |
| `return_base_reward` | Offline Production: {amount} Aura | Base proporcional aguardando resgate |
| `return_collect` | Collect {amount} Aura | Encerra oferta |
| `return_bonus_title` | Claim a 20% return bonus? | Apenas ausência > 10 min e elegível |
| `return_bonus_body` | Watch an optional rewarded ad to claim {amount} Aura with a 20% bonus, or collect the base reward. | Explicita as duas escolhas; base ainda pendente |
| `return_watch_ad` | Watch ad to collect {amount} | Resgate total com bônus explícito |
| `return_base_only` | Continue with base reward | Recusa encerra oportunidade |
| `return_ad_failed` | The ad did not finish. Your reward is still waiting: try again or collect the base reward. | Sem crédito ou perda antes da escolha |
| `return_retry_bonus` | Try the bonus again | Mantém pendência |
| `return_clock_issue` | Offline Production could not be calculated after a clock change. Your progress is safe, and a new time reference was set. | Sem acusação/punição |

## Ascensão

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `ascension_title` | Aura Ascension | Nome de sistema; alinhar ao catálogo final |
| `ascension_locked` | Produce {amount} more Journey Aura to Ascend. | Usa diferença exata |
| `ascension_preview` | Ascension preview | Antes da confirmação |
| `ascension_journey_used` | Journey Aura used: {amount} | Valor canônico |
| `ascension_gain` | Permanent gain: +{multiplier} | Parcela projetada |
| `ascension_multiplier_now` | Current multiplier: {multiplier} | Precisão 0,01× |
| `ascension_multiplier_after` | After Ascension: {multiplier} | Precisão 0,01× |
| `ascension_resets_title` | Starts over | Lista de estados reiniciados |
| `ascension_resets_body` | Available Aura, Journey Aura, Technique levels, Aura Item levels, and their current production. | Resumo; a lista dinâmica também explicita aquisições, Pré-requisitos e Efeitos reiniciados conforme `UX-WIREFRAMES.md` |
| `ascension_keeps_title` | Stays with you | Lista preservada |
| `ascension_keeps_body` | Total Aura, tiers, Transformations, Achievements, 67 Seals, Appearances, and your permanent Ascension multiplier. | Resumo; a lista dinâmica inclui o Resto de Produção preservado conforme `UX-WIREFRAMES.md` |
| `ascension_pending_return` | Finish the pending return choice before Ascending. The base reward is already safe. | Bloqueio legítimo |
| `ascension_confirm_title` | Ascend now? | Confirmação final |
| `ascension_confirm_body` | This restarts the listed economy and permanently updates your multiplier to {multiplier}. | Transação atômica |
| `ascension_confirm_action` | Ascend | Sem anúncio/pagamento |
| `ascension_complete` | Ascension complete. Permanent multiplier: {multiplier}. | Após persistência |

## Backup Manual

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `backup_title` | Manual Backup | Sem conta/nuvem |
| `backup_explain` | Export your progress to a file you control. This game does not sync or recover saves automatically. | Limite claro |
| `backup_export` | Export backup | Abre seletor do sistema |
| `backup_import` | Import backup | Valida antes de mutar |
| `backup_export_success` | Backup exported. Keep the file somewhere safe. | Sem prometer recuperação |
| `backup_export_failed` | Backup could not be exported. Your current progress is unchanged. | Erro seguro |
| `backup_invalid` | This file is not a valid supported backup. Your current progress is unchanged. | Validação |
| `backup_too_new` | This backup was made by a newer game version and cannot be restored here. | Compatibilidade |
| `backup_preview_title` | Review backup | Antes da restauração |
| `backup_preview_date` | Created: {date} | Data local |
| `backup_preview_version` | Game version: {version} | LTR em RTL |
| `backup_preview_total` | Total Aura: {amount} | Resumo minimizado |
| `backup_replace_warning` | Restoring replaces the progress currently on this device. This cannot be undone. | Perda explícita |
| `backup_restore` | Restore this backup | Confirmação destrutiva |
| `backup_restore_success` | Backup restored. | Após gravação atômica |
| `backup_restore_failed` | The backup could not be restored. Your previous progress is still active. | Rollback |

## Ajustes e acessibilidade

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `settings_language` | Language | Nome nativo no seletor |
| `settings_music` | Music | Controle independente |
| `settings_sound_effects` | Sound effects | Controle independente |
| `settings_vibration` | Vibration | Controle independente |
| `settings_accessibility` | Accessibility | Grupo |
| `settings_reduce_motion` | Reduce motion | Override do sistema |
| `settings_reduce_flashes` | Reduce flashes and particles | Opção separada |
| `settings_text_scale_system` | Use device text size | Default |
| `settings_high_contrast` | Increase contrast | Reforço opcional, não corrige baseline |
| `settings_screen_reader_hints` | Extra screen reader hints | Contexto econômico ampliado |
| `settings_privacy` | Privacy | Analytics/política |
| `settings_privacy_policy` | Privacy policy | Link externo com falha segura |
| `settings_privacy_policy_body` | Learn how the game and its advertising partners handle data. | Explicação curta do link externo |
| `settings_ad_privacy_options` | Ad privacy options | Entrada para consentimento regional |
| `settings_ad_privacy_options_body` | Review consent and ad choices available in your region. | Escopo das opções disponíveis |
| `settings_ad_privacy_failed` | Ad privacy options could not be opened. Try again. | Falha segura sem alterar preferências |
| `settings_credits` | Credits and licenses | Ferramentas e proveniência |
| `settings_version` | Version {version} | Diagnóstico |
| `settings_system_default` | Device default | Opção tri-state quando aplicável |
| `settings_on` | On | Estado curto |
| `settings_off` | Off | Estado curto |

## Sistema, conexão e erros

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `system_offline` | Offline | Indicador discreto |
| `system_online_restored` | Connection restored | Anúncio não modal |
| `system_saving` | Saving… | Apenas se demora perceptível |
| `system_saved` | Saved | Confirmação breve |
| `system_save_failed` | Progress could not be saved. Keep the game open and try again. | Bloqueia mutações destrutivas até resolver |
| `system_loading` | Loading… | Estado genérico, inclusive reconciliação breve sem presumir sucesso de anúncio |
| `system_generic_error` | Something went wrong. Your progress is safe. | Fallback não técnico |
| `system_retry_safe` | Try again | Operação idempotente |
| `system_ad_loading` | Loading rewarded ad… | Pode ser cancelado |
| `system_ad_cancelled` | Ad closed before completion. No reward was added. | Resultado literal |
| `system_external_link_failed` | The page could not be opened. Check your connection and try again. | Política/créditos |
| `system_no_content` | Nothing here yet. | Somente estado realmente vazio |

## Metadados da loja

| ID | `en-US` | Contexto / observação |
| --- | --- | --- |
| `store_short_description` | Two taps. Infinite Aura. Build your style and shift the whole scene. | Até 80 caracteres na fonte; revalidar limite por locale |
| `store_full_description` | Tap twice to complete a Six-Seven Cycle and farm Aura. Build active Techniques, grow three equally strong Aura Tree paths, collect Appearances, unlock Transformations, and Ascend for permanent momentum.\n\nPlay your way:\n• Active and passive progress\n• Up to 4 hours of Offline Production\n• Optional rewarded ads only\n• No account, required connection, or in-app purchases\n• Manual Backup, accessibility controls, and 8 languages\n\nAura Shift: Six Seven is a trend-driven incremental game for ages 13 and up. | Corpo da ficha Google Play; quebras são semânticas |
| `store_feature_graphic_alt` | Mascot switching oversized hands between Six and Seven as Aura fills the scene. | Alt-text/briefing de asset promocional |

## Conteúdo cultural integrado

Os catálogos incluem `92` strings `content.*`: nome e descrição para 18 Itens, seis Técnicas, cinco Transformações, 13 Conquistas e três Ramos, além do nome e da celebração de Signal 67. `CONTENT-CATALOG.md` e `ACHIEVEMENTS.md` definem intenção e função; `localization/en-US.json` é a fonte exata entregue à UI. IDs técnicos nunca substituem uma dessas strings na tela.

## Variantes curtas aprovadas

| ID normal | ID curto | `en-US` curto | Limite de uso |
| --- | --- | --- | --- |
| `play_available_aura` | `play_available_aura_short` | Available | HUD, com rótulo acessível completo |
| `play_total_aura` | `play_total_aura_short` | Total | HUD, com rótulo acessível completo |
| `play_passive_rate` | `play_passive_rate_short` | Passive | HUD, com unidade visível |
| `shop_next_milestone` | `shop_next_milestone_short` | Next: L{level} | Card compacto |
| `ascension_multiplier_after` | `ascension_multiplier_after_short` | New: {multiplier} | Prévia compacta |
| `settings_reduce_flashes` | `settings_reduce_flashes_short` | Reduce effects | Somente se explicação estiver adjacente |

## QA de congelamento

- Todos os placeholders devem existir e manter tipo em cada locale.
- `diagnostic_body`, `play_digits_count`, `shop_ad_topup_remaining` e `shop_milestones_crossed` precisam de plural funcional.
- Árabe deve isolar `{amount}`, `{rate}`, `{version}`, `{percent}` e `{multiplier}` como LTR na renderização, sem inserir marcas bidi nos valores persistidos.
- Alemão, francês e português devem ser testados a `200%` de escala textual; pseudo-localização deve testar `+35%` de expansão.
- Japonês deve permitir quebra por unidade linguística e nunca depender de espaços.
- Botões críticos não podem truncar: analytics, diagnóstico, restauração e Ascensão devem crescer verticalmente.
- Conteúdo de `CONTENT-CATALOG.md` e `ACHIEVEMENTS.md` já está incorporado aos catálogos pelos mesmos IDs (`content.<id>.name`, `.description`); a paridade esperada é `92` strings culturais por locale.
