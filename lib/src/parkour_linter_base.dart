import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'force_index_lint.dart';

class ParkourLinterBase extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const ForceIndexLint(),
      ];
}
