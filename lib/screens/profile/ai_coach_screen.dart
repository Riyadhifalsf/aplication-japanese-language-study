import 'package:flutter/material.dart';

import '../../services/ai_assessment_service.dart';
import '../../state/app_controller.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = AiAssessmentService.assess(AppScope.of(context));
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF4A1110),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                const Text('Penilaian belajar',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${ai.score}/100',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                Text(ai.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Analisis', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(ai.summary, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekomendasi berikutnya',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < ai.nextSteps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 12, child: Text('${i + 1}')),
                          const SizedBox(width: 9),
                          Expanded(child: Text(ai.nextSteps[i], style: const TextStyle(height: 1.35))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Mode saat ini adalah penilaian offline berbasis progres aplikasi. Tidak ada data pribadi yang dikirim ke model AI eksternal. Arsitekturnya sengaja dipisahkan agar model LLM/API dapat ditambahkan kemudian tanpa mengubah layar belajar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
