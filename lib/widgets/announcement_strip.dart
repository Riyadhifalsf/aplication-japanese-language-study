import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../state/app_controller.dart';

class AnnouncementStrip extends StatefulWidget {
  const AnnouncementStrip({super.key, this.adsOnly=false});
  final bool adsOnly;
  @override State<AnnouncementStrip> createState()=>_AnnouncementStripState();
}
class _AnnouncementStripState extends State<AnnouncementStrip> {
  final service=AdminDataService();
  List<AdminAnnouncement> items=[];
  bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {await service.load(); if(!mounted)return; final app=AppScope.of(context); setState((){items=widget.adsOnly?service.activeAdsFor(app.isPremium):service.activeBannersFor(app.isPremium);loading=false;});}
  @override Widget build(BuildContext context){
    if(loading||items.isEmpty)return const SizedBox.shrink();
    final item=items.first; final isAd=item.type=='ad';
    return Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(14),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:LinearGradient(colors:isAd?const [Color(0xFF20243A),Color(0xFF5B5FEF)]:const [Color(0xFF0E7490),Color(0xFF2563EB)])),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(14)),child:Icon(isAd?Icons.campaign_rounded:Icons.notifications_active_rounded,color:Colors.white)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),const SizedBox(height:3),Text(item.body,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,height:1.35))])),if(item.ctaLabel.trim().isNotEmpty) ...[const SizedBox(width:8),FilledButton.tonal(onPressed:(){},child:Text(item.ctaLabel))]]));
  }
}
