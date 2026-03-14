library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generate_mutation_generator.dart';

Builder mutationBuilder(BuilderOptions options) {
  return SharedPartBuilder([GenerateMutationGenerator()], 'mutation_utils');
}
