# rich_i18n_cli

[![package badge][package_badge]][pub_link]
[![pub points][pub_points_badge]][pub_link]
[![pub likes][pub_likes_badge]][pub_link]
[![codecov][codecov_badge]][codecov_link]
[![ci badge][ci_badge]][ci_link]
[![license][license_badge]][license_link]
[![pub publisher][pub_publisher_badge]][pub_publisher_link]

A CLI tool for verifying [rich i18n text](https://pub.dev/packages/rich_i18n) in ARB translation files and generating error reports.

## Installation

```sh
dart pub global activate rich_i18n_cli
```

## Usage

```sh
# verify rich i18n using l10n.yaml configuration file and saving report to "text_rich_i18n_styled_error" file
rich_i18n_cli verify

# verify rich i18n using arb-dir directory and saving report to "text_rich_i18n_styled_error" file
rich_i18n_cli verify --arb-dir my_arb_dir

# verify rich i18n using arb-dir directory and saving report to "report.txt" file
rich_i18n_cli verify --arb-dir my_arb_dir --output report.txt

# more info about usage
rich_i18n_cli verify --help
```

## verify

### output

The `verify` command generates a report file containing statistics and errors for each ARB file analyzed. The report structure includes:

- `validKeys`: Number of translation keys that passed validation
- `invalidKeys`: Number of translation keys with errors
- `errors`: Object mapping translation keys to their error messages

### Example

Given an ARB file (`arb/en.arb`):

```json
{
    "title": "Hello <b>World</b>!",
    "description": "Malformed <b>text", // tag is not closed
    "body": "Unrecognized <foo>tag</foo>" // foo is not a valid tag in rich_text
}
```

The generated report will be:

```json
{
  "./arb/en.arb": {
    "validKeys": 1,
    "invalidKeys": 2,
    "errors": {
      "description": "Invalid XML tag: Expected </b>, but found </root>",
      "body": "Unrecognized tag: foo"
    }
  }
}
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[package_badge]: https://img.shields.io/pub/v/rich_i18n_cli.svg
[codecov_badge]: https://img.shields.io/codecov/c/github/MattiaPispisa/rich_i18n/main?flag=rich_i18n_cli&logo=codecov
[codecov_link]: https://app.codecov.io/gh/MattiaPispisa/rich_i18n/tree/main/rich_i18n_cli
[ci_badge]: https://img.shields.io/github/actions/workflow/status/MattiaPispisa/rich_i18n/main.yaml
[ci_link]: https://github.com/MattiaPispisa/rich_i18n/actions/workflows/main.yaml
[pub_points_badge]: https://img.shields.io/pub/points/rich_i18n_cli
[pub_link]: https://pub.dev/packages/rich_i18n_cli
[pub_publisher_badge]: https://img.shields.io/pub/publisher/rich_i18n_cli
[pub_publisher_link]: https://pub.dev/packages?q=publisher%3Amattiapispisa.it
[pub_likes_badge]: https://img.shields.io/pub/likes/rich_i18n_cli
