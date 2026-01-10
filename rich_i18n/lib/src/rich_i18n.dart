import 'package:rich_i18n/rich_i18n.dart';
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
///   - `href`: Link URL
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

  _parseNode(
    document.rootElement,
    initialStyle,
    RichTextItemDescriptor.empty,
    result,
  );

  return result;
}

/// Parses a rich text string with XML tags and returns a list of
/// [VerboseRichTextItem] containing both the parsed items and descriptors.
///
/// Unlike [tryGetRichTextSync], this method:
/// - Throws [RichTextException] if the XML parsing fails
/// - Returns descriptors for each item indicating any unrecognized tags
///   or attributes
///
/// {@macro rich_i18n_supported_tags}
///
/// Example:
/// ```dart
/// // Valid XML with unrecognized tag
/// final result = verboseGetRichTextSync('<hi>hello</hi>');
/// // result[0].descriptor.unrecognizedTag == 'hi'
///
/// // Valid XML with unrecognized attribute
/// final result = verboseGetRichTextSync('<bold color="red">hello</bold>');
/// // result[0].descriptor.unrecognizedAttributes == ['color']
///
/// // Invalid XML throws exception
/// verboseGetRichTextSync('<bold>hello'); // throws RichTextException
/// ```
Future<List<VerboseRichTextItem>> verboseGetRichText(String text) async {
  if (text.isEmpty) {
    return [];
  }

  // Wrap the text in a root element to ensure valid XML
  final wrappedText = '<root>$text</root>';

  XmlDocument document;
  try {
    document = XmlDocument.parse(wrappedText);
  } on XmlParserException catch (e) {
    throw RichTextException(
      'Failed to parse XML: ${e.message}',
      cause: e,
    );
  } on XmlTagException catch (e) {
    throw RichTextException(
      'Invalid XML tag: ${e.message}',
      cause: e,
    );
  }

  final result = <VerboseRichTextItem>[];
  final initialStyle = RichTextItem(text: '');

  _parseNode(
    document.rootElement,
    initialStyle,
    RichTextItemDescriptor.empty,
    result,
    verbose: true,
  );

  return result;
}

/// Internal result of parsing an element's style.
class _ElementParseResult {
  const _ElementParseResult({
    required this.style,
    required this.descriptor,
  });

  final RichTextItem style;
  final RichTextItemDescriptor descriptor;
}

/// Returns a list of attribute names that are not in the allowed list.
List<String> _getUnrecognizedAttributes(
  XmlElement element, {
  required List<String> allowedAttributes,
}) {
  final unrecognized = <String>[];
  for (final attr in element.attributes) {
    final attrName = attr.name.local;
    // Check if it's in the allowed list
    if (allowedAttributes.contains(attrName)) {
      continue;
    }

    // For attributes not explicitly allowed, they are unrecognized
    unrecognized.add(attrName);
  }
  return unrecognized;
}

/// Recursively parses an XML node and its children.
///
/// If [verbose] is true, works with [List<VerboseRichTextItem>] and
/// includes descriptor information. Otherwise, works with [List<RichTextItem>].
void _parseNode(
  XmlNode node,
  RichTextItem currentStyle,
  RichTextItemDescriptor currentDescriptor,
  List<RichTextItem> result, {
  bool verbose = false,
}) {
  if (node is XmlText) {
    final text = node.value;
    if (text.isNotEmpty) {
      if (verbose) {
        _addTextWithStyleVerbose(
          text,
          currentStyle,
          currentDescriptor,
          result as List<VerboseRichTextItem>,
        );
      } else {
        _addTextWithStyle(text, currentStyle, result);
      }
    }
  } else if (node is XmlElement) {
    final parseResult =
        _getStyleForElement(node, currentStyle, verbose: verbose);

    // Merge descriptors if verbose
    var mergedDescriptor = RichTextItemDescriptor.empty;
    if (verbose) {
      mergedDescriptor = RichTextItemDescriptor(
        unrecognizedTag: parseResult.descriptor.unrecognizedTag,
        unrecognizedAttributes: [
          ...currentDescriptor.unrecognizedAttributes,
          ...parseResult.descriptor.unrecognizedAttributes,
        ],
      );
    }

    for (final child in node.children) {
      _parseNode(
        child,
        parseResult.style,
        mergedDescriptor,
        result,
        verbose: verbose,
      );
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
  _backgroundColorCssAttributeName,
  _fontWeightAttributeName,
  _fontWeightCssAttributeName,
  _fontSizeAttributeName,
  _fontSizeCssAttributeName,
  _fontFamilyAttributeName,
  _fontFamilyCssAttributeName,
  _textDecorationAttributeName,
  _textDecorationCssAttributeName,
  _hrefAttributeName,
];

const List<String> _aAvailableAttributes = [
  _hrefAttributeName,
];

/// Returns the updated style and descriptor based on the XML element.
_ElementParseResult _getStyleForElement(
  XmlElement element,
  RichTextItem currentStyle, {
  bool verbose = false,
}) {
  final tagName = element.name.local.toLowerCase();

  switch (tagName) {
    case 'root':
      return _ElementParseResult(
        style: currentStyle,
        descriptor: RichTextItemDescriptor.empty,
      );

    case 'b':
    case 'bold':
    case 'strong':
      if (verbose) {
        final unrecognized =
            _getUnrecognizedAttributes(element, allowedAttributes: const []);
        return _ElementParseResult(
          style: currentStyle.copyWith(fontWeight: kBoldFontWeight),
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style: currentStyle.copyWith(fontWeight: kBoldFontWeight),
        descriptor: RichTextItemDescriptor.empty,
      );

    case 'u':
    case 'underline':
      if (verbose) {
        final unrecognized =
            _getUnrecognizedAttributes(element, allowedAttributes: const []);
        return _ElementParseResult(
          style:
              currentStyle.copyWith(textDecoration: kUnderlineTextDecoration),
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style: currentStyle.copyWith(textDecoration: kUnderlineTextDecoration),
        descriptor: RichTextItemDescriptor.empty,
      );

    case 's':
    case 'strike':
    case 'strikethrough':
    case 'del':
      if (verbose) {
        final unrecognized =
            _getUnrecognizedAttributes(element, allowedAttributes: const []);
        return _ElementParseResult(
          style:
              currentStyle.copyWith(textDecoration: kLineThroughTextDecoration),
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style:
            currentStyle.copyWith(textDecoration: kLineThroughTextDecoration),
        descriptor: RichTextItemDescriptor.empty,
      );

    case 'a':
      final href = element.getAttribute(_hrefAttributeName);
      final newStyle =
          href != null ? currentStyle.copyWith(link: href) : currentStyle;
      if (verbose) {
        final unrecognized = _getUnrecognizedAttributes(
          element,
          allowedAttributes: _aAvailableAttributes,
        );
        return _ElementParseResult(
          style: newStyle,
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style: newStyle,
        descriptor: RichTextItemDescriptor.empty,
      );

    case 'span':
    case 'font':
      final newStyle = _parseSpanAttributes(element, currentStyle);
      if (verbose) {
        final unrecognized = _getUnrecognizedAttributes(
          element,
          allowedAttributes: _spanAvailableAttributes,
        );
        return _ElementParseResult(
          style: newStyle,
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style: newStyle,
        descriptor: RichTextItemDescriptor.empty,
      );

    case 'i':
    case 'italic':
    case 'em':
      // For italic, we can use font-style, but since we don't have that
      // property, we'll skip or you could add it later
      if (verbose) {
        final unrecognized = _getUnrecognizedAttributes(
          element,
          allowedAttributes: const [],
        );
        return _ElementParseResult(
          style: currentStyle,
          descriptor:
              RichTextItemDescriptor(unrecognizedAttributes: unrecognized),
        );
      }
      return _ElementParseResult(
        style: currentStyle,
        descriptor: RichTextItemDescriptor.empty,
      );

    default:
      // Unknown tags are treated as containers without style changes
      if (verbose) {
        final unrecognized = _getUnrecognizedAttributes(
          element,
          allowedAttributes: const [],
        );
        return _ElementParseResult(
          style: currentStyle,
          descriptor: RichTextItemDescriptor(
            unrecognizedTag: tagName,
            unrecognizedAttributes: unrecognized,
          ),
        );
      }
      return _ElementParseResult(
        style: currentStyle,
        descriptor: RichTextItemDescriptor.empty,
      );
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

/// Adds text with the given style and descriptor
/// to the result list in verbose mode.
void _addTextWithStyleVerbose(
  String text,
  RichTextItem style,
  RichTextItemDescriptor descriptor,
  List<VerboseRichTextItem> result,
) {
  if (text.isEmpty) {
    return;
  }

  final newItem = style.copyWith(text: text);

  if (result.isEmpty) {
    result.add(
      VerboseRichTextItem.fromItem(
        item: newItem,
        descriptor: descriptor,
      ),
    );
    return;
  }

  final lastResult = result.last;

  // Check if the new item has the same style AND descriptor as the last one
  if (lastResult.hasSameStyle(newItem) && lastResult.descriptor == descriptor) {
    // Merge text with the last item
    result
      ..removeLast()
      ..add(
        VerboseRichTextItem.fromItem(
          item: lastResult.copyWith(text: lastResult.text + text),
          descriptor: descriptor,
        ),
      );
  } else {
    result.add(
      VerboseRichTextItem.fromItem(
        item: newItem,
        descriptor: descriptor,
      ),
    );
  }
}
