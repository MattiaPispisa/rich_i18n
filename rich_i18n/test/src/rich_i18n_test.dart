import 'package:rich_i18n/rich_i18n.dart';
import 'package:test/test.dart';

void main() {
  group('RichTextItem', () {
    test('equality by value', () {
      final item1 = RichTextItem(text: 'hello', fontWeight: kBoldFontWeight);
      final item2 = RichTextItem(text: 'hello', fontWeight: kBoldFontWeight);
      final item3 = RichTextItem(text: 'hello', fontWeight: 400);

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('hashCode is consistent with equality', () {
      final item1 = RichTextItem(
        text: 'hello',
        fontWeight: kBoldFontWeight,
        color: '#FF0000',
      );
      final item2 = RichTextItem(
        text: 'hello',
        fontWeight: kBoldFontWeight,
        color: '#FF0000',
      );

      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('hashCode is cached', () {
      final item = RichTextItem(text: 'test');
      final hashCode1 = item.hashCode;
      final hashCode2 = item.hashCode;

      // Both calls should return the same value (cached)
      expect(hashCode1, equals(hashCode2));
    });

    test('hasSameStyle returns true for same style different text', () {
      final item1 = RichTextItem(text: 'hello', fontWeight: kBoldFontWeight);
      final item2 = RichTextItem(text: 'world', fontWeight: kBoldFontWeight);

      expect(item1.hasSameStyle(item2), isTrue);
    });

    test('hasSameStyle returns false for different styles', () {
      final item1 = RichTextItem(text: 'hello', fontWeight: kBoldFontWeight);
      final item2 = RichTextItem(text: 'hello', fontWeight: 400);

      expect(item1.hasSameStyle(item2), isFalse);
    });

    test('bold getter returns true when fontWeight is 700', () {
      final item = RichTextItem(text: 'test', fontWeight: kBoldFontWeight);
      expect(item.bold, isTrue);
    });

    test('bold getter returns false when fontWeight is not 700', () {
      final item1 = RichTextItem(text: 'test', fontWeight: 400);
      final item2 = RichTextItem(text: 'test');

      expect(item1.bold, isFalse);
      expect(item2.bold, isFalse);
    });

    test('toString returns correct representation', () {
      final item = RichTextItem(
        text: 'hello',
        fontWeight: kBoldFontWeight,
        color: '#FF0000',
        link: 'https://example.com',
        backgroundColor: 'yellow',
        fontSize: 16,
        fontFamily: 'Roboto',
        textDecoration: kUnderlineTextDecoration,
      );

      final str = item.toString();

      expect(str, contains('text: "hello"'));
      expect(str, contains('bold: true'));
      expect(str, contains('color: #FF0000'));
      expect(str, contains('link: https://example.com'));
      expect(str, contains('backgroundColor: yellow'));
      expect(str, contains('fontWeight: 700'));
      expect(str, contains('fontSize: 16'));
      expect(str, contains('fontFamily: Roboto'));
      expect(str, contains('textDecoration: underline'));
    });
  });

  group('tryGetRichTextSync', () {
    group('Use Case 1: Simple bold tag', () {
      // "hello <bold>dart</bold>" creates two RichTextItem
      test('creates two RichTextItem for "hello <bold>dart</bold>"', () {
        final result = tryGetRichTextSync('hello <bold>dart</bold>');

        expect(result, isNotNull);
        expect(result, hasLength(2));

        expect(result![0].text, equals('hello '));
        expect(result[0].bold, isFalse);

        expect(result[1].text, equals('dart'));
        expect(result[1].bold, isTrue);
        expect(result[1].fontWeight, equals(kBoldFontWeight));
      });

      test('also works with <b> tag', () {
        final result = tryGetRichTextSync('hello <b>dart</b>');

        expect(result, isNotNull);
        expect(result, hasLength(2));

        expect(result![0].text, equals('hello '));
        expect(result[0].bold, isFalse);

        expect(result[1].text, equals('dart'));
        expect(result[1].bold, isTrue);
      });
    });

    group('Use Case 2: Nested tags', () {
      // "hello <bold>dart and <underline>flutter</underline></bold>"
      // creates three RichTextItem
      test('creates three RichTextItem for nested bold and underline', () {
        final result = tryGetRichTextSync(
          'hello <bold>dart and <underline>flutter</underline></bold>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(3));

        // "hello " - no style
        expect(result![0].text, equals('hello '));
        expect(result[0].bold, isFalse);
        expect(result[0].textDecoration, isNull);

        // "dart and " - bold only
        expect(result[1].text, equals('dart and '));
        expect(result[1].bold, isTrue);
        expect(result[1].textDecoration, isNull);

        // "flutter" - bold and underline
        expect(result[2].text, equals('flutter'));
        expect(result[2].bold, isTrue);
        expect(result[2].textDecoration, equals(kUnderlineTextDecoration));
      });
    });

    group('Use Case 3: Style changes back', () {
      // "hello <bold>dart and <underline>flutter</underline></bold> !"
      // The "!" returns to having the same style as "hello " but needs a new
      // RichTextItem because the previous one (with text "flutter") was also
      // underline.
      test('creates four RichTextItem when style changes back', () {
        final result = tryGetRichTextSync(
          'hello <bold>dart and <underline>flutter</underline></bold> !',
        );

        expect(result, isNotNull);
        expect(result, hasLength(4));

        // "hello " - no style
        expect(result![0].text, equals('hello '));
        expect(result[0].bold, isFalse);
        expect(result[0].textDecoration, isNull);

        // "dart and " - bold only
        expect(result[1].text, equals('dart and '));
        expect(result[1].bold, isTrue);
        expect(result[1].textDecoration, isNull);

        // "flutter" - bold and underline
        expect(result[2].text, equals('flutter'));
        expect(result[2].bold, isTrue);
        expect(result[2].textDecoration, equals(kUnderlineTextDecoration));

        // " !" - no style (same as "hello ")
        expect(result[3].text, equals(' !'));
        expect(result[3].bold, isFalse);
        expect(result[3].textDecoration, isNull);
      });
    });

    group('Use Case 4: Empty tags', () {
      // "hello <bold></bold> world"
      // The bold tag is empty, not needed, just one RichTextItem
      test('creates one RichTextItem for empty bold tag', () {
        final result = tryGetRichTextSync('hello <bold></bold> world');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('hello  world'));
        expect(result[0].bold, isFalse);
      });
    });

    group('Additional tests', () {
      test('empty string returns empty list', () {
        final result = tryGetRichTextSync('');

        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('plain text without tags returns single item', () {
        final result = tryGetRichTextSync('hello world');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('hello world'));
        expect(result[0].bold, isFalse);
      });

      test('consecutive same-style segments are merged', () {
        final result = tryGetRichTextSync('<b>hello</b><b> world</b>');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('hello world'));
        expect(result[0].bold, isTrue);
      });

      test('link tag with href', () {
        final result = tryGetRichTextSync(
          'Click <a href="https://example.com">here</a> for more',
        );

        expect(result, isNotNull);
        expect(result, hasLength(3));

        expect(result![0].text, equals('Click '));
        expect(result[0].link, isNull);

        expect(result[1].text, equals('here'));
        expect(result[1].link, equals('https://example.com'));

        expect(result[2].text, equals(' for more'));
        expect(result[2].link, isNull);
      });

      test('span with color attribute', () {
        final result = tryGetRichTextSync(
          'Hello <span color="#FF0000">red</span> world',
        );

        expect(result, isNotNull);
        expect(result, hasLength(3));

        expect(result![0].text, equals('Hello '));
        expect(result[0].color, isNull);

        expect(result[1].text, equals('red'));
        expect(result[1].color, equals('#FF0000'));

        expect(result[2].text, equals(' world'));
        expect(result[2].color, isNull);
      });

      test('span with multiple attributes', () {
        final result = tryGetRichTextSync(
          '<span color="#FF0000" font-size="16" font-weight="700">styled</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('styled'));
        expect(result[0].color, equals('#FF0000'));
        expect(result[0].fontSize, equals(16.0));
        expect(result[0].fontWeight, equals(kBoldFontWeight));
        expect(result[0].bold, isTrue);
      });

      test('strikethrough text', () {
        final result = tryGetRichTextSync('normal <s>deleted</s> text');

        expect(result, isNotNull);
        expect(result, hasLength(3));

        expect(result![0].text, equals('normal '));
        expect(result[0].textDecoration, isNull);

        expect(result[1].text, equals('deleted'));
        expect(result[1].textDecoration, equals(kLineThroughTextDecoration));

        expect(result[2].text, equals(' text'));
        expect(result[2].textDecoration, isNull);
      });

      test('deeply nested tags', () {
        final result = tryGetRichTextSync(
          '<b>bold <u>bold-underline <span color="red">bold-underline-red</span></u></b>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(3));

        expect(result![0].text, equals('bold '));
        expect(result[0].bold, isTrue);
        expect(result[0].textDecoration, isNull);
        expect(result[0].color, isNull);

        expect(result[1].text, equals('bold-underline '));
        expect(result[1].bold, isTrue);
        expect(result[1].textDecoration, equals(kUnderlineTextDecoration));
        expect(result[1].color, isNull);

        expect(result[2].text, equals('bold-underline-red'));
        expect(result[2].bold, isTrue);
        expect(result[2].textDecoration, equals(kUnderlineTextDecoration));
        expect(result[2].color, equals('red'));
      });

      test('invalid XML returns null', () {
        final result = tryGetRichTextSync('hello <b>world');

        expect(result, isNull);
      });

      test('background color attribute', () {
        final result = tryGetRichTextSync(
          '<span background-color="yellow">highlighted</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('highlighted'));
        expect(result[0].backgroundColor, equals('yellow'));
      });

      test('font family attribute', () {
        final result = tryGetRichTextSync(
          '<span font-family="Roboto">custom font</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('custom font'));
        expect(result[0].fontFamily, equals('Roboto'));
      });

      test('alternating styles create multiple items', () {
        final result = tryGetRichTextSync('<b>bold</b>normal<b>bold again</b>');

        expect(result, isNotNull);
        expect(result, hasLength(3));

        expect(result![0].text, equals('bold'));
        expect(result[0].bold, isTrue);

        expect(result[1].text, equals('normal'));
        expect(result[1].bold, isFalse);

        expect(result[2].text, equals('bold again'));
        expect(result[2].bold, isTrue);
      });

      test('XML comments are ignored', () {
        final result = tryGetRichTextSync('hello <!-- comment --> world');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('hello  world'));
      });

      test('font tag works like span', () {
        final result = tryGetRichTextSync(
          '<font color="red" font-size="18">styled</font>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('styled'));
        expect(result[0].color, equals('red'));
        expect(result[0].fontSize, equals(18.0));
      });

      test('italic tags are parsed but have no effect', () {
        final result = tryGetRichTextSync('normal <i>italic</i> text');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('normal italic text'));
      });

      test('italic tag alias works', () {
        final result1 = tryGetRichTextSync('<italic>text</italic>');
        final result2 = tryGetRichTextSync('<em>text</em>');

        expect(result1, isNotNull);
        expect(result1, hasLength(1));
        expect(result1![0].text, equals('text'));

        expect(result2, isNotNull);
        expect(result2, hasLength(1));
        expect(result2![0].text, equals('text'));
      });

      test('span with text-decoration attribute', () {
        final result = tryGetRichTextSync(
          '<span text-decoration="underline">decorated</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('decorated'));
        expect(result[0].textDecoration, equals('underline'));
      });

      test('span with href attribute', () {
        final result = tryGetRichTextSync(
          '<span href="https://example.com">link</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('link'));
        expect(result[0].link, equals('https://example.com'));
      });

      test('a tag without href has no effect', () {
        final result = tryGetRichTextSync('Click <a>here</a> for more');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('Click here for more'));
        expect(result[0].link, isNull);
      });

      test('unknown tags are treated as containers', () {
        final result = tryGetRichTextSync('hello <custom>world</custom>!');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('hello world!'));
      });

      test('strong tag works like bold', () {
        final result = tryGetRichTextSync('<strong>strong text</strong>');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('strong text'));
        expect(result[0].bold, isTrue);
      });

      test('del tag works like strikethrough', () {
        final result = tryGetRichTextSync('<del>deleted</del>');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('deleted'));
        expect(result[0].textDecoration, equals(kLineThroughTextDecoration));
      });

      test('strike tag works', () {
        final result = tryGetRichTextSync('<strike>struck</strike>');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('struck'));
        expect(result[0].textDecoration, equals(kLineThroughTextDecoration));
      });

      test('strikethrough tag works', () {
        final result =
            tryGetRichTextSync('<strikethrough>struck</strikethrough>');

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].text, equals('struck'));
        expect(result[0].textDecoration, equals(kLineThroughTextDecoration));
      });

      test('camelCase attribute names work', () {
        final result = tryGetRichTextSync(
          '<span backgroundColor="yellow" fontWeight="700" fontSize="14" '
          'fontFamily="Arial" textDecoration="underline">styled</span>',
        );

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result![0].backgroundColor, equals('yellow'));
        expect(result[0].fontWeight, equals(700));
        expect(result[0].fontSize, equals(14.0));
        expect(result[0].fontFamily, equals('Arial'));
        expect(result[0].textDecoration, equals('underline'));
      });
    });
  });

  group('verboseGetRichTextSync', () {
    group('Exception handling', () {
      test('throws RichTextException for unclosed tag', () async {
        RichTextException? caught;
        try {
          await verboseGetRichText('<bold>hello');
        } on RichTextException catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
        expect(caught!.message, contains('Invalid XML tag'));
      });

      test('throws RichTextException with message for invalid XML', () async {
        try {
          await verboseGetRichText('<bold>hello');
          fail('Expected RichTextException');
        } on RichTextException catch (e) {
          expect(e.message, contains('Invalid XML tag'));
          expect(e.cause, isNotNull);
        }
      });

      test('throws RichTextException for mismatched tags', () async {
        RichTextException? caught;
        try {
          await verboseGetRichText('<bold>hello</b>');
        } on RichTextException catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
        expect(caught!.message, contains('Invalid XML tag'));
      });

      test('throws RichTextException for malformed XML', () async {
        RichTextException? caught;
        try {
          await verboseGetRichText('<bold attr=>hello</bold>');
        } on RichTextException catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
        expect(caught!.message, contains('Failed to parse XML'));
      });
    });

    group('Unrecognized tags', () {
      test('reports unrecognized tag in descriptor', () async {
        final result = await verboseGetRichText('<hi>hello dart</hi>');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello dart'));
        expect(result[0].descriptor.unrecognizedTag, equals('hi'));
        expect(result[0].descriptor.hasIssues, isTrue);
      });

      test('reports unrecognized tag with no unrecognized attributes',
          () async {
        final result = await verboseGetRichText('<custom>text</custom>');

        expect(result, hasLength(1));
        expect(result[0].descriptor.unrecognizedTag, equals('custom'));
        expect(result[0].descriptor.unrecognizedAttributes, isEmpty);
      });

      test('multiple unrecognized tags create separate items', () async {
        final result =
            await verboseGetRichText('<foo>hello</foo><bar>world</bar>');

        expect(result, hasLength(2));
        expect(result[0].descriptor.unrecognizedTag, equals('foo'));
        expect(result[1].descriptor.unrecognizedTag, equals('bar'));
      });
    });

    group('Unrecognized attributes', () {
      test('reports unrecognized attribute on bold tag', () async {
        final result =
            await verboseGetRichText('<bold color="red">hello dart</bold>');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello dart'));
        expect(result[0].bold, isTrue);
        expect(result[0].descriptor.unrecognizedTag, isNull);
        expect(result[0].descriptor.unrecognizedAttributes, contains('color'));
        expect(result[0].descriptor.hasIssues, isTrue);
      });

      test('reports unrecognized attribute on strike tag', () async {
        final result =
            await verboseGetRichText('<strike color="red">hello dart</strike>');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello dart'));
        expect(result[0].descriptor.unrecognizedTag, isNull);
        expect(result[0].descriptor.unrecognizedAttributes, contains('color'));
        expect(result[0].descriptor.hasIssues, isTrue);
      });

      test('reports unrecognized attribute on italic tag', () async {
        final result =
            await verboseGetRichText('<italic color="red">hello dart</italic>');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello dart'));
        expect(result[0].descriptor.unrecognizedTag, isNull);
        expect(result[0].descriptor.unrecognizedAttributes, contains('color'));
        expect(result[0].descriptor.hasIssues, isTrue);
      });

      test('reports multiple unrecognized attributes', () async {
        final result = await verboseGetRichText(
          '<bold foo="1" bar="2">text</bold>',
        );

        expect(result, hasLength(1));
        expect(result[0].descriptor.unrecognizedAttributes, contains('foo'));
        expect(result[0].descriptor.unrecognizedAttributes, contains('bar'));
        expect(result[0].descriptor.unrecognizedAttributes, hasLength(2));
      });

      test('does not report recognized attributes on span', () async {
        final result = await verboseGetRichText(
          '<span color="red" font-size="16">styled</span>',
        );

        expect(result, hasLength(1));
        expect(result[0].color, equals('red'));
        expect(result[0].fontSize, equals(16.0));
        expect(result[0].descriptor.isEmpty, isTrue);
      });

      test('reports unrecognized attribute on span with recognized ones',
          () async {
        final result = await verboseGetRichText(
          '<span color="red" unknown="value">styled</span>',
        );

        expect(result, hasLength(1));
        expect(result[0].color, equals('red'));
        expect(
          result[0].descriptor.unrecognizedAttributes,
          contains('unknown'),
        );
        expect(result[0].descriptor.unrecognizedAttributes, hasLength(1));
      });

      test('does not report camelCase versions as unrecognized', () async {
        final result = await verboseGetRichText(
          '<span backgroundColor="yellow" fontWeight="700">text</span>',
        );

        expect(result, hasLength(1));
        expect(result[0].backgroundColor, equals('yellow'));
        expect(result[0].fontWeight, equals(700));
        // camelCase attributes are recognized for span
        expect(result[0].descriptor.unrecognizedAttributes, isEmpty);
      });
    });

    group('Valid parsing', () {
      test('returns empty descriptor for recognized tags', () async {
        final result = await verboseGetRichText('<b>hello</b>');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello'));
        expect(result[0].bold, isTrue);
        expect(result[0].descriptor.isEmpty, isTrue);
      });

      test('empty string returns empty list', () async {
        final result = await verboseGetRichText('');
        expect(result, isEmpty);
      });

      test('plain text has empty descriptor', () async {
        final result = await verboseGetRichText('hello world');

        expect(result, hasLength(1));
        expect(result[0].text, equals('hello world'));
        expect(result[0].descriptor.isEmpty, isTrue);
      });

      test('nested tags work correctly', () async {
        final result = await verboseGetRichText('<b>bold <u>underline</u></b>');

        expect(result, hasLength(2));
        expect(result[0].text, equals('bold '));
        expect(result[0].bold, isTrue);
        expect(result[0].descriptor.isEmpty, isTrue);

        expect(result[1].text, equals('underline'));
        expect(result[1].bold, isTrue);
        expect(
          result[1].textDecoration,
          equals(kUnderlineTextDecoration),
        );
        expect(result[1].descriptor.isEmpty, isTrue);
      });

      test('merges consecutive segments with same style and descriptor',
          () async {
        // Two consecutive tags with same style and descriptor should be merged
        final result = await verboseGetRichText('<b>hello</b><b>there</b>');

        expect(result, hasLength(1));
        // "hello" and "there" should be merged into one item
        // because they have the same style (bold) and descriptor (empty)
        expect(result[0].text, equals('hellothere'));
        expect(result[0].bold, isTrue);
        expect(result[0].textDecoration, isNull);
        expect(result[0].descriptor.isEmpty, isTrue);
      });

      test('a tag with href has empty descriptor', () async {
        final result = await verboseGetRichText(
          '<a href="https://example.com">link</a>',
        );

        expect(result, hasLength(1));
        expect(result[0].link, equals('https://example.com'));
        expect(result[0].descriptor.isEmpty, isTrue);
      });

      test('a tag with unrecognized attribute reports it', () async {
        final result = await verboseGetRichText(
          '<a href="https://example.com" target="_blank">link</a>',
        );

        expect(result, hasLength(1));
        expect(result[0].link, equals('https://example.com'));
        expect(result[0].descriptor.unrecognizedAttributes, contains('target'));
      });
    });

    group('RichTextItemDescriptor', () {
      test('empty descriptor has no issues', () async {
        const descriptor = RichTextItemDescriptor.empty;
        expect(descriptor.isEmpty, isTrue);
        expect(descriptor.hasIssues, isFalse);
      });

      test('descriptor with unrecognized tag has issues', () async {
        const descriptor = RichTextItemDescriptor(unrecognizedTag: 'foo');
        expect(descriptor.hasIssues, isTrue);
        expect(descriptor.isEmpty, isFalse);
      });

      test('descriptor with unrecognized attributes has issues', () async {
        const descriptor = RichTextItemDescriptor(
          unrecognizedAttributes: ['foo', 'bar'],
        );
        expect(descriptor.hasIssues, isTrue);
      });

      test('descriptor equality works', () async {
        const d1 = RichTextItemDescriptor(
          unrecognizedTag: 'foo',
          unrecognizedAttributes: ['bar'],
        );
        const d2 = RichTextItemDescriptor(
          unrecognizedTag: 'foo',
          unrecognizedAttributes: ['bar'],
        );
        const d3 = RichTextItemDescriptor(unrecognizedTag: 'foo');
        const d4 = RichTextItemDescriptor(
          unrecognizedTag: 'foo',
          unrecognizedAttributes: ['baz'],
        );

        expect(d1, equals(d2));
        expect(d1, isNot(equals(d3)));
        expect(d1, isNot(equals(d4)));
      });

      test('descriptor toString works', () async {
        const descriptor = RichTextItemDescriptor(
          unrecognizedTag: 'foo',
          unrecognizedAttributes: ['bar'],
        );
        final str = descriptor.toString();
        expect(str, contains('unrecognizedTag: foo'));
        expect(str, contains('unrecognizedAttributes'));
      });

      test('empty descriptor toString', () {
        expect(
          RichTextItemDescriptor.empty.toString(),
          equals('RichTextItemDescriptor.empty'),
        );
      });
    });

    group('RichTextException', () {
      test('toString without cause', () {
        const e = RichTextException('test message');
        expect(e.toString(), equals('RichTextException: test message'));
      });

      test('toString with cause', () {
        final e = RichTextException('test message', cause: Exception('cause'));
        expect(e.toString(), contains('test message'));
        expect(e.toString(), contains('caused by'));
      });
    });

    group('VerboseRichTextItem', () {
      test('equality works', () {
        final item1 = VerboseRichTextItem(
          text: 'hello',
        );
        final item2 = VerboseRichTextItem(text: 'hello');
        final item3 = VerboseRichTextItem(text: 'world');

        expect(item1, equals(item2));
        expect(item1, isNot(equals(item3)));
      });

      test('identical check in equality', () {
        final item = VerboseRichTextItem(
          text: 'hello',
        );
        expect(item == item, isTrue);
      });

      test('equality works with different types', () {
        final item = VerboseRichTextItem(
          text: 'hello',
        );
        // ignore: unrelated_type_equality_checks for test purposes
        expect(item == 'VerboseRichTextItem', isFalse);
      });

      test('hashCode is consistent', () {
        final item1 = VerboseRichTextItem(
          text: 'hello',
        );
        final item2 = VerboseRichTextItem(
          text: 'hello',
        );

        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('toString works', () {
        final item = VerboseRichTextItem(
          text: 'hello',
        );
        final str = item.toString();
        expect(str, contains('VerboseRichTextItem'));
        expect(str, contains('hello'));
      });
    });
  });
}
