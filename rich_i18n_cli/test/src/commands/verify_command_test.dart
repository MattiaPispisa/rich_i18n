import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:rich_i18n_cli/src/command_runner.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

/// When "verify" command is run without a specific directory,
/// it will use the current directory.
Future<void> _doInDirectory(
  Directory directory,
  Future<void> Function() test,
) async {
  final originalDir = Directory.current;
  Directory.current = directory;
  try {
    await test();
  } finally {
    Directory.current = originalDir;
  }
}

void main() {
  group('verify', () {
    late Logger logger;
    late RichI18nCliCommandRunner commandRunner;
    late Directory tempDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = RichI18nCliCommandRunner(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('verify_test_');
      final progress = _MockProgress();

      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      final reportFile = File('text_rich_i18n_styled_error');
      if (reportFile.existsSync()) {
        reportFile.deleteSync();
      }
    });

    // -------------------------------------------------------------------------
    // 1. Configuration & Discovery
    // Tests related to finding files, checking directories, and parsing config.
    // -------------------------------------------------------------------------
    group('Configuration & Discovery', () {
      test('should fail when no ARB files found', () async {
        final exitCode = await commandRunner.run(['verify']);

        expect(exitCode, ExitCode.noInput.code);
        verify(
          () => logger.err(
            any(that: contains('No ARB files found')),
          ),
        ).called(1);
      });

      test('should fail when arb-dir is empty', () async {
        final emptyDir = Directory(path.join(tempDir.path, 'empty'))
          ..createSync(recursive: true);

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          emptyDir.path,
        ]);

        expect(exitCode, ExitCode.noInput.code);
        verify(
          () => logger.err(
            any(that: contains('No ARB files found')),
          ),
        ).called(1);
      });

      test('should fail when arb-dir does not exist', () async {
        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          '/nonexistent/directory',
        ]);

        expect(exitCode, ExitCode.noInput.code);
        verify(
          () => logger.err(any(that: contains('Directory does not exist'))),
        ).called(1);
      });

      test('should handle missing ARB directory from l10n.yaml', () async {
        File(path.join(tempDir.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: nonexistent/directory
''');

        await _doInDirectory(tempDir, () async {
          final exitCode = await commandRunner.run(['verify']);

          expect(exitCode, ExitCode.noInput.code);
          verify(
            () => logger.err(
              any(
                that: contains('ARB directory from l10n.yaml does not exist'),
              ),
            ),
          ).called(1);
        });
      });

      test('should handle empty ARB directory from l10n.yaml', () async {
        File(path.join(tempDir.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: lib/l10n
''');
        Directory(path.join(tempDir.path, 'lib', 'l10n'))
            .createSync(recursive: true);

        await _doInDirectory(tempDir, () async {
          final exitCode = await commandRunner.run(['verify']);

          expect(exitCode, ExitCode.noInput.code);
          verify(
            () => logger.err(
              any(that: contains('No ARB files found in directory')),
            ),
          ).called(1);
        });
      });

      test('handles YAML parsing errors in l10n.yaml', () async {
        File(path.join(tempDir.path, 'l10n.yaml')).writeAsStringSync('''
invalid: yaml: [unclosed
''');

        await _doInDirectory(tempDir, () async {
          final exitCode = await commandRunner.run(['verify']);

          expect(exitCode, ExitCode.noInput.code);
          verify(
            () => logger.err(any(that: contains('Error parsing YAML'))),
          ).called(1);
        });
      });

      test('should handle FormatException when parsing l10n.yaml', () async {
        File(path.join(tempDir.path, 'l10n.yaml'))
            .writeAsStringSync('arb-dir: lib/l10n');

        await _doInDirectory(tempDir, () async {
          final arbDir = Directory(path.join(tempDir.path, 'lib', 'l10n'))
            ..createSync(recursive: true);
          File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('{}');

          final exitCode = await commandRunner.run(['verify']);

          expect(exitCode, ExitCode.success.code);
        });
      });
    });

    // -------------------------------------------------------------------------
    // 2. Happy Paths
    // Standard success scenarios finding valid files via different methods.
    // -------------------------------------------------------------------------
    group('Happy Paths', () {
      test('should find ARB files from arb-dir', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>World</b>!",
  "@hello": {
    "description": "A greeting"
  }
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('Found 1 ARB file(s) to verify')).called(1);
        verify(() => logger.progress('Verifying ARB files')).called(1);
        verify(() => logger.info('✓ No errors found in ARB files')).called(1);
      });

      test('should find ARB files from l10n.yaml', () async {
        File(path.join(tempDir.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
''');
        final arbDir = Directory(path.join(tempDir.path, 'lib', 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>World</b>!"
}
''');

        await _doInDirectory(tempDir, () async {
          final exitCode = await commandRunner.run(['verify']);

          expect(exitCode, ExitCode.success.code);
          verify(() => logger.info('Found 1 ARB file(s) to verify')).called(1);
        });
      });

      test('should handle multiple ARB files', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);

        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>World</b>!"
}
''');
        File(path.join(arbDir.path, 'app_it.arb')).writeAsStringSync('''
{
  "hello": "Ciao <b>Mondo</b>!"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('Found 2 ARB file(s) to verify')).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // 3. Validation Logic
    // Tests that verify the core logic: catching bad tags, attributes, or XML.
    // -------------------------------------------------------------------------
    group('Validation Logic', () {
      test('should create report file with parsing errors in ARB files',
          () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>unclosed tag",
  "world": "Valid <b>text</b>"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
          '--output',
          path.join(tempDir.path, 'report.txt'),
        ]);

        expect(exitCode, ExitCode.config.code);
        verify(() => logger.warn('✗ Found 1 error(s)')).called(1);
        verify(
          () => logger.info('Error report written to: '
              '${path.join(tempDir.path, 'report.txt')}'),
        ).called(1);

        final reportFile = File(path.join(tempDir.path, 'report.txt'));
        expect(reportFile.existsSync(), isTrue);
        final reportContent = reportFile.readAsStringSync();
        final reportJson = jsonDecode(reportContent) as Map<String, dynamic>;

        // Verify JSON structure
        expect(reportJson, isA<Map<String, dynamic>>());
        final fileKey = reportJson.keys.first;
        expect(fileKey, contains('app_en.arb'));

        final fileData = reportJson[fileKey] as Map<String, dynamic>;
        expect(fileData['validKeys'], equals(1));
        expect(fileData['invalidKeys'], equals(1));
        expect(fileData['errors'], isA<Map<String, dynamic>>());

        final errors = fileData['errors'] as Map<String, dynamic>;
        expect(errors.containsKey('hello'), isTrue);
        expect(errors['hello'], isA<String>());
        expect(errors['hello'], contains('Invalid XML tag'));
      });

      test('should create report file with unrecognized tags', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <unknown>World</unknown>!"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.config.code);
        verify(() => logger.warn('✗ Found 1 error(s)')).called(1);

        final reportFile = File('text_rich_i18n_styled_error');
        expect(reportFile.existsSync(), isTrue);
        final reportContent = reportFile.readAsStringSync();
        final reportJson = jsonDecode(reportContent) as Map<String, dynamic>;

        // Verify JSON structure
        final fileKey = reportJson.keys.first;
        expect(fileKey, contains('app_en.arb'));

        final fileData = reportJson[fileKey] as Map<String, dynamic>;
        expect(fileData['validKeys'], equals(0));
        expect(fileData['invalidKeys'], equals(1));

        final errors = fileData['errors'] as Map<String, dynamic>;
        expect(errors.containsKey('hello'), isTrue);
        expect(errors['hello'], contains('Unrecognized tag: unknown'));
      });

      test('should create report file with unrecognized attributes', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync(r'''
{
  "hello": "Hello <b unknownAttr=\"value\">World</b>!"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.config.code);
        verify(() => logger.warn('✗ Found 1 error(s)')).called(1);

        final reportFile = File('text_rich_i18n_styled_error');
        expect(reportFile.existsSync(), isTrue);
        final reportContent = reportFile.readAsStringSync();
        final reportJson = jsonDecode(reportContent) as Map<String, dynamic>;

        // Verify JSON structure
        final fileKey = reportJson.keys.first;
        expect(fileKey, contains('app_en.arb'));

        final fileData = reportJson[fileKey] as Map<String, dynamic>;
        expect(fileData['validKeys'], equals(0));
        expect(fileData['invalidKeys'], equals(1));

        final errors = fileData['errors'] as Map<String, dynamic>;
        expect(errors.containsKey('hello'), isTrue);
        expect(errors['hello'], contains('Unrecognized attributes'));
      });
    });

    // -------------------------------------------------------------------------
    // 4. Content Processing & Edge Cases
    // Handling specific JSON structures, metadata skipping, and types.
    // -------------------------------------------------------------------------
    group('Content Processing & Edge Cases', () {
      test('should skip metadata keys in ARB files', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "@@locale": "en",
  "@hello": {
    "description": "A greeting",
    "type": "text"
  },
  "validKey": "Valid <b>text</b>"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('✓ No errors found in ARB files')).called(1);

        // Verify report JSON includes file with valid keys
        final reportFile = File('text_rich_i18n_styled_error');
        expect(reportFile.existsSync(), isTrue);
        final reportContent = reportFile.readAsStringSync();
        final reportJson = jsonDecode(reportContent) as Map<String, dynamic>;

        final fileKey = reportJson.keys.first;
        final fileData = reportJson[fileKey] as Map<String, dynamic>;
        expect(fileData['validKeys'], equals(1));
        expect(fileData['invalidKeys'], equals(0));
        expect(fileData['errors'], isEmpty);
      });

      test('should handle empty ARB files', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('{}');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('✓ No errors found in ARB files')).called(1);
      });

      test('should handle non-string values in ARB files', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "count": 42,
  "enabled": true,
  "hello": "Hello <b>World</b>!"
}
''');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('✓ No errors found in ARB files')).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // 5. Output & I/O Handling
    // Tests related to report generation location and file system errors.
    // -------------------------------------------------------------------------
    group('Output & I/O Handling', () {
      test('should create report file with custom output path', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <unknown>World</unknown>!"
}
''');

        final customReportPath = path.join(tempDir.path, 'custom_report.txt');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
          '--output',
          customReportPath,
        ]);

        expect(exitCode, ExitCode.config.code);
        verify(
          () => logger.info('Error report written to: $customReportPath'),
        ).called(1);

        final reportFile = File(customReportPath);
        expect(reportFile.existsSync(), isTrue);

        // Verify JSON format
        final reportContent = reportFile.readAsStringSync();
        final reportJson = jsonDecode(reportContent) as Map<String, dynamic>;
        expect(reportJson, isA<Map<String, dynamic>>());

        reportFile.deleteSync();
      });

      test('should handle file read errors gracefully', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb'))
          ..writeAsStringSync('{}')
          ..writeAsStringSync('{ invalid json }');

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
        ]);

        expect(exitCode, ExitCode.config.code);
        verify(
          () => logger.warn(any(that: contains('error(s)'))),
        ).called(1);
      });

      test('should handle report write errors', () async {
        final arbDir = Directory(path.join(tempDir.path, 'l10n'))
          ..createSync(recursive: true);
        File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <unknown>World</unknown>!"
}
''');

        final reportDir = Directory(path.join(tempDir.path, 'report.txt'))
          ..createSync();

        final progress = _MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);
        when(() => progress.complete(any())).thenReturn(null);

        final exitCode = await commandRunner.run([
          'verify',
          '--arb-dir',
          arbDir.path,
          '--output',
          reportDir.path,
        ]);

        expect(exitCode, ExitCode.ioError.code);
        verify(
          () => logger.err(any(that: contains('Error writing report'))),
        ).called(1);
      });
    });
  });
}
