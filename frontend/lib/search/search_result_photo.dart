import 'package:flutter/material.dart';

/// A stable, uncropped photo frame for plant search results.
///
/// Provider images have many different aspect ratios. Keeping the image on a
/// centered `BoxFit.contain` canvas makes the whole specimen visible instead
/// of silently cropping leaves or flowers at the edge of the result card.
class SearchResultPhotoFrame extends StatelessWidget {
  static const double aspectRatio = 4 / 3;

  final ImageProvider<Object> imageProvider;
  final String semanticLabel;
  final bool loading;
  final Widget? overlay;

  const SearchResultPhotoFrame({
    super.key,
    required this.imageProvider,
    required this.semanticLabel,
    this.loading = false,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: const ValueKey('search-result-photo-frame'),
      aspectRatio: aspectRatio,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF10231C)),
            Semantics(
              image: true,
              label: semanticLabel,
              child: Image(
                key: const ValueKey('search-result-centered-image'),
                image: imageProvider,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (loading) ...[
              const ColoredBox(color: Color(0x9930473E)),
              const Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}
