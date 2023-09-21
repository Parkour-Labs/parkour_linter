import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class ForceIndexLint extends DartLintRule {
  const ForceIndexLint() : super(code: lintCode);

  static const lintCode = LintCode(
    name: 'force_index',
    problemMessage: 'all imports must be from index.dart',
  );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) {
    context.registry.addImportDirective(
      (node) {
        final file = resolver.path;
        final basename = p.basename(file);
        if (basename != 'index.dart' && basename != 'main.dart') {
          reporter.reportErrorForNode(lintCode, node);
        }
      },
    );
  }

  @override
  List<Fix> getFixes() => [ForceIndexLintFix()];
}

class ForceIndexLintFix extends DartFix {
  static const message = 'Declare this file as part of the index.dart.';

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;
      // get the directory of the file
      final (imports, linesWithoutImports) = splitFileIntoImportsAndNotImports(resolver.path);
      if (!linesWithoutImports.any((element) => element.startsWith('part of'))) {
        linesWithoutImports.insert(0, 'part of \'index.dart\';');
      }
      final file = File(resolver.path);
      file.writeAsStringSync(linesWithoutImports.join('\n'));
      updateIndexFile(resolver.path, imports);
    });
  }

  (List<String>, List<String>) splitFileIntoImportsAndNotImports(String filePath) {
    final file = File(filePath);
    assert(file.existsSync(), 'File must exist');
    // read files as lines
    final lines = file.readAsLinesSync();
    final imports = <String>[];
    final linesWithoutImports = <String>[];
    String? currentImport;
    for (final line in lines) {
      var isImport = false;
      if (line.startsWith('import')) {
        currentImport = line;
        isImport = true;
      } else if (currentImport != null) {
        currentImport += line;
        isImport = true;
      }
      if (currentImport != null && currentImport.endsWith(';')) {
        imports.add(currentImport);
        currentImport = null;
      }
      if (!isImport) {
        linesWithoutImports.add(line);
      }
    }
    return (imports, linesWithoutImports);
  }

  void updateIndexFile(String path, List<String> imports) {
    final indexFile = File(p.join(p.dirname(path), 'index.dart'));
    if (!indexFile.existsSync()) {
      indexFile.createSync();
    }
    final (indexImports, indexLinesWithoutImports) = splitFileIntoImportsAndNotImports(indexFile.path);
    final newImports = <String>{...indexImports, ...imports};
    final newLines = <String>[...indexLinesWithoutImports, ...newImports];
    indexFile.writeAsStringSync(newLines.join('\n'));
  }
}
