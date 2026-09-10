import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../state/app_controller.dart';

class AdSlot extends StatefulWidget {
  const AdSlot({super.key});
  @override State<AdSlot> createState()=>_AdSlotState();
}
class _AdSlotState extends State<AdSlot> {
  final service=AdminDataService();
  List<AdminAnnouncement> ads=[];
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {await service.load();if(!mounted)return;final app=AppScope.of(context);setState(()=>ads=service.activeAdsFor(app.isPremium));}
  @override Widget build(BuildContext context){
    final app=AppScope.of(context);
    if(app.isPremium) return const SizedBox.shrink();
    final item=ads.isEmpty?null:ads.first;
    return Container(height:item==null?58:88,margin:const EdgeInsets.only(top:14),padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),color:Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:.55),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant)),child:Row(children:[Icon(Icons.campaign_rounded,color:Theme.of(context).colorScheme.primary),const SizedBox(width:10),Expanded(child:item==null?const Text('Ruang iklan • siap dihubungkan ke Ad SDK',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)):Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontWeight:FontWeight.w900)),Text(item.body,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))])),if(item?.ctaLabel.trim().isNotEmpty==true)TextButton(onPressed:(){},child:Text(item!.ctaLabel))]));
  }
}
