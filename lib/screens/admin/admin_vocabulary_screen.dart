import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';
import '../../services/admin_api_service.dart';
import '../../state/app_controller.dart';

class AdminVocabularyScreen extends StatefulWidget {
  const AdminVocabularyScreen({super.key});

  @override
  State<AdminVocabularyScreen> createState() => _AdminVocabularyScreenState();
}

class _AdminVocabularyScreenState extends State<AdminVocabularyScreen> {
  final _search = TextEditingController();
  final _api = AdminApiService();
  String _level = 'Semua';
  bool _onlyKanji = false;
  bool _loadingBackend = false;
  bool _usingBackend = false;
  String _backendMessage = '';
  List<Vocabulary>? _backendVocabulary;

  @override
  void initState() {
    super.initState();
    _loadBackend();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadBackend() async {
    if (!_api.configured) return;
    setState(() {
      _loadingBackend = true;
      _backendMessage = '';
    });
    try {
      final items = await _api.fetchVocabulary();
      if (!mounted) return;
      setState(() {
        _backendVocabulary = items;
        _usingBackend = true;
        _loadingBackend = false;
        _backendMessage = 'Terhubung ke backend';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBackend = false;
        _usingBackend = false;
        _backendMessage = 'Mode lokal: backend belum tersedia';
      });
    }
  }

  List<Vocabulary> _source(AppController app) =>
      _usingBackend && _backendVocabulary != null
          ? _backendVocabulary!
          : app.repository.vocabulary;

  List<Vocabulary> _filtered(AppController app) {
    final q = _search.text.trim().toLowerCase();
    return _source(app).where((v) {
      final levelOk = _level == 'Semua' || v.level == _level;
      final kanjiOk = !_onlyKanji || app.repository.kanjiUsingVocabulary(v.id).isNotEmpty;
      final text = '${v.word} ${v.reading} ${v.meaning}'.toLowerCase();
      return levelOk && kanjiOk && (q.isEmpty || text.contains(q));
    }).toList(growable: false);
  }

  Future<void> _create(BuildContext context, AppController app) async {
    final result = await _vocabularyDialog(context, title: 'Tambah Kotoba');
    if (result == null || !mounted) return;
    try {
      Vocabulary item;
      if (_usingBackend) {
        item = await _api.createVocabulary(
          word: result.word,
          reading: result.reading,
          meaning: result.meaning,
          level: result.level,
        );
      } else {
        final nextId = app.repository.vocabulary.isEmpty
            ? 1
            : app.repository.vocabulary.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
        item = Vocabulary(id: nextId, word: result.word, reading: result.reading, meaning: result.meaning, level: result.level);
      }
      await app.repository.addVocabulary(item);
      if (!mounted) return;
      setState(() {
        _backendVocabulary = _usingBackend
            ? [...(_backendVocabulary ?? const <Vocabulary>[]), item]
            : _backendVocabulary;
      });
      _snack('Kotoba berhasil ditambahkan.');
    } catch (e) {
      if (mounted) _snack('Gagal menambah kotoba: ${_message(e)}', error: true);
    }
  }

  Future<void> _edit(BuildContext context, AppController app, Vocabulary item) async {
    final result = await _vocabularyDialog(context, title: 'Edit Kotoba #${item.id}', initial: item);
    if (result == null || !mounted) return;
    final updated = Vocabulary(id: item.id, word: result.word, reading: result.reading, meaning: result.meaning, level: result.level);
    try {
      final saved = _usingBackend ? await _api.updateVocabulary(updated) : updated;
      if (app.repository.vocabulary.any((x) => x.id == saved.id)) {
        await app.repository.updateVocabulary(saved);
      } else {
        await app.repository.addVocabulary(saved);
      }
      if (!mounted) return;
      setState(() {
        _replaceBackendItem(saved);
      });
      _snack('Kotoba berhasil disimpan.');
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan kotoba: ${_message(e)}', error: true);
    }
  }

  Future<void> _delete(BuildContext context, AppController app, Vocabulary item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kotoba?'),
        content: Text('“${item.word}” akan dihapus dari data ${_usingBackend ? 'backend dan' : ''} aplikasi ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (_usingBackend) await _api.deleteVocabulary(item.id);
      await app.repository.deleteVocabulary(item.id);
      if (!mounted) return;
      setState(() {
        _backendVocabulary = _usingBackend
            ? (_backendVocabulary ?? const <Vocabulary>[]).where((x) => x.id != item.id).toList(growable: false)
            : _backendVocabulary;
      });
      _snack('Kotoba berhasil dihapus.');
    } catch (e) {
      if (mounted) _snack('Gagal menghapus kotoba: ${_message(e)}', error: true);
    }
  }

  Future<void> _reset(BuildContext context, AppController app, Vocabulary item) async {
    if (_usingBackend) {
      _snack('Data backend tidak dikembalikan ke berkas aset. Gunakan Edit atau Hapus untuk mengelola data backend.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kembalikan data bawaan?'),
        content: Text('Perubahan lokal untuk “${item.word}” akan dihapus dan data bawaan akan digunakan lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kembalikan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await app.repository.resetVocabulary(item.id);
      if (!mounted) return;
      setState(() {});
      _snack('Kotoba dikembalikan ke data bawaan.');
    } catch (e) {
      if (mounted) _snack('Gagal mengembalikan kotoba: ${_message(e)}', error: true);
    }
  }

  void _replaceBackendItem(Vocabulary item) {
    if (!_usingBackend) return;
    final list = [...(_backendVocabulary ?? const <Vocabulary>[])];
    final index = list.indexWhere((x) => x.id == item.id);
    if (index < 0) {
      list.add(item);
    } else {
      list[index] = item;
    }
    _backendVocabulary = list;
  }

  Future<_VocabularyDraft?> _vocabularyDialog(BuildContext context, {required String title, Vocabulary? initial}) async {
    final word = TextEditingController(text: initial?.word ?? '');
    final reading = TextEditingController(text: initial?.reading ?? '');
    final meaning = TextEditingController(text: initial?.meaning ?? '');
    String level = initial?.level ?? 'N5';
    final result = await showDialog<_VocabularyDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 40).clamp(280.0, 560.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: word, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Kotoba / Kanji', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: reading, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Bacaan', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: meaning, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Arti Bahasa Indonesia', border: OutlineInputBorder(), helperText: 'Gunakan Bahasa Indonesia. Jangan masukkan terjemahan bahasa Inggris.')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: level,
                      decoration: const InputDecoration(labelText: 'Tingkat', border: OutlineInputBorder()),
                      items: const ['N5', 'N4', 'N3', 'N2', 'N1'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                      onChanged: (v) => setDialogState(() => level = v ?? level),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
              FilledButton.icon(
                onPressed: () {
                  final w = word.text.trim();
                  final r = reading.text.trim();
                  final m = meaning.text.trim();
                  if (w.isEmpty || r.isEmpty || m.isEmpty) return;
                  Navigator.pop(dialogContext, _VocabularyDraft(word: w, reading: r, meaning: m, level: level));
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
    word.dispose();
    reading.dispose();
    meaning.dispose();
    return result;
  }

  String _message(Object error) {
    final text = error.toString();
    return text.replaceFirst(RegExp(r'^(AdminApiException\([^)]*\):\s*)'), '');
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = _filtered(app);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kotoba'),
        actions: [
          if (_loadingBackend)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(tooltip: 'Muat ulang dari backend', onPressed: _loadingBackend ? null : _loadBackend, icon: const Icon(Icons.sync_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _create(context, app), icon: const Icon(Icons.add_rounded), label: const Text('Tambah')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                if (_backendMessage.isNotEmpty)
                  Align(alignment: Alignment.centerLeft, child: Text(_backendMessage, style: Theme.of(context).textTheme.labelMedium)),
                const SizedBox(height: 6),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari kotoba, bacaan, atau arti Bahasa Indonesia…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear_rounded)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, constraints) {
                  final level = DropdownButtonFormField<String>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Tingkat', border: OutlineInputBorder(), isDense: true),
                    items: const ['Semua', 'N5', 'N4', 'N3', 'N2', 'N1'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                    onChanged: (v) => setState(() => _level = v ?? 'Semua'),
                  );
                  final kanji = FilterChip(
                    selected: _onlyKanji,
                    label: const Text('Hanya yang terkait Kanji'),
                    avatar: const Icon(Icons.translate_rounded, size: 18),
                    onSelected: (v) => setState(() => _onlyKanji = v),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [level, const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: kanji)]);
                  }
                  return Row(children: [Expanded(child: level), const SizedBox(width: 10), Flexible(child: Align(alignment: Alignment.centerLeft, child: kanji))]);
                }),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Kotoba tidak ditemukan.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final linked = app.repository.kanjiUsingVocabulary(item.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              CircleAvatar(radius: 18, child: Text(item.level.replaceFirst('N', ''))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text(item.reading, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(item.meaning, maxLines: 3, overflow: TextOverflow.ellipsis),
                                if (linked.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Kanji: ${linked.map((k) => k.character).join('、')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ])),
                            ]),
                            const SizedBox(height: 6),
                            Align(alignment: Alignment.centerRight, child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                TextButton.icon(icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Edit'), onPressed: () => _edit(context, app, item)),
                                TextButton.icon(icon: const Icon(Icons.delete_outline_rounded, size: 18), label: const Text('Hapus'), onPressed: () => _delete(context, app, item)),
                                if (!_usingBackend) TextButton.icon(icon: const Icon(Icons.restore_rounded, size: 18), label: const Text('Kembalikan'), onPressed: () => _reset(context, app, item)),
                              ],
                            )),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyDraft {
  const _VocabularyDraft({required this.word, required this.reading, required this.meaning, required this.level});
  final String word;
  final String reading;
  final String meaning;
  final String level;
}
