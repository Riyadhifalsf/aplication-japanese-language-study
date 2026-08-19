import 'package:flutter/material.dart';
import '../../state/app_controller.dart';

class AdminStudioScreen extends StatefulWidget { const AdminStudioScreen({super.key}); @override State<AdminStudioScreen> createState()=>_AdminStudioScreenState(); }
class _AdminStudioScreenState extends State<AdminStudioScreen>{
  bool glass=true, featureNotifications=true, adaptiveReview=true;
  String releaseTitle=''; String releaseDetails='';
  @override Widget build(BuildContext context){final app=AppScope.of(context); return ListView(padding:const EdgeInsets.all(18),children:[
    Text('Application Studio',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:4),Text('Panel operasional untuk mengubah perilaku aplikasi tanpa menyentuh source code.',style:TextStyle(height:1.4)),
    const SizedBox(height:16),
    Card(child:Column(children:[SwitchListTile(value:glass,onChanged:(v)=>setState(()=>glass=v),title:const Text('Liquid Glass UI'),subtitle:const Text('Aktifkan gaya kaca/transparan untuk komponen utama.'),secondary:const Icon(Icons.blur_on_rounded)),SwitchListTile(value:featureNotifications,onChanged:(v)=>setState(()=>featureNotifications=v),title:const Text('Notifikasi fitur baru'),subtitle:const Text('Setiap release dicatat sebagai event dan dapat dikirim ke HP.'),secondary:const Icon(Icons.notifications_active_rounded)),SwitchListTile(value:adaptiveReview,onChanged:(v)=>setState(()=>adaptiveReview=v),title:const Text('Adaptive review'),subtitle:const Text('Interval review mengikuti performa pengguna.'),secondary:const Icon(Icons.auto_awesome_rounded))])),
    const SizedBox(height:16),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Rilis fitur',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),TextField(decoration:const InputDecoration(labelText:'Nama fitur'),onChanged:(v)=>releaseTitle=v),const SizedBox(height:10),TextField(maxLines:3,decoration:const InputDecoration(labelText:'Ringkasan perubahan'),onChanged:(v)=>releaseDetails=v),const SizedBox(height:12),FilledButton.icon(onPressed:featureNotifications?(){final title=releaseTitle.trim();final details=releaseDetails.trim();if(title.isEmpty||details.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Nama dan ringkasan fitur wajib diisi.')));return;}app.markFeatureRelease(title,details);setState((){releaseTitle='';releaseDetails='';});ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Release dicatat dan notifikasi dikirim.')));}:null,icon:const Icon(Icons.publish_rounded),label:const Text('Publikasikan fitur baru'))]))),
    const SizedBox(height:16),
    Card(child:ListTile(leading:const Icon(Icons.storage_rounded),title:const Text('Content control plane',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${app.repository.kanji.length} kanji · ${app.repository.vocabulary.length} kotoba · ${app.repository.grammar.length} bunpou · ${app.repository.readings.length} bacaan'),trailing:const Icon(Icons.chevron_right_rounded))),
    const SizedBox(height:10),
    Card(child:ListTile(leading:const Icon(Icons.timeline_rounded),title:const Text('Telemetry',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${app.activityJournal.length} event · ${app.sessionCount} sesi · ${app.totalActiveMinutes} menit aktif'))),
    const SizedBox(height:10),
    Card(child:ListTile(leading:const Icon(Icons.badge_rounded),title:const Text('Web3 layer',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${app.web3CredentialCount} credential · ${app.web3Identity.substring(0,12)}…'))),
  ]); }
}
