import 'package:flutter/material.dart';

import '../main.dart';

/// Presents the Ascension trade-off without owning any economy state.
///
/// [Home] remains responsible for calculating the preview and executing the
/// Ascension. Keeping this widget presentation-only makes the reset contract
/// explicit and testable.
class AscensionSheet extends StatelessWidget {
  const AscensionSheet({
    super.key,
    required this.strings,
    required this.artwork,
    required this.currentMultiplier,
    required this.gainedMultiplier,
    required this.resultingMultiplier,
    required this.journeyAura,
    required this.highContrast,
    required this.reduceMotion,
    required this.onAscend,
  });

  final Strings strings;
  final Widget artwork;
  final String currentMultiplier;
  final String gainedMultiplier;
  final String resultingMultiplier;
  final String journeyAura;
  final bool highContrast;
  final bool reduceMotion;
  final VoidCallback onAscend;

  static const _ink = Color(0xFF090B1A);
  static const _surface = Color(0xFF11152E);
  static const _gold = Color(0xFFFFCE73);
  static const _amber = Color(0xFFFF8A3D);
  static const _cyan = Color(0xFF63E6FF);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final disableAnimations = media.disableAnimations || reduceMotion;
    final maxHeight = (media.size.height * .92).clamp(0.0, 820.0).toDouble();
    final currentText = '$currentMultiplier×';
    final gainedText = '+$gainedMultiplier×';
    final resultingText = '$resultingMultiplier×';

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            minHeight: maxHeight,
            maxHeight: maxHeight,
          ),
          child: Material(
            key: const ValueKey('ascension-sheet'),
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: highContrast
                      ? Colors.white
                      : _gold.withValues(alpha: .28),
                  width: highContrast ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: .12),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(29)),
                child: Stack(
                  children: [
                    const Positioned.fill(child: _AscensionAtmosphere()),
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: .20),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _Header(
                                  strings: strings,
                                  artwork: artwork,
                                ),
                                const SizedBox(height: 18),
                                _LoreCard(strings: strings),
                                const SizedBox(height: 14),
                                TweenAnimationBuilder<double>(
                                  duration: disableAnimations
                                      ? Duration.zero
                                      : const Duration(milliseconds: 520),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, value, child) => Opacity(
                                    opacity: value.clamp(0, 1),
                                    child: Transform.scale(
                                      scale: .96 + (.04 * value),
                                      child: child,
                                    ),
                                  ),
                                  child: _MultiplierCard(
                                    strings: strings,
                                    current: _ltr(currentText),
                                    gained: _ltr(gainedText),
                                    resulting: _ltr(resultingText),
                                    journeyAura: _ltr(journeyAura),
                                    highContrast: highContrast,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _ConsequenceCard(
                                  icon: Icons.restart_alt_rounded,
                                  accent: _amber,
                                  title: strings('ascension_resets_title'),
                                  body: strings('ascension_resets_body'),
                                ),
                                const SizedBox(height: 10),
                                _ConsequenceCard(
                                  icon: Icons.all_inclusive_rounded,
                                  accent: _cyan,
                                  title: strings('ascension_keeps_title'),
                                  body: strings('ascension_keeps_body'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _ink.withValues(alpha: .80),
                                _ink,
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: .08),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              10,
                              20,
                              14 + media.padding.bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  strings(
                                    'ascension_confirm_body',
                                    {'multiplier': resultingText},
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .66),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                _AscendAction(
                                  label: strings('ascension_confirm_action'),
                                  onPressed: onAscend,
                                ),
                              ],
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
      ),
    );
  }

  static Widget _ltr(String value) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(value),
      );
}

class _AscensionAtmosphere extends StatelessWidget {
  const _AscensionAtmosphere();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1C1831),
                      AscensionSheet._surface,
                      AscensionSheet._ink,
                    ],
                    stops: [0, .42, 1],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: -110,
              end: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AscensionSheet._gold.withValues(alpha: .20),
                      AscensionSheet._gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 190,
              start: -120,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B7CFF).withValues(alpha: .11),
                      const Color(0xFF8B7CFF).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.strings,
    required this.artwork,
  });

  final Strings strings;
  final Widget artwork;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AscensionSheet._gold.withValues(alpha: .32),
                  const Color(0xFF8B7CFF).withValues(alpha: .12),
                ],
              ),
              border: Border.all(
                color: AscensionSheet._gold.withValues(alpha: .55),
              ),
              boxShadow: [
                BoxShadow(
                  color: AscensionSheet._gold.withValues(alpha: .20),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(child: artwork),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings('ascension_preview').toUpperCase(),
                  style: const TextStyle(
                    color: AscensionSheet._gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.45,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings('ascension_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 27,
                        height: 1.05,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _LoreCard extends StatelessWidget {
  const _LoreCard({required this.strings});

  final Strings strings;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(15, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .075)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AscensionSheet._gold, Color(0xFF8B7CFF)],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings('ascension_lore_body'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 14,
                  height: 1.52,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
}

class _MultiplierCard extends StatelessWidget {
  const _MultiplierCard({
    required this.strings,
    required this.current,
    required this.gained,
    required this.resulting,
    required this.journeyAura,
    required this.highContrast,
  });

  final Strings strings;
  final Widget current;
  final Widget gained;
  final Widget resulting;
  final Widget journeyAura;
  final bool highContrast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AscensionSheet._gold.withValues(alpha: .16),
              const Color(0xFF8B7CFF).withValues(alpha: .13),
              AscensionSheet._cyan.withValues(alpha: .08),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highContrast
                ? Colors.white
                : AscensionSheet._gold.withValues(alpha: .34),
            width: highContrast ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: AscensionSheet._gold.withValues(alpha: .92),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    strings('ascension_permanent_bonus'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AscensionSheet._gold.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AscensionSheet._gold.withValues(alpha: .32),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: AscensionSheet._gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      child: gained,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _MultiplierValue(
                    label: strings(
                      'ascension_multiplier_now',
                      {'multiplier': ''},
                    ).trim(),
                    value: current,
                    color: Colors.white.withValues(alpha: .70),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AscensionSheet._gold.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AscensionSheet._gold,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: _MultiplierValue(
                    label: strings(
                      'ascension_multiplier_after_short',
                      {'multiplier': ''},
                    ).trim(),
                    value: resulting,
                    color: AscensionSheet._gold,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: .09), height: 1),
            const SizedBox(height: 11),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: .48),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    strings(
                      'ascension_journey_used',
                      {'amount': ''},
                    ).trim(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .52),
                      fontSize: 11,
                    ),
                  ),
                ),
                DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  child: journeyAura,
                ),
              ],
            ),
          ],
        ),
      );
}

class _MultiplierValue extends StatelessWidget {
  const _MultiplierValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final Widget value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .50),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: DefaultTextStyle(
              style: TextStyle(
                color: color,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
              child: value,
            ),
          ),
        ],
      );
}

class _ConsequenceCard extends StatelessWidget {
  const _ConsequenceCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: .18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 12,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AscendAction extends StatelessWidget {
  const _AscendAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AscensionSheet._gold, AscensionSheet._amber],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: AscensionSheet._amber.withValues(alpha: .28),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: InkWell(
              key: const ValueKey('ascension-confirm-button'),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF211408),
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF211408),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
