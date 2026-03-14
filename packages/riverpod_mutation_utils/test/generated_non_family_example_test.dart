import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

import '../example/generated_non_family_example.dart';

void main() {
  test(
    'generated non-family mutation accessor uses the base mutation directly',
    () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final sub = container.listen(
        generatedCounterSaveMutation(),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final future = container
          .read(generatedCounterSaveProvider.notifier)
          .save();

      expect(sub.read(), isA<MutationPending<int>>());
      expect(await future, 1);
      expect(sub.read(), isA<MutationSuccess<int>>());
      expect((sub.read() as MutationSuccess<int>).value, 1);
    },
  );
}
