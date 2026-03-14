import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:source_gen/source_gen.dart';

class MutationParameterSpec {
  const MutationParameterSpec({
    required this.type,
    required this.name,
    this.isNamed = false,
    this.isRequiredNamed = false,
  });

  final String type;
  final String name;
  final bool isNamed;
  final bool isRequiredNamed;
}

String renderMutationSpec({
  required String className,
  required String resultTypeDisplay,
  required List<MutationParameterSpec> parameters,
}) {
  final mutationBaseName = '_\$${_lowerFirst(className)}MutationBase';
  final mutationAccessorName = '${_lowerFirst(className)}Mutation';
  final generatedClassName = '_\$${className}Mutation';
  final generatedMixinName = '_\$${className}MutationWiring';
  final generatedBaseName = '_\$$className';
  final parameterList = _renderParameterList(parameters);
  final keyExpression = _renderKeyExpression(parameters);
  final mutationExpression = keyExpression == null
      ? mutationBaseName
      : '$mutationBaseName($keyExpression)';

  final buffer = StringBuffer()
    ..writeln('final $mutationBaseName = Mutation<$resultTypeDisplay>();')
    ..writeln()
    ..writeln(
      'Mutation<$resultTypeDisplay> $mutationAccessorName(${parameterList.isEmpty ? '' : parameterList}) {',
    )
    ..writeln('  return $mutationExpression;')
    ..writeln('}')
    ..writeln()
    ..writeln('abstract class $generatedClassName')
    ..writeln('    extends $generatedBaseName')
    ..writeln('    with $generatedMixinName {}')
    ..writeln()
    ..writeln('mixin $generatedMixinName on $generatedBaseName {')
    ..writeln('  @override')
    ..writeln(
      '  Mutation<$resultTypeDisplay> get mutation => $mutationExpression;',
    );

  buffer.writeln('}');

  return buffer.toString();
}

class GenerateMutationGenerator
    extends GeneratorForAnnotation<GenerateMutation> {
  static const _supportedMixins = <String, int>{
    'StateFormMixin': 1,
    'AsyncStateFormMixin': 1,
    'MutationActionMixin': 0,
  };

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@GenerateMutation()` can only be used on classes.',
        element: element,
      );
    }

    final mixin = _findSupportedMixin(element);
    if (mixin == null) {
      throw InvalidGenerationSourceError(
        'Expected `${element.displayName}` to mix in one of: '
        '${_supportedMixins.keys.join(', ')}.',
        element: element,
      );
    }

    final resultType = _resolveResultType(mixin);
    final build = element.getMethod('build');
    if (build == null) {
      throw InvalidGenerationSourceError(
        'Expected `${element.displayName}` to declare a build(...) method.',
        element: element,
      );
    }

    return renderMutationSpec(
      className: element.displayName,
      resultTypeDisplay: resultType.getDisplayString(),
      parameters: build.formalParameters
          .map(
            (parameter) => MutationParameterSpec(
              type: parameter.type.getDisplayString(),
              name: parameter.displayName,
              isNamed: parameter.isNamed,
              isRequiredNamed: parameter.isRequiredNamed,
            ),
          )
          .toList(growable: false),
    );
  }

  InterfaceType? _findSupportedMixin(ClassElement element) {
    for (final mixin in element.mixins) {
      if (_supportedMixins.containsKey(_typeName(mixin))) {
        return mixin;
      }
    }

    return null;
  }

  DartType _resolveResultType(InterfaceType mixin) {
    final index = _supportedMixins[_typeName(mixin)]!;
    if (mixin.typeArguments.length <= index) {
      throw InvalidGenerationSourceError(
        'Unable to resolve the mutation result type from `${mixin.getDisplayString()}`.',
      );
    }
    return mixin.typeArguments[index];
  }

  String _typeName(InterfaceType type) {
    return type.getDisplayString().split('<').first;
  }
}

String _renderParameter(MutationParameterSpec parameter) {
  if (parameter.isNamed) {
    if (parameter.isRequiredNamed) {
      return 'required ${parameter.type} ${parameter.name}';
    }
    return '${parameter.type} ${parameter.name}';
  }

  return '${parameter.type} ${parameter.name}';
}

String _renderParameterList(List<MutationParameterSpec> parameters) {
  final positional = parameters
      .where((parameter) => !parameter.isNamed)
      .map(_renderParameter)
      .toList(growable: false);
  final named = parameters
      .where((parameter) => parameter.isNamed)
      .map(_renderParameter)
      .toList(growable: false);

  final parts = <String>[
    ...positional,
    if (named.isNotEmpty) '{${named.join(', ')}}',
  ];

  return parts.join(', ');
}

String? _renderKeyExpression(List<MutationParameterSpec> parameters) {
  if (parameters.isEmpty) return null;
  if (parameters.length == 1) return parameters.single.name;
  return '(${parameters.map((parameter) => parameter.name).join(', ')})';
}

String _lowerFirst(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toLowerCase()}${value.substring(1)}';
}
