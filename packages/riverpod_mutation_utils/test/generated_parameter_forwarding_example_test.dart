import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../example/generated_parameter_forwarding_example.dart';

void main() {
  test('optional positional parameters keep defaults and mutation keys', () {
    final container = ProviderContainer.test();

    expect(container.read(generatedCatalogSearchProvider('phone')), 'phone:20');
    expect(
      generatedCatalogSearchMutation('phone'),
      equals(generatedCatalogSearchMutation('phone', 20)),
    );
    expect(
      generatedCatalogSearchMutation('phone', null),
      isNot(equals(generatedCatalogSearchMutation('phone'))),
    );
  });

  test('optional named parameters keep defaults and mutation keys', () {
    final container = ProviderContainer.test();

    expect(
      container.read(generatedCatalogFilterProvider()),
      'null:false:[null]',
    );
    expect(
      generatedCatalogFilterMutation(),
      equals(
        generatedCatalogFilterMutation(
          includeHidden: false,
          filters: const <int?>[null],
        ),
      ),
    );
    expect(
      generatedCatalogFilterMutation(cursor: 'next'),
      isNot(equals(generatedCatalogFilterMutation())),
    );
  });
}
