/// A library for parsing rich text with XML tags into structured items.
///
/// This library provides a simple way to parse strings containing XML-like
/// tags (similar to HTML) and convert them into a list of [RichTextItem]
/// objects with styling properties.
///
/// Example:
/// ```dart
/// import 'package:rich_i18n/rich_i18n.dart';
///
/// void main() {
///   final items = getRichText('Hello <b>World</b>!');
///   // items[0].text == 'Hello '
///   // items[1].text == 'World', items[1].bold == true
///   // items[2].text == '!'
/// }
/// ```
library rich_i18n;

export 'src/rich_i18n.dart';
export 'src/rich_text_item.dart' show RichTextItem;
