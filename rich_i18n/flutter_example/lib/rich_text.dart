import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rich_i18n/rich_i18n.dart';

class RichI18nText extends StatefulWidget {
  const RichI18nText(this.text, {super.key});

  final String text;

  @override
  State<RichI18nText> createState() => _RichI18nTextState();
}

class _RichI18nTextState extends State<RichI18nText> {
  late List<RichTextItem> _parsedItems;

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void didUpdateWidget(covariant RichI18nText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _parseText();
    }
  }

  void _parseText() {
    final items = tryGetRichTextSync(widget.text);
    setState(() {
      _parsedItems = items ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_parsedItems.isEmpty && widget.text.isNotEmpty) {
      return Text(widget.text);
    }

    return Text.rich(
      TextSpan(children: _parsedItems.map(_createSpan).toList()),
    );
  }

  InlineSpan _createSpan(RichTextItem item) {
    TextDecoration? decoration;
    if (item.textDecoration == kUnderlineTextDecoration) {
      decoration = TextDecoration.underline;
    } else if (item.textDecoration == kLineThroughTextDecoration) {
      decoration = TextDecoration.lineThrough;
    }

    FontStyle? fontStyle;
    if (item.fontStyle == kItalicFontStyle) {
      fontStyle = FontStyle.italic;
    }

    FontWeight? fontWeight;
    if (item.fontWeight != null) {
      fontWeight = FontWeight.values.firstWhere(
        (weight) => weight.value == item.fontWeight!,
        orElse: () => FontWeight.normal,
      );
    }

    final color = _parseColor(item.color);
    final backgroundColor = _parseColor(item.backgroundColor);

    TapGestureRecognizer? recognizer;
    MouseCursor? mouseCursor;
    Color? finalColor = color;
    TextDecoration? finalDecoration = decoration;

    if (item.link != null) {
      mouseCursor = SystemMouseCursors.click;

      finalColor ??= Colors.blue;
      finalDecoration ??= TextDecoration.underline;

      recognizer = TapGestureRecognizer()
        ..onTap = () {
          _launchUrl(item.link!);
        };
    }

    return TextSpan(
      text: item.text,
      mouseCursor: mouseCursor,
      recognizer: recognizer,
      style: TextStyle(
        color: finalColor,
        backgroundColor: backgroundColor,
        fontWeight: fontWeight,
        fontSize: item.fontSize,
        fontFamily: item.fontFamily,
        decoration: finalDecoration,
        fontStyle: fontStyle,
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('You clicked: $urlString')));
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    if (colorString.startsWith('#')) {
      final buffer = StringBuffer();
      if (colorString.length == 7) {
        buffer.write('ff');
      }
      buffer.write(colorString.replaceFirst('#', ''));
      try {
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return null;
      }
    }

    const colors = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'orange': Colors.orange,
      'purple': Colors.purple,
    };

    return colors[colorString.toLowerCase()];
  }
}
