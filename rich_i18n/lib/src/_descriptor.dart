import 'package:rich_i18n/rich_i18n.dart';

/// Describes issues found while parsing a rich text item.
///
/// This class is used by [verboseGetRichText] to report:
/// - Unrecognized XML tags
/// - Unrecognized attributes on known tags
class RichTextItemDescriptor {
  /// Creates a new [RichTextItemDescriptor].
  const RichTextItemDescriptor({
    this.unrecognizedTag,
    this.unrecognizedAttributes = const [],
  });

  /// An empty descriptor indicating no issues were found.
  static const empty = RichTextItemDescriptor();

  /// The unrecognized tag name, if any.
  ///
  /// This is `null` if the tag was recognized or if this descriptor
  /// represents plain text (no tag).
  final String? unrecognizedTag;

  /// List of attribute names that were not recognized.
  ///
  /// Empty if all attributes were recognized.
  final List<String> unrecognizedAttributes;

  /// Returns `true` if this descriptor has
  /// any issues (unrecognized tag or attributes).
  bool get hasIssues =>
      unrecognizedTag != null || unrecognizedAttributes.isNotEmpty;

  /// Returns `true` if this descriptor has no issues.
  bool get isEmpty => !hasIssues;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RichTextItemDescriptor) {
      return false;
    }
    if (unrecognizedTag != other.unrecognizedTag) {
      return false;
    }
    if (unrecognizedAttributes.length != other.unrecognizedAttributes.length) {
      return false;
    }
    for (var i = 0; i < unrecognizedAttributes.length; i++) {
      if (unrecognizedAttributes[i] != other.unrecognizedAttributes[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        unrecognizedTag,
        Object.hashAll(unrecognizedAttributes),
      );

  @override
  String toString() {
    if (isEmpty) {
      return 'RichTextItemDescriptor.empty';
    }
    final parts = <String>[];
    if (unrecognizedTag != null) {
      parts.add('unrecognizedTag: $unrecognizedTag');
    }
    if (unrecognizedAttributes.isNotEmpty) {
      parts.add('unrecognizedAttributes: $unrecognizedAttributes');
    }
    return 'RichTextItemDescriptor(${parts.join(', ')})';
  }
}
