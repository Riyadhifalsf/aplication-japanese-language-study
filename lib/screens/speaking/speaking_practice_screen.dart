import 'package:flutter/material.dart';
import '../../state/app_controller.dart';

class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});
  @override State<SpeakingPracticeScreen> createState()=>_SpeakingPracticeScreenState();
}
class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  final target=const ['こんにちは。','ありがとうございます。','日本語を勉強しています。']; int index=0; String? result;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Speaking Practice')),body:ListView(padding:const EdgeInsets.all(18),children:[Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Ucapkan kalimat ini',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:10),Text(target[index],style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:14),LayoutBuilder(builder:(context,constraints){
  final buttons=[
    FilledButton.icon(onPressed:()=>AppScope.of(context).tts.speak(target[index]),icon:const Icon(Icons.volume_up_rounded),label:const Text('Dengar')),
    OutlinedButton.icon(onPressed:()=>setState(()=>result='Siap diverifikasi oleh speech/AI backend.'),icon:const Icon(Icons.mic_rounded),label:const Text('Mulai bicara')),
  ];
  if(constraints.maxWidth<420) return Wrap(spacing:8,runSpacing:8,children:buttons);
  return Row(children:[Expanded(child:buttons[0]),const SizedBox(width:8),Expanded(child:buttons[1])]);
}),if(result!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(result!,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800)))]))),const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.security_update_good_rounded),title:const Text('Verifikasi pronunciation',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:const Text('Arsitektur aplikasi sudah menyediakan titik integrasi untuk STT + model AI. Mesin verifikasi nyata perlu backend/permission mikrofon dan endpoint model agar tidak rapuh di perangkat.'))),const SizedBox(height:12),FilledButton(onPressed:index<target.length-1?()=>setState(()=>index++):null,child:const Text('Kalimat berikutnya'))]));
}
