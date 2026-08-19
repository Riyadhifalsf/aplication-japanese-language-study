import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_data_service.dart';
import '../../state/app_controller.dart';
import '../auth/login_screen.dart';
import '../exams/exam_hub_screen.dart';
import '../premium/premium_screen.dart';
import '../study/learning_path_screen.dart';
import 'admin_studio_screen.dart';
import '../app_shell.dart';
import '../../services/feature_flags_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final data = AdminDataService();
  Timer? timer;
  bool loading = true;
  int tab = 0;

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async { await data.load(); if (!mounted) return; setState(() => loading = false); timer = Timer.periodic(const Duration(seconds: 7), (_) => setState(() {})); }
  @override void dispose() { timer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [_overview(context, app), _users(context), _community(context), _adminMore(context, app)];
    final labels = ['Overview','Users','Community','Lainnya'];
    final icons = [Icons.dashboard_outlined,Icons.people_outline,Icons.forum_outlined,Icons.more_horiz_rounded];
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final content = Scaffold(appBar: AppBar(title: Text(labels[tab]), actions: [IconButton(tooltip:'Refresh', onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded)), PopupMenuButton<String>(onSelected: (v) { if (v=='logout') _logout(context, app); }, itemBuilder: (_) => const [PopupMenuItem(value:'logout', child: Text('Keluar'))])]), body: pages[tab]);
    if (wide) return Scaffold(body: Row(children:[NavigationRail(selectedIndex:tab, extended:MediaQuery.sizeOf(context).width>=1180,onDestinationSelected:(i)=>setState(()=>tab=i),leading:Padding(padding:const EdgeInsets.all(12),child:Image.asset('assets/branding/japanese_study_logo.png',width:48,height:48)),destinations:[for(var i=0;i<labels.length;i++)NavigationRailDestination(icon:Icon(icons[i]),selectedIcon:Icon(icons[i]),label:Text(labels[i]))]),const VerticalDivider(width:1),Expanded(child:content)]));
    return Scaffold(body:content, bottomNavigationBar:NavigationBar(selectedIndex:tab>3?3:tab,onDestinationSelected:(i){if(i<3)setState(()=>tab=i);else showModalBottomSheet<void>(context:context,builder:(c)=>_moreMenu(c, app));},destinations:const[NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Overview'),NavigationDestination(icon:Icon(Icons.people_outline),label:'Users'),NavigationDestination(icon:Icon(Icons.forum_outlined),label:'Community'),NavigationDestination(icon:Icon(Icons.more_horiz_rounded),label:'Lainnya')]));
  }

  Widget _overview(BuildContext context, AppController app) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [cs.primary, cs.secondary])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('ADMIN CONTROL CENTER', style: TextStyle(color:Colors.white70,fontWeight:FontWeight.w900,letterSpacing:1.1)), SizedBox(height:8), Text('Kelola Japanese Study', style: TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)), SizedBox(height:6), Text('Pantau pengguna, konten, komunitas, laporan, dan aktivitas aplikasi dari satu dashboard.', style: TextStyle(color:Colors.white70,height:1.4))])),
      const SizedBox(height:16),
      GridView.count(crossAxisCount: 2, shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing:10, mainAxisSpacing:10, childAspectRatio:1.55, children:[_metric('Total user','${data.totalUsers}', Icons.people_rounded), _metric('Online','${data.onlineUsers}', Icons.wifi_rounded, live:true), _metric('Aktif','${data.activeUsers}', Icons.insights_rounded), _metric('Laporan terbuka','${data.openReports}', Icons.report_problem_rounded, danger:data.openReports>0)]),
      const SizedBox(height:16),
      Row(children:[Expanded(child:_miniChart(context, 'Aktivitas 7 hari', [18,24,20,35,32,48,42])), const SizedBox(width:10), Expanded(child:_miniChart(context, 'Konten', [12,18,8,24,17,30,28]))]),
      const SizedBox(height:16),
      _card(title:'Quick actions', child: Wrap(spacing:8, runSpacing:8, children:[_action('Tambah user', Icons.person_add_rounded, () => _userDialog(context)), _action('Posting komunitas', Icons.post_add_rounded, () => _postDialog(context)), _action('Lihat ujian', Icons.assignment_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamHubScreen()))), _action('Aplikasi utama', Icons.open_in_new_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppShell()))), _action('Fitur Beta', Icons.science_rounded, () => _featureDialog(context, app)), _action('Pengumuman', Icons.campaign_rounded, () => _openAux(context, _announcements(context), 'Announcements'))])),
      const SizedBox(height:16),
      _card(
        title: 'Aktivitas terbaru',
        child: Column(
          children: data.activities.take(8).map((a) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                child: Icon(_activityIcon(a.type), size: 17),
              ),
              title: Text(a.label),
              subtitle: Text(_when(a.createdAt)),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height:16),
      _card(title:'System health', child: Column(children:[_health('Content repository','Normal',true),_health('Local analytics','Aktif',true),_health('Realtime layer','Prototype lokal — siap diganti WebSocket/Firebase',true),_health('Moderation','${data.openReports} laporan perlu ditinjau',data.openReports==0)])),
      const SizedBox(height:20),
      Text('Konten tersedia: ${app.repository.kanji.length} kanji • ${app.repository.vocabulary.length} kotoba • ${app.repository.grammar.length} bunpou • ${app.repository.readings.length} bacaan', style: TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _adminMore(BuildContext context, AppController app) => ListView(padding:const EdgeInsets.all(16),children:[
    _card(title:'Kontrol fitur',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Fitur Beta default nonaktif. Payment juga OFF sampai siap diuji.',style:TextStyle(height:1.4)),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>_featureDialog(context,app),icon:const Icon(Icons.tune_rounded),label:const Text('Kelola feature flags')),
    ])),
    const SizedBox(height:12),
    _card(title:'Akses cepat',child:Wrap(spacing:8,runSpacing:8,children:[
      _action('Reports',Icons.report_problem_outlined,()=>_openAux(context,_reports(context),'Reports')),
      _action('Content',Icons.library_books_outlined,()=>_openAux(context,_content(context,app),'Content')),
      _action('Announcements',Icons.campaign_outlined,()=>_openAux(context,_announcements(context),'Announcements')),
      _action('Studio',Icons.tune_rounded,()=>_openAux(context,const AdminStudioScreen(),'Studio')),
      _action('Aplikasi utama',Icons.open_in_new_rounded,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AppShell()))),
    ])),
  ]);

  Widget _moreMenu(BuildContext context, AppController app) => SafeArea(child: ListView(shrinkWrap:true, children:[
    ListTile(leading:const Icon(Icons.science_rounded),title:const Text('Fitur Beta',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:const Text('Aktif/nonaktifkan fitur eksperimen'),onTap:(){Navigator.pop(context);_featureDialog(context,app);}),
    ListTile(leading:const Icon(Icons.report_problem_outlined),title:const Text('Reports'),onTap:(){Navigator.pop(context);_openAux(context,_reports(context),'Reports');}),
    ListTile(leading:const Icon(Icons.library_books_outlined),title:const Text('Content'),onTap:(){Navigator.pop(context);_openAux(context,_content(context,app),'Content');}),
    ListTile(leading:const Icon(Icons.campaign_outlined),title:const Text('Announcements'),onTap:(){Navigator.pop(context);_openAux(context,_announcements(context),'Announcements');}),
    ListTile(leading:const Icon(Icons.tune_rounded),title:const Text('Studio'),onTap:(){Navigator.pop(context);_openAux(context,const AdminStudioScreen(),'Studio');}),
    const Divider(),
    ListTile(leading:const Icon(Icons.open_in_new_rounded),title:const Text('Buka aplikasi utama'),subtitle:const Text('Admin tetap bisa melihat sisi pengguna.'),onTap:(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>const AppShell()));}),
  ]));

  void _openAux(BuildContext context, Widget page, String title) => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar:AppBar(title:Text(title)), body:page)));

  Future<void> _featureDialog(BuildContext context, AppController app) async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(sheet)=>StatefulBuilder(builder:(context,setSheetState){
      final defs=FeatureFlagsService.definitions;
      return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Feature control',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
        const SizedBox(height:4),
        const Text('Fitur Beta default OFF. Payment juga OFF dan baru boleh dinyalakan saat backend transaksi sudah siap.',style:TextStyle(height:1.4)),
        const SizedBox(height:12),
        ...defs.map((f)=>SwitchListTile(contentPadding:EdgeInsets.zero,value:app.featureEnabled(f.key),onChanged:(value)async{await app.setFeatureFlag(f.key,value);setSheetState((){});setState((){});},title:Row(children:[Expanded(child:Text(f.name,style:const TextStyle(fontWeight:FontWeight.w900))),if(f.beta)Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Theme.of(context).colorScheme.tertiaryContainer,borderRadius:BorderRadius.circular(99)),child:Text('BETA',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:Theme.of(context).colorScheme.onTertiaryContainer)))]),subtitle:Text(f.description))),
      ])));
    }));
    await app.reloadFeatureFlags();
  }

  Widget _users(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('User management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            FilledButton.icon(
              onPressed: () => _userDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama atau email'),
        ),
        const SizedBox(height: 12),
        ...data.users.map((u) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(u.name.isEmpty ? '?' : u.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${u.email} • ${u.role.toUpperCase()} • ${u.level}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: u.online ? Colors.green : Colors.grey,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => _userAction(context, u, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'online', child: Text('Toggle online')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _community(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Community moderation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            FilledButton.icon(
              onPressed: () => _postDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...data.posts.map((p) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(p.author.isEmpty ? '?' : p.author.substring(0, 1)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.author, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(
                              '${p.status} • ${_when(p.createdAt)}',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) => _postAction(context, p, v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.text, style: const TextStyle(fontSize: 16, height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 18),
                      Text(' ${p.likes}'),
                      const SizedBox(width: 18),
                      const Icon(Icons.comment_outlined, size: 18),
                      Text(' ${p.comments}'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _commentDialog(context, p),
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const Text('Komentar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        _card(
          title: 'Komentar terbaru',
          child: Column(
            children: data.comments.take(8).map((c) {
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(c.text),
                subtitle: Text('${c.author} • ${_when(c.createdAt)}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _commentAction(context, c, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    PopupMenuItem(value: 'hide', child: Text('Sembunyikan')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _reports(BuildContext context) => ListView(padding:const EdgeInsets.all(16),children:[Row(children:[const Expanded(child:Text('Complaint & reports',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),Text('${data.openReports} open',style:const TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:12), ...data.reports.map((r)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:r.status=='open'?Colors.orange.shade100:Colors.green.shade100,child:Icon(r.status=='open'?Icons.priority_high:Icons.check,color:r.status=='open'?Colors.orange:Colors.green)),title:Text(r.category,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r.reporter}\n${r.message}',maxLines:3),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v)=>_reportAction(context,r,v),itemBuilder:(_)=>const[PopupMenuItem(value:'resolve',child:Text('Tandai selesai')),PopupMenuItem(value:'reopen',child:Text('Buka lagi')),PopupMenuItem(value:'delete',child:Text('Hapus'))])))).toList(),const SizedBox(height:16),FilledButton.tonalIcon(onPressed:()=>_reportDialog(context),icon:const Icon(Icons.add_alert),label:const Text('Buat laporan simulasi'))]);

  Widget _content(BuildContext context, AppController app) => ListView(padding:const EdgeInsets.all(16),children:[const Text('Content management',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),_crudCard('Learning Path','Bab N5–N1 dan struktur course',Icons.route_rounded,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LearningPathScreen()))),_crudCard('Kanji','${app.repository.kanji.length} kanji',Icons.translate_rounded,()=>_toast(context,'CRUD Kanji siap dihubungkan ke backend repository.')),_crudCard('Kotoba','${app.repository.vocabulary.length} kata',Icons.abc_rounded,()=>_toast(context,'CRUD Kotoba siap dihubungkan ke backend repository.')),_crudCard('Bunpou','${app.repository.grammar.length} grammar',Icons.menu_book_rounded,()=>_toast(context,'CRUD Bunpou siap dihubungkan ke backend repository.')),_crudCard('JLPT / JFT','50 paket per track',Icons.assignment_turned_in_rounded,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ExamHubScreen())))]);

  Widget _announcements(BuildContext context) {
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[const Expanded(child:Text('Announcements & Ads',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>_announcementDialog(context),icon:const Icon(Icons.add),label:const Text('Tambah'))]),
      const SizedBox(height:8),
      const Text('Kelola pengumuman, banner, dan iklan. Iklan dapat dibatasi untuk pengguna Free.'),
      const SizedBox(height:14),
      if(data.announcements.isEmpty)_card(title:'Belum ada konten',child:const Text('Buat pengumuman atau iklan pertama.')),
      ...data.announcements.map((a)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(a.type=='ad'?Icons.ads_click_rounded:a.type=='banner'?Icons.view_carousel_rounded:Icons.notifications_active_rounded)),title:Text(a.title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${a.type.toUpperCase()} • ${a.active?'AKTIF':'NONAKTIF'} • ${a.freeOnly?'FREE SAJA':'SEMUA USER'}\n${a.body}',maxLines:3,overflow:TextOverflow.ellipsis),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit')await _announcementDialog(context,a);if(v=='toggle'){a.active=!a.active;await data.updateAnnouncement(a);}if(v=='delete')await data.deleteAnnouncement(a.id);if(mounted)setState((){});},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'toggle',child:Text('Aktif / Nonaktif')),PopupMenuItem(value:'delete',child:Text('Hapus'))])))),
    ]);
  }

  Future<void> _announcementDialog(BuildContext context,[AdminAnnouncement? existing])async{
    final title=TextEditingController(text:existing?.title??'');final body=TextEditingController(text:existing?.body??'');final cta=TextEditingController(text:existing?.ctaLabel??'');String type=existing?.type??'announcement';bool active=existing?.active??true;bool freeOnly=existing?.freeOnly??false;
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:Text(existing==null?'Buat pengumuman / iklan':'Edit pengumuman / iklan'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Judul')),TextField(controller:body,maxLines:4,decoration:const InputDecoration(labelText:'Isi / pesan')),DropdownButtonFormField<String>(value:type,items:const['announcement','banner','ad'].map((x)=>DropdownMenuItem(value:x,child:Text(x=='announcement'?'Pengumuman':x=='banner'?'Banner':'Iklan'))).toList(),onChanged:(v)=>set(()=>type=v??type),decoration:const InputDecoration(labelText:'Tipe')),TextField(controller:cta,decoration:const InputDecoration(labelText:'Tombol (opsional)')),SwitchListTile(value:active,onChanged:(v)=>set(()=>active=v),title:const Text('Aktif')),SwitchListTile(value:freeOnly,onChanged:(v)=>set(()=>freeOnly=v),title:const Text('Khusus Free'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))])));
    if(ok!=true)return;final item=AdminAnnouncement(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),body:body.text.trim(),type:type,active:active,freeOnly:freeOnly,ctaLabel:cta.text.trim(),createdAt:existing?.createdAt??DateTime.now());if(existing==null)await data.addAnnouncement(item);else await data.updateAnnouncement(item);if(mounted)setState((){});
  }

  Widget _metric(String l,String v,IconData i,{bool live=false,bool danger=false})=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:danger?Colors.red:live?Colors.green:null),const Spacer(),Text(v,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),Text(l,style:const TextStyle(fontWeight:FontWeight.w700))])));
  Widget _miniChart(BuildContext context,String title,List<int> values)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:12),SizedBox(height:65,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:values.map((v)=>Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:FractionallySizedBox(heightFactor:v/50,alignment:Alignment.bottomCenter,child:DecoratedBox(decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(4))))))).toList()))])));
  Widget _card({required String title,required Widget child})=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),child])));
  Widget _action(String t,IconData i,VoidCallback onTap)=>ActionChip(avatar:Icon(i,size:17),label:Text(t),onPressed:onTap);
  Widget _health(String a,String b,bool good)=>ListTile(dense:true,leading:Icon(good?Icons.check_circle:Icons.warning_amber_rounded,color:good?Colors.green:Colors.orange),title:Text(a),subtitle:Text(b));
  Widget _crudCard(String title,String sub,IconData icon,VoidCallback onTap)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:onTap));
  IconData _activityIcon(String t)=>switch(t){'user'=>Icons.person,'community'=>Icons.forum,'comment'=>Icons.comment,'report'=>Icons.report,'system'=>Icons.settings,_=>Icons.bolt};
  String _when(DateTime? d){if(d==null)return '-';final x=DateTime.now().difference(d);if(x.inSeconds<60)return 'baru saja';if(x.inMinutes<60)return '${x.inMinutes}m lalu';if(x.inHours<24)return '${x.inHours}j lalu';return '${x.inDays}h lalu';}
  void _toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));

  Future<void> _userDialog(BuildContext context,[AdminUser? existing]) async {final name=TextEditingController(text:existing?.name??'');final email=TextEditingController(text:existing?.email??'');String level=existing?.level??'N5';String role=existing?.role??'user';final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:Text(existing==null?'Tambah user':'Edit user'),content:SingleChildScrollView(child:Column(children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Nama')),TextField(controller:email,decoration:const InputDecoration(labelText:'Email')),DropdownButtonFormField<String>(value:role,items:const['user','moderator','admin'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>role=v??'user'),decoration:const InputDecoration(labelText:'Role')),DropdownButtonFormField<String>(value:level,items:const['N5','N4','N3','N2','N1'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>level=v??'N5'),decoration:const InputDecoration(labelText:'Level'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))])));if(ok!=true)return;final u=AdminUser(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),email:email.text.trim(),role:role,level:level,online:existing?.online??false,createdAt:existing?.createdAt??DateTime.now()); if(existing==null)await data.addUser(u);else await data.updateUser(u);if(mounted)setState((){});}
  Future<void> _postDialog(BuildContext context,[CommunityPost? existing]) async {final author=TextEditingController(text:existing?.author??'Admin');final text=TextEditingController(text:existing?.text??'');final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(existing==null?'Buat posting':'Edit posting'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:author,decoration:const InputDecoration(labelText:'Author')),TextField(controller:text,maxLines:5,decoration:const InputDecoration(labelText:'Isi'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Simpan'))]));if(ok!=true)return;final p=CommunityPost(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),author:author.text.trim(),text:text.text.trim(),likes:existing?.likes??0,comments:existing?.comments??0,status:'published',createdAt:existing?.createdAt??DateTime.now());if(existing==null)await data.addPost(p);else await data.updatePost(p);if(mounted)setState((){});}
  Future<void> _commentDialog(BuildContext context,CommunityPost p) async {final author=TextEditingController(text:'Admin');final text=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Tambah komentar'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:author,decoration:const InputDecoration(labelText:'Author')),TextField(controller:text,decoration:const InputDecoration(labelText:'Komentar'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Kirim'))]));if(ok!=true)return;await data.addComment(AdminComment(id:DateTime.now().microsecondsSinceEpoch.toString(),postId:p.id,author:author.text.trim(),text:text.text.trim(),createdAt:DateTime.now()));if(mounted)setState((){});}
  Future<void> _reportDialog(BuildContext context) async {final reporter=TextEditingController(text:'user@example.com');final message=TextEditingController();String cat='Bug';final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:const Text('Buat laporan'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:reporter,decoration:const InputDecoration(labelText:'Reporter')),DropdownButtonFormField<String>(value:cat,items:const['Bug','Konten','Pembayaran','Akun','Pelanggaran','Lainnya'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>cat=v??cat)),TextField(controller:message,maxLines:4,decoration:const InputDecoration(labelText:'Pesan'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Kirim'))])));if(ok!=true)return;await data.addReport(ComplaintReport(id:DateTime.now().microsecondsSinceEpoch.toString(),reporter:reporter.text.trim(),category:cat,message:message.text.trim(),createdAt:DateTime.now()));if(mounted)setState((){});}

  Future<void> _userAction(BuildContext c,AdminUser u,String v)async{if(v=='edit')return _userDialog(c,u);if(v=='online')await data.setUserOnline(u.id,!u.online);if(v=='delete')await data.deleteUser(u.id);if(mounted)setState((){});}
  Future<void> _postAction(BuildContext c,CommunityPost p,String v)async{if(v=='edit')return _postDialog(c,p);if(v=='delete')await data.deletePost(p.id);if(mounted)setState((){});}
  Future<void> _commentAction(BuildContext c,AdminComment x,String v)async{if(v=='delete')await data.deleteComment(x.id);if(v=='hide'){x.status='hidden';await data.updateComment(x);}if(mounted)setState((){});}
  Future<void> _reportAction(BuildContext c,ComplaintReport r,String v)async{if(v=='delete')await data.deleteReport(r.id);if(v=='resolve'){r.status='resolved';await data.updateReport(r);}if(v=='reopen'){r.status='open';await data.updateReport(r);}if(mounted)setState((){});}
  Future<void> _logout(BuildContext context,AppController app) async {await app.logout();if(context.mounted)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
}
