import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

import '../example/generated_multi_param_example.dart';

void main() {
  test(
    'generated multi-param family mutation accessor isolates state by record key',
    () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final firstSub = container.listen(
        generatedScopedItemUpdateMutation('item-1', orgId: 'org-1'),
        (_, _) {},
        fireImmediately: true,
      );
      final secondSub = container.listen(
        generatedScopedItemUpdateMutation('item-1', orgId: 'org-2'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(firstSub.close);
      addTearDown(secondSub.close);

      final future = container
          .read(
            generatedScopedItemUpdateProvider(
              'item-1',
              orgId: 'org-1',
            ).notifier,
          )
          .save();

      expect(firstSub.read(), isA<MutationPending<String>>());
      expect(secondSub.read(), isA<MutationIdle<String>>());

      expect(await future, 'saved:org-1:item-1');
      expect(secondSub.read(), isA<MutationIdle<String>>());
      expect(firstSub.read(), isA<MutationSuccess<String>>());
      expect(
        (firstSub.read() as MutationSuccess<String>).value,
        'saved:org-1:item-1',
      );
    },
  );
}
