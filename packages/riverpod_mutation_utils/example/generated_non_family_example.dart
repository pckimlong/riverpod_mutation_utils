import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'generated_non_family_example.g.dart';

@generateMutation
@riverpod
class GeneratedCounterSave extends _$GeneratedCounterSave
    with StateFormMixin<int, int>, _$GeneratedCounterSaveMutation {
  @override
  int build() => 0;

  Future<int> save() {
    return submit((tx, form) async {
      await Future<void>.delayed(Duration.zero);
      state = form + 1;
      return state;
    });
  }
}

void main() {
  print(generatedCounterSaveMutation());
}
