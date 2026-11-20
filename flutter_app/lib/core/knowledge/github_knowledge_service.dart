import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a curated or custom GitHub open-source knowledge dataset.
class GithubDatasetSource {
  final String id;
  final String titleAr;
  final String titleEn;
  final String category;
  final String repoSlug;
  final String rawUrl;
  final String format; // 'csv' | 'json' | 'md' | 'txt'
  final String descriptionAr;
  final String descriptionEn;
  final bool isCustom;

  const GithubDatasetSource({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.repoSlug,
    required this.rawUrl,
    required this.format,
    required this.descriptionAr,
    required this.descriptionEn,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleAr': titleAr,
        'titleEn': titleEn,
        'category': category,
        'repoSlug': repoSlug,
        'rawUrl': rawUrl,
        'format': format,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'isCustom': isCustom,
      };

  factory GithubDatasetSource.fromJson(Map<String, dynamic> json) {
    return GithubDatasetSource(
      id: (json['id'] ?? '').toString(),
      titleAr: (json['titleAr'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      category: (json['category'] ?? 'Custom').toString(),
      repoSlug: (json['repoSlug'] ?? 'github').toString(),
      rawUrl: (json['rawUrl'] ?? '').toString(),
      format: (json['format'] ?? 'txt').toString(),
      descriptionAr: (json['descriptionAr'] ?? '').toString(),
      descriptionEn: (json['descriptionEn'] ?? '').toString(),
      isCustom: json['isCustom'] == true,
    );
  }
}

/// A single indexed knowledge chunk pulled from GitHub and stored locally.
class KnowledgeEntry {
  final String sourceId;
  final String sourceTitle;
  final String title;
  final String content;

  const KnowledgeEntry({
    required this.sourceId,
    required this.sourceTitle,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        's': sourceId,
        'st': sourceTitle,
        't': title,
        'c': content,
      };

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntry(
      sourceId: (json['s'] ?? '').toString(),
      sourceTitle: (json['st'] ?? '').toString(),
      title: (json['t'] ?? '').toString(),
      content: (json['c'] ?? '').toString(),
    );
  }
}

class GithubKnowledgeState {
  final List<GithubDatasetSource> sources;
  final Map<String, List<KnowledgeEntry>> entriesBySource;
  final Map<String, DateTime> lastSyncedBySource;
  final Set<String> syncingIds;
  final bool ragEnabled;
  final String? lastError;

  const GithubKnowledgeState({
    this.sources = const [],
    this.entriesBySource = const {},
    this.lastSyncedBySource = const {},
    this.syncingIds = const {},
    this.ragEnabled = true,
    this.lastError,
  });

  int get totalEntries =>
      entriesBySource.values.fold<int>(0, (sum, list) => sum + list.length);

  int get syncedSourcesCount =>
      entriesBySource.values.where((list) => list.isNotEmpty).length;

  GithubKnowledgeState copyWith({
    List<GithubDatasetSource>? sources,
    Map<String, List<KnowledgeEntry>>? entriesBySource,
    Map<String, DateTime>? lastSyncedBySource,
    Set<String>? syncingIds,
    bool? ragEnabled,
    String? lastError,
    bool clearError = false,
  }) {
    return GithubKnowledgeState(
      sources: sources ?? this.sources,
      entriesBySource: entriesBySource ?? this.entriesBySource,
      lastSyncedBySource: lastSyncedBySource ?? this.lastSyncedBySource,
      syncingIds: syncingIds ?? this.syncingIds,
      ragEnabled: ragEnabled ?? this.ragEnabled,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Massive GitHub Open-Source Knowledge Engine & Local RAG Retriever.
class GithubKnowledgeNotifier extends StateNotifier<GithubKnowledgeState> {
  static const _kEntriesPrefix = 'lisora_gh_entries_v3_';
  static const _kMetaKey = 'lisora_gh_meta_v3';
  static const _kCustomSourcesKey = 'lisora_gh_custom_sources_v3';
  static const _kRagEnabledKey = 'lisora_gh_rag_enabled_v3';

  static const List<GithubDatasetSource> builtInSources = [
    GithubDatasetSource(
      id: 'awesome_prompts',
      titleAr: 'موسوعة أوامر الذكاء الاصطناعي (Prompts)',
      titleEn: 'Awesome ChatGPT Prompts (170+ Personas)',
      category: 'AI & Prompts',
      repoSlug: 'f/awesome-chatgpt-prompts',
      rawUrl: 'https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv',
      format: 'csv',
      descriptionAr: 'مئات الشخصيات والأوامر الاحترافية الجاهزة للبرمجة والطب والتسويق والتعليم.',
      descriptionEn: 'Curated library of 170+ expert AI system prompts and specialist roles.',
    ),
    GithubDatasetSource(
      id: 'arabic_prog_books',
      titleAr: 'موسوعة كتب ومصادر البرمجة العربية',
      titleEn: 'Arabic Free Programming Books Corpus',
      category: 'Arabic Tech',
      repoSlug: 'EbookFoundation/free-programming-books',
      rawUrl:
          'https://raw.githubusercontent.com/EbookFoundation/free-programming-books/main/books/free-programming-books-ar.md',
      format: 'md',
      descriptionAr: 'قاعدة بيانات ضخمة باللغة العربية لكتب ومصادر لغات البرمجة وهندسة البرمجيات.',
      descriptionEn: 'Massive Arabic programming books and engineering reference index.',
    ),
    GithubDatasetSource(
      id: 'world_countries',
      titleAr: 'قاعدة بيانات دول العالم (عربي وإنجليزي)',
      titleEn: 'World Countries Encyclopedia (250+ Nations)',
      category: 'World Data',
      repoSlug: 'mledoze/countries',
      rawUrl: 'https://raw.githubusercontent.com/mledoze/countries/master/countries.json',
      format: 'json',
      descriptionAr: 'بيانات شاملة لـ 250 دولة: العواصم، اللغات، العملات، المناطق، والأسماء العربية.',
      descriptionEn: 'Complete structured dataset of 250+ countries, capitals, currencies & Arabic names.',
    ),
    GithubDatasetSource(
      id: 'public_apis',
      titleAr: 'دليل الـ APIs العالمية للمطورين (+1400)',
      titleEn: 'Public APIs Mega Directory (1400+ APIs)',
      category: 'Developers',
      repoSlug: 'public-apis/public-apis',
      rawUrl: 'https://raw.githubusercontent.com/public-apis/public-apis/master/README.md',
      format: 'md',
      descriptionAr: 'أكبر فهرس على GitHub للواجهات البرمجية المجانية في كل المجالات.',
      descriptionEn: 'Largest GitHub directory of free public APIs across all categories.',
    ),
    GithubDatasetSource(
      id: 'quotes_mega',
      titleAr: 'موسوعة الاقتباسات والحكم العالمية (+5000)',
      titleEn: 'Mega Quotes & Wisdom Database (5000+)',
      category: 'Literature',
      repoSlug: 'JamesFT/Database-Quotes-JSON',
      rawUrl: 'https://raw.githubusercontent.com/JamesFT/Database-Quotes-JSON/master/quotes.json',
      format: 'json',
      descriptionAr: 'آلاف الاقتباسات العالمية والمؤلفين للاستشهاد والكتابة الإبداعية.',
      descriptionEn: 'Thousands of famous quotes and authors for writing & inspiration.',
    ),
    GithubDatasetSource(
      id: 'english_10k',
      titleAr: 'معجم أهم 10,000 كلمة إنجليزية شائعة',
      titleEn: 'Google 10,000 Most Common English Words',
      category: 'English',
      repoSlug: 'first20hours/google-10000-english',
      rawUrl:
          'https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa.txt',
      format: 'txt',
      descriptionAr: 'أهم المفردات الإنجليزية الأكثر استخداماً لتقوية اللغة والترجمة.',
      descriptionEn: 'Top 10,000 most frequently used English words corpus.',
    ),
    GithubDatasetSource(
      id: 'awesome_master',
      titleAr: 'الفهرس العملاق لمشاريع GitHub (Awesome)',
      titleEn: 'Sindre Sorhus Awesome Master Index',
      category: 'Knowledge',
      repoSlug: 'sindresorhus/awesome',
      rawUrl: 'https://raw.githubusercontent.com/sindresorhus/awesome/main/readme.md',
      format: 'md',
      descriptionAr: 'الفهرس الرئيسي لأهم قوائم المعرفة والتقنية والذكاء الاصطناعي على GitHub.',
      descriptionEn: 'Master index of awesome lists covering AI, CS, science, and tools.',
    ),
  ];

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 40),
      responseType: ResponseType.plain,
    ),
  );

  GithubKnowledgeNotifier() : super(const GithubKnowledgeState(sources: builtInSources)) {
    _loadCached();
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ragEnabled = prefs.getBool(_kRagEnabledKey) ?? true;

      // Load custom sources
      final customRaw = prefs.getString(_kCustomSourcesKey);
      final allSources = List<GithubDatasetSource>.from(builtInSources);
      if (customRaw != null && customRaw.isNotEmpty) {
        final decoded = jsonDecode(customRaw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            allSources.add(GithubDatasetSource.fromJson(item));
          }
        }
      }

      // Load timestamps
      final metaRaw = prefs.getString(_kMetaKey);
      final Map<String, DateTime> timestamps = {};
      if (metaRaw != null && metaRaw.isNotEmpty) {
        final metaMap = jsonDecode(metaRaw) as Map<String, dynamic>;
        metaMap.forEach((k, v) {
          final dt = DateTime.tryParse(v.toString());
          if (dt != null) timestamps[k] = dt;
        });
      }

      // Load entries per source
      final Map<String, List<KnowledgeEntry>> entriesMap = {};
      for (final src in allSources) {
        final raw = prefs.getString('$_kEntriesPrefix${src.id}');
        if (raw != null && raw.isNotEmpty) {
          final list = jsonDecode(raw) as List<dynamic>;
          entriesMap[src.id] = list
              .whereType<Map<String, dynamic>>()
              .map(KnowledgeEntry.fromJson)
              .toList();
        }
      }

      state = state.copyWith(
        sources: allSources,
        entriesBySource: entriesMap,
        lastSyncedBySource: timestamps,
        ragEnabled: ragEnabled,
      );
    } catch (_) {}
  }

  Future<void> setRagEnabled(bool enabled) async {
    state = state.copyWith(ragEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRagEnabledKey, enabled);
    } catch (_) {}
  }

  /// Auto-converts standard GitHub blob links into raw.githubusercontent.com URLs.
  static String normalizeGithubUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.contains('github.com/') && trimmed.contains('/blob/')) {
      return trimmed
          .replaceFirst('https://github.com/', 'https://raw.githubusercontent.com/')
          .replaceFirst('/blob/', '/');
    }
    return trimmed;
  }

  /// Adds a user-supplied GitHub dataset URL and immediately syncs it.
  Future<bool> addCustomSource({
    required String title,
    required String url,
  }) async {
    final rawUrl = normalizeGithubUrl(url);
    if (!rawUrl.startsWith('http')) return false;

    String format = 'txt';
    final lower = rawUrl.toLowerCase();
    if (lower.endsWith('.json')) {
      format = 'json';
    } else if (lower.endsWith('.csv')) {
      format = 'csv';
    } else if (lower.endsWith('.md')) {
      format = 'md';
    }

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final src = GithubDatasetSource(
      id: id,
      titleAr: title.trim().isEmpty ? 'قاعدة بيانات GitHub مخصصة' : title.trim(),
      titleEn: title.trim().isEmpty ? 'Custom GitHub Dataset' : title.trim(),
      category: 'Custom GitHub',
      repoSlug: Uri.tryParse(rawUrl)?.host ?? 'github',
      rawUrl: rawUrl,
      format: format,
      descriptionAr: rawUrl,
      descriptionEn: rawUrl,
      isCustom: true,
    );

    final updatedSources = [...state.sources, src];
    state = state.copyWith(sources: updatedSources);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customs = updatedSources.where((s) => s.isCustom).map((s) => s.toJson()).toList();
      await prefs.setString(_kCustomSourcesKey, jsonEncode(customs));
    } catch (_) {}

    return syncSource(src.id);
  }

  Future<void> removeCustomSource(String sourceId) async {
    final updatedSources = state.sources.where((s) => s.id != sourceId).toList();
    final updatedEntries = Map<String, List<KnowledgeEntry>>.from(state.entriesBySource)..remove(sourceId);
    final updatedDates = Map<String, DateTime>.from(state.lastSyncedBySource)..remove(sourceId);

    state = state.copyWith(
      sources: updatedSources,
      entriesBySource: updatedEntries,
      lastSyncedBySource: updatedDates,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_kEntriesPrefix$sourceId');
      final customs = updatedSources.where((s) => s.isCustom).map((s) => s.toJson()).toList();
      await prefs.setString(_kCustomSourcesKey, jsonEncode(customs));
    } catch (_) {}
  }

  /// Downloads, parses, and locally caches a GitHub dataset.
  Future<bool> syncSource(String sourceId) async {
    final src = state.sources.firstWhere(
      (s) => s.id == sourceId,
      orElse: () => builtInSources.first,
    );

    final nextSyncing = Set<String>.from(state.syncingIds)..add(sourceId);
    state = state.copyWith(syncingIds: nextSyncing, clearError: true);

    try {
      final res = await _dio.get<String>(src.rawUrl);
      final rawText = res.data ?? '';
      if (rawText.trim().isEmpty) {
        throw Exception('Empty response from GitHub.');
      }

      final parsed = _parseRawDataset(src, rawText);
      final capped = parsed.length > 600 ? parsed.sublist(0, 600) : parsed;

      final updatedEntries = Map<String, List<KnowledgeEntry>>.from(state.entriesBySource);
      updatedEntries[sourceId] = capped;

      final updatedDates = Map<String, DateTime>.from(state.lastSyncedBySource);
      updatedDates[sourceId] = DateTime.now();

      final doneSyncing = Set<String>.from(state.syncingIds)..remove(sourceId);
      state = state.copyWith(
        entriesBySource: updatedEntries,
        lastSyncedBySource: updatedDates,
        syncingIds: doneSyncing,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_kEntriesPrefix$sourceId',
        jsonEncode(capped.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        _kMetaKey,
        jsonEncode(updatedDates.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );
      return true;
    } catch (e) {
      final doneSyncing = Set<String>.from(state.syncingIds)..remove(sourceId);
      state = state.copyWith(
        syncingIds: doneSyncing,
        lastError: 'فشل مزامنة ${src.repoSlug}: $e',
      );
      return false;
    }
  }

  Future<void> syncAllBuiltIn() async {
    for (final src in state.sources) {
      await syncSource(src.id);
    }
  }

  List<KnowledgeEntry> _parseRawDataset(GithubDatasetSource src, String raw) {
    final entries = <KnowledgeEntry>[];
    if (src.format == 'csv') {
      final lines = const LineSplitter().convert(raw);
      for (int i = 1; i < lines.length && entries.length < 400; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length >= 2) {
          final title = parts[0].replaceAll('"', '').trim();
          final content = parts[1].replaceAll('"', '').trim();
          if (title.isNotEmpty && content.isNotEmpty) {
            entries.add(KnowledgeEntry(
              sourceId: src.id,
              sourceTitle: src.titleEn,
              title: title,
              content: content.length > 420 ? '${content.substring(0, 420)}...' : content,
            ));
          }
        }
      }
    } else if (src.format == 'json') {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (entries.length >= 450) break;
          if (item is Map) {
            if (src.id == 'world_countries') {
              final nameMap = item['name'];
              final common = (nameMap is Map ? nameMap['common'] : item['name'])?.toString() ?? '';
              final translations = item['translations'];
              final ara = (translations is Map && translations['ara'] is Map)
                  ? (translations['ara']['common'] ?? '').toString()
                  : '';
              final capitalList = item['capital'];
              final capital = (capitalList is List && capitalList.isNotEmpty)
                  ? capitalList.first.toString()
                  : '';
              final region = (item['region'] ?? '').toString();
              final subregion = (item['subregion'] ?? '').toString();
              if (common.isNotEmpty) {
                entries.add(KnowledgeEntry(
                  sourceId: src.id,
                  sourceTitle: src.titleAr,
                  title: ara.isNotEmpty ? '$common ($ara)' : common,
                  content: 'Capital: $capital | Region: $region ($subregion)',
                ));
              }
            } else if (item['quoteText'] != null) {
              final q = item['quoteText'].toString().trim();
              final a = (item['quoteAuthor'] ?? 'Unknown').toString().trim();
              if (q.isNotEmpty) {
                entries.add(KnowledgeEntry(
                  sourceId: src.id,
                  sourceTitle: src.titleEn,
                  title: a.isEmpty ? 'Quote' : a,
                  content: q,
                ));
              }
            } else {
              final title = (item['title'] ?? item['name'] ?? item['act'] ?? item['key'] ?? 'Record').toString();
              final body = (item['description'] ?? item['content'] ?? item['prompt'] ?? item['text'] ?? jsonEncode(item)).toString();
              entries.add(KnowledgeEntry(
                sourceId: src.id,
                sourceTitle: src.titleEn,
                title: title.length > 100 ? title.substring(0, 100) : title,
                content: body.length > 360 ? '${body.substring(0, 360)}...' : body,
              ));
            }
          }
        }
      }
    } else if (src.format == 'md') {
      final lines = const LineSplitter().convert(raw);
      String currentHeading = src.titleEn;
      final linkRegex = RegExp(r"""\[([^\]]+)\]\((https?://[^)]+)\)""");
      for (final line in lines) {
        if (entries.length >= 450) break;
        final trimmed = line.trim();
        if (trimmed.startsWith('##')) {
          currentHeading = trimmed.replaceAll('#', '').trim();
        } else if (trimmed.startsWith('|') && trimmed.contains('http')) {
          final cols = trimmed.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
          if (cols.length >= 2) {
            final title = cols[0].replaceAll(RegExp(r"""[\[\]\(\)]"""), ' ').trim();
            final desc = cols[1];
            entries.add(KnowledgeEntry(
              sourceId: src.id,
              sourceTitle: src.titleEn,
              title: '$currentHeading: $title',
              content: desc.length > 260 ? '${desc.substring(0, 260)}...' : desc,
            ));
          }
        } else if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
          final m = linkRegex.firstMatch(trimmed);
          if (m != null) {
            final label = m.group(1) ?? '';
            final url = m.group(2) ?? '';
            entries.add(KnowledgeEntry(
              sourceId: src.id,
              sourceTitle: src.titleAr,
              title: '$currentHeading — $label',
              content: '${trimmed.replaceAll(RegExp(r"""^[\*\-]\s+"""), '')} ($url)',
            ));
          }
        }
      }
    } else {
      // Plain text (e.g. 10,000 English words grouped into compact chunks of 25 words)
      final lines = const LineSplitter().convert(raw).where((l) => l.trim().isNotEmpty).toList();
      const chunkSize = 25;
      for (int i = 0; i < lines.length && entries.length < 400; i += chunkSize) {
        final end = math.min(i + chunkSize, lines.length);
        final slice = lines.sublist(i, end);
        entries.add(KnowledgeEntry(
          sourceId: src.id,
          sourceTitle: src.titleEn,
          title: 'Batch ${entries.length + 1} (${slice.first}..${slice.last})',
          content: slice.join(', '),
        ));
      }
    }
    return entries;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  /// Fast local RAG search across all cached GitHub datasets.
  List<KnowledgeEntry> search(String query, {int limit = 6}) {
    final cleanQuery = _normalizeText(query);
    if (cleanQuery.isEmpty) return const [];
    final tokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toSet();
    if (tokens.isEmpty) return const [];

    final scored = <_ScoredEntry>[];
    for (final list in state.entriesBySource.values) {
      for (final entry in list) {
        final hayTitle = _normalizeText(entry.title);
        final hayContent = _normalizeText(entry.content);
        int score = 0;
        if (hayTitle.contains(cleanQuery)) score += 12;
        if (hayContent.contains(cleanQuery)) score += 8;
        for (final t in tokens) {
          if (hayTitle.contains(t)) score += 5;
          if (hayContent.contains(t)) score += 2;
        }
        if (score > 0) {
          scored.add(_ScoredEntry(entry, score));
        }
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((s) => s.entry).toList();
  }

  /// Builds a concise RAG context block to inject into the AI system prompt.
  String buildRagContext(String userQuery) {
    if (!state.ragEnabled || state.totalEntries == 0) return '';
    final hits = search(userQuery, limit: 4);
    if (hits.isEmpty) return '';

    final buf = StringBuffer();
    buf.writeln('\n[GITHUB KNOWLEDGE BASE CONTEXT — USE WHEN RELEVANT]:');
    for (final h in hits) {
      buf.writeln('- [${h.sourceTitle}] ${h.title}: ${h.content}');
    }
    return buf.toString();
  }

  static String _normalizeText(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }
}

class _ScoredEntry {
  final KnowledgeEntry entry;
  final int score;
  const _ScoredEntry(this.entry, this.score);
}

final githubKnowledgeProvider =
    StateNotifierProvider<GithubKnowledgeNotifier, GithubKnowledgeState>(
  (ref) => GithubKnowledgeNotifier(),
);
