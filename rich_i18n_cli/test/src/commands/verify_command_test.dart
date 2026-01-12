import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:rich_i18n_cli/src/command_runner.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

void main() {
  group('verify', () {
    late Logger logger;
    late RichI18nCliCommandRunner commandRunner;
    late Directory tempDir;

    setUp(() {
      logger = _MockLogger();
      commandRunner = RichI18nCliCommandRunner(logger: logger);
      tempDir = Directory.systemTemp.createTempSync('verify_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('fails when no ARB files found', () async {
      final exitCode = await commandRunner.run(['verify']);

      expect(exitCode, ExitCode.noInput.code);
      verify(
        () => logger.err(
          any(that: contains('No ARB files found')),
        ),
      ).called(1);
    });

    test('fails when arb-dir does not exist', () async {
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

    test('finds ARB files from arb-dir', () async {
      // Create test ARB file
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

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

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

    test('finds ARB files from l10n.yaml', () async {
      // Create l10n.yaml
      File(path.join(tempDir.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
''');

      // Create ARB directory and file
      final arbDir = Directory(path.join(tempDir.path, 'lib', 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>World</b>!"
}
''');

      // Change to temp directory
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        final progress = _MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);
        when(() => progress.complete(any())).thenReturn(null);

        final exitCode = await commandRunner.run(['verify']);

        expect(exitCode, ExitCode.success.code);
        verify(() => logger.info('Found 1 ARB file(s) to verify')).called(1);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('reports parsing errors in ARB files', () async {
      // Create test ARB file with invalid XML
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <b>unclosed tag",
  "world": "Valid <b>text</b>"
}
''');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

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

      // Verify report file was created
      final reportFile = File(path.join(tempDir.path, 'report.txt'));
      expect(reportFile.existsSync(), isTrue);
      final reportContent = reportFile.readAsStringSync();
      expect(reportContent, contains('hello'));
      expect(reportContent, contains('parsingException'));
    });

    test('reports unrecognized tags', () async {
      // Create test ARB file with unrecognized tag
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <unknown>World</unknown>!"
}
''');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      expect(exitCode, ExitCode.config.code);
      verify(() => logger.warn('✗ Found 1 error(s)')).called(1);

      // Verify report file was created
      final reportFile = File('text_rich_i18n_styled_error');
      expect(reportFile.existsSync(), isTrue);
      final reportContent = reportFile.readAsStringSync();
      expect(reportContent, contains('hello'));
      expect(reportContent, contains('descriptorIssue'));
      expect(reportContent, contains('Unrecognized tag: unknown'));

      // Cleanup
      if (reportFile.existsSync()) {
        reportFile.deleteSync();
      }
    });

    test('reports unrecognized attributes', () async {
      // Create test ARB file with unrecognized attribute
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync(r'''
{
  "hello": "Hello <b unknownAttr=\"value\">World</b>!"
}
''');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      expect(exitCode, ExitCode.config.code);
      verify(() => logger.warn('✗ Found 1 error(s)')).called(1);

      // Verify report file was created
      final reportFile = File('text_rich_i18n_styled_error');
      expect(reportFile.existsSync(), isTrue);
      final reportContent = reportFile.readAsStringSync();
      expect(reportContent, contains('hello'));
      expect(reportContent, contains('descriptorIssue'));
      expect(reportContent, contains('Unrecognized attributes'));

      // Cleanup
      if (reportFile.existsSync()) {
        reportFile.deleteSync();
      }
    });

    test('skips metadata keys in ARB files', () async {
      // Create test ARB file with only metadata
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "@@locale": "en",
  "@hello": {
    "description": "A greeting",
    "type": "text"
  }
}
''');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('✓ No errors found in ARB files')).called(1);
    });

    test('handles multiple ARB files', () async {
      // Create multiple ARB files
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

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('Found 2 ARB file(s) to verify')).called(1);
    });

    test('handles file read errors gracefully', () async {
      // Create directory but make file unreadable (on Unix)
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb'))
        ..writeAsStringSync('{}')

        // On Unix, we can test permission errors
        // For now, we'll test with invalid JSON
        ..writeAsStringSync('{ invalid json }');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

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

    test('creates report file with custom output path', () async {
      // Create test ARB file with error to trigger report message
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "hello": "Hello <unknown>World</unknown>!"
}
''');

      final customReportPath = path.join(tempDir.path, 'custom_report.txt');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

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
    });

    test('handles empty ARB files', () async {
      // Create empty ARB file
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('{}');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('✓ No errors found in ARB files')).called(1);
    });

    test('handles non-string values in ARB files', () async {
      // Create ARB file with non-string values
      final arbDir = Directory(path.join(tempDir.path, 'l10n'))
        ..createSync(recursive: true);
      File(path.join(arbDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "count": 42,
  "enabled": true,
  "hello": "Hello <b>World</b>!"
}
''');

      final progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      when(() => progress.complete(any())).thenReturn(null);

      final exitCode = await commandRunner.run([
        'verify',
        '--arb-dir',
        arbDir.path,
      ]);

      // Should only process string values, so should succeed
      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('✓ No errors found in ARB files')).called(1);
    });
  });
}
