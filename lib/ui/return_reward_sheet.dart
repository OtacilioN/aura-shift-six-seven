import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../main.dart';

enum ReturnBonusOutcome { claimed, cancelled, failed }

/// Reward-first presentation for the persisted offline-return choice.
///
/// Economy and ad orchestration stay with [Home]. This widget owns only the
/// interaction state that must remain visible in the sheet: loading, failure,
/// retry, and duplicate-tap prevention.
class ReturnRewardSheet extends StatefulWidget {
  const ReturnRewardSheet({
    super.key,
    required this.strings,
    required this.baseAmount,
    required this.bonusAmount,
    required this.awayDuration,
    required this.creditCapped,
    required this.bonusAvailable,
    required this.highContrast,
    required this.reduceMotion,
    required this.auraArtwork,
    required this.timeArtwork,
    required this.bonusArtwork,
    required this.onClaimBase,
    required this.onClaimBonus,
  });

  final Strings strings;
  final String baseAmount;
  final String bonusAmount;
  final Duration? awayDuration;
  final bool creditCapped;
  final bool bonusAvailable;
  final bool highContrast;
  final bool reduceMotion;
  final Widget auraArtwork;
  final Widget timeArtwork;
  final Widget bonusArtwork;
  final bool Function() onClaimBase;
  final Future<ReturnBonusOutcome> Function() onClaimBonus;

  @override
  State<ReturnRewardSheet> createState() => _ReturnRewardSheetState();
}

class _ReturnRewardSheetState extends State<ReturnRewardSheet> {
  bool _adInFlight = false;
  bool _adFailed = false;

  void _claimBase() {
    if (_adInFlight) return;
    if (widget.onClaimBase()) Navigator.pop(context);
  }

  Future<void> _claimBonus() async {
    if (_adInFlight || !widget.bonusAvailable) return;
    setState(() {
      _adInFlight = true;
      _adFailed = false;
    });

    ReturnBonusOutcome outcome;
    try {
      outcome = await widget.onClaimBonus();
    } catch (_) {
      outcome = ReturnBonusOutcome.failed;
    }
    if (!mounted) return;

    if (outcome == ReturnBonusOutcome.claimed) {
      setState(() => _adInFlight = false);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _adInFlight = false;
      _adFailed = outcome == ReturnBonusOutcome.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final disableAnimations = media.disableAnimations || widget.reduceMotion;
    final sheetHeight = widget.bonusAvailable
        ? (media.size.height * .92).clamp(0.0, 760.0).toDouble()
        : (media.size.height * .70).clamp(0.0, 580.0).toDouble();
    final baseAmount = _ltr(widget.baseAmount);
    final bonusAmount = _ltr(widget.bonusAmount);
    final baseRewardLabel = widget.strings(
      'return_base_reward',
      {'amount': baseAmount},
    );
    final amountCopy = _AmountCopy.fromLocalizedLabel(
      baseRewardLabel,
      baseAmount,
    );
    final awayLabel = widget.awayDuration == null
        ? null
        : widget.strings('return_away_time', {
            'duration': _ltr(AuraFormat.duration(widget.awayDuration!)),
          });
    final bonusBody = widget.strings(
      'return_bonus_body',
      {'amount': bonusAmount},
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_adInFlight) Navigator.pop(context);
      },
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              minHeight: sheetHeight,
              maxHeight: sheetHeight,
            ),
            child: Material(
              key: const ValueKey('return-reward-sheet'),
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF10142F),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(
                    color: widget.highContrast
                        ? colors.onSurface
                        : colors.primary.withValues(alpha: .22),
                    width: widget.highContrast ? 2 : 1,
                  ),
                  boxShadow: widget.highContrast
                      ? const []
                      : [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: .12),
                            blurRadius: 34,
                            offset: const Offset(0, -8),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        key: const ValueKey('return-reward-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReturnRewardHero(
                              strings: widget.strings,
                              amountCopy: amountCopy,
                              amount: widget.baseAmount,
                              fullRewardLabel: baseRewardLabel,
                              awayLabel: awayLabel,
                              creditCapped: widget.creditCapped,
                              highContrast: widget.highContrast,
                              disableAnimations: disableAnimations,
                              auraArtwork: widget.auraArtwork,
                              timeArtwork: widget.timeArtwork,
                            ),
                            if (widget.bonusAvailable) ...[
                              const SizedBox(height: 14),
                              _ReturnBonusCard(
                                title: widget.strings('return_bonus_title'),
                                body: bonusBody,
                                amount: widget.bonusAmount,
                                highContrast: widget.highContrast,
                                artwork: widget.bonusArtwork,
                              ),
                            ],
                            AnimatedSize(
                              duration: disableAnimations
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: _adFailed
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _ReturnAdError(
                                        message: widget.strings(
                                          'return_ad_failed',
                                        ),
                                        highContrast: widget.highContrast,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _ReturnRewardActions(
                      strings: widget.strings,
                      baseAmount: baseAmount,
                      bonusAmount: bonusAmount,
                      bonusAvailable: widget.bonusAvailable,
                      adInFlight: _adInFlight,
                      adFailed: _adFailed,
                      disableAnimations: disableAnimations,
                      onClaimBase: _claimBase,
                      onClaimBonus: _claimBonus,
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

class _ReturnRewardActions extends StatelessWidget {
  const _ReturnRewardActions({
    required this.strings,
    required this.baseAmount,
    required this.bonusAmount,
    required this.bonusAvailable,
    required this.adInFlight,
    required this.adFailed,
    required this.disableAnimations,
    required this.onClaimBase,
    required this.onClaimBonus,
  });

  final Strings strings;
  final String baseAmount;
  final String bonusAmount;
  final bool bonusAvailable;
  final bool adInFlight;
  final bool adFailed;
  final bool disableAnimations;
  final VoidCallback onClaimBase;
  final VoidCallback onClaimBonus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF10142F),
        border: Border(
          top: BorderSide(color: colors.onSurface.withValues(alpha: .07)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bonusAvailable) ...[
            FilledButton(
              key: const ValueKey('return-watch-ad'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                backgroundColor: colors.secondary,
                foregroundColor: const Color(0xFF090B1A),
                disabledBackgroundColor:
                    colors.secondary.withValues(alpha: .32),
                disabledForegroundColor:
                    colors.onSurface.withValues(alpha: .55),
              ),
              onPressed: adInFlight ? null : onClaimBonus,
              child: AnimatedSwitcher(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: adInFlight
                    ? _AdLoadingLabel(
                        key: const ValueKey('return-ad-loading'),
                        label: strings('system_ad_loading'),
                      )
                    : Text(
                        adFailed
                            ? strings('return_retry_bonus')
                            : strings('return_watch_ad', {
                                'amount': bonusAmount,
                              }),
                        key: ValueKey(
                          adFailed
                              ? 'return-ad-retry-label'
                              : 'return-ad-offer-label',
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const ValueKey('return-claim-base'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              onPressed: adInFlight ? null : onClaimBase,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings('return_collect', {'amount': baseAmount}),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings('return_base_only'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: .68),
                        ),
                  ),
                ],
              ),
            ),
          ] else
            FilledButton(
              key: const ValueKey('return-claim-base'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: adInFlight ? null : onClaimBase,
              child: Text(
                strings('return_collect', {'amount': baseAmount}),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReturnRewardHero extends StatelessWidget {
  const _ReturnRewardHero({
    required this.strings,
    required this.amountCopy,
    required this.amount,
    required this.fullRewardLabel,
    required this.awayLabel,
    required this.creditCapped,
    required this.highContrast,
    required this.disableAnimations,
    required this.auraArtwork,
    required this.timeArtwork,
  });

  final Strings strings;
  final _AmountCopy amountCopy;
  final String amount;
  final String fullRewardLabel;
  final String? awayLabel;
  final bool creditCapped;
  final bool highContrast;
  final bool disableAnimations;
  final Widget auraArtwork;
  final Widget timeArtwork;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('return-reward-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C244C), Color(0xFF131630)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highContrast
              ? colors.onSurface
              : colors.primary.withValues(alpha: .26),
          width: highContrast ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (!highContrast) ...[
            PositionedDirectional(
              top: -82,
              start: -58,
              child: _AtmosphereOrb(
                size: 190,
                color: colors.primary.withValues(alpha: .07),
              ),
            ),
            PositionedDirectional(
              bottom: -105,
              end: -55,
              child: _AtmosphereOrb(
                size: 220,
                color: colors.secondary.withValues(alpha: .09),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, progress, child) => Opacity(
                    opacity: progress.clamp(0, 1),
                    child: Transform.scale(
                      scale: .88 + (.12 * progress),
                      child: child,
                    ),
                  ),
                  child: _AuraHalo(
                    highContrast: highContrast,
                    artwork: auraArtwork,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    strings('return_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (awayLabel != null) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    container: true,
                    label: awayLabel,
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('return-away-time'),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          10,
                          7,
                          12,
                          7,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: .065),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.onSurface.withValues(alpha: .11),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 18,
                              child: timeArtwork,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                awayLabel!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colors.onSurface
                                          .withValues(alpha: .82),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colors.primary.withValues(alpha: .35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  key: const ValueKey('return-base-amount'),
                  container: true,
                  label: fullRewardLabel,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        if (amountCopy.label.isNotEmpty)
                          Text(
                            amountCopy.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: .72),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .3,
                                ),
                          ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 7,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                amount,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                  color: colors.primary,
                                  fontSize: 42,
                                  height: 1.05,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            if (amountCopy.unit.isNotEmpty)
                              Text(
                                amountCopy.unit,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (creditCapped) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    container: true,
                    label: strings('return_credit_cap'),
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('return-credit-cap'),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          10,
                          8,
                          12,
                          8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166)
                              .withValues(alpha: highContrast ? .2 : .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD166)
                                .withValues(alpha: highContrast ? 1 : .34),
                            width: highContrast ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_bottom_rounded,
                              size: 19,
                              color: Color(0xFFFFD166),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings('return_credit_cap'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colors.onSurface
                                          .withValues(alpha: .88),
                                      height: 1.3,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraHalo extends StatelessWidget {
  const _AuraHalo({required this.highContrast, required this.artwork});

  final bool highContrast;
  final Widget artwork;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors.primary.withValues(alpha: .2),
              colors.secondary.withValues(alpha: .12),
            ],
          ),
          border: Border.all(
            color: highContrast
                ? colors.onSurface
                : colors.primary.withValues(alpha: .46),
            width: highContrast ? 2 : 1,
          ),
          boxShadow: highContrast
              ? const []
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .24),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: SizedBox.square(dimension: 56, child: artwork),
      ),
    );
  }
}

class _ReturnBonusCard extends StatelessWidget {
  const _ReturnBonusCard({
    required this.title,
    required this.body,
    required this.amount,
    required this.highContrast,
    required this.artwork,
  });

  final String title;
  final String body;
  final String amount;
  final bool highContrast;
  final Widget artwork;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title $body',
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('return-bonus-card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.secondary.withValues(alpha: .16),
                colors.primary.withValues(alpha: .055),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highContrast
                  ? colors.onSurface
                  : colors.secondary.withValues(alpha: .34),
              width: highContrast ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: artwork,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 19, height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '+20%',
                      style: TextStyle(
                        color: Color(0xFF171225),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '+$amount',
                    key: const ValueKey('return-bonus-amount'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFFFD166),
                      fontSize: 26,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnAdError extends StatelessWidget {
  const _ReturnAdError({
    required this.message,
    required this.highContrast,
  });

  final String message;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('return-ad-error'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highContrast
                  ? colors.error
                  : colors.error.withValues(alpha: .42),
              width: highContrast ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: colors.error, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdLoadingLabel extends StatelessWidget {
  const _AdLoadingLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF090B1A),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      );
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

class _AmountCopy {
  const _AmountCopy({required this.label, required this.unit});

  factory _AmountCopy.fromLocalizedLabel(String label, String amount) {
    final amountIndex = label.indexOf(amount);
    if (amountIndex < 0) return _AmountCopy(label: label, unit: '');
    final leading = label.substring(0, amountIndex).trimRight().replaceFirst(
          RegExp(r'[:：]\s*$'),
          '',
        );
    final trailing = label.substring(amountIndex + amount.length).trim();
    return _AmountCopy(label: leading, unit: trailing);
  }

  final String label;
  final String unit;
}

String _ltr(String value) => '\u2066$value\u2069';
