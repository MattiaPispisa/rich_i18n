import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:rich_i18n/rich_i18n.dart';
import 'package:yaml/yaml.dart';

/// {@template verify_command}
/// A command which verifies rich i18n text in ARB files.
/// {@endtemplate}
class VerifyCommand extends Command<int> {
  /// {@macro verify_command}
  VerifyCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'arb-dir',
        help: 'Directory containing ARB files (if l10n.yaml not found)',
        valueHelp: 'path',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file for error report '
            '(default: text_rich_i18n_styled_error)',
        defaultsTo: 'text_rich_i18n_styled_error',
      );
  }

  final Logger _logger;

  @override
  String get description => 'Verify rich i18n text in ARB translation files '
      'and generate error report.';

  static const String commandName = 'verify';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final arbDir = argResults?['arb-dir'] as String?;
    final outputFile =
        argResults?['output'] as String? ?? 'text_rich_i18n_styled_error';

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
    final errors = <ArbError>[];
    final progress = _logger.progress('Verifying ARB files');

    for (final arbFile in arbFiles) {
      try {
        final fileErrors = await _verifyArbFile(arbFile);
        errors.addAll(fileErrors);
      } on Exception catch (e) {
        _logger.err('Error processing $arbFile: $e');
        errors.add(
          ArbError(
            file: arbFile,
            key: null,
            error: 'Failed to process file: $e',
            errorType: ArbErrorType.fileError,
          ),
        );
      }
    }

    progress.complete('Verified ${arbFiles.length} ARB file(s)');

    // Generate report
    if (errors.isEmpty) {
      _logger.info('✓ No errors found in ARB files');
      // Still create an empty report file
      await _writeReport(outputFile, errors);
      return ExitCode.success.code;
    }

    _logger.warn('✗ Found ${errors.length} error(s)');

    try {
      await _writeReport(outputFile, errors);
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
      if (!await dir.exists()) {
        throw Exception('Directory does not exist: $arbDir');
      }
      return _findArbFilesInDirectory(dir);
    }

    // Try to find l10n.yaml in current directory
    final l10nYaml = File('l10n.yaml');
    if (await l10nYaml.exists()) {
      return _findArbFilesFromL10nYaml(l10nYaml);
    }

    // Fallback: search in common locations
    final commonLocations = ['lib/l10n', 'lib/l10n/app_*.arb', 'l10n'];
    for (final location in commonLocations) {
      final dir = Directory(location);
      if (await dir.exists()) {
        final files = await _findArbFilesInDirectory(dir);
        if (files.isNotEmpty) {
          return files;
        }
      }
    }

    throw Exception(
      'No ARB files found. Please specify --arb-dir or ensure l10n.yaml exists.',
    );
  }

  /// Finds ARB files from l10n.yaml configuration.
  Future<List<String>> _findArbFilesFromL10nYaml(File l10nYaml) async {
    try {
      final content = await l10nYaml.readAsString();
      final yaml = loadYaml(content) as Map;

      // Extract arb-dir from l10n.yaml
      final arbDir = yaml['arb-dir'] as String? ?? 'lib/l10n';

      // Resolve paths relative to l10n.yaml location
      final l10nYamlDir = path.dirname(l10nYaml.path);
      final resolvedArbDir = path.normalize(path.join(l10nYamlDir, arbDir));

      final dir = Directory(resolvedArbDir);
      if (!await dir.exists()) {
        throw Exception(
            'ARB directory from l10n.yaml does not exist: $resolvedArbDir');
      }

      final files = await _findArbFilesInDirectory(dir);
      if (files.isEmpty) {
        throw Exception('No ARB files found in directory: $resolvedArbDir');
      }

      return files;
    } on YamlException catch (e) {
      throw Exception('Error parsing YAML: $e');
    } on FormatException catch (e) {
      throw Exception('Error parsing l10n.yaml: $e');
    } on Exception catch (e) {
      throw Exception('Error reading l10n.yaml: $e');
    }
  }

  /// Finds all .arb files in a directory recursively.
  Future<List<String>> _findArbFilesInDirectory(Directory dir) async {
    final files = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.arb')) {
        files.add(entity.path);
      }
    }
    return files;
  }

  /// Verifies a single ARB file and returns any errors found.
  Future<List<ArbError>> _verifyArbFile(String arbFile) async {
    final errors = <ArbError>[];

    try {
      final file = File(arbFile);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Process each key-value pair in the ARB file
      for (final entry in json.entries) {
        final key = entry.key;
        final value = entry.value;

        // Skip metadata keys (start with @)
        if (key.startsWith('@')) {
          continue;
        }

        // Only process string values
        if (value is String) {
          try {
            final items = await verboseGetRichText(value);

            // Check for issues in descriptors
            for (final item in items) {
              if (item.descriptor.hasIssues) {
                final issues = <String>[];

                if (item.descriptor.unrecognizedTag != null) {
                  issues.add(
                    'Unrecognized tag: ${item.descriptor.unrecognizedTag}',
                  );
                }

                if (item.descriptor.unrecognizedAttributes.isNotEmpty) {
                  issues.add(
                    'Unrecognized attributes: '
                    '${item.descriptor.unrecognizedAttributes.join(", ")}',
                  );
                }

                errors.add(
                  ArbError(
                    file: arbFile,
                    key: key,
                    error: issues.join('; '),
                    errorType: ArbErrorType.descriptorIssue,
                    text: item.text,
                  ),
                );
              }
            }
          } on RichTextException catch (e) {
            errors.add(
              ArbError(
                file: arbFile,
                key: key,
                error: e.message,
                errorType: ArbErrorType.parsingException,
                cause: e.cause?.toString(),
              ),
            );
          } on FormatException catch (e) {
            errors.add(
              ArbError(
                file: arbFile,
                key: key,
                error: 'JSON parsing error: $e',
                errorType: ArbErrorType.fileError,
              ),
            );
          }
        }
      }
    } on FormatException catch (e) {
      errors.add(
        ArbError(
          file: arbFile,
          key: null,
          error: 'Failed to parse ARB file (JSON): $e',
          errorType: ArbErrorType.fileError,
        ),
      );
    } on IOException catch (e) {
      errors.add(
        ArbError(
          file: arbFile,
          key: null,
          error: 'Failed to read ARB file: $e',
          errorType: ArbErrorType.fileError,
        ),
      );
    }

    return errors;
  }

  /// Writes the error report to a file.
  Future<void> _writeReport(
    String outputFile,
    List<ArbError> errors,
  ) async {
    final file = File(outputFile);
    final buffer = StringBuffer();

    buffer
      ..writeln('# Rich I18n Styled Text Error Report')
      ..writeln('# Generated by rich_i18n_cli verify command')
      ..writeln('#')
      ..writeln('# This file lists all errors found when verifying rich text')
      ..writeln('# in ARB translation files.')
      ..writeln('')
      ..writeln('Total errors: ${errors.length}')
      ..writeln('');

    if (errors.isEmpty) {
      buffer.writeln('No errors found. All rich text strings are valid.');
    } else {
      // Group errors by file
      final errorsByFile = <String, List<ArbError>>{};
      for (final error in errors) {
        errorsByFile.putIfAbsent(error.file, () => []).add(error);
      }

      for (final entry in errorsByFile.entries) {
        buffer
          ..writeln('## File: ${entry.key}')
          ..writeln('');

        for (final error in entry.value) {
          buffer
            ..writeln('### Key: ${error.key ?? "(file-level error)"}')
            ..writeln('**Error Type:** ${error.errorType.name}')
            ..writeln('**Error:** ${error.error}');

          if (error.text != null) {
            buffer.writeln('**Text:** ${error.text}');
          }

          if (error.cause != null) {
            buffer.writeln('**Cause:** ${error.cause}');
          }

          buffer.writeln('');
        }
        buffer.writeln('');
      }
    }

    await file.writeAsString(buffer.toString());
  }
}

/// Represents an error found in an ARB file.
class ArbError {
  /// Creates a new [ArbError].
  const ArbError({
    required this.file,
    required this.key,
    required this.error,
    required this.errorType,
    this.text,
    this.cause,
  });

  /// The ARB file where the error was found.
  final String file;

  /// The translation key where the error was found (null for file-level errors).
  final String? key;

  /// The error message.
  final String error;

  /// The type of error.
  final ArbErrorType errorType;

  /// The text content that caused the error (if applicable).
  final String? text;

  /// The underlying cause of the error (if applicable).
  final String? cause;
}

/// Types of errors that can occur during verification.
enum ArbErrorType {
  /// Parsing exception (invalid XML).
  parsingException,

  /// Issues found in descriptor (unrecognized tags/attributes).
  descriptorIssue,

  /// File-level error (could not read/parse file).
  fileError,

  /// Unknown/unexpected error.
  unknownError,
}
