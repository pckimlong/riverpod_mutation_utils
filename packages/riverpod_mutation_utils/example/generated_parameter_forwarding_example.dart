import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'generated_parameter_forwarding_example.g.dart';

@generateMutation
@riverpod
class GeneratedCatalogSearch extends _$GeneratedCatalogSearchMutation
    with StateFormMixin<String, List<String?>?> {
  @override
  String build(String query, [int? limit = 20]) => '$query:$limit';
}

@generateMutation
@riverpod
class GeneratedCatalogFilter extends _$GeneratedCatalogFilterMutation
    with StateFormMixin<String, Map<String, List<int?>>> {
  @override
  String build({
    String? cursor,
    bool includeHidden = false,
    List<int?> filters = const <int?>[null],
  }) => '$cursor:$includeHidden:$filters';
}
