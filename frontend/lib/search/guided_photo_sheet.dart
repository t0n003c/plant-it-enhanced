import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/search/photo_source_sheet.dart';

class GuidedPhotoSelection {
  final List<XFile> images;
  final List<String> organs;

  const GuidedPhotoSelection({
    required this.images,
    required this.organs,
  });
}

class GuidedPhotoSheet extends StatefulWidget {
  final XFile initialImage;

  const GuidedPhotoSheet({
    super.key,
    required this.initialImage,
  });

  @override
  State<GuidedPhotoSheet> createState() => _GuidedPhotoSheetState();
}

class _GuidedPhotoSheetState extends State<GuidedPhotoSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  late final Map<String, XFile> _photos;

  @override
  void initState() {
    super.initState();
    _photos = {'auto': widget.initialImage};
  }

  Future<void> _pick(String organ, ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image != null && mounted) {
      setState(() => _photos[organ] = image);
    }
  }

  void _identify() {
    const List<String> order = ['auto', 'leaf', 'flower'];
    final List<String> organs = order.where(_photos.containsKey).toList();
    Navigator.of(context).pop(GuidedPhotoSelection(
      images: organs.map((organ) => _photos[organ]!).toList(),
      organs: organs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PhotoSourceSheet.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).guidedPhotoTitle,
                      style: const TextStyle(
                        color: PhotoSourceSheet.primaryTextColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: PhotoSourceSheet.primaryTextColor,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                AppLocalizations.of(context).guidedPhotoIntro,
                style: const TextStyle(
                  color: PhotoSourceSheet.secondaryTextColor,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _PhotoSlot(
                        icon: Icons.yard_outlined,
                        title: AppLocalizations.of(context).wholePlantView,
                        hint: AppLocalizations.of(context).wholePlantPhotoHint,
                        photo: _photos['auto'],
                        onCamera: () => _pick('auto', ImageSource.camera),
                        onGallery: () => _pick('auto', ImageSource.gallery),
                      ),
                      const SizedBox(height: 10),
                      _PhotoSlot(
                        icon: Icons.eco_outlined,
                        title: AppLocalizations.of(context).leafView,
                        hint: AppLocalizations.of(context).leafPhotoHint,
                        photo: _photos['leaf'],
                        onCamera: () => _pick('leaf', ImageSource.camera),
                        onGallery: () => _pick('leaf', ImageSource.gallery),
                      ),
                      const SizedBox(height: 10),
                      _PhotoSlot(
                        icon: Icons.local_florist_outlined,
                        title: AppLocalizations.of(context).flowerView,
                        hint: AppLocalizations.of(context).flowerPhotoHint,
                        photo: _photos['flower'],
                        onCamera: () => _pick('flower', ImageSource.camera),
                        onGallery: () => _pick('flower', ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('identifyGuidedPhotosAction'),
                onPressed: _identify,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFFC7F9CC),
                  foregroundColor: const Color(0xFF10231C),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  AppLocalizations.of(context)
                      .identifyWithPhotos(_photos.length),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final XFile? photo;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoSlot({
    required this.icon,
    required this.title,
    required this.hint,
    required this.photo,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PhotoSourceSheet.actionBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: PhotoSourceSheet.iconColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PhotoSourceSheet.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photo?.name ?? hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PhotoSourceSheet.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (photo != null)
                const Icon(Icons.check_circle, color: Color(0xFFC7F9CC)),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCamera,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(AppLocalizations.of(context).takePlantPhoto),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onGallery,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(AppLocalizations.of(context).choosePlantPhoto),
          ),
        ],
      ),
    );
  }
}
