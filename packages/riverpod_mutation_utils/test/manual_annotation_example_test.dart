import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

import '../example/manual_annotation_example.dart';

void main() {
  test('manual annotation example isolates mutation state by id', () async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);

    final firstSub = container.listen(
      itemUpdateFormMutation('first'),
      (_, _) {},
      fireImmediately: true,
    );
    final secondSub = container.listen(
      itemUpdateFormMutation('second'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(firstSub.close);
    addTearDown(secondSub.close);

    final future = container
        .read(manualItemUpdateFormProvider('first').notifier)
        .save();

    expect(firstSub.read(), isA<MutationPending<String>>());
    expect(secondSub.read(), isA<MutationIdle<String>>());

    expect(await future, 'saved:first');
    expect(secondSub.read(), isA<MutationIdle<String>>());
    expect(firstSub.read(), isA<MutationSuccess<String>>());
    expect((firstSub.read() as MutationSuccess<String>).value, 'saved:first');
  });
}
