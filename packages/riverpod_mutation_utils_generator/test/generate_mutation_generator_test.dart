import 'package:riverpod_mutation_utils_generator/src/generate_mutation_generator.dart';
import 'package:test/test.dart';

void main() {
  group('renderMutationSpec', () {
    test('renders an unkeyed mutation for non-family notifiers', () {
      final output = renderMutationSpec(
        className: 'CounterSave',
        resultTypeDisplay: 'int',
        parameters: const [],
      );

      expect(
        output,
        contains('final _\$counterSaveMutationBase = Mutation<int>();'),
      );
      expect(output, contains('Mutation<int> counterSaveMutation() {'));
      expect(
        output,
        contains('mixin _\$CounterSaveMutation on _\$CounterSave {'),
      );
      expect(
        output,
        contains(
          'Mutation<int> get mutationBase => _\$counterSaveMutationBase;',
        ),
      );
      expect(output, isNot(contains('mutationKey')));
    });

    test('renders keyed mutations for family notifiers', () {
      final output = renderMutationSpec(
        className: 'ItemUpdateForm',
        resultTypeDisplay: 'String',
        parameters: const [
          MutationParameterSpec(type: 'String', name: 'id'),
          MutationParameterSpec(
            type: 'String',
            name: 'orgId',
            isNamed: true,
            isRequiredNamed: true,
          ),
        ],
      );

      expect(
        output,
        contains('final _\$itemUpdateFormMutationBase = Mutation<String>();'),
      );
      expect(
        output,
        contains(
          'Mutation<String> itemUpdateFormMutation(String id, {required String orgId}) {',
        ),
      );
      expect(output, contains('Object get mutationKey => (id, orgId);'));
    });
  });
}
