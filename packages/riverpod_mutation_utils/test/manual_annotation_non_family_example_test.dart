import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

import '../example/manual_annotation_non_family_example.dart';

void main() {
  test(
    'manual non-family annotation example uses the base mutation directly',
    () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final sub = container.listen(
        counterSaveMutation,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final future = container.read(manualCounterSaveProvider.notifier).save();

      expect(sub.read(), isA<MutationPending<int>>());
      expect(await future, 1);
      expect(sub.read(), isA<MutationSuccess<int>>());
      expect((sub.read() as MutationSuccess<int>).value, 1);
    },
  );
}
