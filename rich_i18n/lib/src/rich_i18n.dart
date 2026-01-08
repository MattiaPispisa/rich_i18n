import 'rich_text_item.dart';
import 'package:xml/xml.dart';

/// Parses a rich text string with XML tags
/// and returns a list of [RichTextItem].
///
/// {@template rich_i18n_supported_tags}
/// Supported XML tags (HTML-like):
/// - `<b>` or `<bold>`: Bold text
/// - `<u>` or `<underline>`: Underlined text
/// - `<s>` or `<strike>` or `<strikethrough>`: Strikethrough text
/// - `<a href="url">`: Hyperlink
/// - `<span>` with attributes:
///   - `color`: Text color (e.g., "#FF0000" or "red")
///   - `background-color`|`backgroundColor`: Background color
///   - `font-weight`|`fontWeight`: Font weight (e.g., "700")
///   - `font-size`|`fontSize`: Font size (e.g., "14")
///   - `font-family`|`fontFamily`: Font family name
///   - `text-decoration`|`textDecoration`:
/// Text decoration ([kUnderlineTextDecoration], [kLineThroughTextDecoration])
/// {@endtemplate}
///
/// {@template rich_i18n_examples}
/// Examples:
/// ```dart
/// // Simple bold text
/// tryGetRichTextSync('hello <b>dart</b>');
/// // Returns: [RichTextItem(text: 'hello '), RichTextItem(text: 'dart', bold: true)]
///
/// // Nested tags
/// tryGetRichTextSync('hello <b>dart and <u>flutter</u></b>');
/// // Returns: [
/// //   RichTextItem(text: 'hello '),
/// //   RichTextItem(text: 'dart and ', bold: true),
/// //   RichTextItem(text: 'flutter', bold: true, textDecoration: 'underline')
/// // ]
/// ```
/// {@endtemplate}
List<RichTextItem>? tryGetRichTextSync(String text) {
  if (text.isEmpty) {
    return [];
  }

  // Wrap the text in a root element to ensure valid XML
  final wrappedText = '<root>$text</root>';

  XmlDocument document;
  try {
    document = XmlDocument.parse(wrappedText);
  } catch (e) {
    // If parsing fails, return null
    return null;
  }

  final result = <RichTextItem>[];
  final initialStyle = RichTextItem(text: '');

  _parseNode(document.rootElement, initialStyle, result);

  return result;
}

/// Recursively parses an XML node and its children.
void _parseNode(
  XmlNode node,
  RichTextItem currentStyle,
  List<RichTextItem> result,
) {
  if (node is XmlText) {
    final text = node.value;
    if (text.isNotEmpty) {
      _addTextWithStyle(text, currentStyle, result);
    }
  } else if (node is XmlElement) {
    final newStyle = _getStyleForElement(node, currentStyle);

    for (final child in node.children) {
      _parseNode(child, newStyle, result);
    }
  }
  // Other node types (comments, CDATA, etc.) are ignored as they have no
  // children that need processing
}

const _colorAttributeName = 'color';

const _backgroundColorAttributeName = 'background-color';
const _backgroundColorCssAttributeName = 'backgroundColor';

const _fontWeightAttributeName = 'font-weight';
const _fontWeightCssAttributeName = 'fontWeight';

const _fontSizeAttributeName = 'font-size';
const _fontSizeCssAttributeName = 'fontSize';

const _fontFamilyAttributeName = 'font-family';
const _fontFamilyCssAttributeName = 'fontFamily';

const _textDecorationAttributeName = 'text-decoration';
const _textDecorationCssAttributeName = 'textDecoration';

const _hrefAttributeName = 'href';

const List<String> _spanAvailableAttributes = [
  _colorAttributeName,
  _backgroundColorAttributeName,
  _fontWeightAttributeName,
  _fontSizeAttributeName,
  _fontFamilyAttributeName,
  _textDecorationAttributeName,
  _hrefAttributeName,
];

const List<String> _aAvailableAttributes = [
  _hrefAttributeName,
];

const List<String> _tagAvailables = [
  'span',
  'a',
  'font',
  'i',
  'italic',
  'em',
  'b',
  'bold',
  'strong',
  'u',
  'underline',
  's',
  'strike',
  'strikethrough',
  'del',
];

/// Returns the updated style based on the XML element.
RichTextItem _getStyleForElement(
  XmlElement element,
  RichTextItem currentStyle,
) {
  final tagName = element.name.local.toLowerCase();

  switch (tagName) {
    case 'root':
      // Root element doesn't add any style
      return currentStyle;

    case 'b':
    case 'bold':
    case 'strong':
      return currentStyle.copyWith(fontWeight: kBoldFontWeight);

    case 'u':
    case 'underline':
      return currentStyle.copyWith(textDecoration: kUnderlineTextDecoration);

    case 's':
    case 'strike':
    case 'strikethrough':
    case 'del':
      return currentStyle.copyWith(textDecoration: kLineThroughTextDecoration);

    case 'a':
      final href = element.getAttribute(_hrefAttributeName);
      if (href != null) {
        return currentStyle.copyWith(link: href);
      }
      return currentStyle;

    case 'span':
    case 'font':
      return _parseSpanAttributes(element, currentStyle);

    case 'i':
    case 'italic':
    case 'em':
      // For italic, we can use font-style, but since we don't have that
      // property, we'll skip or you could add it later
      return currentStyle;

    default:
      // Unknown tags are treated as containers without style changes
      return currentStyle;
  }
}

/// Parses span/font element attributes and returns the updated style.
RichTextItem _parseSpanAttributes(
  XmlElement element,
  RichTextItem currentStyle,
) {
  var newStyle = currentStyle;

  // Parse color attribute
  final color = element.getAttribute(_colorAttributeName);
  if (color != null) {
    newStyle = newStyle.copyWith(color: color);
  }

  // Parse background-color attribute
  final backgroundColor = element.getAttribute(_backgroundColorAttributeName) ??
      element.getAttribute(_backgroundColorCssAttributeName);
  if (backgroundColor != null) {
    newStyle = newStyle.copyWith(backgroundColor: backgroundColor);
  }

  // Parse font-weight attribute
  final fontWeightStr = element.getAttribute(_fontWeightAttributeName) ??
      element.getAttribute(_fontWeightCssAttributeName);
  if (fontWeightStr != null) {
    final fontWeight = int.tryParse(fontWeightStr);
    if (fontWeight != null) {
      newStyle = newStyle.copyWith(fontWeight: fontWeight);
    }
  }

  // Parse font-size attribute
  final fontSizeStr = element.getAttribute(_fontSizeAttributeName) ??
      element.getAttribute(_fontSizeCssAttributeName);
  if (fontSizeStr != null) {
    final fontSize = double.tryParse(fontSizeStr);
    if (fontSize != null) {
      newStyle = newStyle.copyWith(fontSize: fontSize);
    }
  }

  // Parse font-family attribute
  final fontFamily = element.getAttribute(_fontFamilyAttributeName) ??
      element.getAttribute(_fontFamilyCssAttributeName);
  if (fontFamily != null) {
    newStyle = newStyle.copyWith(fontFamily: fontFamily);
  }

  // Parse text-decoration attribute
  final textDecoration = element.getAttribute(_textDecorationAttributeName) ??
      element.getAttribute(_textDecorationCssAttributeName);
  if (textDecoration != null) {
    newStyle = newStyle.copyWith(textDecoration: textDecoration);
  }

  // Parse href attribute (for links in span)
  final href = element.getAttribute(_hrefAttributeName);
  if (href != null) {
    newStyle = newStyle.copyWith(link: href);
  }

  return newStyle;
}

/// Adds text with the given style to the result list.
///
/// If the last item in the result has the same style, the text is appended
/// to that item. Otherwise, a new item is created.
void _addTextWithStyle(
  String text,
  RichTextItem style,
  List<RichTextItem> result,
) {
  if (text.isEmpty) {
    return;
  }

  final newItem = style.copyWith(text: text);

  if (result.isEmpty) {
    result.add(newItem);
    return;
  }

  final lastItem = result.last;

  // Check if the new item has the same style as the last one
  if (lastItem.hasSameStyle(newItem)) {
    // Merge text with the last item
    result
      ..removeLast()
      ..add(lastItem.copyWith(text: lastItem.text + text));
  } else {
    result.add(newItem);
  }
}
