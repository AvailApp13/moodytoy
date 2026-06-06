import 'package:flutter/material.dart';
import '../../core/services/translation_service.dart';

/// Drop-in замена для Text() с динамическим переводом.
///
/// Использование:
///   Было:   Text(user.bio ?? '')
///   Стало:  TranslatedText(user.bio)
///
///   Было:   Text(user.bio!, style: myStyle)
///   Стало:  TranslatedText(user.bio, style: myStyle)
class TranslatedText extends StatefulWidget {
  final String? text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallback; // если text == null

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallback,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _displayed;

  @override
  void initState() {
    super.initState();
    // 1. Сразу показываем кэшированный перевод или оригинал
    _displayed = TranslationService.translateSync(widget.text)
        .nullIfEmpty ?? widget.fallback;
    // 2. Запускаем async перевод (обновит UI если перевод пришёл)
    _translate();
  }

  @override
  void didUpdateWidget(TranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _displayed = TranslationService.translateSync(widget.text)
          .nullIfEmpty ?? widget.fallback;
      _translate();
    }
  }

  Future<void> _translate() async {
    final result = await TranslationService.translate(widget.text);
    if (mounted && result != null && result != _displayed) {
      setState(() => _displayed = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed ?? widget.fallback ?? '',
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
