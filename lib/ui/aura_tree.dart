import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/formatting.dart';
import '../core/game_controller.dart';
import '../game/art_catalog.dart';
import 'art_widgets.dart';

typedef AuraTranslate = String Function(
  String key, [
  Map<String, String> values,
]);

class AuraItemTree extends StatefulWidget {
  const AuraItemTree({
    super.key,
    required this.controller,
    required this.translate,
    required this.locale,
    required this.art,
    required this.onPurchase,
    required this.onComplement,
    this.onDetailsOpen,
    this.onDetailsClose,
  });

  final GameController controller;
  final AuraTranslate translate;
  final String locale;
  final ArtCatalog? art;
  final void Function(Upgrade upgrade, int quantity) onPurchase;
  final Future<void> Function(Upgrade upgrade) onComplement;
  final Future<void> Function()? onDetailsOpen;
  final Future<void> Function()? onDetailsClose;

  @override
  State<AuraItemTree> createState() => _AuraItemTreeState();
}

class _AuraItemTreeState extends State<AuraItemTree> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showDetails(Upgrade upgrade) async {
    setState(() => _selectedId = upgrade.id);
    try {
      await widget.onDetailsOpen?.call();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Directionality(
          textDirection:
              widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AuraUpgradeDetailsSheet(
            controller: widget.controller,
            upgrade: upgrade,
            translate: widget.translate,
            locale: widget.locale,
            art: widget.art,
            onPurchase: widget.onPurchase,
            onComplement: widget.onComplement,
          ),
        ),
      );
    } finally {
      await widget.onDetailsClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => Column(
          children: [
            _TreeBalanceBar(
              controller: widget.controller,
              translate: widget.translate,
              locale: widget.locale,
              art: widget.art,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF111735), Color(0xFF090C1F)],
                      ),
                      border: Border.all(
                        color: widget.controller.highContrast
                            ? const Color(0xFFF7F5FF)
                            : Colors.white.withValues(alpha: .08),
                        width: widget.controller.highContrast ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          overscroll: false,
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            key: const PageStorageKey('aura-tree-scroll'),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RepaintBoundary(
                              child: _AuraTreeCanvas(
                                width: width,
                                controller: widget.controller,
                                translate: widget.translate,
                                locale: widget.locale,
                                art: widget.art,
                                selectedId: _selectedId,
                                onSelected: _showDetails,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _TreeBalanceBar extends StatelessWidget {
  const _TreeBalanceBar({
    required this.controller,
    required this.translate,
    required this.locale,
    required this.art,
  });

  final GameController controller;
  final AuraTranslate translate;
  final String locale;
  final ArtCatalog? art;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(12) > 18;
          final amount = Row(
            children: [
              AuraAssetIcon(
                catalog: art,
                role: AuraUiIcon.auraAvailable,
                fallbackIcon: Icons.auto_awesome,
                semanticLabel: translate('play_available_aura'),
                decorative: true,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('play_available_aura_short').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      AuraFormat.integer(controller.available, locale: locale),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFFF7F5FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7CFF).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B7CFF).withValues(alpha: .28),
              ),
            ),
            child: Text(
              translate('shop_aura_tree'),
              style: const TextStyle(
                color: Color(0xFFD8D2FF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151A3A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: controller.highContrast
                    ? const Color(0xFFF7F5FF)
                    : Colors.white.withValues(alpha: .07),
                width: controller.highContrast ? 2 : 1,
              ),
            ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      amount,
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: badge,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: amount),
                      const SizedBox(width: 10),
                      badge,
                    ],
                  ),
          );
        },
      );
}

class _AuraTreeCanvas extends StatelessWidget {
  const _AuraTreeCanvas({
    required this.width,
    required this.controller,
    required this.translate,
    required this.locale,
    required this.art,
    required this.selectedId,
    required this.onSelected,
  });

  final double width;
  final GameController controller;
  final AuraTranslate translate;
  final String locale;
  final ArtCatalog? art;
  final String? selectedId;
  final ValueChanged<Upgrade> onSelected;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final scaledLabel = MediaQuery.textScalerOf(context).scale(11);
    final nodeHeight = 78 + (scaledLabel * 3.2).clamp(24.0, 76.0);
    final branchLabelHeight = (scaledLabel * 3.2 + 16).clamp(40.0, 96.0);
    final geometry = _TreeGeometry(
      width,
      direction,
      nodeHeight: nodeHeight,
      branchLabelHeight: branchLabelHeight,
    );
    final branchUpgrades = <String, List<Upgrade>>{
      for (final branch in const ['A', 'B', 'C'])
        branch: upgrades
            .where((upgrade) => upgrade.branch == branch)
            .toList(growable: false),
    };
    final convergenceUpgrades = upgrades
        .where((upgrade) => upgrade.branch == 'Spectrum')
        .toList(growable: false);
    final root = upgrades.firstWhere((upgrade) => upgrade.id == 'TECH-01');

    return SizedBox(
      width: width,
      height: geometry.canvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AuraTreePainter(geometry),
            ),
          ),
          for (final branch in const ['A', 'B', 'C'])
            _BranchLaneLabel(
              key: ValueKey('aura-branch-label-$branch'),
              branch: branch,
              title: _branchTitle(translate, branch),
              centerX: geometry.branchX(branch),
              top: geometry.branchLabelTop,
            ),
          _positionedNode(
            geometry.root,
            geometry.nodeWidth,
            _AuraTreeNode(
              key: const ValueKey('aura-root-TECH-01'),
              upgrade: root,
              controller: controller,
              translate: translate,
              locale: locale,
              art: art,
              shortLabel: translate(root.nameKey),
              height: geometry.nodeHeight,
              sortOrder: 0,
              selected: selectedId == root.id,
              onTap: () => onSelected(root),
            ),
          ),
          for (final branch in const ['A', 'B', 'C'])
            for (var depth = 1; depth <= 5; depth++)
              _positionedNode(
                geometry.item(branch, depth),
                geometry.nodeWidth,
                _AuraTreeNode(
                  key: ValueKey('aura-node-ITEM-$branch-0$depth'),
                  upgrade: branchUpgrades[branch]![depth - 1],
                  controller: controller,
                  translate: translate,
                  locale: locale,
                  art: art,
                  shortLabel:
                      '${_branchTitle(translate, branch)} \u2066$depth\u2069',
                  height: geometry.nodeHeight,
                  sortOrder: depth * 10 + const ['A', 'B', 'C'].indexOf(branch),
                  selected: selectedId == branchUpgrades[branch]![depth - 1].id,
                  onTap: () => onSelected(branchUpgrades[branch]![depth - 1]),
                ),
              ),
          for (var index = 0; index < convergenceUpgrades.length; index++)
            _positionedNode(
              geometry.convergence(index + 1),
              geometry.nodeWidth,
              _AuraTreeNode(
                key: ValueKey('aura-node-ITEM-CONV-0${index + 1}'),
                upgrade: convergenceUpgrades[index],
                controller: controller,
                translate: translate,
                locale: locale,
                art: art,
                shortLabel: 'Spectrum ${index + 1}',
                height: geometry.nodeHeight,
                sortOrder: const [13, 33, 53][index],
                selected: selectedId == convergenceUpgrades[index].id,
                onTap: () => onSelected(convergenceUpgrades[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _positionedNode(Offset center, double width, Widget child) =>
      Positioned(
        left: center.dx - width / 2,
        top: center.dy - 36,
        width: width,
        child: child,
      );
}

class _BranchLaneLabel extends StatelessWidget {
  const _BranchLaneLabel({
    super.key,
    required this.branch,
    required this.title,
    required this.centerX,
    required this.top,
  });

  final String branch;
  final String title;
  final double centerX;
  final double top;

  @override
  Widget build(BuildContext context) {
    final color = _branchColor(branch);
    return Positioned(
      top: top,
      left: centerX - 48,
      width: 96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1027),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .46)),
        ),
        child: Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuraTreeNode extends StatelessWidget {
  const _AuraTreeNode({
    super.key,
    required this.upgrade,
    required this.controller,
    required this.translate,
    required this.locale,
    required this.art,
    required this.shortLabel,
    required this.height,
    required this.sortOrder,
    required this.selected,
    required this.onTap,
  });

  final Upgrade upgrade;
  final GameController controller;
  final AuraTranslate translate;
  final String locale;
  final ArtCatalog? art;
  final String shortLabel;
  final double height;
  final int sortOrder;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = controller.isUnlocked(upgrade);
    final one = controller.purchaseQuote(upgrade, 1);
    final purchasable = unlocked && one.affordable;
    final level = controller.level(upgrade.id);
    final title = translate(upgrade.nameKey);
    final branch = upgrade.isTechnique ? 'root' : upgrade.branch;
    final color = _branchColor(branch);
    final status = level > 0
        ? translate('shop_level', {'level': '$level'})
        : unlocked
            ? translate('shop_unlocked')
            : translate('collection_locked');
    final requirements = controller.requirementsFor(upgrade);
    final effect = upgrade.base20 *
        BigInt.from(level * controller.milestoneFactor(level)) *
        controller.multiplier;
    final effectKind = translate(
      upgrade.isTechnique ? 'play_cycle_power' : 'play_passive_rate',
    );
    final semantics = [
      title,
      if (shortLabel != title) shortLabel,
      status,
      if (unlocked && !purchasable)
        translate('shop_missing', {
          'amount': _ltr(
            AuraFormat.integer(one.cost - controller.available, locale: locale),
          ),
        }),
      '$effectKind: ${_ltr(AuraFormat.rate(effect, locale: locale))} ${upgrade.isTechnique ? 'Aura' : 'Aura/s'}',
      for (final requirement in requirements) _semanticRequirement(requirement),
    ].join('. ');

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      sortKey: OrdinalSortKey(sortOrder.toDouble()),
      child: Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: controller.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10152F),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF7F5FF)
                          : unlocked
                              ? color.withValues(alpha: purchasable ? .72 : .38)
                              : Colors.white.withValues(alpha: .08),
                      width: selected
                          ? 3
                          : controller.highContrast
                              ? 2
                              : 1.5,
                    ),
                    boxShadow: unlocked && !controller.highContrast
                        ? [
                            BoxShadow(
                              color: color.withValues(
                                alpha: selected ? .36 : .14,
                              ),
                              blurRadius: selected ? 20 : 12,
                            ),
                          ]
                        : const [],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (upgrade.branch == 'Spectrum')
                        AuraAssetArt(
                          catalog: art,
                          assetId: AuraUiArt.branch('Spectrum')?.nodeId,
                          fallback: const Icon(Icons.hexagon_outlined),
                          width: 64,
                          height: 64,
                          semanticLabel: title,
                          decorative: true,
                          opacity: unlocked ? 1 : .42,
                        ),
                      _NodeArtwork(
                        upgrade: upgrade,
                        art: art,
                        title: title,
                        opacity: unlocked ? 1 : .34,
                        size: upgrade.branch == 'Spectrum' ? 40 : 57,
                      ),
                      if (!upgrade.isTechnique && upgrade.branch != 'Spectrum')
                        PositionedDirectional(
                          top: -7,
                          start: -7,
                          child: AuraAssetArt(
                            catalog: art,
                            assetId: AuraUiArt.branch(upgrade.branch)?.nodeId,
                            fallback: Icon(
                              _branchFallback(upgrade.branch),
                              color: color,
                              size: 20,
                            ),
                            width: 27,
                            height: 27,
                            semanticLabel: title,
                            decorative: true,
                            opacity: unlocked ? 1 : .45,
                          ),
                        ),
                      if (!unlocked)
                        PositionedDirectional(
                          top: 4,
                          end: 4,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: const Color(0xE6090B1A),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .24),
                              ),
                            ),
                            child: const Icon(Icons.lock, size: 14),
                          ),
                        ),
                      if (purchasable)
                        PositionedDirectional(
                          top: 4,
                          end: 4,
                          child: Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB7F171),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF090B1A),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Color(0xFF090B1A),
                            ),
                          ),
                        ),
                      if (!unlocked)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _DashedNodeBorderPainter(
                                color: controller.highContrast
                                    ? const Color(0xFFF7F5FF)
                                    : Colors.white.withValues(alpha: .34),
                                width: controller.highContrast ? 2 : 1.5,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: -7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF080B1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: level > 0
                                  ? color.withValues(alpha: .7)
                                  : Colors.white.withValues(alpha: .16),
                            ),
                          ),
                          child: Text(
                            'N$level',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Color(0xFFF7F5FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    shortLabel,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    textDirection:
                        upgrade.branch == 'Spectrum' ? TextDirection.ltr : null,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFF7F5FF)
                          : Colors.white.withValues(alpha: unlocked ? .8 : .46),
                      fontSize: 11,
                      height: 1.08,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _semanticRequirement(UpgradeRequirement requirement) {
    final met = controller.requirementMet(requirement);
    final status =
        met ? translate('shop_unlocked') : translate('collection_locked');
    if (requirement.kind == UpgradeRequirementKind.totalAura) {
      return '${translate('shop_tier_required', {
            'amount': _ltr(
              AuraFormat.integer(requirement.total!, locale: locale),
            ),
          })} $status';
    }
    final prerequisite = upgrades.firstWhere(
      (candidate) => candidate.id == requirement.upgradeId,
    );
    return '${translate('shop_item_required', {
          'name': translate(prerequisite.nameKey),
          'level': _ltr('${requirement.level}'),
        })} $status';
  }

  String _ltr(String value) => '\u2066$value\u2069';
}

class _DashedNodeBorderPainter extends CustomPainter {
  const _DashedNodeBorderPainter({
    required this.color,
    required this.width,
  });

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(23),
        ).deflate(width / 2),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in border.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedNodeBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}

class _NodeArtwork extends StatelessWidget {
  const _NodeArtwork({
    required this.upgrade,
    required this.art,
    required this.title,
    required this.opacity,
    this.size = 57,
  });

  final Upgrade upgrade;
  final ArtCatalog? art;
  final String title;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (upgrade.isTechnique) {
      return AuraAssetIcon(
        catalog: art,
        role: AuraUiIcon.technique,
        fallbackIcon: Icons.bolt,
        semanticLabel: title,
        decorative: true,
        opacity: opacity,
        size: math.min(size, 48),
      );
    }
    return AuraAssetArt(
      catalog: art,
      assetId: AuraUiArt.appearanceThumbnail(upgrade.id),
      fallback: Icon(
        _branchFallback(upgrade.branch),
        color: _branchColor(upgrade.branch),
        size: size * .74,
      ),
      width: size,
      height: size,
      semanticLabel: title,
      decorative: true,
      opacity: opacity,
    );
  }
}

class _TreeGeometry {
  const _TreeGeometry(
    this.width,
    this.direction, {
    required this.nodeHeight,
    required this.branchLabelHeight,
  });

  final double width;
  final TextDirection direction;
  final double nodeHeight;
  final double branchLabelHeight;

  double get nodeWidth => width < 320 ? 84 : 100;
  double get branchLabelTop => root.dy - 36 + nodeHeight + 4;
  double get _firstDepthY => branchLabelTop + branchLabelHeight + 44;
  double get _stageGap => math.max(110, nodeHeight + 12);
  double get canvasHeight => convergence(3).dy - 36 + nodeHeight + 20;

  double branchX(String branch) {
    final inset = (width * .16).clamp(52.0, 104.0);
    final start = direction == TextDirection.ltr ? inset : width - inset;
    final end = direction == TextDirection.ltr ? width - inset : inset;
    return switch (branch) {
      'A' => start,
      'B' => width / 2,
      'C' => end,
      _ => width / 2,
    };
  }

  Offset get root => Offset(width / 2, 58);

  Offset item(String branch, int depth) {
    final stage = switch (depth) {
      1 => 0,
      2 => 2,
      3 => 3,
      4 => 5,
      5 => 6,
      _ => throw RangeError.range(depth, 1, 5, 'depth'),
    };
    return Offset(branchX(branch), _firstDepthY + _stageGap * stage);
  }

  Offset convergence(int index) {
    final stage = switch (index) {
      1 => 1,
      2 => 4,
      3 => 7,
      _ => throw RangeError.range(index, 1, 3, 'index'),
    };
    return Offset(width / 2, _firstDepthY + _stageGap * stage);
  }
}

class _AuraTreePainter extends CustomPainter {
  const _AuraTreePainter(this.geometry);

  final _TreeGeometry geometry;

  static const colors = <String, Color>{
    'A': Color(0xFF43E6FF),
    'B': Color(0xFFFF4FA3),
    'C': Color(0xFFFFD166),
  };

  @override
  void paint(Canvas canvas, Size size) {
    _drawAtmosphere(canvas, size);
    _drawRoot(canvas);
    for (final branch in const ['A', 'B', 'C']) {
      for (var depth = 1; depth < 5; depth++) {
        _drawBranchConnection(
          canvas,
          geometry.item(branch, depth),
          geometry.item(branch, depth + 1),
          branch,
          bendsAroundConvergence: branch == 'B' && (depth == 1 || depth == 3),
        );
      }
    }
    _drawConvergence(canvas, 1, sourceDepth: 1);
    _drawConvergence(canvas, 2, sourceDepth: 3);
    _drawConvergence(canvas, 3, sourceDepth: 5);
  }

  void _drawAtmosphere(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..strokeWidth = 1;
    for (var y = 82.0; y < size.height; y += 56) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), gridPaint);
    }
    for (final branch in const ['A', 'B', 'C']) {
      final x = geometry.branchX(branch);
      final laneTop = geometry.item(branch, 1).dy - 44;
      final laneHeight =
          geometry.item(branch, 5).dy - geometry.item(branch, 1).dy + 88;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[branch]!.withValues(alpha: .055),
            colors[branch]!.withValues(alpha: .012),
          ],
        ).createShader(Rect.fromLTWH(x - 43, laneTop, 86, laneHeight));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 43, laneTop, 86, laneHeight),
          const Radius.circular(43),
        ),
        paint,
      );
    }
  }

  void _drawRoot(Canvas canvas) {
    final neutral = Paint()
      ..color = const Color(0xFF8B7CFF).withValues(alpha: .62)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final branch in const ['A', 'B', 'C']) {
      final target = geometry.item(branch, 1);
      final startY = geometry.root.dy + 31;
      final endY = target.dy - 34;
      final middleY = (startY + endY) / 2;
      final path = Path()
        ..moveTo(geometry.root.dx, startY)
        ..cubicTo(
          geometry.root.dx,
          middleY,
          target.dx,
          middleY,
          target.dx,
          endY,
        );
      canvas.drawPath(path, neutral);
    }
  }

  void _drawBranchConnection(
    Canvas canvas,
    Offset from,
    Offset to,
    String branch, {
    required bool bendsAroundConvergence,
  }) {
    final paint = Paint()
      ..color = colors[branch]!.withValues(alpha: .68)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final start = Offset(from.dx, from.dy + 34);
    final end = Offset(to.dx, to.dy - 34);
    final path = Path()..moveTo(start.dx, start.dy);

    if (bendsAroundConvergence) {
      final side = geometry.direction == TextDirection.ltr ? 1.0 : -1.0;
      final detourX = start.dx + (78 * side);
      path
        ..cubicTo(start.dx, start.dy + 42, detourX, start.dy + 42, detourX,
            (start.dy + end.dy) / 2)
        ..cubicTo(detourX, end.dy - 42, end.dx, end.dy - 42, end.dx, end.dy);
    } else if (branch == 'A') {
      final mirror = geometry.direction == TextDirection.ltr ? 1.0 : -1.0;
      path.cubicTo(
        start.dx - 8 * mirror,
        start.dy + 38,
        end.dx + 8 * mirror,
        end.dy - 38,
        end.dx,
        end.dy,
      );
    } else if (branch == 'B') {
      final middle = (start.dy + end.dy) / 2;
      path
        ..cubicTo(start.dx + 17, start.dy + 20, start.dx + 17, middle - 20,
            start.dx, middle)
        ..cubicTo(start.dx - 17, middle + 20, end.dx - 17, end.dy - 20, end.dx,
            end.dy);
    } else {
      final middle = (start.dy + end.dy) / 2;
      final mirror = geometry.direction == TextDirection.ltr ? 1.0 : -1.0;
      path
        ..lineTo(start.dx, middle - 14)
        ..lineTo(start.dx + 12 * mirror, middle - 14)
        ..lineTo(start.dx + 12 * mirror, middle + 14)
        ..lineTo(end.dx, middle + 14)
        ..lineTo(end.dx, end.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawConvergence(Canvas canvas, int index, {required int sourceDepth}) {
    final target = geometry.convergence(index);
    for (final branch in const ['A', 'B', 'C']) {
      final source = geometry.item(branch, sourceDepth);
      final path = Path()
        ..moveTo(source.dx, source.dy + 30)
        ..cubicTo(
          source.dx,
          source.dy + 58,
          target.dx,
          target.dy - 58,
          target.dx,
          target.dy - 35,
        );
      _drawDashedPath(
        canvas,
        path,
        Paint()
          ..color = colors[branch]!.withValues(alpha: .5)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      target,
      45,
      Paint()
        ..color = const Color(0xFF8B7CFF).withValues(alpha: .045)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 7, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuraTreePainter oldDelegate) =>
      oldDelegate.geometry.width != geometry.width ||
      oldDelegate.geometry.direction != geometry.direction;
}

class AuraUpgradeDetailsSheet extends StatelessWidget {
  const AuraUpgradeDetailsSheet({
    super.key,
    required this.controller,
    required this.upgrade,
    required this.translate,
    required this.locale,
    required this.art,
    required this.onPurchase,
    required this.onComplement,
  });

  final GameController controller;
  final Upgrade upgrade;
  final AuraTranslate translate;
  final String locale;
  final ArtCatalog? art;
  final void Function(Upgrade upgrade, int quantity) onPurchase;
  final Future<void> Function(Upgrade upgrade) onComplement;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: Material(
          color: const Color(0xFF10142F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _buildContent(context),
          ),
        ),
      );

  Widget _buildContent(BuildContext context) {
    final level = controller.level(upgrade.id);
    final unlocked = controller.isUnlocked(upgrade);
    final currentEffect = _effectAt(level);
    final nextEffect = _effectAt(level + 1);
    final one = controller.purchaseQuote(upgrade, 1);
    final ten = controller.purchaseQuote(upgrade, 10);
    final max = controller.purchaseQuote(upgrade, -1);
    final complement = controller.complementQuote(upgrade);
    final requirements = controller.requirementsFor(upgrade);
    final requirementsMet = requirements.every(controller.requirementMet);
    final title = translate(upgrade.nameKey);
    final branch = upgrade.isTechnique ? 'root' : upgrade.branch;
    final branchColor = _branchColor(branch);
    final rateUnit = upgrade.isTechnique ? 'Aura' : 'Aura/s';
    final effectKind = translate(
      upgrade.isTechnique ? 'play_cycle_power' : 'play_passive_rate',
    );
    final missing = one.cost > controller.available
        ? one.cost - controller.available
        : BigInt.zero;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              PositionedDirectional(
                end: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: translate('action_close'),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey('aura-detail-${upgrade.id}'),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF090C20),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: branchColor.withValues(alpha: .58),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _NodeArtwork(
                        upgrade: upgrade,
                        art: art,
                        title: title,
                        opacity: unlocked ? 1 : .48,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _DetailPill(
                              label: _branchTitle(translate, branch),
                              color: branchColor,
                            ),
                            _DetailPill(
                              label: translate('shop_level', {
                                'level': '$level',
                              }),
                              color: level > 0
                                  ? const Color(0xFFB7F171)
                                  : branchColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                translate(upgrade.descriptionKey),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFD2D0DE),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _EffectPanel(
                      label: _effectLabel('shop_current_effect', effectKind),
                      value:
                          '${AuraFormat.rate(currentEffect, locale: locale)} $rateUnit',
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EffectPanel(
                      label: _effectLabel('shop_next_effect', effectKind),
                      value:
                          '${AuraFormat.rate(nextEffect, locale: locale)} $rateUnit',
                      color: branchColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1027),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .07)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFFFFD166),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        translate('shop_next_milestone', {
                          'level': _ltrToken('${_nextMilestone(level)}'),
                        }),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                requirements.isEmpty || requirementsMet
                    ? translate('shop_unlocked')
                    : translate('shop_all_requirements'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 8),
              if (requirements.isEmpty)
                _RequirementRow(
                  met: true,
                  label: translate('shop_unlocked'),
                )
              else
                for (final requirement in requirements)
                  _RequirementRow(
                    key: ValueKey(
                      'requirement-${upgrade.id}-${requirement.kind == UpgradeRequirementKind.totalAura ? 'total' : requirement.upgradeId}',
                    ),
                    met: controller.requirementMet(requirement),
                    label: _requirementLabel(requirement),
                  ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171D41),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: unlocked
                        ? branchColor.withValues(alpha: .24)
                        : Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('shop_cost', {
                        'amount': AuraFormat.integer(one.cost, locale: locale),
                      }),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (unlocked && missing > BigInt.zero) ...[
                      const SizedBox(height: 5),
                      Text(
                        translate('shop_missing', {
                          'amount': AuraFormat.integer(missing, locale: locale),
                        }),
                        style: const TextStyle(
                          color: Color(0xFFFFE59A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _PurchaseOptions(
                      upgrade: upgrade,
                      unlocked: unlocked,
                      one: one,
                      ten: ten,
                      max: max,
                      available: controller.available,
                      translate: translate,
                      locale: locale,
                      onPurchase: onPurchase,
                    ),
                    if (complement != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: ValueKey('buy-complement-${upgrade.id}'),
                          onPressed: () async {
                            await onComplement(upgrade);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: AuraAssetIcon(
                            catalog: art,
                            role: AuraUiIcon.rewardedAd,
                            fallbackIcon: Icons.play_circle_outline,
                            semanticLabel: translate('shop_ad_topup_title'),
                            decorative: true,
                            size: 24,
                          ),
                          label: Text(translate('shop_ad_topup_title')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BigInt _effectAt(int level) =>
      upgrade.base20 *
      BigInt.from(level * controller.milestoneFactor(level)) *
      controller.multiplier;

  String _effectLabel(String key, String effectKind) {
    final label = translate(key, {'rate': ''})
        .trim()
        .replaceFirst(RegExp(r'[\s:：؛،,.-]+$'), '');
    return '$label · $effectKind';
  }

  String _requirementLabel(UpgradeRequirement requirement) {
    if (requirement.kind == UpgradeRequirementKind.totalAura) {
      final target = requirement.total!;
      return '${translate('shop_tier_required', {
            'amount': _ltrToken(AuraFormat.integer(target, locale: locale)),
          })} ${_ltrToken('(${AuraFormat.integer(controller.total, locale: locale)}/${AuraFormat.integer(target, locale: locale)})')}';
    }
    final prerequisite = upgrades.firstWhere(
      (candidate) => candidate.id == requirement.upgradeId,
    );
    return '${translate('shop_item_required', {
          'name': translate(prerequisite.nameKey),
          'level': _ltrToken('${requirement.level}'),
        })} ${_ltrToken('(${controller.level(prerequisite.id)}/${requirement.level})')}';
  }

  int _nextMilestone(int level) {
    for (final milestone in const [10, 25, 50]) {
      if (level < milestone) return milestone;
    }
    return ((level ~/ 100) + 1) * 100;
  }

  String _ltrToken(String value) => '\u2066$value\u2069';
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _EffectPanel extends StatelessWidget {
  const _EffectPanel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F26),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .55),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    super.key,
    required this.met,
    required this.label,
  });

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: (met ? const Color(0xFFB7F171) : const Color(0xFFFFE59A))
                    .withValues(alpha: .11),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                met ? Icons.check : Icons.lock_outline,
                color: met ? const Color(0xFFB7F171) : const Color(0xFFFFE59A),
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: met
                      ? Colors.white.withValues(alpha: .76)
                      : const Color(0xFFF7F5FF),
                  height: 1.4,
                  fontWeight: met ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PurchaseOptions extends StatelessWidget {
  const _PurchaseOptions({
    required this.upgrade,
    required this.unlocked,
    required this.one,
    required this.ten,
    required this.max,
    required this.available,
    required this.translate,
    required this.locale,
    required this.onPurchase,
  });

  final Upgrade upgrade;
  final bool unlocked;
  final UpgradePurchaseQuote one;
  final UpgradePurchaseQuote ten;
  final UpgradePurchaseQuote max;
  final BigInt available;
  final AuraTranslate translate;
  final String locale;
  final void Function(Upgrade upgrade, int quantity) onPurchase;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 390 ||
              MediaQuery.textScalerOf(context).scale(16) > 22;
          final buttons = [
            _PurchaseButton(
              key: ValueKey('buy-x1-${upgrade.id}'),
              label: translate('shop_buy_one'),
              cost: one.cost,
              enabled: unlocked && one.affordable,
              primary: true,
              locale: locale,
              missingLabel: _missingLabel(one),
              onPressed: () => _purchaseAndClose(context, 1),
            ),
            _PurchaseButton(
              key: ValueKey('buy-x10-${upgrade.id}'),
              label: translate('shop_buy_ten'),
              cost: ten.cost,
              enabled: unlocked && ten.affordable,
              locale: locale,
              missingLabel: _missingLabel(ten),
              onPressed: () => _purchaseAndClose(context, 10),
            ),
            _PurchaseButton(
              key: ValueKey('buy-max-${upgrade.id}'),
              label: '${translate('shop_buy_max')} (×${max.quantity})',
              cost: max.cost,
              enabled: unlocked && max.affordable,
              locale: locale,
              missingLabel: max.affordable ? null : _missingLabel(one),
              onPressed: () => _purchaseAndClose(context, -1),
            ),
          ];
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  buttons[index],
                  if (index != buttons.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                Expanded(child: buttons[index]),
                if (index != buttons.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        },
      );

  String? _missingLabel(UpgradePurchaseQuote quote) {
    if (quote.affordable || quote.cost <= available) return null;
    return translate('shop_missing', {
      'amount':
          '\u2066${AuraFormat.integer(quote.cost - available, locale: locale)}\u2069',
    });
  }

  void _purchaseAndClose(BuildContext context, int quantity) {
    onPurchase(upgrade, quantity);
    Navigator.pop(context);
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    super.key,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.locale,
    required this.onPressed,
    this.missingLabel,
    this.primary = false,
  });

  final String label;
  final BigInt cost;
  final bool enabled;
  final String locale;
  final VoidCallback onPressed;
  final String? missingLabel;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(
          '${AuraFormat.integer(cost, locale: locale)} Aura',
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        if (missingLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            missingLabel!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFE59A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
    return primary
        ? FilledButton(
            onPressed: enabled ? onPressed : null,
            child: child,
          )
        : OutlinedButton(
            onPressed: enabled ? onPressed : null,
            child: child,
          );
  }
}

String _branchTitle(AuraTranslate translate, String branch) => switch (branch) {
      'A' => translate('content.branch_a.name'),
      'B' => translate('content.branch_b.name'),
      'C' => translate('content.branch_c.name'),
      'Spectrum' => 'Spectrum',
      _ => translate('shop_techniques'),
    };

Color _branchColor(String branch) => switch (branch) {
      'A' => const Color(0xFF43E6FF),
      'B' => const Color(0xFFFF4FA3),
      'C' => const Color(0xFFFFD166),
      'Spectrum' => const Color(0xFFB8A7FF),
      _ => const Color(0xFF8B7CFF),
    };

IconData _branchFallback(String branch) => switch (branch) {
      'A' => Icons.diamond_outlined,
      'B' => Icons.circle_outlined,
      'C' => Icons.change_history,
      'Spectrum' => Icons.hexagon_outlined,
      _ => Icons.bolt,
    };
