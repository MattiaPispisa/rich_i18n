# rich_i18n

[![package badge][package_badge]][pub_link]
[![pub points][pub_points_badge]][pub_link]
[![pub likes][pub_likes_badge]][pub_link]
[![codecov][codecov_badge]][codecov_link]
[![ci badge][ci_badge]][ci_link]
[![license][license_badge]][license_link]
[![pub publisher][pub_publisher_badge]][pub_publisher_link]


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

final items = tryGetRichTextSync('Hello <b>World</b>!');
// Result:
// [
//   RichTextItem(text: 'Hello '),
//   RichTextItem(text: 'World', fontWeight: 700),
//   RichTextItem(text: '!'),
// ]
```

### Nested Tags

```dart
final items = tryGetRichTextSync('Hello <b>bold and <u>underline</u></b>!');
// Result:
// [
//   RichTextItem(text: 'Hello '),
//   RichTextItem(text: 'bold and ', fontWeight: 700),
//   RichTextItem(text: 'underline', fontWeight: 700, textDecoration: 'underline'),
//   RichTextItem(text: '!'),
// ]
```

### All Supported Tags

See the full list of supported tags in the [tryGetRichTextSync API documentation](https://pub.dev/documentation/rich_i18n/latest/rich_i18n/tryGetRichTextSync.html).

### Span Attributes

```dart
final items = tryGetRichTextSync('''
  <span 
    color="#FF0000" 
    background-color="yellow"
    >
    Styled text
  </span>
''');
```

See the full list of supported attributes in the [tryGetRichTextSync API documentation](https://pub.dev/documentation/rich_i18n/latest/rich_i18n/tryGetRichTextSync.html).

## Error Handling

If the input contains invalid XML, the original text is returned as a single `RichTextItem`:

```dart
final items = tryGetRichTextSync('Invalid <b>XML');
// Result: [RichTextItem(text: 'Invalid <b>XML')]
```

## Performance

- `RichTextItem` caches its `hashCode` at construction time for efficient use in collections
- Consecutive text segments with the same style are automatically merged
- Empty tags are ignored (no unnecessary items created)

## Flutter Example

A complete Flutter example app is available in the `flutter_example` directory,
demonstrating how to convert the parsed `RichTextItem` objects into Flutter's
`TextSpan` widgets for rendering rich text in Flutter applications.

The example includes an interactive editor where you can:
- Edit XML source with rich text tags
- See the rendered preview in real-time
- Test various formatting options (bold, underline, colors, links, etc.)

<img width="500" alt="rich_text_flutter_example" src="https://raw.githubusercontent.com/MattiaPispisa/rich_i18n/main/assets/rich_text_flutter_example.png">

## Why not Flutter?

This library is intentionally **framework-agnostic** and has no Flutter dependency:

- **No version constraints**: Your app won't have conflicts with Flutter SDK versions
- **No custom widgets to maintain**: You don't need to import and maintain a third-party widget in your codebase
- **Maximum flexibility**: Convert to `TextSpan`, HTML, or any other format you need
- **Pure Dart**: Can be used in CLI tools, servers, or any Dart project


[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[package_badge]: https://img.shields.io/pub/v/rich_i18n.svg
[codecov_badge]: https://img.shields.io/codecov/c/github/MattiaPispisa/rich_i18n/main?flag=rich_i18n&logo=codecov
[codecov_link]: https://app.codecov.io/gh/MattiaPispisa/rich_i18n/tree/main/packages/rich_i18n
[ci_badge]: https://img.shields.io/github/actions/workflow/status/MattiaPispisa/rich_i18n/main.yaml
[ci_link]: https://github.com/MattiaPispisa/rich_i18n/actions/workflows/main.yaml
[pub_points_badge]: https://img.shields.io/pub/points/rich_i18n
[pub_link]: https://pub.dev/packages/rich_i18n
[pub_publisher_badge]: https://img.shields.io/pub/publisher/rich_i18n
[pub_publisher_link]: https://pub.dev/packages?q=publisher%3Amattiapispisa.it
[pub_likes_badge]: https://img.shields.io/pub/likes/rich_i18n
