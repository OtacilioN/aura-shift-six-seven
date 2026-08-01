import 'dart:async';
import 'dart:collection';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/aura_audio_controller.dart';
import '../achievements/achievement_sync_service.dart';
import '../cloud_save/cloud_save_coordinator.dart';
import '../cloud_save/cloud_save_models.dart';
import '../core/formatting.dart';
import '../core/game_controller.dart';
import '../core/rewarded_ads.dart';
import '../core/return_reminder_notifications.dart';
import '../core/return_reminder_schedule.dart';
import '../core/store_review.dart';
import '../game/art_catalog.dart';
import '../game/aura_scene.dart';
import '../main.dart';
import '../play_games/play_games_coordinator.dart';
import 'art_widgets.dart';
import 'aura_details_sheet.dart';
import 'aura_achievements.dart';
import 'aura_rankings.dart';
import 'ascension_sheet.dart';
import 'aura_tree.dart';
import 'cloud_save_section.dart';
import 'progression_guidance.dart';
import 'return_reward_sheet.dart';

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
    required this.rewardedAds,
    required this.returnReminders,
    required this.storeReview,
    required this.playGames,
    required this.achievements,
    required this.cloudSave,
  });
  final GameController controller;
  final Strings strings;
  final AuraAudioController audio;
  final RewardedAds rewardedAds;
  final ReturnReminderNotifications returnReminders;
  final StoreReview storeReview;
  final PlayGamesCoordinator playGames;
  final AchievementSyncService achievements;
  final CloudSaveCoordinator cloudSave;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int tab = 0;
  String? _shopFocusUpgradeId;
  int _shopFocusRequestToken = 0;
  bool promptedAnalytics = false;
  bool promptedReturn = false;
  final ListQueue<_VisualFeedback> _visualFeedback = ListQueue();
  late final AuraScene scene;
  late final Future<ArtCatalog?> artCatalog;
  late Set<String> _knownTransformations;
  late Set<String> _knownSeals;
  bool _showingVisualFeedback = false;
  bool _rewardedUpgradeInFlight = false;
  bool _storeReviewInFlight = false;
  bool _storeReviewCheckQueued = false;
  bool _showingCloudConflict = false;
  String? _lastPromptedCloudConflict;
  late bool _adsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scene = AuraScene(widget.controller, widget.audio);
    unawaited(widget.audio.start(widget.controller));
    artCatalog = _loadArtCatalog();
    _knownTransformations = widget.controller.transformations;
    _knownSeals = widget.controller.seals;
    _adsEnabled =
        widget.controller.adsUnlocked && widget.controller.adOfferExplained;
    widget.controller.addListener(_detectUnlocks);
    widget.cloudSave.addListener(_handleCloudSave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.rewardedAds.setEnabled(_adsEnabled));
      _queueStoreReview();
      _handleCloudSave();
    });
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
    widget.cloudSave.removeListener(_handleCloudSave);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _detectUnlocks() {
    final adsEnabled =
        widget.controller.adsUnlocked && widget.controller.adOfferExplained;
    if (adsEnabled != _adsEnabled) {
      _adsEnabled = adsEnabled;
      unawaited(widget.rewardedAds.setEnabled(adsEnabled));
    }
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

    _queueStoreReview();
  }

  void _queueStoreReview() {
    if (!widget.controller.storeReviewEligible ||
        widget.controller.returnRewardAvailable ||
        _storeReviewInFlight ||
        _storeReviewCheckQueued) {
      return;
    }
    _storeReviewCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storeReviewCheckQueued = false;
      unawaited(_requestStoreReviewWhenClear());
    });
  }

  Future<void> _requestStoreReviewWhenClear() async {
    if (_storeReviewInFlight ||
        !widget.controller.storeReviewEligible ||
        widget.controller.returnRewardAvailable) {
      return;
    }
    while (mounted && (_showingVisualFeedback || _visualFeedback.isNotEmpty)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted ||
        !widget.controller.storeReviewEligible ||
        widget.controller.returnRewardAvailable) {
      return;
    }
    _storeReviewInFlight = true;
    widget.controller.markStoreReviewRequested();
    try {
      await widget.storeReview.request();
    } catch (_) {
      // Store review availability and quota are owned by the platform.
    } finally {
      _storeReviewInFlight = false;
    }
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
      unawaited(widget.cloudSave.onAppPaused());
      unawaited(widget.playGames.onPaused());
      unawaited(widget.achievements.onPaused());
      scene.pauseEngine();
      unawaited(_scheduleReturnReminder());
    }
    if (state == AppLifecycleState.resumed) {
      // Local gameplay must never wait for optional platform integrations.
      // In particular, notification cancellation and cloud/Play Games calls
      // can be delayed while Android is leaving Doze after the screen unlocks.
      widget.controller.resume();
      if (tab == 0) scene.resumeEngine();
      unawaited(_resumeFromBackground());
    }
  }

  Future<void> _resumeFromBackground() async {
    await _runBestEffortLifecycleTask(
      'while cancelling the return reminder',
      widget.returnReminders.cancel,
    );
    await _runBestEffortLifecycleTask(
      'while resuming cloud save',
      widget.cloudSave.onAppResumed,
    );
    await _runBestEffortLifecycleTask(
      'while resuming Play Games',
      widget.playGames.onResumed,
    );
    await _runBestEffortLifecycleTask(
      'while resuming achievement sync',
      widget.achievements.onResumed,
    );
  }

  Future<void> _runBestEffortLifecycleTask(
    String context,
    Future<void> Function() task,
  ) async {
    try {
      await task();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Aura Shift lifecycle',
        context: ErrorDescription(context),
      ));
    }
  }

  void _handleCloudSave() {
    final state = widget.cloudSave.state;
    if (state is! CloudSaveConflictPending || _showingCloudConflict) return;
    final conflict = state.conflict;
    final identity = conflict.nativeConflictToken ??
        '${conflict.playerId}:${conflict.first.envelope.payloadHash}:'
            '${conflict.second?.envelope.payloadHash ?? 'account-switch'}';
    if (_lastPromptedCloudConflict == identity) return;
    _lastPromptedCloudConflict = identity;
    _showingCloudConflict = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _showingCloudConflict = false;
        return;
      }
      await showCloudSaveConflictDialog(
        context,
        coordinator: widget.cloudSave,
        strings: widget.strings,
      );
      _showingCloudConflict = false;
    });
  }

  Future<void> _scheduleReturnReminder() async {
    final controller = widget.controller;
    if (!controller.returnReminderEnabled || controller.returnRewardAvailable) {
      return;
    }
    try {
      await widget.returnReminders.schedule(
        scheduledAt: ReturnReminderSchedule.afterLeaving(DateTime.now()),
        title: widget.strings('return_reminder_notification_title'),
        body: widget.strings('return_reminder_notification_body'),
      );
    } catch (_) {
      // This optional convenience must not affect saving the offline reward.
    }
  }

  Future<void> _maybePromptReturnReminder() async {
    final controller = widget.controller;
    if (!mounted || controller.returnReminderPrompted) return;
    final wantsReminder = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(widget.strings('return_reminder_prompt_title')),
        content: Text(widget.strings('return_reminder_prompt_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(widget.strings('return_reminder_not_now')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(widget.strings('return_reminder_enable')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (wantsReminder != true) {
      controller.chooseReturnReminder(false);
      return;
    }
    final granted = await widget.returnReminders.requestPermission();
    if (mounted) controller.chooseReturnReminder(granted);
  }

  void _selectTab(int value) {
    if (value == tab) return;
    if (tab == 0) scene.pauseEngine();
    if (value == 0) scene.resumeEngine();
    setState(() => tab = value);
    unawaited(widget.audio.changeTab(value));
  }

  void _openShopUpgrade(String upgradeId) {
    final changedTab = tab != 1;
    if (tab == 0) scene.pauseEngine();
    setState(() {
      tab = 1;
      _shopFocusUpgradeId = upgradeId;
      _shopFocusRequestToken++;
    });
    if (changedTab) unawaited(widget.audio.changeTab(1));
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
        _returnRewardDialog().whenComplete(() async {
          await _maybePromptReturnReminder();
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
            onOpenUpgrade: _openShopUpgrade,
          ),
          _Shop(
            controller: c,
            strings: s,
            art: art,
            audio: widget.audio,
            onPurchase: _buyUpgrade,
            onRewardedUpgrade: _claimRewardedUpgrade,
            focusUpgradeId: _shopFocusUpgradeId,
            focusRequestToken: _shopFocusRequestToken,
          ),
          AuraCollectionView(
            controller: c,
            strings: s,
            art: art,
            audio: widget.audio,
          ),
          _Settings(
            controller: c,
            strings: s,
            art: art,
            audio: widget.audio,
            rewardedAds: widget.rewardedAds,
            returnReminders: widget.returnReminders,
            playGames: widget.playGames,
            achievements: widget.achievements,
            cloudSave: widget.cloudSave,
          ),
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

  Widget _iconArtwork(
    AuraUiIcon role,
    String label,
    IconData fallback, {
    double size = 56,
  }) =>
      FutureBuilder<ArtCatalog?>(
        future: artCatalog,
        builder: (_, snapshot) => AuraAssetIcon(
          catalog: snapshot.data,
          role: role,
          fallbackIcon: fallback,
          semanticLabel: label,
          size: size,
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
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: const Color(0xFF03040C).withValues(alpha: .78),
          builder: (sheet) {
            final c = widget.controller;
            final s = widget.strings;
            return AnimatedBuilder(
              animation: c,
              builder: (context, _) {
                final gain = c.ascensionGain();
                final resultingMultiplier = c.multiplier + gain;
                return AscensionSheet(
                  strings: s,
                  artwork: _eventArtwork(
                    AuraEventArtwork.ascension,
                    s('ascension_title'),
                    fallback: Icons.upgrade,
                  ),
                  currentMultiplier: AuraFormat.multiplier(c.multiplier),
                  gainedMultiplier: AuraFormat.multiplier(gain),
                  resultingMultiplier:
                      AuraFormat.multiplier(resultingMultiplier),
                  journeyAura: AuraFormat.integer(c.journey, locale: s.locale),
                  highContrast: c.highContrast,
                  reduceMotion: c.reduceMotion,
                  onAscend: () {
                    widget.audio.prepareAscension();
                    c.ascend();
                    widget.cloudSave.requestPrioritySync();
                    unawaited(widget.audio.playAscension());
                    _enqueueVisualFeedback(
                      AuraEventArtwork.ascension,
                      s('ascension_title'),
                      s('ascension_complete', {
                        'multiplier': '${AuraFormat.multiplier(c.multiplier)}×',
                      }),
                    );
                    Navigator.pop(sheet);
                  },
                );
              },
            );
          }));

  Future<void> _returnRewardDialog() {
    return _withSheetAudio(() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheet) {
          final base = AuraFormat.integer(
            widget.controller.returnBase ~/ BigInt.from(10000000),
            locale: widget.strings.locale,
          );
          final bonus = AuraFormat.integer(
            widget.controller.returnBonus ~/ BigInt.from(10000000),
            locale: widget.strings.locale,
          );
          final awayMilliseconds = widget.controller.returnAwayMilliseconds;
          final creditedMilliseconds =
              widget.controller.returnCreditedMilliseconds;
          return ReturnRewardSheet(
            strings: widget.strings,
            baseAmount: base,
            bonusAmount: bonus,
            awayDuration: awayMilliseconds > 0
                ? Duration(milliseconds: awayMilliseconds)
                : null,
            creditCapped: creditedMilliseconds > 0 &&
                creditedMilliseconds < awayMilliseconds,
            bonusAvailable: widget.controller.returnBonusAvailable,
            highContrast: widget.controller.highContrast,
            reduceMotion: widget.controller.reduceMotion,
            auraArtwork: _iconArtwork(
              AuraUiIcon.auraAvailable,
              widget.strings('return_title'),
              Icons.auto_awesome_rounded,
            ),
            timeArtwork: _iconArtwork(
              AuraUiIcon.passiveRate,
              widget.strings('return_away_time'),
              Icons.schedule_rounded,
              size: 18,
            ),
            bonusArtwork: _iconArtwork(
              AuraUiIcon.rewardedAd,
              widget.strings('return_bonus_title'),
              Icons.smart_display_rounded,
              size: 32,
            ),
            onClaimBase: widget.controller.claimReturnBase,
            onClaimBonus: () async {
              if (!await _explainFirstAdOffer(sheet)) {
                return ReturnBonusOutcome.cancelled;
              }
              if (!widget.controller.returnBonusAvailable) {
                return ReturnBonusOutcome.cancelled;
              }
              try {
                final rewarded = await _showRewardedAd(
                  RewardedPlacement.returnBonus,
                );
                if (!rewarded) {
                  unawaited(widget.audio.playUiError());
                  return ReturnBonusOutcome.failed;
                }
                final credited = widget.controller.resolveReturnBonus(
                  rewarded: true,
                );
                if (!credited) {
                  unawaited(widget.audio.playUiError());
                  return ReturnBonusOutcome.failed;
                }
                unawaited(widget.audio.playReturnBonus());
                return ReturnBonusOutcome.claimed;
              } catch (_) {
                unawaited(widget.audio.playUiError());
                return ReturnBonusOutcome.failed;
              }
            },
          );
        }));
  }

  Future<bool> _explainFirstAdOffer(BuildContext dialogContext) async {
    if (widget.controller.adOfferExplained) return true;
    final proceed = await showDialog<bool>(
          context: dialogContext,
          builder: (dialog) => AlertDialog(
            title: Text(widget.strings('ads_first_offer_title')),
            content: Text(widget.strings('ads_first_offer_body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(widget.strings('ads_first_offer_not_now')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(widget.strings('ads_first_offer_continue')),
              ),
            ],
          ),
        ) ??
        false;
    if (proceed) {
      widget.controller.markAdOfferExplained();
      _adsEnabled = true;
      await widget.rewardedAds.setEnabled(true);
    }
    return proceed;
  }

  Future<void> _claimRewardedUpgrade(Upgrade upgrade) async {
    if (_rewardedUpgradeInFlight) return;
    _rewardedUpgradeInFlight = true;
    if (mounted) setState(() {});
    try {
      if (!await _explainFirstAdOffer(context)) return;
      final quote = widget.controller.beginRewardedUpgrade(upgrade);
      if (quote == null) return;
      var rewarded = false;
      try {
        rewarded = await _showRewardedAd(RewardedPlacement.shopUpgrade);
      } catch (_) {}
      final redeemed = widget.controller.redeemRewardedUpgrade(
        quote,
        rewarded: rewarded,
      );
      if (redeemed) {
        final after = quote.level + quote.levelsGranted;
        _announcePurchase(upgrade, quote.level, after);
        unawaited(widget.audio.playPurchaseResult(
          success: true,
          quantity: quote.levelsGranted,
          unlockedAppearance: !upgrade.isTechnique && quote.level == 0,
          levelMilestone: _crossedMilestone(quote.level, after),
        ));
      } else if (mounted) {
        unawaited(
          widget.audio.playPurchaseResult(success: false, quantity: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.strings('shop_ad_unavailable')),
        ));
      }
    } finally {
      _rewardedUpgradeInFlight = false;
      if (mounted) setState(() {});
    }
  }

  Future<bool> _showRewardedAd(RewardedPlacement placement) async {
    var audioTransition = Future<void>.value();
    var interrupted = false;

    void queueAudioTransition(Future<void> Function() transition) {
      audioTransition = audioTransition
          .catchError((_) {})
          .then((_) => transition())
          .catchError((_) {});
    }

    void pauseForFullscreen() {
      if (interrupted) return;
      interrupted = true;
      queueAudioTransition(widget.audio.pauseForInterruption);
    }

    void resumeAfterFullscreen() {
      if (!interrupted) return;
      interrupted = false;
      queueAudioTransition(widget.audio.resumeAfterInterruption);
    }

    try {
      return await widget.rewardedAds.show(
        placement,
        onAdShowed: pauseForFullscreen,
        onAdClosed: resumeAfterFullscreen,
      );
    } finally {
      // Fail safe if the SDK throws after opening but before its close callback.
      resumeAfterFullscreen();
      await audioTransition;
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
    required this.onOpenUpgrade,
  });
  final GameController controller;
  final Strings strings;
  final AuraScene scene;
  final ArtCatalog? art;
  final AuraAudioController audio;
  final VoidCallback ascend;
  final ValueChanged<String> onOpenUpgrade;
  @override
  Widget build(BuildContext context) => Column(children: [
        _AuraHud(
          controller: controller,
          strings: strings,
          art: art,
          onDetails: () => _details(context),
          onNextSteps: () => _showNextSteps(context),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: _AuraArena(
                    scene: scene,
                    controller: controller,
                    strings: strings,
                  ),
                ),
              ),
              if (controller.canAscend)
                PositionedDirectional(
                  top: 20,
                  end: 24,
                  child: _AscendButton(
                    strings: strings,
                    art: art,
                    gain: AuraFormat.multiplier(controller.ascensionGain()),
                    highContrast: controller.highContrast,
                    onTap: ascend,
                  ),
                ),
            ],
          ),
        ),
      ]);

  Future<void> _showNextSteps(BuildContext context) async {
    unawaited(audio.playUiOpen());
    await audio.beginDuck();
    if (!context.mounted) {
      await audio.endDuck();
      return;
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        builder: (sheet) => AuraNextStepsSheet(
          controller: controller,
          strings: strings,
          onOpenUpgrade: (upgradeId) {
            Navigator.pop(sheet);
            onOpenUpgrade(upgradeId);
          },
        ),
      );
    } finally {
      await audio.endDuck();
      unawaited(audio.playUiClose());
    }
  }

  Future<void> _details(BuildContext context) async {
    final snapshot = AuraDetailsSnapshot.fromController(controller);
    unawaited(audio.playUiOpen());
    await audio.beginDuck();
    if (!context.mounted) {
      await audio.endDuck();
      return;
    }
    try {
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => AuraDetailsSheet(
              snapshot: snapshot,
              strings: strings,
              artwork: AuraAssetIcon(
                catalog: art,
                role: AuraUiIcon.cyclePower,
                fallbackIcon: Icons.bolt,
                semanticLabel: strings('play_cycle_power'),
                size: 56,
              )));
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
    required this.onNextSteps,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final VoidCallback onDetails;
  final VoidCallback onNextSteps;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuraNextStepsTrigger(
                strings: s,
                onTap: onNextSteps,
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
            ],
          ),
        ]),
        const SizedBox(height: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    required this.highContrast,
    required this.onTap,
  });
  final Strings strings;
  final ArtCatalog? art;
  final String gain;
  final bool highContrast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFCE73);
    return Semantics(
      button: true,
      label: strings('ascension_title'),
      value: strings(
        'ascension_gain',
        {'multiplier': '$gain×'},
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xE6131630),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: highContrast ? Colors.white : gold.withValues(alpha: .62),
              width: highContrast ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: .22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: InkWell(
            key: const ValueKey('ascension-trigger'),
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(7, 6, 12, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            gold.withValues(alpha: .28),
                            const Color(0xFFFF8A3D).withValues(alpha: .12),
                          ],
                        ),
                      ),
                      child: Center(
                        child: AuraAssetIcon(
                          catalog: art,
                          role: AuraUiIcon.ascension,
                          fallbackIcon: Icons.auto_awesome,
                          semanticLabel: strings('ascension_title'),
                          decorative: true,
                          size: 23,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings('ascension_confirm_action'),
                          style: const TextStyle(
                            color: Color(0xFFF7F5FF),
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '+$gain×',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    required this.onRewardedUpgrade,
    required this.focusUpgradeId,
    required this.focusRequestToken,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final AuraAudioController audio;
  final void Function(Upgrade, int) onPurchase;
  final Future<void> Function(Upgrade) onRewardedUpgrade;
  final String? focusUpgradeId;
  final int focusRequestToken;

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
                onRewardedUpgrade: onRewardedUpgrade,
                focusUpgradeId: focusUpgradeId,
                focusRequestToken: focusRequestToken,
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

enum _CollectionSection {
  appearances,
  transformations,
  seals,
}

class AuraCollectionView extends StatefulWidget {
  const AuraCollectionView({
    super.key,
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
  State<AuraCollectionView> createState() => _AuraCollectionViewState();
}

class _AuraCollectionViewState extends State<AuraCollectionView> {
  static const _forms = [
    ('FORM-01', 1000),
    ('FORM-02', 1000000),
    ('FORM-03', 1000000000),
    ('FORM-04', 1000000000000),
    ('FORM-05', 1000000000000000),
  ];

  _CollectionSection _section = _CollectionSection.appearances;

  GameController get controller => widget.controller;
  Strings get strings => widget.strings;
  ArtCatalog? get art => widget.art;
  AuraAudioController get audio => widget.audio;

  @override
  Widget build(BuildContext context) {
    final appearanceItems =
        upgrades.where((upgrade) => !upgrade.isTechnique).toList();
    final appearanceIds = appearanceItems.map((upgrade) => upgrade.id).toSet();
    final formIds = _forms.map((form) => form.$1).toSet();
    final seals = controller.seals.toList()..sort();

    final sections = <_CollectionSection, _CollectionSectionData>{
      _CollectionSection.appearances: _CollectionSectionData(
        label: strings('collection_appearances'),
        count:
            '${controller.appearances.where(appearanceIds.contains).length}/${appearanceItems.length}',
        assetId: AuraUiArt.icon(AuraUiIcon.appearance),
        iconRole: AuraUiIcon.appearance,
        fallbackIcon: Icons.face_retouching_natural,
      ),
      _CollectionSection.transformations: _CollectionSectionData(
        label: strings('collection_transformations'),
        count:
            '${controller.transformations.where(formIds.contains).length}/${_forms.length}',
        assetId: AuraUiArt.icon(AuraUiIcon.transformation),
        iconRole: AuraUiIcon.transformation,
        fallbackIcon: Icons.auto_awesome,
      ),
      _CollectionSection.seals: _CollectionSectionData(
        label: strings('collection_seals'),
        count: '${seals.length}',
        assetId: AuraUiArt.icon(AuraUiIcon.seal),
        iconRole: AuraUiIcon.seal,
        fallbackIcon: Icons.workspace_premium_outlined,
      ),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ArtworkHeading(
                catalog: art,
                assetId: AuraUiArt.icon(AuraUiIcon.navCollection),
                fallbackIcon: Icons.auto_awesome_outlined,
                title: strings('nav_collection'),
                semanticLabel: strings('nav_collection'),
                large: true,
              ),
              const SizedBox(height: 18),
              _CollectionSectionPicker(
                sections: sections,
                selected: _section,
                art: art,
                onSelected: (section) => setState(() => _section = section),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _section.index,
            children: [
              _appearanceList(
                appearanceItems,
                sections[_CollectionSection.appearances]!,
              ),
              _transformationList(
                sections[_CollectionSection.transformations]!,
              ),
              _sealList(seals, sections[_CollectionSection.seals]!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionList({
    required String storageKey,
    required _CollectionSectionData section,
    required List<Widget> children,
  }) =>
      ListView(
        key: PageStorageKey(storageKey),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ArtworkHeading(
            catalog: art,
            assetId: section.assetId,
            fallbackIcon: section.fallbackIcon,
            title: section.label,
            semanticLabel: section.label,
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      );

  Widget _appearanceList(
    List<Upgrade> appearanceItems,
    _CollectionSectionData section,
  ) =>
      _sectionList(
        storageKey: 'collection-appearances-scroll',
        section: section,
        children: [
          ...appearanceItems.map((u) {
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
        ],
      );

  Widget _transformationList(_CollectionSectionData section) => _sectionList(
        storageKey: 'collection-transformations-scroll',
        section: section,
        children: [
          ..._forms.map((f) {
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
        ],
      );

  Widget _sealList(
    List<String> seals,
    _CollectionSectionData section,
  ) =>
      _sectionList(
        storageKey: 'collection-seals-scroll',
        section: section,
        children: [
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
        ],
      );
}

class _CollectionSectionData {
  const _CollectionSectionData({
    required this.label,
    required this.count,
    required this.assetId,
    required this.iconRole,
    required this.fallbackIcon,
  });

  final String label;
  final String count;
  final String assetId;
  final AuraUiIcon iconRole;
  final IconData fallbackIcon;
}

class _CollectionSectionPicker extends StatelessWidget {
  const _CollectionSectionPicker({
    required this.sections,
    required this.selected,
    required this.art,
    required this.onSelected,
  });

  final Map<_CollectionSection, _CollectionSectionData> sections;
  final _CollectionSection selected;
  final ArtCatalog? art;
  final ValueChanged<_CollectionSection> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final columns = constraints.maxWidth >= 640 ? 4 : 2;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final entry in sections.entries)
                SizedBox(
                  width: width,
                  child: _CollectionSectionButton(
                    key: ValueKey(
                      'collection-section-${entry.key.name}',
                    ),
                    section: entry.value,
                    selected: selected == entry.key,
                    art: art,
                    onTap: () => onSelected(entry.key),
                  ),
                ),
            ],
          );
        },
      );
}

class _CollectionSectionButton extends StatelessWidget {
  const _CollectionSectionButton({
    super.key,
    required this.section,
    required this.selected,
    required this.art,
    required this.onTap,
  });

  final _CollectionSectionData section;
  final bool selected;
  final ArtCatalog? art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF43E6FF);
    final titleLineHeight =
        (MediaQuery.textScalerOf(context).scale(13) * 1.35).clamp(18.0, 30.0);
    final borderColor = selected
        ? cyan.withValues(alpha: .68)
        : Colors.white.withValues(alpha: .09);
    final backgroundColor = selected
        ? cyan.withValues(alpha: .13)
        : const Color(0xFF161B3A).withValues(alpha: .72);

    return Semantics(
      button: true,
      selected: selected,
      label: section.label,
      value: section.count,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: titleLineHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        section.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFF7F5FF)
                              : const Color(0xFFC9C7D8),
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AuraAssetIcon(
                        catalog: art,
                        role: section.iconRole,
                        fallbackIcon: section.fallbackIcon,
                        semanticLabel: section.label,
                        decorative: true,
                        size: 24,
                        opacity: selected ? 1 : .68,
                      ),
                      const Spacer(),
                      Container(
                        key: ValueKey(
                          'collection-count-${section.iconRole.name}',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cyan.withValues(alpha: .18)
                              : Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          section.count,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: selected ? cyan : const Color(0xFFC9C7D8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({
    required this.controller,
    required this.strings,
    required this.art,
    required this.audio,
    required this.rewardedAds,
    required this.returnReminders,
    required this.playGames,
    required this.achievements,
    required this.cloudSave,
  });
  final GameController controller;
  final Strings strings;
  final ArtCatalog? art;
  final AuraAudioController audio;
  final RewardedAds rewardedAds;
  final ReturnReminderNotifications returnReminders;
  final PlayGamesCoordinator playGames;
  final AchievementSyncService achievements;
  final CloudSaveCoordinator cloudSave;

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
            _Switch(
              strings('return_reminder_settings'),
              controller.returnReminderEnabled,
              (enabled) async {
                if (!enabled) {
                  controller.setReturnReminderEnabled(false);
                  await returnReminders.cancel();
                  unawaited(audio.playToggle(false));
                  return;
                }
                final granted = await returnReminders.requestPermission();
                if (!context.mounted) return;
                controller.setReturnReminderEnabled(granted);
                if (granted) {
                  unawaited(audio.playToggle(true));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings('return_reminder_permission_denied'),
                      ),
                    ),
                  );
                }
              },
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
                key: const ValueKey('open-aura-achievements'),
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(
                  strings.locale == 'pt-BR' ? 'Conquistas' : 'Achievements',
                ),
                subtitle: Text(
                  strings.locale == 'pt-BR'
                      ? 'Sincronize seu progresso com o Google Play Games.'
                      : 'Sync your progress with Google Play Games.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  unawaited(audio.playUiOpen());
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => AuraAchievementsScreen(
                      coordinator: achievements,
                      locale: strings.locale,
                    ),
                  ));
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(strings('settings_privacy_policy')),
                subtitle: Text(strings('settings_privacy_policy_body')),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openPrivacyPolicy(context),
              ),
            ),
            AnimatedBuilder(
              animation: rewardedAds,
              builder: (context, _) => rewardedAds.privacyOptionsRequired
                  ? Card(
                      child: ListTile(
                        leading: const Icon(Icons.tune_outlined),
                        title: Text(strings('settings_ad_privacy_options')),
                        subtitle:
                            Text(strings('settings_ad_privacy_options_body')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showAdPrivacyOptions(context),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Card(
              child: ListTile(
                key: const ValueKey('open-aura-rankings'),
                leading: const Icon(Icons.leaderboard_outlined),
                title: Text(strings.locale == 'pt-BR'
                    ? 'Rankings de Aura'
                    : 'Aura Leaderboards'),
                subtitle: Text(strings.locale == 'pt-BR'
                    ? 'Compare sua produção global e com amigos.'
                    : 'Compare your production globally and with friends.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  unawaited(audio.playUiOpen());
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => AuraRankingsScreen(
                      coordinator: playGames,
                      strings: strings,
                    ),
                  ));
                },
              ),
            ),
            CloudSaveSection(
              coordinator: cloudSave,
              strings: strings,
            ),
            ListTile(
                title: Text(strings('settings_version', {'version': '6.7.0'})),
                subtitle: const Text('arith-v1 · balance-v0.4'))
          ]);

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse('https://sixseven.otaciliomaia.com/privacy/'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings('system_external_link_failed'))),
      );
    }
  }

  Future<void> _showAdPrivacyOptions(BuildContext context) async {
    final shown = await rewardedAds.showPrivacyOptions();
    if (!shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings('settings_ad_privacy_failed'))),
      );
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
