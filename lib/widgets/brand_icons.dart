import 'package:flutter/material.dart';

/// Ikon brand Google "G" empat warna, digambar manual agar tanpa dependensi.
class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.17;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    // Biru: busur kiri-atas sampai kiri-bawah.
    canvas.drawArc(
      rect,
      1.65,
      2.85,
      false,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Hijau: busur bawah.
    canvas.drawArc(
      rect,
      -0.55,
      1.75,
      false,
      Paint()
        ..color = green
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Kuning: busur kanan-bawah kecil.
    canvas.drawArc(
      rect,
      -1.25,
      0.72,
      false,
      Paint()
        ..color = yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Merah: garis horizontal tengah-kanan.
    final barY = s * 0.5;
    canvas.drawLine(
      Offset(s * 0.52, barY),
      Offset(s * 0.92, barY),
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Merah: busur kanan-atas kecil penghubung.
    canvas.drawArc(
      rect,
      -1.62,
      0.38,
      false,
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Lencana "terverifikasi" ala ikon verified: centang putih di lingkaran biru.
///
/// Dipakai untuk: akun terverifikasi di profil, email terverifikasi,
/// dan konten resmi. Singkat, tidak berisik.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 20, this.tooltip});

  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1D9BF0),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.62),
    );
    final tip = tooltip;
    if (tip == null || tip.isEmpty) return badge;
    return Tooltip(message: tip, child: badge);
  }
}

/// Ikon Facebook "f" putih di lingkaran biru.
class FacebookFIcon extends StatelessWidget {
  const FacebookFIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.62,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}
