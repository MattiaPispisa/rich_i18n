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

// -----------------------------------------------------------------------------
// Internal Parsing Logic
// -----------------------------------------------------------------------------

/// Internal result of parsing an element's style.
class _ElementParseResult {
  const _ElementParseResult({
    required this.style,
    required this.descriptor,
  });

  final RichTextItem style;
  final RichTextItemDescriptor descriptor;
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
}

// -----------------------------------------------------------------------------
// Tag & Attribute Configuration
// -----------------------------------------------------------------------------

// Function typedefs for builders
// --- Attribute Handlers ---
RichTextItem _handleColor(RichTextItem s, String v) => s.copyWith(color: v);
RichTextItem _handleBgColor(RichTextItem s, String v) =>
    s.copyWith(backgroundColor: v);
RichTextItem _handleFontWeight(RichTextItem s, String v) {
  final val = int.tryParse(v);
  return val != null ? s.copyWith(fontWeight: val) : s;
}

RichTextItem _handleFontSize(RichTextItem s, String v) {
  final val = double.tryParse(v);
  return val != null ? s.copyWith(fontSize: val) : s;
}

RichTextItem _handleFontFamily(RichTextItem s, String v) =>
    s.copyWith(fontFamily: v);
RichTextItem _handleTextDecoration(RichTextItem s, String v) =>
    s.copyWith(textDecoration: v);
RichTextItem _handleHref(RichTextItem s, String v) => s.copyWith(link: v);

// --- Attribute Registry ---
final Map<String, RichTextItem Function(RichTextItem current, String value)>
    _attributeHandlers = {
  'color': _handleColor,
  'background-color': _handleBgColor,
  'backgroundColor': _handleBgColor,
  'font-weight': _handleFontWeight,
  'fontWeight': _handleFontWeight,
  'font-size': _handleFontSize,
  'fontSize': _handleFontSize,
  'font-family': _handleFontFamily,
  'fontFamily': _handleFontFamily,
  'text-decoration': _handleTextDecoration,
  'textDecoration': _handleTextDecoration,
  'href': _handleHref,
};

// --- Implicit Style Builders ---
RichTextItem _applyBold(RichTextItem s) =>
    s.copyWith(fontWeight: kBoldFontWeight);
RichTextItem _applyUnderline(RichTextItem s) =>
    s.copyWith(textDecoration: kUnderlineTextDecoration);
RichTextItem _applyStrike(RichTextItem s) =>
    s.copyWith(textDecoration: kLineThroughTextDecoration);

// --- Tag Configuration Class ---
class _TagConfig {
  const _TagConfig({
    this.implicitBuilder,
    this.allowedAttributes = const {},
  });

  /// Optional builder to apply the tag's implicit style (e.g. bold for <b>)
  final RichTextItem Function(RichTextItem current)? implicitBuilder;

  /// Set of allowed attribute names for this tag
  final Set<String> allowedAttributes;
}

// --- Common Attribute Sets ---
const _spanAttributes = {
  'color',
  'background-color',
  'backgroundColor',
  'font-weight',
  'fontWeight',
  'font-size',
  'fontSize',
  'font-family',
  'fontFamily',
  'text-decoration',
  'textDecoration',
  'href',
};

const _linkAttributes = {'href'};

// --- Tag Registry ---
final Map<String, _TagConfig> _tagConfigs = {
  'root': const _TagConfig(),

  // Bold variants
  'b': const _TagConfig(implicitBuilder: _applyBold),
  'bold': const _TagConfig(implicitBuilder: _applyBold),
  'strong': const _TagConfig(implicitBuilder: _applyBold),

  // Underline variants
  'u': const _TagConfig(implicitBuilder: _applyUnderline),
  'underline': const _TagConfig(implicitBuilder: _applyUnderline),

  // Strike variants
  's': const _TagConfig(implicitBuilder: _applyStrike),
  'strike': const _TagConfig(implicitBuilder: _applyStrike),
  'strikethrough': const _TagConfig(implicitBuilder: _applyStrike),
  'del': const _TagConfig(implicitBuilder: _applyStrike),

  // Link
  'a': const _TagConfig(allowedAttributes: _linkAttributes),

  // Span / Font
  'span': const _TagConfig(allowedAttributes: _spanAttributes),
  'font': const _TagConfig(allowedAttributes: _spanAttributes),

  // Italic (Placeholder: currently no style applied)
  'i': const _TagConfig(),
  'italic': const _TagConfig(),
  'em': const _TagConfig(),
};

/// Returns the updated style and descriptor based on the XML element.
///
/// This method uses a data-driven approach via [_tagConfigs]
/// and [_attributeHandlers].
/// It is optimized to exit early when [verbose] is false, avoiding unnecessary
/// iteration or allocation.
_ElementParseResult _getStyleForElement(
  XmlElement element,
  RichTextItem currentStyle, {
  bool verbose = false,
}) {
  final tagName = element.name.local.toLowerCase();
  final config = _tagConfigs[tagName];

  // --- Case 1: Unknown Tag ---
  if (config == null) {
    if (!verbose) {
      // Optimization: If not verbose, ignore unknown tags immediately
      return _ElementParseResult(
        style: currentStyle,
        descriptor: RichTextItemDescriptor.empty,
      );
    }

    // In verbose mode, collect all attributes as unrecognized
    final unrecognizedAttrs =
        element.attributes.map((attr) => attr.name.local).toList();

    return _ElementParseResult(
      style: currentStyle,
      descriptor: RichTextItemDescriptor(
        unrecognizedTag: tagName,
        unrecognizedAttributes: unrecognizedAttrs,
      ),
    );
  }

  // --- Case 2: Known Tag ---

  // A. Apply implicit style (e.g., Bold)
  var nextStyle = currentStyle;
  if (config.implicitBuilder != null) {
    nextStyle = config.implicitBuilder!(nextStyle);
  }

  // B. Process Attributes (Optimized)

  // If the tag does not allow attributes (e.g., <b>)
  // and we are not in verbose mode,
  // we exit immediately to avoid the cost of iterating over attributes.
  if (config.allowedAttributes.isEmpty && !verbose) {
    return _ElementParseResult(
      style: nextStyle,
      descriptor: RichTextItemDescriptor.empty,
    );
  }

  List<String>? unrecognizedAttrs;
  if (verbose) {
    unrecognizedAttrs = [];
  }

  // Iterate over attributes
  for (final attr in element.attributes) {
    final attrName = attr.name.local;

    // Check if the attribute is allowed for this specific tag
    if (config.allowedAttributes.contains(attrName)) {
      final attrValue = attr.value;
      final handler = _attributeHandlers[attrName];
      if (handler != null) {
        nextStyle = handler(nextStyle, attrValue);
      }
    } else if (verbose) {
      // Logic executed only if verbose is true
      unrecognizedAttrs!.add(attrName);
    }
  }

  return _ElementParseResult(
    style: nextStyle,
    descriptor:
        (verbose && unrecognizedAttrs != null && unrecognizedAttrs.isNotEmpty)
            ? RichTextItemDescriptor(unrecognizedAttributes: unrecognizedAttrs)
            : RichTextItemDescriptor.empty,
  );
}

// -----------------------------------------------------------------------------
// Helper Methods
// -----------------------------------------------------------------------------

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
