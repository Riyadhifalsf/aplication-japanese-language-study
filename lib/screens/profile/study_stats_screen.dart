import 'package:flutter/material.dart';
import '../../state/app_controller.dart';

class StudyStatsScreen extends StatelessWidget { const StudyStatsScreen({super.key});
 @override Widget build(BuildContext context){final app=AppScope.of(context); final acc=(app.quizAccuracy*100).round(); return Scaffold(appBar:AppBar(title:const Text('Statistik & jejak belajar')),body:ListView(padding:const EdgeInsets.fromLTRB(18,8,18,30),children:[
  Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Sejak ${app.firstUsedAt==null?'-':'${app.firstUsedAt!.day}/${app.firstUsedAt!.month}/${app.firstUsedAt!.year}'}',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),const SizedBox(height:7),Text('${app.totalActiveMinutes} menit aktif',style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900)),Text('${app.sessionCount} sesi · ${app.activeDays} hari aktif · ${app.activityJournal.length} event tercatat')]))),
  const SizedBox(height:12),
  Row(children:[Expanded(child:_M('Quiz','${app.quizAnswered}',Icons.quiz_rounded)),const SizedBox(width:10),Expanded(child:_M('Akurasi','$acc%',Icons.track_changes_rounded))]),
  const SizedBox(height:10),
  Row(children:[Expanded(child:_M('Kanji dikuasai','${app.masteredKanjiIds.length}',Icons.translate_rounded)),const SizedBox(width:10),Expanded(child:_M('Hari aktif','${app.activeDays}',Icons.calendar_today_rounded))]),
  const SizedBox(height:18),const Text('Penguasaan materi',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),for(final l in const ['N5','N4','N3','N2','N1'])_P(l,app.levelOverallMastery(l)),
  const SizedBox(height:18),const Text('Aktivitas terbaru',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:8),...app.activityJournal.reversed.take(24).map((e)=>ListTile(dense:true,leading:const Icon(Icons.timeline_rounded),title:Text('${e['label']??'-'}'),subtitle:Text('${e['type']??'-'} · ${e['at']??'-'}'))),
 ]));}
}
class _M extends StatelessWidget{const _M(this.l,this.v,this.i);final String l,v;final IconData i;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(i),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l,style:TextStyle(fontSize:11,color:Theme.of(c).colorScheme.onSurfaceVariant)),Text(v,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]))])));}
class _P extends StatelessWidget{const _P(this.l,this.p);final String l;final double p;@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:11),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text(l,style:const TextStyle(fontWeight:FontWeight.w800)),const Spacer(),Text('${(p*100).round()}%')]),const SizedBox(height:5),LinearProgressIndicator(value:p,minHeight:8)]));}
