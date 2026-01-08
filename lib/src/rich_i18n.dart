import 'package:xml/xml.dart';

import 'rich_text_item.dart';

/// Parses a rich text string with XML tags and returns a list of [RichTextItem].
///
/// Supported XML tags (HTML-like):
/// - `<b>` or `<bold>`: Bold text
/// - `<u>` or `<underline>`: Underlined text
/// - `<s>` or `<strike>` or `<strikethrough>`: Strikethrough text
/// - `<a href="url">`: Hyperlink
/// - `<span>` with attributes:
///   - `color`: Text color (e.g., "#FF0000" or "red")
///   - `background-color`: Background color
///   - `font-weight`: Font weight (e.g., "700")
///   - `font-size`: Font size (e.g., "14")
///   - `font-family`: Font family name
///
/// Examples:
/// ```dart
/// // Simple bold text
/// getRichText('hello <b>dart</b>');
/// // Returns: [RichTextItem(text: 'hello '), RichTextItem(text: 'dart', bold: true)]
///
/// // Nested tags
/// getRichText('hello <b>dart and <u>flutter</u></b>');
/// // Returns: [
/// //   RichTextItem(text: 'hello '),
/// //   RichTextItem(text: 'dart and ', bold: true),
/// //   RichTextItem(text: 'flutter', bold: true, textDecoration: 'underline')
/// // ]
/// ```
List<RichTextItem> getRichText(String text) {
  if (text.isEmpty) {
    return [];
  }

  // Wrap the text in a root element to ensure valid XML
  final wrappedText = '<root>$text</root>';

  XmlDocument document;
  try {
    document = XmlDocument.parse(wrappedText);
  } catch (e) {
    // If parsing fails, return the original text as a single item
    return [RichTextItem(text: text)];
  }

  final result = <RichTextItem>[];
  const initialContext = StyleContext();

  _parseNode(document.rootElement, initialContext, result);

  return result;
}

/// Recursively parses an XML node and its children.
void _parseNode(
  XmlNode node,
  StyleContext context,
  List<RichTextItem> result,
) {
  if (node is XmlText) {
    final text = node.value;
    if (text.isNotEmpty) {
      _addTextWithStyle(text, context, result);
    }
  } else if (node is XmlElement) {
    final newContext = _getContextForElement(node, context);

    for (final child in node.children) {
      _parseNode(child, newContext, result);
    }
  } else {
    // For other node types (comments, CDATA, etc.), process children if any
    for (final child in node.children) {
      _parseNode(child, context, result);
    }
  }
}

/// Returns the updated style context based on the XML element.
StyleContext _getContextForElement(XmlElement element, StyleContext context) {
  final tagName = element.name.local.toLowerCase();

  switch (tagName) {
    case 'root':
      // Root element doesn't add any style
      return context;

    case 'b':
    case 'bold':
    case 'strong':
      return context.merge(bold: true);

    case 'u':
    case 'underline':
      return context.merge(textDecoration: 'underline');

    case 's':
    case 'strike':
    case 'strikethrough':
    case 'del':
      return context.merge(textDecoration: 'line-through');

    case 'a':
      final href = element.getAttribute('href');
      return context.merge(link: href);

    case 'span':
    case 'font':
      return _parseSpanAttributes(element, context);

    case 'i':
    case 'italic':
    case 'em':
      // For italic, we can use font-style, but since we don't have that
      // property, we'll skip or you could add it later
      return context;

    default:
      // Unknown tags are treated as containers without style changes
      return context;
  }
}

/// Parses span/font element attributes and returns the updated context.
StyleContext _parseSpanAttributes(XmlElement element, StyleContext context) {
  var newContext = context;

  // Parse color attribute
  final color = element.getAttribute('color');
  if (color != null) {
    newContext = newContext.merge(color: color);
  }

  // Parse background-color attribute
  final backgroundColor = element.getAttribute('background-color') ??
      element.getAttribute('backgroundColor');
  if (backgroundColor != null) {
    newContext = newContext.merge(backgroundColor: backgroundColor);
  }

  // Parse font-weight attribute
  final fontWeightStr =
      element.getAttribute('font-weight') ?? element.getAttribute('fontWeight');
  if (fontWeightStr != null) {
    final fontWeight = int.tryParse(fontWeightStr);
    if (fontWeight != null) {
      newContext = newContext.merge(fontWeight: fontWeight);
    }
  }

  // Parse font-size attribute
  final fontSizeStr =
      element.getAttribute('font-size') ?? element.getAttribute('fontSize');
  if (fontSizeStr != null) {
    final fontSize = double.tryParse(fontSizeStr);
    if (fontSize != null) {
      newContext = newContext.merge(fontSize: fontSize);
    }
  }

  // Parse font-family attribute
  final fontFamily =
      element.getAttribute('font-family') ?? element.getAttribute('fontFamily');
  if (fontFamily != null) {
    newContext = newContext.merge(fontFamily: fontFamily);
  }

  // Parse text-decoration attribute
  final textDecoration = element.getAttribute('text-decoration') ??
      element.getAttribute('textDecoration');
  if (textDecoration != null) {
    newContext = newContext.merge(textDecoration: textDecoration);
  }

  // Parse href attribute (for links in span)
  final href = element.getAttribute('href');
  if (href != null) {
    newContext = newContext.merge(link: href);
  }

  return newContext;
}

/// Adds text with the given style context to the result list.
///
/// If the last item in the result has the same style, the text is appended
/// to that item. Otherwise, a new item is created.
void _addTextWithStyle(
  String text,
  StyleContext context,
  List<RichTextItem> result,
) {
  if (text.isEmpty) {
    return;
  }

  if (result.isEmpty) {
    result.add(context.toRichTextItem(text));
    return;
  }

  final lastItem = result.last;
  final newItem = context.toRichTextItem(text);

  // Check if the new item has the same style as the last one
  if (lastItem.hasSameStyle(newItem)) {
    // Merge text with the last item
    result
      ..removeLast()
      ..add(lastItem.copyWithText(lastItem.text + text));
  } else {
    result.add(newItem);
  }
}
