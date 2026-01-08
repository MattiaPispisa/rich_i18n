# rich_i18n

A Dart library for parsing rich text with XML tags into structured items.

## Why not Flutter?

This library is intentionally **framework-agnostic** and has no Flutter dependency:

- **No version constraints**: Your app won't have conflicts with Flutter SDK versions
- **No custom widgets to maintain**: You don't need to import and maintain a third-party widget in your codebase
- **Maximum flexibility**: Convert to `TextSpan`, HTML, or any other format you need
- **Pure Dart**: Can be used in CLI tools, servers, or any Dart project

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

| Tag                         | Description                 | Example                                  |
|-----------------------------|-----------------------------|------------------------------------------|
| `<b>`, `<bold>`, `<strong>` | Bold text (fontWeight: 700) | `<b>bold</b>`                            |
| `<u>`, `<underline>`        | Underlined text             | `<u>underline</u>`                       |
| `<s>`, `<strike>`, `<del>`  | Strikethrough text          | `<s>deleted</s>`                         |
| `<a href="url">`            | Hyperlink                   | `<a href="https://example.com">link</a>` |
| `<span>`                    | Custom styling              | See below                                |

### Span Attributes

```dart
final items = getRichText('''
  <span 
    color="#FF0000" 
    background-color="yellow"
    font-size="18"
    font-weight="500"
    font-family="Roboto">
    Styled text
  </span>
''');
```

Supported attributes:
- `color` - Text color (e.g., "#FF0000", "red")
- `background-color` or `backgroundColor` - Background color
- `font-weight` or `fontWeight` - Font weight (e.g., "400", "700")
- `font-size` or `fontSize` - Font size in pixels
- `font-family` or `fontFamily` - Font family name
- `text-decoration` or `textDecoration` - Text decoration

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