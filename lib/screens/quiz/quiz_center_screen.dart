import 'package:flutter/material.dart';

import '../../models/exam_question.dart';
import '../../state/app_controller.dart';
import '../../services/feature_flags_service.dart';
import '../exams/exam_hub_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_hiragana_quiz_screen.dart';
import '../kanji/kanji_mastery_quiz_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../kanji/kanji_similar_quiz_screen.dart';
import '../kanji/kanji_theme_quiz_screen.dart';
import '../vocab/vocabulary_quiz_screen.dart';
import 'quiz_setup_screen.dart';
import '../review/mistake_review_screen.dart';
import '../games/game_hub_screen.dart';
import '../speaking/speaking_practice_screen.dart';

class QuizCenterScreen extends StatelessWidget {
  const QuizCenterScreen({super.key});
  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = app.selectedStudyLevel == 'JFT' ? 'N5' : app.selectedStudyLevel;
    final examLocked = !app.canAccessFeature('exam_simulation');
    final speakingEnabled = app.speakingEnabled;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 32), children: [
      _Section(title:'Latihan utama', subtitle:'Pilih latihan yang ingin kamu kerjakan sekarang.'),
      const SizedBox(height:10),
      _Grid(items:[
        _Item('Quiz Kotoba','Arti, bacaan, konteks',Icons.abc_rounded,()=>_open(context,VocabularyQuizScreen(level:level,sessionSize:15))),
        _Item('Quiz Kanji','Penguasaan & kartu flip',Icons.translate_rounded,()=>_open(context,KanjiMasteryQuizScreen(level:level,sessionSize:15))),
        _Item('Kanji → Hiragana','Baca kanji dengan tepat',Icons.spellcheck_rounded,()=>_open(context,const KanjiHiraganaQuizScreen())),
        _Item('Kanji Mirip','Bedakan karakter serupa',Icons.blur_on_rounded,()=>_open(context,const KanjiSimilarQuizScreen())),
        _Item('Quiz Tema','Kosakata berbasis tema',Icons.category_rounded,()=>_open(context,const KanjiThemeQuizScreen())),
        _Item('Review Jatuh Tempo','${app.dueKanjiReviewCount} kanji siap direview',Icons.notifications_active_rounded,()=>_open(context,const KanjiReviewScreen())),
        _Item('Kana','Hiragana & katakana',Icons.grid_view_rounded,()=>_open(context,const KanaScreen())),
        _Item('Quiz Custom','Atur mode dan jumlah soal',Icons.tune_rounded,()=>_open(context,const QuizSetupScreen())),
        _Item('Ulasan Kesalahan','Lihat jawaban salah',Icons.rate_review_rounded,()=>_open(context,const MistakeReviewScreen())),
        _Item('Games','Typing Kana, Kotoba, Kanji',Icons.sports_esports_rounded,()=>_open(context,const GameHubScreen())),
        _Item('Speaking Practice','Dengar dan latih pengucapan',Icons.mic_rounded,()=>_open(context,const SpeakingPracticeScreen()),beta: true, enabledOverride: speakingEnabled, flagKey: FeatureFlagsService.speaking),
      ], enabled:true),
      const SizedBox(height:22),
      _Section(title:'Ujian & simulasi', subtitle:'Paket ujian dipisahkan dari latihan harian.'),
      const SizedBox(height:10),
      _Grid(items:[_Item('Simulasi JLPT','N5 sampai N1',Icons.school_rounded,()=>_open(context,const ExamHubScreen())),_Item('Simulasi JFT-Basic','Paket latihan A2',Icons.badge_rounded,()=>_open(context,const ExamHubScreen(initialType:ExamType.jft)))], enabled:!examLocked),
      if(examLocked) Padding(padding:const EdgeInsets.only(top:10),child:_XpLock(requiredXp:app.featureXpRequirement('exam_simulation'))),
    ]);
  }
}
class _Section extends StatelessWidget { const _Section({required this.title,required this.subtitle}); final String title,subtitle; @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))]); }
class _Grid extends StatelessWidget { const _Grid({required this.items,required this.enabled}); final List<_Item> items; final bool enabled; @override Widget build(BuildContext context)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:260,childAspectRatio:1.18,mainAxisSpacing:10,crossAxisSpacing:10),itemCount:items.length,itemBuilder:(_,i){final item=items[i];final on=item.enabledOverride??enabled;return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:on?item.onTap:null,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[CircleAvatar(child:Icon(on?item.icon:Icons.lock_rounded)),const Spacer(),if(item.beta) const _BetaBadge()]),const Spacer(),Text(item.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(item.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.onSurfaceVariant))]))));}); }
class _BetaBadge extends StatelessWidget { const _BetaBadge(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:Theme.of(context).colorScheme.tertiaryContainer,borderRadius:BorderRadius.circular(99)),child:Text('BETA',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:Theme.of(context).colorScheme.onTertiaryContainer))); }
class _Item { const _Item(this.title,this.subtitle,this.icon,this.onTap,{this.beta=false,this.enabledOverride,this.flagKey}); final String title,subtitle; final IconData icon; final VoidCallback onTap; final bool beta; final bool? enabledOverride; final String? flagKey; }
class _XpLock extends StatelessWidget { const _XpLock({required this.requiredXp}); final int requiredXp; @override Widget build(BuildContext context)=>Card(color:Theme.of(context).colorScheme.secondaryContainer.withValues(alpha:.55),child:ListTile(leading:const Icon(Icons.lock_rounded),title:const Text('Fitur ini belum terbuka',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('Kumpulkan ${requiredXp} XP untuk membuka akses.'))); }
