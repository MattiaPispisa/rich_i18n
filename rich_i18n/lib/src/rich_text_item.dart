/// The font weight value that represents bold text.
const int kBoldFontWeight = 700;

/// The text decoration value that represents underline text.
const String kUnderlineTextDecoration = 'underline';

/// The text decoration value that represents line through text.
const String kLineThroughTextDecoration = 'lineThrough';

/// Represents a segment of rich text with styling properties.
///
/// Each [RichTextItem] contains text and optional styling attributes
/// that can be applied to render rich formatted text.
///
/// Equality is based on property values, not reference.
///
/// Example:
/// ```dart
/// final item1 = RichTextItem(text: 'hello', fontWeight: 700);
/// final item2 = RichTextItem(text: 'hello', fontWeight: 700);
/// final item3 = RichTextItem(text: 'hello', fontWeight: 400);
/// item1 == item2 // true
/// item1 == item3 // false
/// ```
///
/// Note: [bold] is a convenience getter that returns `true` when
/// [fontWeight] equals [kBoldFontWeight] (700).
class RichTextItem {
  /// Creates a new [RichTextItem] with the given properties.
  RichTextItem({
    required this.text,
    this.color,
    this.link,
    this.backgroundColor,
    this.fontWeight,
    this.fontSize,
    this.fontFamily,
    this.textDecoration,
  }) : _cachedHashCode = _computeHashCode(
          text: text,
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

  /// The text color (e.g., "#FF0000" or "red").
  final String? color;

  /// The link URL if this text is a hyperlink.
  final String? link;

  /// The background color of the text.
  final String? backgroundColor;

  /// The font weight (e.g., 400 for normal, 700 for bold).
  ///
  /// See also [bold] for a convenient way to check if the text is bold.
  final int? fontWeight;

  /// The font size in logical pixels.
  final double? fontSize;

  /// The font family name.
  final String? fontFamily;

  /// The text decoration.
  ///
  /// Currently supported are:
  /// - [kUnderlineTextDecoration]
  /// - [kLineThroughTextDecoration]
  final String? textDecoration;

  /// Cached hash code computed at construction time.
  final int _cachedHashCode;

  /// Whether the text is bold.
  ///
  /// Returns `true` if [fontWeight] equals [kBoldFontWeight] (700),
  bool get bold => fontWeight == kBoldFontWeight;

  /// Computes the hash code based on all properties.
  static int _computeHashCode({
    required String text,
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
    return text == other.text && hasSameStyle(other);
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

  /// Creates a copy of this item with the given properties replaced.
  ///
  /// Any parameter that is not provided will retain the current value.
  RichTextItem copyWith({
    String? text,
    String? color,
    String? link,
    String? backgroundColor,
    int? fontWeight,
    double? fontSize,
    String? fontFamily,
    String? textDecoration,
  }) {
    return RichTextItem(
      text: text ?? this.text,
      color: color ?? this.color,
      link: link ?? this.link,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textDecoration: textDecoration ?? this.textDecoration,
    );
  }

  /// Returns true if this item has the same style as [other],
  /// ignoring the text content.
  bool hasSameStyle(RichTextItem other) {
    return color == other.color &&
        link == other.link &&
        backgroundColor == other.backgroundColor &&
        fontWeight == other.fontWeight &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily &&
        textDecoration == other.textDecoration;
  }
}
