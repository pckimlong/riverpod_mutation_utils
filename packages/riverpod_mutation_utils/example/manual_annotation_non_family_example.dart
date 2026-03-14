import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'manual_annotation_non_family_example.g.dart';

final counterSaveMutation = Mutation<int>();

@riverpod
class ManualCounterSave extends _$ManualCounterSave
    with StateFormMixin<int, int> {
  @override
  int build() => 0;

  @override
  Mutation<int> get mutationBase => counterSaveMutation;

  Future<int> save() {
    return submit((tx, form) async {
      await Future<void>.delayed(Duration.zero);
      state = form + 1;
      return state;
    });
  }
}

void main() {
  print(counterSaveMutation);
}
