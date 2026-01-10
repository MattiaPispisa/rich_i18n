import 'package:rich_i18n/rich_i18n.dart';

/// The font weight value that represents bold text.
const int kBoldFontWeight = 700;

/// The text decoration value that represents underline text.
const String kUnderlineTextDecoration = 'underline';

/// The text decoration value that represents line through text.
const String kLineThroughTextDecoration = 'lineThrough';

/// The font style value that represents italic text.
const String kItalicFontStyle = 'italic';

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
    this.fontStyle,
    this.textDecoration,
  }) : _cachedHashCode = _computeHashCode(
          text: text,
          color: color,
          fontStyle: fontStyle,
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

  /// The font style.
  ///
  /// Currently supported are:
  /// - [kItalicFontStyle]
  final String? fontStyle;

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
    required String? fontStyle,
    required String? color,
    required String? link,
    required String? backgroundColor,
    required int? fontWeight,
    required double? fontSize,
    required String? fontFamily,
    required String? textDecoration,
  }) {
    return Object.hash(
      text,
      fontStyle,
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
        'fontStyle: $fontStyle, '
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
    String? fontStyle,
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
      fontStyle: fontStyle ?? this.fontStyle,
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
        fontStyle == other.fontStyle &&
        textDecoration == other.textDecoration;
  }
}

/// A [RichTextItem] with additional descriptor information.
///
/// Used by [verboseGetRichText] to provide information about
/// unrecognized tags and attributes.
class VerboseRichTextItem extends RichTextItem {
  /// Creates a new [VerboseRichTextItem] with the given properties
  /// and descriptor.
  VerboseRichTextItem({
    required super.text,
    super.color,
    super.link,
    super.backgroundColor,
    super.fontWeight,
    super.fontSize,
    super.fontFamily,
    super.textDecoration,
    this.descriptor = RichTextItemDescriptor.empty,
  });

  /// Creates a [VerboseRichTextItem] from a [RichTextItem] and descriptor.
  VerboseRichTextItem.fromItem({
    required RichTextItem item,
    this.descriptor = RichTextItemDescriptor.empty,
  }) : super(
          text: item.text,
          color: item.color,
          link: item.link,
          backgroundColor: item.backgroundColor,
          fontWeight: item.fontWeight,
          fontSize: item.fontSize,
          fontFamily: item.fontFamily,
          textDecoration: item.textDecoration,
        );

  /// The descriptor containing any parsing issues for this item.
  final RichTextItemDescriptor descriptor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! VerboseRichTextItem) {
      return super == other;
    }
    return super == other && descriptor == other.descriptor;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, descriptor);

  @override
  String toString() {
    return 'VerboseRichTextItem(${super.toString()}, descriptor: $descriptor)';
  }
}
