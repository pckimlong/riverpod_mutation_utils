import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'manual_annotation_example.g.dart';

final itemUpdateFormMutationBase = Mutation<String>();

Mutation<String> itemUpdateFormMutation(String id) {
  return itemUpdateFormMutationBase(id);
}

@riverpod
class ManualItemUpdateForm extends _$ManualItemUpdateForm
    with StateFormMixin<String, String> {
  @override
  String build(String id) => id;

  @override
  Mutation<String> get mutation => itemUpdateFormMutation(id);

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
