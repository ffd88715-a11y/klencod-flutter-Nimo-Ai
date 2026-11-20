import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/knowledge/github_knowledge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// LISORA AI v3.0 — Massive GitHub Open-Source Knowledge Databases & Local RAG Hub.
class GithubDbScreen extends ConsumerStatefulWidget {
  const GithubDbScreen({super.key});

  @override
  ConsumerState<GithubDbScreen> createState() => _GithubDbScreenState();
}

class _GithubDbScreenState extends ConsumerState<GithubDbScreen> {
  final _searchCtrl = TextEditingController();
  List<KnowledgeEntry> _searchResults = [];
  bool _isSyncingAll = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final hits = ref.read(githubKnowledgeProvider.notifier).search(query, limit: 25);
    setState(() => _searchResults = hits);
  }

  Future<void> _syncAll() async {
    if (_isSyncingAll) return;
    setState(() => _isSyncingAll = true);
    await ref.read(githubKnowledgeProvider.notifier).syncAllBuiltIn();
    if (mounted) setState(() => _isSyncingAll = false);
  }

  void _showAddCustomGithubDialog() {
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
                            : (isAr ? 'تعذّر تحميل الرابط — تأكد أنه ملف نصي/JSON/CSV صالح.' : 'Failed to sync URL.'),
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
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'قواعد بيانات GitHub العملاقة' : 'GitHub Mega-Datasets'),
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
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? '${gh.totalEntries} سجل معرفي مدمج محلياً'
                                  : '${gh.totalEntries} Indexed Knowledge Records',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              isAr
                                  ? '${gh.syncedSourcesCount} من ${gh.sources.length} قاعدة بيانات متزامنة'
                                  : '${gh.syncedSourcesCount} of ${gh.sources.length} GitHub repos synced',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAr
                              ? 'حقن بيانات GitHub تلقائياً في عقل الذكاء الاصطناعي (RAG)'
                              : 'Auto-inject GitHub Data into AI Brain (RAG)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      CupertinoSwitch(
                        value: gh.ragEnabled,
                        activeTrackColor: TalkoraColors.iosGreen,
                        onChanged: (v) => ref.read(githubKnowledgeProvider.notifier).setRagEnabled(v),
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
                          label: Text(isAr ? 'مزامنة كل القواعد الآن' : 'Sync All Datasets'),
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

          if (gh.lastError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TalkoraColors.iosRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(gh.lastError!, style: const TextStyle(color: TalkoraColors.iosRed, fontSize: 12.5)),
            ),
          ],

          const SizedBox(height: 16),

          // Live Search Across Synced GitHub Data
          TextField(
            controller: _searchCtrl,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'ابحث داخل قواعد بيانات GitHub المدمجة...'
                  : 'Search inside synced GitHub datasets...',
              prefixIcon: const Icon(CupertinoIcons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _runSearch('');
                      },
                    )
                  : null,
            ),
          ),

          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isAr ? 'نتائج البحث (${_searchResults.length})' : 'Search Results (${_searchResults.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._searchResults.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(entry.title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.5)),
                    subtitle: Text(
                      entry.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${entry.title}\n${entry.content}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'تم نسخ السجل' : 'Copied record')),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text(
            isAr ? 'مستودعات قواعد البيانات المتاحة على GitHub' : 'Available GitHub Knowledge Repositories',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 10),

          ...gh.sources.map((src) {
            final count = gh.entriesBySource[src.id]?.length ?? 0;
            final isSyncing = gh.syncingIds.contains(src.id);
            final synced = count > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IosIconBadge(
                            icon: CupertinoIcons.cube_box_fill,
                            color: synced ? TalkoraColors.iosGreen : TalkoraColors.iosBlue,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? src.titleAr : src.titleEn,
                                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                                ),
                                Text(
                                  '${src.repoSlug} • ${src.format.toUpperCase()}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (src.isCustom)
                            IconButton(
                              icon: const Icon(CupertinoIcons.trash, color: TalkoraColors.iosRed, size: 19),
                              onPressed: () =>
                                  ref.read(githubKnowledgeProvider.notifier).removeCustomSource(src.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? src.descriptionAr : src.descriptionEn,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IosStatusPill(
                            label: synced
                                ? (isAr ? 'مدمج: $count سجل' : 'Synced: $count records')
                                : (isAr ? 'غير متزامن بعد' : 'Not synced yet'),
                            color: synced ? TalkoraColors.iosGreen : TalkoraColors.iosOrange,
                          ),
                          FilledButton.tonalIcon(
                            onPressed: isSyncing
                                ? null
                                : () => ref.read(githubKnowledgeProvider.notifier).syncSource(src.id),
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CupertinoActivityIndicator(),
                                  )
                                : Icon(
                                    synced ? CupertinoIcons.refresh : CupertinoIcons.cloud_download,
                                    size: 16,
                                  ),
                            label: Text(synced ? (isAr ? 'تحديث' : 'Refresh') : (isAr ? 'تحميل ودمج' : 'Sync Now')),
                          ),
                        ],
                      ),
                    ],
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
