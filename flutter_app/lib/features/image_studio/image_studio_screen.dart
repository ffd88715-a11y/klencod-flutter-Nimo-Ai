import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/ai/image_gen_service.dart';
import 'package:talkora_ai/core/device/native_bridge_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';

/// LISORA AI v3.0 — AI Image Generation Studio (Free Pollinations Flux + DALL-E 3 + HF FLUX).
class ImageStudioScreen extends ConsumerStatefulWidget {
  const ImageStudioScreen({super.key});

  @override
  ConsumerState<ImageStudioScreen> createState() => _ImageStudioScreenState();
}

class _ImageStudioScreenState extends ConsumerState<ImageStudioScreen> {
  final _promptCtrl = TextEditingController();
  String _selectedStyle = 'realistic';
  String _selectedEngine = 'pollinations_flux';
  String _selectedAspect = '1:1';
  bool _isGenerating = false;
  bool _isEnhancing = false;
  Uint8List? _currentBytes;
  GeneratedImageItem? _currentItem;
  String? _errorText;
  List<GeneratedImageItem> _history = [];

  static const Map<String, String> _styleLabelsAr = {
    'realistic': 'واقعي 8K',
    'cinematic': 'سينمائي',
    'anime': 'أنمي',
    '3d': 'ثلاثي الأبعاد',
    'logo': 'شعار Logo',
    'cyberpunk': 'سايبر بانك',
    'digital_art': 'فن رقمي',
  };

  static const Map<String, String> _styleLabelsEn = {
    'realistic': 'Realistic 8K',
    'cinematic': 'Cinematic',
    'anime': 'Anime',
    '3d': '3D Render',
    'logo': 'Logo',
    'cyberpunk': 'Cyberpunk',
    'digital_art': 'Digital Art',
  };

  static const Map<String, String> _engineLabels = {
    'pollinations_flux': 'Flux AI (مجاني)',
    'pollinations_turbo': 'Turbo Fast (مجاني)',
    'openai_dalle3': 'OpenAI DALL-E 3',
    'hf_flux': 'HuggingFace FLUX',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await ref.read(imageGenServiceProvider).loadHistory();
    if (mounted) setState(() => _history = items);
  }

  (int, int) _resolveDimensions() {
    switch (_selectedAspect) {
      case '16:9':
        return (1280, 720);
      case '9:16':
        return (720, 1280);
      case '4:3':
        return (1024, 768);
      default:
        return (1024, 1024);
    }
  }

  Future<void> _enhancePromptWithAi() async {
    final raw = _promptCtrl.text.trim();
    if (raw.isEmpty || _isEnhancing) return;
    setState(() => _isEnhancing = true);

    final ai = ref.read(aiSettingsProvider);
    final service = ref.read(universalAiServiceProvider);
    final res = await service.sendChat(
      settings: ai,
      systemPromptOverride:
          'You are an expert AI image prompt engineer. Convert the user idea (even if Arabic) into ONE vivid, detailed English image generation prompt (max 45 words). Return ONLY the prompt text with no quotes or explanations.',
      messages: [
        AiChatMessage(role: 'user', content: raw, timestamp: DateTime.now()),
      ],
    );
    if (!mounted) return;
    setState(() {
      _isEnhancing = false;
      if (res.success && res.text.trim().isNotEmpty) {
        _promptCtrl.text = res.text.trim();
      }
    });
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorText = null;
    });

    final dims = _resolveDimensions();
    final aiSettings = ref.read(aiSettingsProvider);
    final result = await ref.read(imageGenServiceProvider).generateImage(
          prompt: prompt,
          styleKey: _selectedStyle,
          engine: _selectedEngine,
          width: dims.$1,
          height: dims.$2,
          aiSettings: aiSettings,
        );

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      if (result.success) {
        _currentBytes = result.bytes;
        _currentItem = result.item;
        ref.read(learnerProfileProvider.notifier).addXp(15);
      } else {
        _errorText = result.error;
      }
    });
    await _loadHistory();
  }

  Future<void> _saveToGallery() async {
    if (_currentBytes == null) return;
    final isAr = ref.read(learnerProfileProvider).uiLocale == 'ar';
    final ok = await ref.read(nativeBridgeProvider).saveImageToGallery(
          _currentBytes!,
          'lisora_ai_${DateTime.now().millisecondsSinceEpoch}.png',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isAr ? 'تم حفظ الصورة في المعرض (Pictures/LisoraAI)!' : 'Saved to Gallery (Pictures/LisoraAI)!')
              : (isAr ? 'تعذّر الحفظ — تأكد من الصلاحيات.' : 'Failed to save image.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(learnerProfileProvider).uiLocale == 'ar';
    final theme = Theme.of(context);
    final styleMap = isAr ? _styleLabelsAr : _styleLabelsEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'استوديو توليد الصور AI' : 'AI Image Studio'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: isAr ? 'مسح السجل' : 'Clear History',
              icon: const Icon(CupertinoIcons.trash, size: 20),
              onPressed: () async {
                await ref.read(imageGenServiceProvider).clearHistory();
                await _loadHistory();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Prompt Composer Card
          IosGroupedSection(
            header: isAr ? 'وصف الصورة (عربي أو إنجليزي)' : 'IMAGE PROMPT',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _promptCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'مثال: رائد فضاء يمشي في شوارع القاهرة القديمة وقت الغروب...'
                            : 'Describe the image you want to create...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isEnhancing ? null : _enhancePromptWithAi,
                            icon: _isEnhancing
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CupertinoActivityIndicator(),
                                  )
                                : const Icon(CupertinoIcons.wand_stars, size: 17),
                            label: Text(
                              isAr ? 'تحسين الوصف بالذكاء' : 'AI Enhance Prompt',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isGenerating ? null : _generate,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CupertinoActivityIndicator(color: Colors.white),
                                  )
                                : const Icon(CupertinoIcons.sparkles, size: 18),
                            label: Text(isAr ? 'توليد الصورة' : 'Generate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Engine & Aspect Ratio Selector
          IosGroupedSection(
            header: isAr ? 'محرك التوليد والأبعاد' : 'ENGINE & ASPECT RATIO',
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _engineLabels.entries.map((e) {
                        final selected = _selectedEngine == e.key;
                        return ChoiceChip(
                          label: Text(e.value, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedEngine = e.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['1:1', '16:9', '9:16', '4:3'].map((ratio) {
                        return ChoiceChip(
                          label: Text(ratio, style: const TextStyle(fontSize: 12)),
                          selected: _selectedAspect == ratio,
                          onSelected: (_) => setState(() => _selectedAspect = ratio),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Style Presets
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
            child: Text(
              isAr ? 'النمط الفني' : 'ART STYLE',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styleMap.entries.map((e) {
              return ChoiceChip(
                label: Text(e.value, style: const TextStyle(fontSize: 12.5)),
                selected: _selectedStyle == e.key,
                onSelected: (_) => setState(() => _selectedStyle = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Error Feedback
          if (_errorText != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: TalkoraColors.iosRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_errorText!, style: const TextStyle(color: TalkoraColors.iosRed)),
            ),

          // Generated Image Preview Card
          if (_isGenerating)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(radius: 16),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'جاري رسم صورتك بالذكاء الاصطناعي...' : 'Generating your masterpiece...',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else if (_currentBytes != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.memory(_currentBytes!, width: double.infinity, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentItem != null)
                          IosStatusPill(
                            label: _currentItem!.engine,
                            color: TalkoraColors.iosGreen,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saveToGallery,
                                icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                                label: Text(isAr ? 'حفظ في المعرض' : 'Save to Gallery'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () {
                                if (_currentItem?.imageUrl.isNotEmpty ?? false) {
                                  ref.read(nativeBridgeProvider).shareText(
                                        '${_currentItem!.prompt}\n${_currentItem!.imageUrl}',
                                        subject: 'LISORA AI Image',
                                      );
                                }
                              },
                              icon: const Icon(CupertinoIcons.share),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Recent Generations Gallery
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              isAr ? 'المعرض السابق (${_history.length})' : 'Recent Gallery (${_history.length})',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemCount: _history.length,
              itemBuilder: (context, idx) {
                final item = _history[idx];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(CupertinoIcons.photo, size: 32),
                                ),
                              )
                            : const Center(child: Icon(CupertinoIcons.photo, size: 32)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item.prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
