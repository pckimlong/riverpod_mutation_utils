import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:riverpod_mutation_utils_generator/riverpod_mutation_utils_generator.dart';
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
      expect(output, contains('abstract class _\$CounterSaveMutation'));
      expect(output, contains('    extends _\$CounterSave'));
      expect(output, contains('    with _\$CounterSaveMutationWiring {}'));
      expect(
        output,
        contains('mixin _\$CounterSaveMutationWiring on _\$CounterSave {'),
      );
      expect(
        output,
        contains('Mutation<int> get mutation => _\$counterSaveMutationBase;'),
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
      expect(
        output,
        contains(
          'Mutation<String> get mutation => _\$itemUpdateFormMutationBase((id, orgId));',
        ),
      );
    });

    test(
      'preserves optional parameters, defaults, and nested nullable types',
      () {
        final output = renderMutationSpec(
          className: 'CatalogSearch',
          resultTypeDisplay: 'List<String?>?',
          parameters: const [
            MutationParameterSpec(type: 'String', name: 'query'),
            MutationParameterSpec(
              type: 'int?',
              name: 'limit',
              isOptionalPositional: true,
              defaultValueCode: '20',
            ),
          ],
        );

        expect(
          output,
          contains(
            'Mutation<List<String?>?> catalogSearchMutation(String query, [int? limit = 20]) {',
          ),
        );
        expect(
          output,
          contains('_\$catalogSearchMutationBase((query, limit))'),
        );
      },
    );

    test('preserves optional named defaults', () {
      final output = renderMutationSpec(
        className: 'CatalogFilter',
        resultTypeDisplay: 'Map<String, List<int?>>',
        parameters: const [
          MutationParameterSpec(type: 'String?', name: 'cursor', isNamed: true),
          MutationParameterSpec(
            type: 'bool',
            name: 'includeHidden',
            isNamed: true,
            defaultValueCode: 'false',
          ),
        ],
      );

      expect(
        output,
        contains(
          'catalogFilterMutation({String? cursor, bool includeHidden = false})',
        ),
      );
      expect(
        output,
        contains('_\$catalogFilterMutationBase((cursor, includeHidden))'),
      );
    });
  });

  test(
    'extracts parameter syntax through the public analyzer element API',
    () async {
      await testBuilder(
        mutationBuilder(BuilderOptions.empty),
        const {
          'riverpod_mutation_utils|lib/riverpod_mutation_utils.dart': r'''
class GenerateMutation {
  const GenerateMutation();
}

const generateMutation = GenerateMutation();
''',
          'riverpod_mutation_utils_generator|lib/input.dart': r'''
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart'
    show generateMutation;

mixin StateFormMixin<FormState, Result> {}

@generateMutation
class SearchForm with StateFormMixin<String, List<String?>?> {
  String build(
    String query, [
    int? limit = 20,
  ]) => query;
}
''',
        },
        outputs: {
          'riverpod_mutation_utils_generator|lib/input.mutation_utils.g.part':
              decodedMatches(
                allOf(
                  contains(
                    'Mutation<List<String?>?> searchFormMutation('
                    'String query, [int? limit = 20])',
                  ),
                  contains('_\$searchFormMutationBase((query, limit))'),
                ),
              ),
        },
      );
    },
  );
}
