import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

import '../example/riverpod_mutation_utils_example.dart';

void main() {
  test('generated family mutation accessor isolates state by id', () async {
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
        .read(itemUpdateFormProvider('first').notifier)
        .save();

    expect(firstSub.read(), isA<MutationPending<String>>());
    expect(secondSub.read(), isA<MutationIdle<String>>());

    expect(await future, 'saved:first');
    expect(secondSub.read(), isA<MutationIdle<String>>());
    expect(firstSub.read(), isA<MutationSuccess<String>>());
    expect((firstSub.read() as MutationSuccess<String>).value, 'saved:first');
  });
}
