import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/nimo_clipboard_bar.dart';

/// Nimo v4.0 Ultra — Mega Knowledge Databases Hub:
/// Combines 4,300+ Built-In Offline Indexed Records (sub-5ms search) + Live GitHub Mega-Datasets RAG.
class GithubDbScreen extends ConsumerStatefulWidget {
  const GithubDbScreen({super.key});

  @override
  ConsumerState<GithubDbScreen> createState() => _GithubDbScreenState();
}

class _GithubDbScreenState extends ConsumerState<GithubDbScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  List<LocalDbRecord> _localHits = [];
  List<KnowledgeEntry> _githubHits = [];
  bool _isSyncingAll = false;

  static const Map<String, String> _catLabelsAr = {
    'coding': 'البرمجة',
    'code_bank': 'بنك الأكواد',
    'code_recipes': 'وصفات كود',
    'prompts': 'أوامر AI',
    'english': 'الإنجليزية',
    'dictionary': 'القاموس',
    'science': 'العلوم',
    'world': 'دول العالم',
    'mobile_dev': 'الموبايل',
    'backend_cloud': 'الخوادم',
    'business': 'الأعمال',
    'fitness': 'اللياقة',
    'cybersecurity': 'الأمن السيبراني',
    'ai': 'ذكاء 2026',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSearch('');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final q = query.trim();
    final local = ref
        .read(nimoLocalDbProvider.notifier)
        .search(q, category: _selectedCategory, limit: 20);
    final gh = q.isEmpty
        ? const <KnowledgeEntry>[]
        : ref.read(githubKnowledgeProvider.notifier).search(q, limit: 10);
    setState(() {
      _localHits = local;
      _githubHits = gh;
    });
  }

  Future<void> _syncAll() async {
    if (_isSyncingAll) return;
    NimoSoundFx.click();
    setState(() => _isSyncingAll = true);
    await ref.read(githubKnowledgeProvider.notifier).syncAllBuiltIn();
    if (mounted) setState(() => _isSyncingAll = false);
  }

  void _showAddCustomGithubDialog() {
    NimoSoundFx.click();
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إضافة قاعدة بيانات من GitHub' : 'Add Custom GitHub Dataset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم القاعدة' : 'Dataset Name',
                hintText: isAr ? 'مثال: بيانات طبية أو برمجية' : 'e.g., Medical or Code Dataset',
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'GitHub URL (.json / .csv / .md / .txt)',
                  hintText: 'https://github.com/user/repo/blob/main/data.json',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          FilledButton(
            onPressed: () async {
              NimoSoundFx.pop();
              final url = urlCtrl.text.trim();
              final title = titleCtrl.text.trim();
              Navigator.pop(ctx);
              if (url.isNotEmpty) {
                final ok = await ref
                    .read(githubKnowledgeProvider.notifier)
                    .addCustomSource(title: title, url: url);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (isAr ? 'تم ضم قاعدة البيانات بنجاح!' : 'Dataset added & synced!')
                            : (isAr ? 'تعذّر تحميل الرابط.' : 'Failed to sync URL.'),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isAr ? 'تحميل ودمج' : 'Import & Sync'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gh = ref.watch(githubKnowledgeProvider);
    final localDb = ref.watch(nimoLocalDbProvider);
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final totalAll = localDb.totalRecords + gh.totalEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'قواعد بيانات Nimo العملاقة' : 'Nimo Mega-Databases'),
        actions: [
          IconButton(
            tooltip: isAr ? 'إضافة رابط GitHub مخصص' : 'Add Custom GitHub URL',
            icon: const Icon(CupertinoIcons.add_circled_solid, size: 23),
            onPressed: _showAddCustomGithubDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Stats & RAG Hero Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IosIconBadge(
                        icon: CupertinoIcons.layers_alt_fill,
                        color: TalkoraColors.iosIndigo,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? '$totalAll سجل معرفي مفهرس وفوري'
                                  : '$totalAll Indexed Knowledge Records',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              isAr
                                  ? '${localDb.totalRecords} سجل محلي أوفلاين + ${gh.totalEntries} من GitHub'
                                  : '${localDb.totalRecords} built-in offline + ${gh.totalEntries} GitHub',
                              style: theme.textTheme.bodySmall?.copyWith(color: TalkoraColors.iosGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAr
                              ? 'دمج قواعد البيانات تلقائياً في عقل Nimo (RAG فائق السرعة)'
                              : 'Auto-inject Mega-DB into Nimo Brain (Ultra-Fast RAG)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      CupertinoSwitch(
                        value: gh.ragEnabled,
                        activeTrackColor: TalkoraColors.iosGreen,
                        onChanged: (v) {
                          NimoSoundFx.click();
                          ref.read(githubKnowledgeProvider.notifier).setRagEnabled(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSyncingAll ? null : _syncAll,
                          icon: _isSyncingAll
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CupertinoActivityIndicator(color: Colors.white),
                                )
                              : const Icon(CupertinoIcons.cloud_download_fill, size: 18),
                          label: Text(isAr ? 'مزامنة GitHub الإضافية' : 'Sync GitHub Packs'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: _showAddCustomGithubDialog,
                        icon: const Icon(CupertinoIcons.link, size: 18),
                        label: Text(isAr ? 'رابط مخصص' : 'Add URL'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Instant Sub-5ms Search Box with Paste Button
          TextField(
            controller: _searchCtrl,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'ابحث فورياً داخل $totalAll سجل (برمجة، إنجليزية، علوم، أوامر AI)...'
                  : 'Instant search across $totalAll records...',
              prefixIcon: const Icon(CupertinoIcons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isAr ? 'لصق' : 'Paste',
                    icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                    onPressed: () async {
                      final ok = await NimoClipboardHelper.pasteIntoController(
                        context,
                        _searchCtrl,
                        isAr: isAr,
                      );
                      if (ok) _runSearch(_searchCtrl.text);
                    },
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                      onPressed: () {
                        NimoSoundFx.click();
                        _searchCtrl.clear();
                        _runSearch('');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(isAr ? 'الكل (${localDb.totalRecords})' : 'All (${localDb.totalRecords})',
                        style: const TextStyle(fontSize: 12)),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      NimoSoundFx.click();
                      setState(() => _selectedCategory = null);
                      _runSearch(_searchCtrl.text);
                    },
                  ),
                ),
                ...localDb.categoryCounts.entries.map((e) {
                  final label = isAr ? (_catLabelsAr[e.key] ?? e.key) : e.key;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text('$label (${e.value})', style: const TextStyle(fontSize: 12)),
                      selected: _selectedCategory == e.key,
                      onSelected: (_) {
                        NimoSoundFx.click();
                        setState(() => _selectedCategory = e.key);
                        _runSearch(_searchCtrl.text);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Instant Results Preview
          Text(
            _searchCtrl.text.trim().isEmpty
                ? (isAr ? 'عينة من قاعدة Nimo المحلية (تعمل بدون إنترنت)' : 'Nimo Offline Database Preview')
                : (isAr
                    ? 'نتائج البحث الفوري (${_localHits.length + _githubHits.length})'
                    : 'Instant Results (${_localHits.length + _githubHits.length})'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._localHits.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rec.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.2),
                            ),
                          ),
                          NimoCopyChip(
                            textToCopy: '${rec.title}\n${rec.body}',
                            isAr: isAr,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(rec.body, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._githubHits.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(entry.title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.2)),
                  subtitle: Text(entry.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  trailing: NimoCopyChip(
                    textToCopy: '${entry.title}\n${entry.content}',
                    isAr: isAr,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),
          Text(
            isAr ? 'قواعد بيانات GitHub السحابية الإضافية' : 'Live GitHub Cloud Datasets',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...gh.sources.map((src) {
            final count = gh.entriesBySource[src.id]?.length ?? 0;
            final syncing = gh.syncingIds.contains(src.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const IosIconBadge(
                    icon: CupertinoIcons.cloud_fill,
                    color: TalkoraColors.iosBlue,
                    size: 36,
                  ),
                  title: Text(isAr ? src.titleAr : src.titleEn,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  subtitle: Text(
                    count > 0
                        ? (isAr ? '$count سجل متزامن • ${src.repoSlug}' : '$count synced • ${src.repoSlug}')
                        : (isAr ? src.descriptionAr : src.descriptionEn),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: syncing
                      ? const CupertinoActivityIndicator()
                      : FilledButton.tonal(
                          onPressed: () {
                            NimoSoundFx.click();
                            ref.read(githubKnowledgeProvider.notifier).syncSource(src.id);
                          },
                          child: Text(count > 0 ? (isAr ? 'تحديث' : 'Refresh') : (isAr ? 'تحميل' : 'Sync')),
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
