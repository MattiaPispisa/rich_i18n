# rich_i18n

A Dart library for parsing rich text with XML tags into structured items.


## Installation

```yaml
dependencies:
  rich_i18n: ^0.1.0
```

## Usage

### Basic Example

```dart
import 'package:rich_i18n/rich_i18n.dart';

final items = getRichText('Hello <b>World</b>!');
// Result:
// [
//   RichTextItem(text: 'Hello '),
//   RichTextItem(text: 'World', fontWeight: 700),
//   RichTextItem(text: '!'),
// ]
```

### Nested Tags

```dart
final items = getRichText('Hello <b>bold and <u>underline</u></b>!');
// Result:
// [
//   RichTextItem(text: 'Hello '),
//   RichTextItem(text: 'bold and ', fontWeight: 700),
//   RichTextItem(text: 'underline', fontWeight: 700, textDecoration: 'underline'),
//   RichTextItem(text: '!'),
// ]
```

### All Supported Tags

See the full list of supported tags in the [getRichText API documentation](https://pub.dev/documentation/rich_i18n/latest/rich_i18n/getRichText.html).

### Span Attributes

```dart
final items = getRichText('''
  <span 
    color="#FF0000" 
    background-color="yellow"
    >
    Styled text
  </span>
''');
```

See the full list of supported attributes in the [getRichText API documentation](https://pub.dev/documentation/rich_i18n/latest/rich_i18n/getRichText.html).

## Error Handling

If the input contains invalid XML, the original text is returned as a single `RichTextItem`:

```dart
final items = getRichText('Invalid <b>XML');
// Result: [RichTextItem(text: 'Invalid <b>XML')]
```

## Performance

- `RichTextItem` caches its `hashCode` at construction time for efficient use in collections
- Consecutive text segments with the same style are automatically merged
- Empty tags are ignored (no unnecessary items created)

## Why not Flutter?

This library is intentionally **framework-agnostic** and has no Flutter dependency:

- **No version constraints**: Your app won't have conflicts with Flutter SDK versions
- **No custom widgets to maintain**: You don't need to import and maintain a third-party widget in your codebase
- **Maximum flexibility**: Convert to `TextSpan`, HTML, or any other format you need
- **Pure Dart**: Can be used in CLI tools, servers, or any Dart project
