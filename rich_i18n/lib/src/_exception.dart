/// Exception thrown when parsing rich text fails.
///
/// This exception wraps the underlying XML parsing errors and provides
/// a user-friendly message describing the parsing failure.
class RichTextException implements Exception {
  /// Creates a new [RichTextException]
  /// with the given message and optional cause.
  const RichTextException(this.message, {this.cause});

  /// A description of the parsing error.
  final String message;

  /// The underlying exception that caused this error, if any.
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'RichTextException: $message (caused by: $cause)';
    }
    return 'RichTextException: $message';
  }
}
