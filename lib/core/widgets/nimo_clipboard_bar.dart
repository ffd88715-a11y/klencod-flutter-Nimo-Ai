import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';

/// Enhanced Copy & Paste utility with tactile pop sound, smart cursor insertion, and clean feedback.
class NimoClipboardHelper {
  const NimoClipboardHelper._();

  static Future<void> copyText(
    BuildContext context,
    String text, {
    required bool isAr,
    String? customLabel,
  }) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    NimoSoundFx.pop();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, color: TalkoraColors.iosGreen, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                customLabel ?? (isAr ? 'تم النسخ بنجاح' : 'Copied to clipboard'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pastes clipboard text cleanly at the current cursor position (or replaces selection).
  static Future<bool> pasteIntoController(
    BuildContext context,
    TextEditingController controller, {
    required bool isAr,
    bool replaceAll = false,
  }) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final clip = data?.text ?? '';
    if (clip.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1200),
            content: Text(isAr ? 'الحافظة فارغة حالياً' : 'Clipboard is empty'),
          ),
        );
      }
      return false;
    }

    NimoSoundFx.pop();
    if (replaceAll || !controller.selection.isValid) {
      final combined = replaceAll ? clip : '${controller.text}$clip';
      controller.value = TextEditingValue(
        text: combined,
        selection: TextSelection.collapsed(offset: combined.length),
      );
    } else {
      final sel = controller.selection;
      final before = controller.text.substring(0, sel.start);
      final after = controller.text.substring(sel.end);
      final next = '$before$clip$after';
      controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: before.length + clip.length),
      );
    }
    return true;
  }
}

/// Animated one-tap Copy Button that morphs into a green checkmark for 1.6s.
class NimoCopyChip extends StatefulWidget {
  final String textToCopy;
  final bool isAr;
  final String? label;
  final bool compact;

  const NimoCopyChip({
    super.key,
    required this.textToCopy,
    required this.isAr,
    this.label,
    this.compact = false,
  });

  @override
  State<NimoCopyChip> createState() => _NimoCopyChipState();
}

class _NimoCopyChipState extends State<NimoCopyChip> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await NimoClipboardHelper.copyText(
      context,
      widget.textToCopy,
      isAr: widget.isAr,
    );
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _copied ? TalkoraColors.iosGreen : Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _handleCopy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 10, vertical: widget.compact ? 4 : 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_clipboard,
              size: widget.compact ? 13.5 : 15,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              _copied
                  ? (widget.isAr ? 'تم النسخ' : 'Copied')
                  : (widget.label ?? (widget.isAr ? 'نسخ' : 'Copy')),
              style: TextStyle(
                fontSize: widget.compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
