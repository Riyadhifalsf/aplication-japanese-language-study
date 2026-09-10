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
    // Logo "G" empat warna resmi: merah di atas, biru sisi kanan, hijau
    // bawah, kuning kiri-bawah, + bilah horizontal. Sudut dalam radian
    // searah jarum jam dari timur (konvensi drawArc).
    final s = size.width;
    final stroke = s * 0.17;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: s * 0.405,
    );
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    Paint pen(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Merah: busur atas (10:30 -> 1:30).
    canvas.drawArc(rect, -2.36, 1.57, false, pen(red));
    // Biru: sisi kanan (1:30 -> 4:30).
    canvas.drawArc(rect, -0.79, 1.58, false, pen(blue));
    // Hijau: busur bawah (4:30 -> 7:30).
    canvas.drawArc(rect, 0.79, 1.57, false, pen(green));
    // Kuning: kiri-bawah (7:30 -> 9:00). Celah 9:00 -> 10:30 = bukaan "G".
    canvas.drawArc(rect, 2.36, 0.78, false, pen(yellow));
    // Merah: bilah horizontal tengah-kanan.
    canvas.drawLine(
      Offset(s * 0.5, s * 0.5),
      Offset(s * 0.93, s * 0.5),
      pen(red),
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


