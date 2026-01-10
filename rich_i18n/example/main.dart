// ignore_for_file: avoid_print just for example purposes

import 'package:rich_i18n/rich_i18n.dart';

void main() async {
  print('=' * 60);
  print('rich_i18n Examples');
  print('=' * 60);
  print('');

  // Example 1: Basic text parsing with bold tag
  _sectionPrintLayout(
    title: 'Example 1: Basic bold text',
    body: () {
      final basicItems = tryGetRichTextSync('Hello <b>World</b>!');
      if (basicItems != null) {
        for (final item in basicItems) {
          print('  Text: "${item.text}"');
          print('    Bold: ${item.bold}');
          print('    FontWeight: ${item.fontWeight}');
        }
      }
    },
  );

  // Example 2: Nested tags
  _sectionPrintLayout(
    title: 'Example 2: Nested tags (bold and underline)',
    body: () {
      final nestedItems = tryGetRichTextSync(
        'Hello <b>bold and <u>underlined</u> text</b>!',
      );
      if (nestedItems != null) {
        for (final item in nestedItems) {
          print('  Text: "${item.text}"');
          print('    Bold: ${item.bold}');
          print('    TextDecoration: ${item.textDecoration}');
        }
      }
    },
  );

  // Example 3: Multiple text styles
  _sectionPrintLayout(
    title: 'Example 3: Multiple text styles',
    body: () {
      final stylesItems = tryGetRichTextSync(
        '<b>Bold</b> <i>Italic</i> <u>Underline</u> <s>Strike</s>',
      );
      if (stylesItems != null) {
        for (final item in stylesItems) {
          print('  Text: "${item.text}"');
          print('    Bold: ${item.bold}');
          print('    Italic: ${item.fontStyle == kItalicFontStyle}');
          print(
            '    Underline: ${item.textDecoration == kUnderlineTextDecoration}',
          );
          print(
            '    Strike: ${item.textDecoration == kLineThroughTextDecoration}',
          );
        }
      }
    },
  );

  // Example 4: Span with attributes (color, font size, etc.)
  _sectionPrintLayout(
    title: 'Example 4: Span with attributes',
    body: () {
      final spanItems = tryGetRichTextSync(
        '<span color="#FF0000" font-size="18" font-weight="700"> '
        'Red bold large text</span>',
      );
      if (spanItems != null) {
        for (final item in spanItems) {
          print('  Text: "${item.text}"');
          print('    Color: ${item.color}');
          print('    FontSize: ${item.fontSize}');
          print('    FontWeight: ${item.fontWeight}');
        }
      }
    },
  );
  // Example 5: Background color and font family
  _sectionPrintLayout(
    title: 'Example 5: Background color and font family',
    body: () {
      final styledItems = tryGetRichTextSync(
        '<span background-color="yellow" font-family="Arial">'
        ' Styled text</span>',
      );
      if (styledItems != null) {
        for (final item in styledItems) {
          print('  Text: "${item.text}"');
          print('    BackgroundColor: ${item.backgroundColor}');
          print('    FontFamily: ${item.fontFamily}');
        }
      }
    },
  );
  // Example 6: Links
  _sectionPrintLayout(
    title: 'Example 6: Hyperlinks',
    body: () {
      final linkItems = tryGetRichTextSync(
        'Click <a href="https://example.com">here</a> for more info',
      );
      if (linkItems != null) {
        for (final item in linkItems) {
          print('  Text: "${item.text}"');
          print('    Link: ${item.link}');
        }
      }
    },
  );

  // Example 7: Complex nested structure
  _sectionPrintLayout(
    title: 'Example 7: Complex nested structure',
    body: () {
      final complexItems = tryGetRichTextSync(
        '<b>Bold text with <span color="red">red nested</span> '
        'and <u>underlined</u> parts</b>',
      );
      if (complexItems != null) {
        for (final item in complexItems) {
          print('  Text: "${item.text}"');
          print('    Bold: ${item.bold}');
          print('    Color: ${item.color}');
          print(
            '    Underline: ${item.textDecoration == kUnderlineTextDecoration}',
          );
        }
      }
    },
  );

  // Example 8: Error handling with tryGetRichTextSync (returns null)
  _sectionPrintLayout(
    title: 'Example 8: Error handling (invalid XML)',
    body: () {
      final invalidItems = tryGetRichTextSync('Invalid <b>unclosed tag');
      if (invalidItems == null) {
        print('  Result: null (invalid XML)');
      }
    },
  );

  // Example 9: Verbose mode with error reporting
  await _sectionPrintLayoutAsync(
    title: 'Example 9: Verbose mode (with descriptors)',
    body: () async {
      try {
        final verboseItems = await verboseGetRichText(
          '<unknown>hello</unknown> <bold>world</bold>',
        );
        for (final item in verboseItems) {
          print('  Text: "${item.text}"');
          if (item.descriptor.hasIssues) {
            print('    Issues detected:');
            if (item.descriptor.unrecognizedTag != null) {
              print(
                '      Unrecognized tag: ${item.descriptor.unrecognizedTag}',
              );
            }
            if (item.descriptor.unrecognizedAttributes.isNotEmpty) {
              print('      Unrecognized attributes: '
                  '${item.descriptor.unrecognizedAttributes}');
            }
          } else {
            print('    No issues');
          }
        }
      } catch (e) {
        print('  Error: $e');
      }
    },
  );

  // Example 10: Empty tags are ignored (merged)
  _sectionPrintLayout(
    title: 'Example 10: Consecutive same-style segments are merged',
    body: () {
      final mergedItems = tryGetRichTextSync('<b>hello</b><b> world</b>');
      if (mergedItems != null) {
        print('  Input: <b>hello</b><b> world</b>');
        print('  Result: ${mergedItems.length} item(s)');
        for (final item in mergedItems) {
          print('    Text: "${item.text}" (merged)');
        }
      }
    },
  );

  print('=' * 60);
  print('All examples completed!');
  print('=' * 60);
}

void _sectionPrintLayout({
  required String title,
  void Function()? body,
}) {
  print(title);
  print('-' * 60);
  body?.call();
  print('');
}

Future<void> _sectionPrintLayoutAsync({
  required String title,
  required Future<void> Function() body,
}) async {
  print(title);
  print('-' * 60);
  await body();
  print('');
}
