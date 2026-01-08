/// A library for parsing rich text with XML tags into structured items.
///
/// This library provides a simple way to parse strings containing XML-like
/// tags (similar to HTML) and convert them into a list of [RichTextItem]
/// objects with styling properties.
///
/// {@macro rich_i18n_supported_tags}
/// {@macro rich_i18n_examples}
library rich_i18n;

import 'package:rich_i18n/rich_i18n.dart';

export 'src/rich_i18n.dart' show tryGetRichTextSync;
export 'src/rich_text_item.dart'
    show
        RichTextItem,
        kBoldFontWeight,
        kLineThroughTextDecoration,
        kUnderlineTextDecoration;
