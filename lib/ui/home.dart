import 'dart:async';
import 'dart:collection';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/aura_audio_controller.dart';
import '../core/backup_service.dart';
import '../core/formatting.dart';
import '../core/game_controller.dart';
import '../core/rewarded_ads.dart';
import '../game/art_catalog.dart';
import '../game/aura_scene.dart';
import '../main.dart';
import 'art_widgets.dart';
import 'aura_tree.dart';

class _VisualFeedback {
  const _VisualFeedback(this.artwork, this.title, this.body);

  final AuraEventArtwork artwork;
  final String title;
  final String body;
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.controller,
    required this.strings,
    required this.audio,
  });
  final GameController controller;
  final Strings strings;
  final AuraAudioController audio;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int tab = 0;
  bool promptedAnalytics = false;
  bool promptedReturn = false;
  final RewardedAds rewardedAds = GoogleRewardedAds();
  final ListQueue<_VisualFeedback> _visualFeedback = ListQueue();
  late final AuraScene scene;
  late final Future<ArtCatalog?> artCatalog;
  late Set<String> _knownTransformations;
  late Set<String> _knownSeals;
  late Set<String> _knownAchievements;
  bool _showingVisualFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scene = AuraScene(widget.controller, widget.audio);
    unawaited(widget.audio.start(widget.controller));
    artCatalog = _loadArtCatalog();
    _knownTransformations = widget.controller.transformations;
    _knownSeals = widget.controller.seals;
    _knownAchievements = widget.controller.achievements;
    widget.controller.addListener(_detectUnlocks);
  }

  Future<ArtCatalog?> _loadArtCatalog() async {
    try {
      return await ArtCatalog.load(rootBundle);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_detectUnlocks);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _detectUnlocks() {
    final nextTransformations = widget.controller.transformations;
    for (final id in nextTransformations.difference(_knownTransformations)) {
      final key = id.toLowerCase().replaceAll('-', '_');
      _enqueueVisualFeedback(
        AuraEventArtwork.transformation,
        widget.strings('collection_transformations'),
        widget.strings('content.$key.name'),
      );
    }
    _knownTransformations = nextTransformations;

    final nextSeals = widget.controller.seals;
    for (final id in nextSeals.difference(_knownSeals)) {
      _enqueueVisualFeedback(
        AuraEventArtwork.aura67,
        widget.strings('collection_seals'),
        id,
      );
    }
    _knownSeals = nextSeals;

    final nextAchievements = widget.controller.achievements;
    for (final id in nextAchievements.difference(_knownAchievements)) {
      final key = id.toLowerCase().replaceAll('-', '_');
      _enqueueVisualFeedback(
        AuraEventArtwork.achievement,
        widget.strings('collection_achievements'),
        widget.strings('content.$key.name'),
      );
    }
    _knownAchievements = nextAchievements;
  }

  void _enqueueVisualFeedback(
    AuraEventArtwork artwork,
    String title,
    String body,
  ) {
    _visualFeedback.add(_VisualFeedback(artwork, title, body));
    unawaited(_showNextVisualFeedback());
  }

  Future<void> _showNextVisualFeedback() async {
    if (_showingVisualFeedback || _visualFeedback.isEmpty || !mounted) return;
    _showingVisualFeedback = true;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final feedback = _visualFeedback.removeFirst();
    final art = await artCatalog;
    if (!mounted) return;
    final snack = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            AuraAssetArt(
              catalog: art,
              assetId: AuraUiArt.event(feedback.artwork),
              fallback: const Icon(Icons.auto_awesome, color: Colors.white),
              width: 52,
              height: 52,
              semanticLabel: feedback.title,
              decorative: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feedback.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(feedback.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await snack.closed;
    _showingVisualFeedback = false;
    if (_visualFeedback.isNotEmpty) unawaited(_showNextVisualFeedback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(widget.audio.handleLifecycleState(state));
    if (state == AppLifecycleState.paused) {
      widget.controller.pause();
      scene.pauseEngine();
    }
    if (state == AppLifecycleState.resumed) {
      widget.controller.resume();
      if (tab == 0) scene.resumeEngine();
    }
  }

  void _selectTab(int value) {
    if (value == tab) return;
    if (tab == 0) scene.pauseEngine();
    if (value == 0) scene.resumeEngine();
    setState(() => tab = value);
    unawaited(widget.audio.changeTab(value));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = widget.strings;
    if (c.total > BigInt.zero && !c.analyticsDecided && !promptedAnalytics) {
      promptedAnalytics = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyticsDialog());
    }
    if (c.returnRewardAvailable && !promptedReturn) {
      promptedReturn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _returnRewardDialog().whenComplete(() {
          if (mounted) setState(() => promptedReturn = false);
        });
      });
    }
    return FutureBuilder<ArtCatalog?>(
      future: artCatalog,
      builder: (context, snapshot) {
        final art = snapshot.data;
        final pages = [
          _Play(
            controller: c,
            strings: s,
            scene: scene,
            art: art,
            audio: widget.audio,
            ascend: _ascensionDialog,
          ),
          _Shop(
            controller: c,
            strings: s,
            art: art,
            audio: widget.audio,
            onPurchase: _buyUpgrade,
            onComplement: _completeComplement,
          ),
          _Collection(controller: c, strings: s, art: art, audio: widget.audio),
          _Settings(controller: c, strings: s, art: art, audio: widget.audio),
        ];
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                // The Flame scene must stay mounted when another tab is open.
                // AuraScene.onRemove is terminal for the current instance.
                child: IndexedStack(index: tab, children: pages),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: NavigationBar(
              height: 72,
              selectedIndex: tab,
              onDestinationSelected: _selectTab,
              destinations: [
                _navigationDestination(
                  art,
                  role: AuraUiIcon.navPlay,
                  fallback: Icons.bolt_outlined,
                  selectedFallback: Icons.bolt,
                  label: s('nav_play'),
                ),
                _navigationDestination(
                  art,
                  role: AuraUiIcon.navShop,
                  fallback: Icons.account_tree_outlined,
                  selectedFallback: Icons.account_tree,
                  label: s('nav_shop'),
                ),
                _navigationDestination(
                  art,
                  role: AuraUiIcon.navCollection,
                  fallback: Icons.auto_awesome_outlined,
                  selectedFallback: Icons.auto_awesome,
                  label: s('nav_collection'),
                ),
                _navigationDestination(
                  art,
                  role: AuraUiIcon.navSettings,
                  fallback: Icons.tune_outlined,
                  selectedFallback: Icons.tune,
                  label: s('nav_settings'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  NavigationDestination _navigationDestination(
    ArtCatalog? art, {
    required AuraUiIcon role,
    required IconData fallback,
    required IconData selectedFallback,
    required String label,
  }) =>
      NavigationDestination(
        icon: AuraAssetIcon(
          catalog: art,
          role: role,
          fallbackIcon: fallback,
          semanticLabel: label,
          decorative: true,
          opacity: .68,
          size: 26,
        ),
        selectedIcon: AuraAssetIcon(
          catalog: art,
          role: role,
          fallbackIcon: selectedFallback,
          semanticLabel: label,
          decorative: true,
          size: 30,
        ),
        label: label,
      );

  Widget _eventArtwork(
    AuraEventArtwork event,
    String label, {
    IconData fallback = Icons.auto_awesome,
  }) =>
      FutureBuilder<ArtCatalog?>(
        future: artCatalog,
        builder: (_, snapshot) => AuraAssetArt(
          catalog: snapshot.data,
          assetId: AuraUiArt.event(event),
          fallback: Icon(fallback, size: 52),
          width: 64,
          height: 64,
          semanticLabel: label,
        ),
      );

  Widget _iconArtwork(AuraUiIcon role, String label, IconData fallback) =>
      FutureBuilder<ArtCatalog?>(
        future: artCatalog,
        builder: (_, snapshot) => AuraAssetIcon(
          catalog: snapshot.data,
          role: role,
          fallbackIcon: fallback,
          semanticLabel: label,
          size: 56,
        ),
      );

  Future<void> _withSheetAudio(Future<void> Function() showSheet) async {
    unawaited(widget.audio.playUiOpen());
    await widget.audio.beginDuck();
    try {
      await showSheet();
    } finally {
      await widget.audio.endDuck();
      unawaited(widget.audio.playUiClose());
    }
  }

  Future<void> _analyticsDialog() =>
      _withSheetAudio(() => showModalBottomSheet<void>(
          context: context,
          builder: (sheet) => _Sheet(
              title: widget.strings('analytics_title'),
              body: widget.strings('analytics_body'),
              artwork: _iconArtwork(
                AuraUiIcon.info,
                widget.strings('analytics_title'),
                Icons.info_outline,
              ),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          widget.controller.chooseAnalytics(false);
                          unawaited(widget.audio.playToggle(false));
                          Navigator.pop(sheet);
                        },
                        child: Text(widget.strings('analytics_decline')))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: () {
                          widget.controller.chooseAnalytics(true);
                          unawaited(widget.audio.playToggle(true));
                          Navigator.pop(sheet);
                        },
                        child: Text(widget.strings('analytics_allow'))))
              ]))));
  Future<void> _ascensionDialog() =>
      _withSheetAudio(() => showModalBottomSheet<void>(
          context: context,
          builder: (sheet) {
            final c = widget.controller;
            final s = widget.strings;
            return AnimatedBuilder(
              animation: c,
              builder: (context, _) {
                final gain = c.ascensionGain();
                final resultingMultiplier = c.multiplier + gain;
                return _Sheet(
                    title: s('ascension_title'),
                    body: '${s('ascension_journey_used', {
                          'amount':
                              AuraFormat.integer(c.journey, locale: s.locale)
                        })}\n${s('ascension_gain', {
                          'multiplier': '${AuraFormat.multiplier(gain)}×'
                        })}\n${s('ascension_multiplier_now', {
                          'multiplier':
                              '${AuraFormat.multiplier(c.multiplier)}×'
                        })}\n${s('ascension_multiplier_after', {
                          'multiplier':
                              '${AuraFormat.multiplier(resultingMultiplier)}×'
                        })}',
                    artwork: _eventArtwork(
                      AuraEventArtwork.ascension,
                      s('ascension_title'),
                      fallback: Icons.upgrade,
                    ),
                    child: FilledButton(
                        onPressed: c.canAscend
                            ? () {
                                widget.audio.prepareAscension();
                                c.ascend();
                                unawaited(widget.audio.playAscension());
                                _enqueueVisualFeedback(
                                  AuraEventArtwork.ascension,
                                  s('ascension_title'),
                                  s('ascension_complete', {
                                    'multiplier':
                                        '${AuraFormat.multiplier(c.multiplier)}×',
                                  }),
                                );
                                Navigator.pop(sheet);
                              }
                            : null,
                        child: Text(s('ascension_confirm_action'))));
              },
            );
          }));

  Future<void> _returnRewardDialog() =>
      _withSheetAudio(() => showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          builder: (sheet) {
            final base = AuraFormat.integer(
                widget.controller.returnBase ~/ BigInt.from(10000000),
                locale: widget.strings.locale);
            final bonus = AuraFormat.integer(
                widget.controller.returnBonus ~/ BigInt.from(10000000),
                locale: widget.strings.locale);
            return _Sheet(
                title: widget.strings('return_title'),
                body: '${widget.strings('return_base_reward', {
                      'amount': base
                    })}\n${widget.strings('return_bonus_body', {
                      'amount': bonus
                    })}',
                artwork: _iconArtwork(
                  AuraUiIcon.rewardedAd,
                  widget.strings('return_title'),
                  Icons.card_giftcard,
                ),
                child: Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () {
                            widget.controller.claimReturnBase();
                            Navigator.pop(sheet);
                          },
                          child: Text(widget.strings('return_base_only')))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                          onPressed: () async {
                            var rewarded = false;
                            try {
                              rewarded = await widget.audio.whileInterrupted(
                                () => rewardedAds
                                    .show(RewardedPlacement.returnBonus),
                              );
                            } catch (_) {}
                            if (rewarded) {
                              final credited = widget.controller
                                  .resolveReturnBonus(rewarded: true);
                              if (credited) {
                                unawaited(widget.audio.playReturnBonus());
                              }
                              if (sheet.mounted) Navigator.pop(sheet);
                            } else if (sheet.mounted) {
                              unawaited(widget.audio.playUiError());
                              ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(
                                content:
                                    Text(widget.strings('return_ad_failed')),
                              ));
                            }
                          },
                          child: Text(widget
                              .strings('return_watch_ad', {'amount': bonus}))))
                ]));
          }));

  Future<void> _completeComplement(Upgrade upgrade) async {
    final quote = widget.controller.beginComplement(upgrade);
    if (quote == null) return;
    var rewarded = false;
    try {
      rewarded = await widget.audio.whileInterrupted(
        () => rewardedAds.show(RewardedPlacement.auraComplement),
      );
    } catch (_) {}
    final redeemed =
        widget.controller.redeemComplement(quote, rewarded: rewarded);
    if (redeemed) {
      final after = quote.level + 1;
      _announcePurchase(upgrade, quote.level, after);
      unawaited(widget.audio.playPurchaseResult(
        success: true,
        quantity: 1,
        unlockedAppearance: !upgrade.isTechnique && quote.level == 0,
        levelMilestone: _crossedMilestone(quote.level, after),
      ));
    } else if (mounted) {
      unawaited(widget.audio.playPurchaseResult(success: false, quantity: 1));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.strings('shop_ad_unavailable')),
      ));
    }
  }

  void _buyUpgrade(Upgrade upgrade, int quantity) {
    final before = widget.controller.level(upgrade.id);
    final bought = widget.controller.buy(upgrade, quantity);
    final after = widget.controller.level(upgrade.id);
    unawaited(widget.audio.playPurchaseResult(
      success: bought,
      quantity: quantity,
      unlockedAppearance: bought && !upgrade.isTechnique && before == 0,
      levelMilestone: bought && _crossedMilestone(before, after),
    ));
    if (!bought) return;
    _announcePurchase(upgrade, before, after);
  }

  bool _crossedMilestone(int before, int after) =>
      <int>[10, 25, 50]
          .any((milestone) => before < milestone && after >= milestone) ||
      (after >= 100 && before ~/ 100 != after ~/ 100);

  void _announcePurchase(Upgrade upgrade, int before, int after) {
    final crossedMilestone = _crossedMilestone(before, after);
    _enqueueVisualFeedback(
      crossedMilestone ? AuraEventArtwork.milestone : AuraEventArtwork.purchase,
      widget.strings(upgrade.nameKey),
      widget.strings('shop_level', {'level': '$after'}),
    );
  }
}

class _Play extends StatelessWidget {
  const _Play({
    required this.controller,
    required this.strings,
    required this.scene,
    required this.art,
    required this.audio,
    required this.ascend,
  });
  final GameController controller;
  final Strings strings;
  final AuraScene scene;
  final ArtCatalog? art;
  final AuraAudioController audio;
  final VoidCallback ascend;
  @override
  Widget build(BuildContext context) => Column(children: [
        _AuraHud(
          controller: controller,
          strings: strings,
          art: art,
          onDetails: () => _details(context),
        ),
        if (controller.canAscend)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: _AscendButton(
              strings: strings,
              art: art,
              gain: AuraFormat.multiplier(controller.ascensionGain()),
              onTap: ascend,
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: _AuraArena(
              scene: scene,
              controller: controller,
              strings: strings,
            ),
          ),
        ),
      ]);
  Future<void> _details(BuildContext context) async {
    unawaited(audio.playUiOpen());
    await audio.beginDuck();
    if (!context.mounted) {
      await audio.endDuck();
      return;
    }
    try {
      await showModalBottomSheet<void>(
          context: context,
          builder: (_) => _Sheet(
              title: strings('play_aura_details'),
              body:
                  '${strings('play_available_aura')}: ${controller.available}\n${strings('play_total_aura')}: ${controller.total}\n${strings('play_journey_aura')}: ${controller.journey}\n${strings('play_cycle_power')}: ${AuraFormat.exactRate(controller.powerNumerator)}\n${strings('play_passive_rate')}: ${AuraFormat.exactRate(controller.passiveNumerator)}/s',
              artwork: AuraAssetIcon(
                catalog: art,
                role: AuraUiIcon.cyclePower,
                fallbackIcon: Icons.bolt,
                semanticLabel: strings('play_cycle_power'),
                size: 56,
              ),
              child: const SizedBox()));
    } finally {
      await audio.endDuck();
      unawaited(audio.playUiClose());
    }
  }
}

class _AuraHud extends StatelessWidget {
  const _AuraHud({
    required this.controller,
    required this.strings,
    required this.art,
    required this.onDetails,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2249), Color(0xFF12132E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B7CFF).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AuraAssetIcon(
            catalog: art,
            role: AuraUiIcon.auraAvailable,
            fallbackIcon: Icons.bolt,
            semanticLabel: s('play_available_aura'),
            decorative: true,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('play_available_aura_short').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFF7F5FF), Color(0xFF43E6FF)],
                    ).createShader(r),
                    child: Text(
                      AuraFormat.integer(controller.available,
                          locale: s.locale),
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s('play_aura_details'),
            onPressed: onDetails,
            icon: AuraAssetIcon(
              catalog: art,
              role: AuraUiIcon.info,
              fallbackIcon: Icons.info_outline,
              semanticLabel: s('play_aura_details'),
              decorative: true,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _StatChip(
              art: art,
              icon: AuraUiIcon.auraTotal,
              label: s('play_total_aura_short'),
              value: AuraFormat.integer(controller.total, locale: s.locale),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              art: art,
              icon: AuraUiIcon.passiveRate,
              label: s('play_passive_rate_short'),
              value:
                  '${AuraFormat.rate(controller.passiveNumerator, locale: s.locale)}/s',
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.art,
    required this.icon,
    required this.label,
    required this.value,
  });
  final ArtCatalog? art;
  final AuraUiIcon icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          AuraAssetIcon(
            catalog: art,
            role: icon,
            fallbackIcon: Icons.circle_outlined,
            semanticLabel: label,
            decorative: true,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF7F5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _AscendButton extends StatelessWidget {
  const _AscendButton({
    required this.strings,
    required this.art,
    required this.gain,
    required this.onTap,
  });
  final Strings strings;
  final ArtCatalog? art;
  final String gain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD166), Color(0xFFFF7A18)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A18).withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AuraAssetIcon(
                catalog: art,
                role: AuraUiIcon.ascension,
                fallbackIcon: Icons.auto_awesome,
                semanticLabel: strings('ascension_title'),
                decorative: true,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                strings('ascension_title'),
                style: const TextStyle(
                  color: Color(0xFF20130A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '×$gain',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Color(0xFF20130A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ]),
          ),
        ),
      );
}

class _AuraArena extends StatelessWidget {
  const _AuraArena({
    required this.scene,
    required this.controller,
    required this.strings,
  });
  final AuraScene scene;
  final GameController controller;
  final Strings strings;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        onTap: scene.activateCycle,
        label: controller.phase == CyclePhase.six
            ? strings('tutorial_first_touch')
            : strings('tutorial_second_touch'),
        child: ValueListenableBuilder<double>(
          valueListenable: scene.charge,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => scene.contactDown(event.pointer),
            onPointerUp: (event) => scene.contactEnded(event.pointer),
            onPointerCancel: (event) => scene.contactEnded(event.pointer),
            child: GameWidget(game: scene),
          ),
          builder: (context, charge, child) {
            final glow = Color.lerp(
              const Color(0xFF8B7CFF),
              const Color(0xFFFFB020),
              charge,
            )!;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.22 + charge * 0.5),
                    blurRadius: 26 + charge * 46,
                    spreadRadius: charge * 5,
                  ),
                ],
              ),
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: child,
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: glow.withValues(alpha: 0.5 + charge * 0.5),
                        width: 1.5 + charge * 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 26,
                  child: IgnorePointer(
                    child: _CoachHint(controller: controller, strings: strings),
                  ),
                ),
              ]),
            );
          },
        ),
      );
}

class _CoachHint extends StatefulWidget {
  const _CoachHint({required this.controller, required this.strings});
  final GameController controller;
  final Strings strings;

  @override
  State<_CoachHint> createState() => _CoachHintState();
}

class _CoachHintState extends State<_CoachHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final s = widget.strings;
    final cycles = ctrl.cycles;
    String text;
    IconData icon = Icons.touch_app;
    if (cycles < 1) {
      text = ctrl.phase == CyclePhase.six
          ? s('tutorial_first_touch')
          : s('tutorial_second_touch');
    } else if (cycles < 3) {
      text = s('tutorial_complete');
      icon = Icons.check_circle_outline;
    } else {
      return const SizedBox.shrink();
    }
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -6 * _c.value),
          child: Opacity(opacity: 0.72 + 0.28 * _c.value, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xF20E1330),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF43E6FF).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43E6FF).withValues(alpha: 0.25),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: const Color(0xFF43E6FF)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFF7F5FF),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Shop extends StatelessWidget {
  const _Shop({
    required this.controller,
    required this.strings,
    required this.art,
    required this.audio,
    required this.onPurchase,
    required this.onComplement,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final AuraAudioController audio;
  final void Function(Upgrade, int) onPurchase;
  final Future<void> Function(Upgrade) onComplement;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(
          children: [
            _ArtworkHeading(
              catalog: art,
              assetId: AuraUiArt.icon(AuraUiIcon.navShop),
              fallbackIcon: Icons.shopping_bag_outlined,
              title: s('nav_shop'),
              semanticLabel: s('nav_shop'),
              large: true,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AuraItemTree(
                controller: controller,
                translate: s.call,
                locale: s.locale,
                art: art,
                onPurchase: onPurchase,
                onComplement: onComplement,
                onDetailsOpen: () async {
                  unawaited(audio.playUiOpen());
                  await audio.beginDuck();
                },
                onDetailsClose: () async {
                  await audio.endDuck();
                  unawaited(audio.playUiClose());
                },
              ),
            ),
          ],
        ));
  }
}

class _Collection extends StatelessWidget {
  const _Collection({
    required this.controller,
    required this.strings,
    required this.art,
    required this.audio,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final AuraAudioController audio;

  @override
  Widget build(BuildContext context) {
    const forms = [
      ('FORM-01', 1000),
      ('FORM-02', 1000000),
      ('FORM-03', 1000000000),
      ('FORM-04', 1000000000000),
      ('FORM-05', 1000000000000000)
    ];
    final seals = controller.seals.toList()..sort();
    return ListView(
        key: const PageStorageKey('collection-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _ArtworkHeading(
            catalog: art,
            assetId: AuraUiArt.icon(AuraUiIcon.navCollection),
            fallbackIcon: Icons.auto_awesome_outlined,
            title: strings('nav_collection'),
            semanticLabel: strings('nav_collection'),
            large: true,
          ),
          const SizedBox(height: 20),
          _ArtworkHeading(
            catalog: art,
            assetId: AuraUiArt.icon(AuraUiIcon.appearance),
            fallbackIcon: Icons.face_retouching_natural,
            title: strings('collection_appearances'),
            semanticLabel: strings('collection_appearances'),
          ),
          const SizedBox(height: 6),
          ...upgrades.where((u) => !u.isTechnique).map((u) {
            final owns = controller.appearances.contains(u.id);
            final equipped = controller.equippedAppearances.contains(u.id);
            final title = strings(u.nameKey);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: owns
                  ? SwitchListTile(
                      key: ValueKey('appearance-toggle-${u.id}'),
                      contentPadding:
                          const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
                      secondary: AuraAssetArt(
                        catalog: art,
                        assetId: AuraUiArt.appearanceThumbnail(u.id),
                        fallback: const Icon(Icons.face_outlined),
                        width: 54,
                        height: 54,
                        semanticLabel: title,
                        decorative: true,
                      ),
                      title: Text(title, maxLines: 2),
                      subtitle: Text(
                        equipped
                            ? strings('collection_equipped')
                            : strings('collection_hidden'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: equipped,
                      onChanged: (enabled) {
                        controller.setAppearanceEquipped(
                          u.id,
                          equipped: enabled,
                        );
                        unawaited(
                          audio.playCollectionChange(hidden: !enabled),
                        );
                      },
                    )
                  : ListTile(
                      leading: AuraAssetArt(
                        catalog: art,
                        assetId: AuraUiArt.appearanceThumbnail(u.id),
                        fallback: const Icon(Icons.face_outlined),
                        width: 54,
                        height: 54,
                        semanticLabel: title,
                        decorative: true,
                        opacity: owns ? 1 : .38,
                      ),
                      title: Text(title, maxLines: 2),
                      subtitle: Text(strings('collection_locked')),
                      trailing: AuraAssetIcon(
                        catalog: art,
                        role: AuraUiIcon.lock,
                        fallbackIcon: Icons.lock_outline,
                        semanticLabel: strings('collection_locked'),
                        size: 26,
                      ),
                    ),
            );
          }),
          const Divider(height: 36),
          _ArtworkHeading(
            catalog: art,
            assetId: AuraUiArt.icon(AuraUiIcon.transformation),
            fallbackIcon: Icons.auto_awesome,
            title: strings('collection_transformations'),
            semanticLabel: strings('collection_transformations'),
          ),
          const SizedBox(height: 6),
          ...forms.map((f) {
            final unlocked = controller.transformations.contains(f.$1);
            final key = f.$1.toLowerCase().replaceAll('-', '_');
            final title = strings('content.$key.name');
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: AuraAssetArt(
                  catalog: art,
                  assetId: AuraUiArt.formThumbnail(f.$1),
                  fallback: const Icon(Icons.auto_awesome_outlined),
                  width: 58,
                  height: 58,
                  semanticLabel: title,
                  decorative: true,
                  opacity: unlocked ? 1 : .38,
                ),
                title: Text(title),
                subtitle: Text(unlocked
                    ? strings('content.$key.description')
                    : strings('shop_tier_required', {
                        'amount': AuraFormat.integer(BigInt.from(f.$2),
                            locale: strings.locale),
                      })),
                trailing: AuraAssetIcon(
                  catalog: art,
                  role: unlocked ? AuraUiIcon.transformation : AuraUiIcon.lock,
                  fallbackIcon:
                      unlocked ? Icons.auto_awesome : Icons.lock_outline,
                  semanticLabel: unlocked
                      ? strings('collection_equipped')
                      : strings('collection_locked'),
                  size: 26,
                ),
              ),
            );
          }),
          const Divider(height: 36),
          _ArtworkHeading(
            catalog: art,
            assetId: AuraUiArt.icon(AuraUiIcon.seal),
            fallbackIcon: Icons.workspace_premium_outlined,
            title: strings('collection_seals'),
            semanticLabel: strings('collection_seals'),
          ),
          const SizedBox(height: 6),
          if (seals.isEmpty)
            Card(
              child: ListTile(
                leading: AuraSealArtwork(
                  catalog: art,
                  semanticLabel: strings('collection_locked'),
                  size: 58,
                  locked: true,
                  decorative: true,
                ),
                title: Text(strings('collection_locked')),
              ),
            ),
          ...seals.map((seal) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: AuraSealArtwork(
                    catalog: art,
                    semanticLabel: seal,
                    size: 62,
                    decorative: true,
                  ),
                  title: Text(seal, textDirection: TextDirection.ltr),
                  trailing: AuraAssetIcon(
                    catalog: art,
                    role: AuraUiIcon.seal,
                    fallbackIcon: Icons.workspace_premium,
                    semanticLabel: strings('collection_seals'),
                    size: 26,
                  ),
                ),
              )),
          const Divider(height: 36),
          _ArtworkHeading(
            catalog: art,
            assetId: AuraUiArt.icon(AuraUiIcon.achievement),
            fallbackIcon: Icons.verified_outlined,
            title: strings('collection_achievements'),
            semanticLabel: strings('collection_achievements'),
          ),
          const SizedBox(height: 6),
          ...achievementIds.map((id) {
            final unlocked = controller.achievements.contains(id);
            final secret = id.startsWith('ACH-S');
            final key = id.toLowerCase().replaceAll('-', '_');
            final revealed = unlocked || !secret;
            final title = revealed
                ? strings('content.$key.name')
                : strings('collection_secret');
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: AuraAssetArt(
                  catalog: art,
                  assetId: revealed
                      ? AuraUiArt.achievementBadge(id)
                      : AuraUiArt.icon(AuraUiIcon.lock),
                  fallback: Icon(unlocked ? Icons.verified : Icons.lock_outline,
                      color: unlocked ? const Color(0xFFB7F171) : null),
                  width: 56,
                  height: 56,
                  semanticLabel: title,
                  decorative: true,
                  opacity: unlocked ? 1 : .42,
                ),
                title: Text(title),
                subtitle: Text(revealed
                    ? strings('content.$key.description')
                    : strings('collection_locked')),
                trailing: unlocked
                    ? AuraAssetIcon(
                        catalog: art,
                        role: AuraUiIcon.achievement,
                        fallbackIcon: Icons.verified,
                        semanticLabel: strings(
                            'collection_achievement_unlocked', {'name': title}),
                        size: 26,
                      )
                    : null,
              ),
            );
          })
        ]);
  }
}

class _Settings extends StatelessWidget {
  const _Settings({
    required this.controller,
    required this.strings,
    required this.art,
    required this.audio,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final AuraAudioController audio;

  @override
  Widget build(BuildContext context) => ListView(
          key: const PageStorageKey('settings-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            _ArtworkHeading(
              catalog: art,
              assetId: AuraUiArt.icon(AuraUiIcon.navSettings),
              fallbackIcon: Icons.tune_outlined,
              title: strings('nav_settings'),
              semanticLabel: strings('nav_settings'),
              large: true,
            ),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                        initialValue: strings.locale,
                        decoration: InputDecoration(
                            labelText: strings('settings_language'),
                            border: InputBorder.none),
                        items: Strings.supported.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) async {
                          if (value == null) return;
                          controller.setLocale(value);
                          await strings.change(value);
                        }))),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: audio,
              builder: (context, _) => Column(children: [
                _AudioVolumeCard(
                  label: strings('settings_music'),
                  value: audio.musicVolume,
                  enabled: !audio.musicMuted,
                  icon: Icons.music_note,
                  onEnabledChanged: (enabled) {
                    unawaited(audio.setMusicMuted(!enabled));
                    unawaited(audio.playToggle(enabled));
                  },
                  onVolumeChanged: (value) =>
                      unawaited(audio.setMusicVolume(value)),
                ),
                _AudioVolumeCard(
                  label: strings('settings_sound_effects'),
                  value: audio.effectsVolume,
                  enabled: !audio.effectsMuted,
                  icon: Icons.volume_up_outlined,
                  onEnabledChanged: (enabled) =>
                      unawaited(audio.setEffectsEnabled(enabled)),
                  onVolumeChanged: (value) =>
                      unawaited(audio.setEffectsVolume(value)),
                ),
              ]),
            ),
            _Switch(strings('settings_reduce_motion'), controller.reduceMotion,
                (v) {
              controller.setBool('reduceMotion', v);
              unawaited(audio.playToggle(v));
            }),
            _Switch(strings('settings_high_contrast'), controller.highContrast,
                (v) {
              controller.setBool('highContrast', v);
              unawaited(audio.playToggle(v));
            }),
            _Switch(strings('analytics_setting'), controller.analyticsEnabled,
                (v) {
              controller.chooseAnalytics(v);
              unawaited(audio.playToggle(v));
            }),
            Card(
                child: ListTile(
                    leading: AuraAssetIcon(
                      catalog: art,
                      role: AuraUiIcon.backup,
                      fallbackIcon: Icons.save_outlined,
                      semanticLabel: strings('backup_title'),
                      size: 32,
                    ),
                    title: Text(strings('backup_title')),
                    subtitle: Text(strings('backup_explain')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _backup(context))),
            ListTile(
                title: Text(strings('settings_version', {'version': '0.1.5'})),
                subtitle:
                    const Text('Development build · arith-v1 · balance-v0.3'))
          ]);
  Future<void> _backup(BuildContext context) async {
    unawaited(audio.playUiOpen());
    await audio.beginDuck();
    if (!context.mounted) {
      await audio.endDuck();
      return;
    }
    try {
      await showModalBottomSheet<void>(
          context: context,
          builder: (sheet) => _Sheet(
              title: strings('backup_title'),
              body: strings('backup_explain'),
              artwork: AuraAssetIcon(
                catalog: art,
                role: AuraUiIcon.backup,
                fallbackIcon: Icons.save_outlined,
                semanticLabel: strings('backup_title'),
                size: 58,
              ),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await BackupService.exportAndShare(controller);
                            if (sheet.mounted) {
                              ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(
                                  content:
                                      Text(strings('backup_export_success'))));
                            }
                          } catch (_) {
                            unawaited(audio.playUiError());
                            if (sheet.mounted) {
                              ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(
                                  content:
                                      Text(strings('backup_export_failed'))));
                            }
                          }
                        },
                        child: Text(strings('backup_export')))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: () async {
                          final payload = await BackupService.pickPayload();
                          if (payload == null || !sheet.mounted) return;
                          final approve = await showDialog<bool>(
                              context: sheet,
                              builder: (dialog) => AlertDialog(
                                      title:
                                          Text(strings('backup_preview_title')),
                                      content: Text(
                                          strings('backup_replace_warning')),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialog, false),
                                            child:
                                                Text(strings('action_cancel'))),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(dialog, true),
                                            child:
                                                Text(strings('backup_restore')))
                                      ]));
                          if (approve == true) {
                            final restored =
                                await controller.restoreState(payload);
                            if (!restored) {
                              unawaited(audio.playUiError());
                              if (sheet.mounted) {
                                ScaffoldMessenger.of(sheet)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text(strings('backup_restore_failed')),
                                ));
                              }
                            }
                          }
                        },
                        child: Text(strings('backup_import'))))
              ])));
    } finally {
      await audio.endDuck();
      unawaited(audio.playUiClose());
    }
  }
}

class _AudioVolumeCard extends StatelessWidget {
  const _AudioVolumeCard({
    required this.label,
    required this.value,
    required this.enabled,
    required this.icon,
    required this.onEnabledChanged,
    required this.onVolumeChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final IconData icon;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: [
          SwitchListTile(
            secondary: Icon(icon),
            title: Text(label),
            subtitle: Text('${(value * 100).round()}%'),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          Slider(
            value: value,
            onChanged: enabled ? onVolumeChanged : null,
            semanticFormatterCallback: (value) =>
                '$label ${(value * 100).round()}%',
          ),
        ]),
      );
}

class _Switch extends StatelessWidget {
  const _Switch(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Card(
      child: SwitchListTile(
          title: Text(label), value: value, onChanged: onChanged));
}

class _ArtworkHeading extends StatelessWidget {
  const _ArtworkHeading({
    required this.catalog,
    required this.assetId,
    required this.fallbackIcon,
    required this.title,
    required this.semanticLabel,
    this.large = false,
  });

  final ArtCatalog? catalog;
  final String assetId;
  final IconData fallbackIcon;
  final String title;
  final String semanticLabel;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 46.0;
    return Row(
      children: [
        AuraAssetArt(
          catalog: catalog,
          assetId: assetId,
          fallback: Icon(fallbackIcon, size: size * .65),
          width: size,
          height: size,
          semanticLabel: semanticLabel,
          decorative: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: large
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.body,
    required this.child,
    this.artwork,
  });
  final String title, body;
  final Widget child;
  final Widget? artwork;

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  if (artwork != null) ...[
                    artwork!,
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(body),
                const SizedBox(height: 20),
                child
              ])));
}
