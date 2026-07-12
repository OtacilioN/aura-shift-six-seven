import 'package:flutter/material.dart';

import '../game/art_catalog.dart';

/// Manifest-backed image with a stable fallback and explicit semantics.
class AuraAssetArt extends StatelessWidget {
  const AuraAssetArt({
    super.key,
    required this.catalog,
    required this.assetId,
    required this.fallback,
    required this.width,
    required this.height,
    this.semanticLabel,
    this.decorative = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.opacity = 1,
  }) : assert(decorative || semanticLabel != null);

  final ArtCatalog? catalog;
  final String? assetId;
  final Widget fallback;
  final double width;
  final double height;
  final String? semanticLabel;
  final bool decorative;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final record = assetId == null ? null : catalog?[assetId!];
    final image = record == null
        ? fallback
        : Image.asset(
            record.runtimePath,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => fallback,
          );
    final sized = SizedBox(width: width, height: height, child: image);
    final visible =
        opacity == 1 ? sized : Opacity(opacity: opacity, child: sized);
    if (decorative) return ExcludeSemantics(child: visible);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: visible),
    );
  }
}

class AuraAssetIcon extends StatelessWidget {
  const AuraAssetIcon({
    super.key,
    required this.catalog,
    required this.role,
    required this.fallbackIcon,
    required this.semanticLabel,
    this.size = 28,
    this.decorative = false,
    this.opacity = 1,
  });

  final ArtCatalog? catalog;
  final AuraUiIcon role;
  final IconData fallbackIcon;
  final String semanticLabel;
  final double size;
  final bool decorative;
  final double opacity;

  @override
  Widget build(BuildContext context) => AuraAssetArt(
        catalog: catalog,
        assetId: AuraUiArt.icon(role),
        fallback: Icon(fallbackIcon, size: size),
        width: size,
        height: size,
        semanticLabel: semanticLabel,
        decorative: decorative,
        opacity: opacity,
      );
}

/// The Seal is authored as three composable layers and must remain readable if
/// one layer fails to decode.
class AuraSealArtwork extends StatelessWidget {
  const AuraSealArtwork({
    super.key,
    required this.catalog,
    required this.semanticLabel,
    this.size = 64,
    this.locked = false,
    this.decorative = false,
  });

  final ArtCatalog? catalog;
  final String semanticLabel;
  final double size;
  final bool locked;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final art = locked
        ? AuraAssetArt(
            catalog: catalog,
            assetId: AuraUiArt.sealLockedThumbnailId,
            fallback: Icon(Icons.lock_outline, size: size * .55),
            width: size,
            height: size,
            semanticLabel: semanticLabel,
            decorative: decorative,
            opacity: .48,
          )
        : SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final id in AuraUiArt.sealLayerIds)
                  AuraAssetArt(
                    catalog: catalog,
                    assetId: id,
                    fallback: const SizedBox.shrink(),
                    width: size,
                    height: size,
                    semanticLabel: semanticLabel,
                    decorative: true,
                  ),
                if (catalog == null ||
                    AuraUiArt.sealLayerIds.every((id) => catalog?[id] == null))
                  Icon(Icons.workspace_premium,
                      size: size * .62, color: const Color(0xFFFFD166)),
              ],
            ),
          );
    if (locked || decorative) return art;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: art),
    );
  }
}
