import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'generated_multi_param_example.g.dart';

@generateMutation
@riverpod
class GeneratedScopedItemUpdate extends _$GeneratedScopedItemUpdate
    with StateFormMixin<String, String>, _$GeneratedScopedItemUpdateMutation {
  @override
  String build(String id, {required String orgId}) => '$orgId:$id';

  Future<String> save() {
    return submit((tx, form) async {
      await Future<void>.delayed(Duration.zero);
      return 'saved:$form';
    });
  }
}

void main() {
  print(generatedScopedItemUpdateMutation('item-1', orgId: 'org-1'));
}
