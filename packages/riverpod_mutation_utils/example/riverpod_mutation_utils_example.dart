import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'riverpod_mutation_utils_example.g.dart';

@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateFormMutation
    with StateFormMixin<String, String> {
  @override
  String build(String id) => id;

  Future<String> save() {
    return submit((tx, form) async {
      await Future<void>.delayed(Duration.zero);
      return 'saved:$form';
    });
  }
}

void main() {
  print(itemUpdateFormMutation('item-1'));
}
