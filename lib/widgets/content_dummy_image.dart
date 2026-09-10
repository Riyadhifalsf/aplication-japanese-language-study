import 'package:flutter/material.dart';

/// Gambar sementara untuk materi/permainan.
///
/// Saat gambar asli sudah tersedia, cukup isi [assetPath] atau ganti dengan
/// URL gambar dari backend tanpa mengubah layout pemanggil.
class ContentDummyImage extends StatelessWidget {
  const ContentDummyImage({this.title, this.subtitle, this.assetPath, this.height = 150, super.key});

  final String? title;
  final String? subtitle;
  final String? assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = assetPath == null
        ? Image.asset('assets/branding/content_dummy.svg', fit: BoxFit.cover, width: double.infinity, height: height)
        : Image.asset(assetPath!, fit: BoxFit.cover, width: double.infinity, height: height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (title != null || subtitle != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, cs.scrim.withValues(alpha: .72)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) Text(title!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
