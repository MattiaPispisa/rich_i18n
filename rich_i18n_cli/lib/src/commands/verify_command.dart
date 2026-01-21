import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:rich_i18n/rich_i18n.dart';
import 'package:yaml/yaml.dart';

const _kCommandName = 'verify';
const _kArbExtension = '.arb';
const _kL10nYamlFile = 'l10n.yaml';
const _kDefaultArbDir = 'lib/l10n';
const _kMetadataPrefix = '@';

const _kArgArbDir = 'arb-dir';
const _kArgOutput = 'output';
const _kDefaultOutput = 'text_rich_i18n_styled_error';
const _kYamlArbDirKey = 'arb-dir';

/// {@template verify_command}
/// A command which verifies rich i18n text in ARB files.
/// {@endtemplate}
class VerifyCommand extends Command<int> {
  /// {@macro verify_command}
  VerifyCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        _kArgArbDir,
        help: 'Directory containing ARB files '
            '(defaults to search in $_kL10nYamlFile)',
        valueHelp: 'path',
      )
      ..addOption(
        _kArgOutput,
        abbr: 'o',
        help: 'Output file for error report ',
        defaultsTo: _kDefaultOutput,
      );
  }

  final Logger _logger;

  @override
  String get description => 'Verify rich i18n text in ARB translation files '
      'and generate error report.';

  @override
  String get name => _kCommandName;

  @override
  Future<int> run() async {
    final arbDir = argResults?[_kArgArbDir] as String?;
    final outputFile = argResults?[_kArgOutput] as String? ?? _kDefaultOutput;

    // Find ARB files
    final List<String> arbFiles;
    try {
      arbFiles = await _findArbFiles(arbDir);
    } on Exception catch (e) {
      _logger.err('Error finding ARB files: $e');
      return ExitCode.noInput.code;
    }

    if (arbFiles.isEmpty) {
      _logger.err('No ARB files found.');
      return ExitCode.noInput.code;
    }

    _logger.info('Found ${arbFiles.length} ARB file(s) to verify');

    // Process each ARB file
    final errors = <_ArbError>[];
    final fileStats = <String, _FileStats>{};
    final progress = _logger.progress('Verifying ARB files');

    for (final arbFile in arbFiles) {
      try {
        final result = await _verifyArbFile(arbFile);
        errors.addAll(result.errors);
        fileStats[arbFile] = result.stats;
      } on Exception catch (e) {
        _logger.err('Error processing $arbFile: $e');
        errors.add(
          _ArbError(
            file: arbFile,
            key: null,
            error: 'Failed to process file: $e',
            errorType: _ArbErrorType.fileError,
          ),
        );
        // For file-level errors, we don't have stats
        fileStats[arbFile] = const _FileStats(
          validKeys: 0,
          invalidKeys: 0,
        );
      }
    }

    progress.complete('Verified ${arbFiles.length} ARB file(s)');

    // Generate report
    if (errors.isEmpty) {
      _logger.info('✓ No errors found in ARB files');
      await _writeReport(outputFile, errors, fileStats);
      return ExitCode.success.code;
    }

    _logger.warn('✗ Found ${errors.length} error(s)');

    try {
      await _writeReport(outputFile, errors, fileStats);
      _logger.info('Error report written to: $outputFile');
      return ExitCode.config.code;
    } on Exception catch (e) {
      _logger.err('Error writing report: $e');
      return ExitCode.ioError.code;
    }
  }

  /// Finds ARB files either from l10n.yaml or provided directory.
  Future<List<String>> _findArbFiles(String? arbDir) async {
    if (arbDir != null) {
      final dir = Directory(arbDir);
      if (!dir.existsSync()) {
        throw Exception('Directory does not exist: $arbDir');
      }
      return _findArbFilesInDirectory(dir);
    }

    // Try to find l10n.yaml in current directory
    final l10nYaml = File(_kL10nYamlFile);
    if (l10nYaml.existsSync()) {
      return _findArbFilesFromL10nYaml(l10nYaml);
    }

    // Fallback: search in common locations
    final commonLocations = [
      _kDefaultArbDir,
      '$_kDefaultArbDir/app_*$_kArbExtension',
      'l10n',
    ];
    for (final location in commonLocations) {
      final dir = Directory(location);
      if (dir.existsSync()) {
        final files = await _findArbFilesInDirectory(dir);
        if (files.isNotEmpty) {
          return files;
        }
      }
    }

    throw Exception(
      'No ARB files found. Please specify --$_kArgArbDir'
      ' or ensure $_kL10nYamlFile exists.',
    );
  }

  /// Finds ARB files from l10n.yaml configuration.
  Future<List<String>> _findArbFilesFromL10nYaml(File l10nYaml) async {
    try {
      final content = await l10nYaml.readAsString();
      final yaml = loadYaml(content) as Map;

      // Extract arb-dir from l10n.yaml
      final arbDir = yaml[_kYamlArbDirKey] as String? ?? _kDefaultArbDir;

      // Resolve paths relative to l10n.yaml location
      final l10nYamlDir = path.dirname(l10nYaml.path);
      final resolvedArbDir = path.normalize(path.join(l10nYamlDir, arbDir));

      final dir = Directory(resolvedArbDir);
      if (!dir.existsSync()) {
        throw Exception(
          'ARB directory from $_kL10nYamlFile does not exist: $resolvedArbDir',
        );
      }

      final files = await _findArbFilesInDirectory(dir);
      if (files.isEmpty) {
        throw Exception('No ARB files found in directory: $resolvedArbDir');
      }

      return files;
    } on YamlException catch (e) {
      throw Exception('Error parsing YAML: $e');
    } on FormatException catch (e) {
      throw Exception('Error parsing $_kL10nYamlFile: $e');
    } on Exception catch (e) {
      throw Exception('Error reading $_kL10nYamlFile: $e');
    }
  }

  /// Finds all .arb files in a directory recursively.
  Future<List<String>> _findArbFilesInDirectory(Directory dir) async {
    final files = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(_kArbExtension)) {
        files.add(entity.path);
      }
    }
    return files;
  }

  /// Verifies a single ARB file and returns any errors found.
  Future<_VerifyResult> _verifyArbFile(String arbFile) async {
    final errors = <_ArbError>[];
    var validKeys = 0;
    var invalidKeys = 0;

    try {
      final file = File(arbFile);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      for (final entry in json.entries) {
        final result = await _validateArbEntry(
          key: entry.key,
          value: entry.value,
          arbFile: arbFile,
        );

        if (result.isIgnored) continue;

        if (result.isValid) {
          validKeys++;
        } else {
          invalidKeys++;
          errors.addAll(result.errors);
        }
      }
    } on FormatException catch (e) {
      errors.add(
        _ArbError(
          file: arbFile,
          key: null,
          error: 'Failed to parse ARB file (JSON): $e',
          errorType: _ArbErrorType.fileError,
        ),
      );
    } on IOException catch (e) {
      errors.add(
        _ArbError(
          file: arbFile,
          key: null,
          error: 'Failed to read ARB file: $e',
          errorType: _ArbErrorType.fileError,
        ),
      );
    }

    return _VerifyResult(
      errors: errors,
      stats: _FileStats(validKeys: validKeys, invalidKeys: invalidKeys),
    );
  }

  /// Validates a single ARB entry using early returns to avoid nesting.
  Future<_EntryResult> _validateArbEntry({
    required String key,
    required dynamic value,
    required String arbFile,
  }) async {
    // 1. Check for metadata keys (Ignored)
    if (key.startsWith(_kMetadataPrefix)) {
      return _EntryResult.ignored();
    }

    // 2. Check for non-string values
    // (Considered Valid but skipped for processing)
    if (value is! String) {
      return _EntryResult.valid();
    }

    // 3. Process Rich Text String
    try {
      final items = await verboseGetRichText(value);
      final entryErrors = <_ArbError>[];

      for (final item in items) {
        if (item.descriptor.hasIssues) {
          final issues = <String>[];

          if (item.descriptor.unrecognizedTag != null) {
            issues.add('Unrecognized tag: ${item.descriptor.unrecognizedTag}');
          }

          if (item.descriptor.unrecognizedAttributes.isNotEmpty) {
            final attrs = item.descriptor.unrecognizedAttributes.join(', ');
            issues.add('Unrecognized attributes: $attrs');
          }

          entryErrors.add(
            _ArbError(
              file: arbFile,
              key: key,
              error: issues.join('; '),
              errorType: _ArbErrorType.descriptorIssue,
              text: item.text,
            ),
          );
        }
      }

      if (entryErrors.isNotEmpty) {
        return _EntryResult.invalid(entryErrors);
      }

      return _EntryResult.valid();
    } on RichTextException catch (e) {
      return _EntryResult.invalid(
        [
          _ArbError(
            file: arbFile,
            key: key,
            error: e.message,
            errorType: _ArbErrorType.parsingException,
            cause: e.cause?.toString(),
          ),
        ],
      );
    } on FormatException catch (e) {
      return _EntryResult.invalid(
        [
          _ArbError(
            file: arbFile,
            key: key,
            error: 'JSON parsing error: $e',
            errorType: _ArbErrorType.fileError,
          ),
        ],
      );
    }
  }

  /// Writes the error report to a file in JSON format.
  Future<void> _writeReport(
    String outputFile,
    List<_ArbError> errors,
    Map<String, _FileStats> fileStats,
  ) async {
    final file = File(outputFile);
    final report = <String, dynamic>{};

    // Group errors by file
    final errorsByFile = <String, List<_ArbError>>{};
    for (final error in errors) {
      errorsByFile.putIfAbsent(error.file, () => []).add(error);
    }

    // Build report for each file
    for (final entry in errorsByFile.entries) {
      final filePath = entry.key;
      final fileErrors = entry.value;
      final stats = fileStats[filePath] ??
          const _FileStats(
            validKeys: 0,
            invalidKeys: 0,
          );

      // Build errors object (key -> error message)
      final errorsMap = <String, String>{};
      for (final error in fileErrors) {
        if (error.key != null) {
          errorsMap[error.key!] = error.error;
        }
      }

      report[filePath] = {
        'validKeys': stats.validKeys,
        'invalidKeys': stats.invalidKeys,
        'errors': errorsMap,
      };
    }

    // Include files with no errors but with stats
    for (final entry in fileStats.entries) {
      if (!report.containsKey(entry.key)) {
        report[entry.key] = {
          'validKeys': entry.value.validKeys,
          'invalidKeys': entry.value.invalidKeys,
          'errors': <String, String>{},
        };
      }
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(report);
    await file.writeAsString(jsonString);
  }
}

/// Represents an error found in an ARB file.
class _ArbError {
  /// Creates a new [_ArbError].
  const _ArbError({
    required this.file,
    required this.key,
    required this.error,
    required this.errorType,
    this.text,
    this.cause,
  });

  /// The ARB file where the error was found.
  final String file;

  /// The translation key where the error was found
  /// (null for file-level errors).
  final String? key;

  /// The error message.
  final String error;

  /// The type of error.
  final _ArbErrorType errorType;

  /// The text content that caused the error (if applicable).
  final String? text;

  /// The underlying cause of the error (if applicable).
  final String? cause;
}

/// Types of errors that can occur during verification.
enum _ArbErrorType {
  /// Parsing exception (invalid XML).
  parsingException,

  /// Issues found in descriptor (unrecognized tags/attributes).
  descriptorIssue,

  /// File-level error (could not read/parse file).
  fileError,
}

/// Statistics for a single ARB file.
class _FileStats {
  /// Creates a new [_FileStats].
  const _FileStats({
    required this.validKeys,
    required this.invalidKeys,
  });

  /// Number of valid translation keys.
  final int validKeys;

  /// Number of invalid translation keys.
  final int invalidKeys;
}

/// Result of verifying an ARB file.
class _VerifyResult {
  _VerifyResult({
    required this.errors,
    required this.stats,
  });

  final List<_ArbError> errors;
  final _FileStats stats;
}

/// Helper class to handle the result of a single entry validation
class _EntryResult {
  const _EntryResult({
    this.isValid = false,
    this.isIgnored = false,
    this.errors = const [],
  });

  factory _EntryResult.valid() => const _EntryResult(isValid: true);
  factory _EntryResult.ignored() => const _EntryResult(isIgnored: true);
  factory _EntryResult.invalid(List<_ArbError> errors) =>
      _EntryResult(errors: errors);

  final bool isValid;
  final bool isIgnored;
  final List<_ArbError> errors;
}
