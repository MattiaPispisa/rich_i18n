/// Represents a segment of rich text with styling properties.
///
/// Each [RichTextItem] contains text and optional styling attributes
/// that can be applied to render rich formatted text.
///
/// Equality is based on property values, not reference.
/// The hashCode is cached at construction time for efficiency.
class RichTextItem {
  /// Creates a new [RichTextItem] with the given properties.
  RichTextItem({
    required this.text,
    this.bold,
    this.color,
    this.link,
    this.backgroundColor,
    this.fontWeight,
    this.fontSize,
    this.fontFamily,
    this.textDecoration,
  }) : _cachedHashCode = _computeHashCode(
          text: text,
          bold: bold,
          color: color,
          link: link,
          backgroundColor: backgroundColor,
          fontWeight: fontWeight,
          fontSize: fontSize,
          fontFamily: fontFamily,
          textDecoration: textDecoration,
        );

  /// The text content of this item.
  final String text;

  /// Whether the text is bold.
  final bool? bold;

  /// The text color (e.g., "#FF0000" or "red").
  final String? color;

  /// The link URL if this text is a hyperlink.
  final String? link;

  /// The background color of the text.
  final String? backgroundColor;

  /// The font weight (e.g., 400 for normal, 700 for bold).
  final int? fontWeight;

  /// The font size in logical pixels.
  final double? fontSize;

  /// The font family name.
  final String? fontFamily;

  /// The text decoration (e.g., "underline", "line-through").
  final String? textDecoration;

  /// Cached hash code computed at construction time.
  final int _cachedHashCode;

  /// Computes the hash code based on all properties.
  static int _computeHashCode({
    required String text,
    bool? bold,
    String? color,
    String? link,
    String? backgroundColor,
    int? fontWeight,
    double? fontSize,
    String? fontFamily,
    String? textDecoration,
  }) {
    return Object.hash(
      text,
      bold,
      color,
      link,
      backgroundColor,
      fontWeight,
      fontSize,
      fontFamily,
      textDecoration,
    );
  }

  @override
  int get hashCode => _cachedHashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RichTextItem) {
      return false;
    }
    return text == other.text &&
        bold == other.bold &&
        color == other.color &&
        link == other.link &&
        backgroundColor == other.backgroundColor &&
        fontWeight == other.fontWeight &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily &&
        textDecoration == other.textDecoration;
  }

  @override
  String toString() {
    return 'RichTextItem('
        'text: "$text", '
        'bold: $bold, '
        'color: $color, '
        'link: $link, '
        'backgroundColor: $backgroundColor, '
        'fontWeight: $fontWeight, '
        'fontSize: $fontSize, '
        'fontFamily: $fontFamily, '
        'textDecoration: $textDecoration)';
  }

  /// Creates a copy of this item with the given text but same styling.
  RichTextItem copyWithText(String newText) {
    return RichTextItem(
      text: newText,
      bold: bold,
      color: color,
      link: link,
      backgroundColor: backgroundColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontFamily: fontFamily,
      textDecoration: textDecoration,
    );
  }

  /// Returns true if this item has the same style as [other],
  /// ignoring the text content.
  bool hasSameStyle(RichTextItem other) {
    return bold == other.bold &&
        color == other.color &&
        link == other.link &&
        backgroundColor == other.backgroundColor &&
        fontWeight == other.fontWeight &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily &&
        textDecoration == other.textDecoration;
  }
}

/// Represents the current styling context while parsing.
///
/// This class is used internally to track the accumulated styles
/// as we traverse the XML tree.
class StyleContext {
  /// Creates a new [StyleContext] with optional initial values.
  const StyleContext({
    this.bold,
    this.color,
    this.link,
    this.backgroundColor,
    this.fontWeight,
    this.fontSize,
    this.fontFamily,
    this.textDecoration,
  });

  /// Whether the text is bold.
  final bool? bold;

  /// The text color.
  final String? color;

  /// The link URL.
  final String? link;

  /// The background color.
  final String? backgroundColor;

  /// The font weight.
  final int? fontWeight;

  /// The font size.
  final double? fontSize;

  /// The font family.
  final String? fontFamily;

  /// The text decoration.
  final String? textDecoration;

  /// Creates a new [StyleContext] by merging this context with new values.
  StyleContext merge({
    bool? bold,
    String? color,
    String? link,
    String? backgroundColor,
    int? fontWeight,
    double? fontSize,
    String? fontFamily,
    String? textDecoration,
  }) {
    return StyleContext(
      bold: bold ?? this.bold,
      color: color ?? this.color,
      link: link ?? this.link,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textDecoration: textDecoration ?? this.textDecoration,
    );
  }

  /// Creates a [RichTextItem] from this context with the given text.
  RichTextItem toRichTextItem(String text) {
    return RichTextItem(
      text: text,
      bold: bold,
      color: color,
      link: link,
      backgroundColor: backgroundColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontFamily: fontFamily,
      textDecoration: textDecoration,
    );
  }

  /// Returns true if this context has the same style as [other].
  bool hasSameStyle(StyleContext other) {
    return bold == other.bold &&
        color == other.color &&
        link == other.link &&
        backgroundColor == other.backgroundColor &&
        fontWeight == other.fontWeight &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily &&
        textDecoration == other.textDecoration;
  }
}

