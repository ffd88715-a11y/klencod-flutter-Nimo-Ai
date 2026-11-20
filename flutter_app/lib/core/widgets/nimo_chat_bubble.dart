import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/widgets/ios_components.dart';
import 'package:talkora_ai/core/widgets/nimo_clipboard_bar.dart';

class _MessagePart {
  final bool isCode;
  final String language;
  final String text;
  const _MessagePart({required this.isCode, this.language = '', required this.text});
}

/// Nimo v4.0 Ultra Chat Bubble — rich Markdown & code block cards, one-tap copy,
/// send-to-Coding-Lab shortcut, human voice playback, regenerate & share actions.
class NimoChatBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool isAr;
  final VoidCallback? onSpeak;
  final VoidCallback? onRegenerate;
  final VoidCallback? onShare;
  final void Function(String code, String language)? onOpenInCodingLab;

  const NimoChatBubble({
    super.key,
    required this.message,
    required this.isAr,
    this.onSpeak,
    this.onRegenerate,
    this.onShare,
    this.onOpenInCodingLab,
  });

  List<_MessagePart> _parseContent(String raw) {
    final parts = <_MessagePart>[];
    final regex = RegExp(r"""```([a-zA-Z0-9_+-]*)\n?([\s\S]*?)```""");
    int lastEnd = 0;
    for (final m in regex.allMatches(raw)) {
      if (m.start > lastEnd) {
        final before = raw.substring(lastEnd, m.start).trim();
        if (before.isNotEmpty) {
          parts.add(_MessagePart(isCode: false, text: before));
        }
      }
      final lang = (m.group(1) ?? '').trim();
      final code = (m.group(2) ?? '').trimRight();
      if (code.isNotEmpty) {
        parts.add(_MessagePart(isCode: true, language: lang.isEmpty ? 'code' : lang, text: code));
      }
      lastEnd = m.end;
    }
    if (lastEnd < raw.length) {
      final tail = raw.substring(lastEnd).trim();
      if (tail.isNotEmpty) {
        parts.add(_MessagePart(isCode: false, text: tail));
      }
    }
    if (parts.isEmpty) {
      parts.add(_MessagePart(isCode: false, text: raw));
    }
    return parts;
  }

  TextSpan _buildRichInline(String text, TextStyle baseStyle, Color accent) {
    final spans = <InlineSpan>[];
    final tokenRegex = RegExp(r"""(\*\*[^*]+\*\*|`[^`]+`)""");
    int cursor = 0;
    for (final m in tokenRegex.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
      }
      final tok = m.group(0)!;
      if (tok.startsWith('**') && tok.endsWith('**')) {
        spans.add(TextSpan(
          text: tok.substring(2, tok.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (tok.startsWith('`') && tok.endsWith('`')) {
        spans.add(TextSpan(
          text: ' ${tok.substring(1, tok.length - 1)} ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: (baseStyle.fontSize ?? 15) - 1.5,
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.14),
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return TextSpan(children: spans);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.role == 'user';
    final parts = _parseContent(message.content);

    final textColor = isUser
        ? Colors.white
        : (isDark ? TalkoraColors.darkText : TalkoraColors.lightMainText);
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: textColor,
      fontSize: 15.2,
      height: 1.5,
    );

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.84 : 0.92),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    Color.lerp(theme.colorScheme.primary, TalkoraColors.iosIndigo, 0.35)!,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E2028), const Color(0xFF171920)]
                      : [Colors.white, const Color(0xFFF7F8FC)],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.22)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : TalkoraColors.lightSeparator.withValues(alpha: 0.45)),
            width: 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip for assistant messages (Nimo badge + model + time)
            if (!isUser) ...[
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, TalkoraColors.iosIndigo],
                      ),
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Nimo',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (message.modelUsed != null) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.modelUsed!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? TalkoraColors.darkSecondaryText
                              : TalkoraColors.lightSecondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark
                          ? TalkoraColors.darkSecondaryText
                          : TalkoraColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (message.actionBadge != null) ...[
              IosStatusPill(
                label: message.actionBadge!,
                color: TalkoraColors.iosGreen,
                icon: CupertinoIcons.checkmark_seal_fill,
              ),
              const SizedBox(height: 8),
            ],

            // Parsed text & code block cards
            for (final part in parts)
              if (part.isCode)
                _CodeCardBlock(
                  code: part.text,
                  language: part.language,
                  isAr: isAr,
                  onOpenInCodingLab: onOpenInCodingLab == null
                      ? null
                      : () => onOpenInCodingLab!(part.text, part.language),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SelectableText.rich(
                    _buildRichInline(
                      part.text,
                      baseStyle,
                      isUser ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                ),

            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  message.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  },
                ),
              ),
            ],

            // Bottom action bar
            const SizedBox(height: 8),
            if (isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.78)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => NimoClipboardHelper.copyText(context, message.content, isAr: isAr),
                    child: Icon(
                      CupertinoIcons.doc_on_clipboard,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  NimoCopyChip(textToCopy: message.content, isAr: isAr, compact: true),
                  if (onSpeak != null)
                    _MiniActionBtn(
                      icon: CupertinoIcons.waveform,
                      label: isAr ? 'صوت طبيعي' : 'Speak',
                      color: TalkoraColors.iosTeal,
                      onTap: onSpeak!,
                    ),
                  if (onRegenerate != null)
                    _MiniActionBtn(
                      icon: CupertinoIcons.refresh,
                      label: isAr ? 'إعادة' : 'Retry',
                      color: TalkoraColors.iosIndigo,
                      onTap: onRegenerate!,
                    ),
                  if (onShare != null)
                    _MiniActionBtn(
                      icon: CupertinoIcons.share,
                      label: isAr ? 'مشاركة' : 'Share',
                      color: TalkoraColors.iosGreen,
                      onTap: onShare!,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        NimoSoundFx.click();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeCardBlock extends StatelessWidget {
  final String code;
  final String language;
  final bool isAr;
  final VoidCallback? onOpenInCodingLab;

  const _CodeCardBlock({
    required this.code,
    required this.language,
    required this.isAr,
    this.onOpenInCodingLab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: const Color(0xFF1A1D26),
            child: Row(
              children: [
                const Icon(CupertinoIcons.chevron_left_slash_chevron_right,
                    size: 14, color: TalkoraColors.iosTeal),
                const SizedBox(width: 6),
                Text(
                  language.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TalkoraColors.iosTeal,
                  ),
                ),
                const Spacer(),
                if (onOpenInCodingLab != null) ...[
                  InkWell(
                    onTap: () {
                      NimoSoundFx.click();
                      onOpenInCodingLab!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.hammer_fill, size: 12.5, color: TalkoraColors.iosOrange),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'مختبر البرمجة' : 'Code Lab',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TalkoraColors.iosOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                NimoCopyChip(
                  textToCopy: code,
                  isAr: isAr,
                  label: isAr ? 'نسخ الكود' : 'Copy Code',
                  compact: true,
                ),
              ],
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.8,
                  height: 1.5,
                  color: const Color(0xFFE6EDF3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
