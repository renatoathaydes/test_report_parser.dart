import 'dart:async';

import 'common.dart';

Future<void> writeJsonParser(
    List<DartClass> classes, FutureOr<void> Function(String) writer) async {
  await writer(r'''
Event parseJsonToEvent(String text) {
  final map = json.decode(text);
  switch(map['type']) {
''');
  final infoByClassName = _collectClassInfo(classes);
  for (var cls in classes.where((cls) => !cls.isAbstract)) {
    final typeField = cls.fields.firstWhere((f) => f.name == 'type',
        orElse: () => const DartField.empty());
    final fieldType = typeField.value;
    if (fieldType != null) {
      final assignments = _generateFieldAssignments(infoByClassName, cls);
      final instantiation = _instantiateClass(infoByClassName, cls);
      await writer('    case $fieldType:$assignments\n'
          '      return $instantiation;\n');
    }
  }
  await writer(r'''
    default:
      throw Exception('Unknown Event type: $map');
  }
}
''');
}

String _instantiateClass(
  Map<String, _ClassInfo> infoByClassName,
  DartClass cls,
) =>
    _instantiate(infoByClassName, cls.name, cls.fields);

String _instantiate(Map<String, _ClassInfo> infoByClassName, String className,
    Iterable<DartField> fields,
    [String parentName = 'map']) {
  final args = fields
      .where((f) => f.value == null)
      .map((f) =>
          "${f.name}: ${_generateFieldParam(infoByClassName, f, parentName)}")
      .join(', ');
  return '$className($args)';
}

List<String> _collectNonPrimitiveFields(
    Map<String, _ClassInfo> infoByClassName, DartClass cls,
    [String parent = 'map']) {
  final classInfo = infoByClassName[cls.name];
  if (classInfo == null || classInfo.nonPrimitiveFields.isEmpty) {
    return const [];
  }
  final result = <String>[];
  final visitedTypes = <String>{};
  for (final field in classInfo.nonPrimitiveFields) {
    result.add("      final ${field.name} = $parent['${field.name}']"
        "${field.isGeneric ? '.cast<${field.genericType}>()' : ''};");
    if (visitedTypes.add(field.type)) {
      final info = infoByClassName[field.type];
      if (info != null) {
        result.addAll(
            _collectNonPrimitiveFields(infoByClassName, info.cls, field.name));
      }
    }
  }
  return result;
}

String _generateFieldAssignments(
    Map<String, _ClassInfo> infoByClassName, DartClass cls) {
  final classInfo = infoByClassName[cls.name];
  if (classInfo == null || classInfo.nonPrimitiveFields.isEmpty) {
    return '';
  }
  return '\n' +
      _collectNonPrimitiveFields(infoByClassName, classInfo.cls).join('\n');
}

String _generateFieldParam(
  Map<String, _ClassInfo> infoByClassName,
  DartField field,
  String parentName,
) {
  final classInfo = infoByClassName[field.type];
  if (classInfo != null) {
    return _instantiate(
        infoByClassName, field.type, classInfo.cls.fields, field.name);
  } else {
    return "$parentName['${field.name}']"
        "${field.isGeneric ? '.cast<${field.genericType}>()' : ''}";
  }
}

Map<String, _ClassInfo> _collectClassInfo(List<DartClass> classes) {
  final result = <String, _ClassInfo>{};
  final classNames = classes.map((cls) => cls.name).toSet();
  for (final cls in classes) {
    result[cls.name] = _ClassInfo(
        cls, cls.fields.where((f) => classNames.contains(f.type)).toSet());
  }
  return result;
}

class _ClassInfo {
  final DartClass cls;
  final Set<DartField> nonPrimitiveFields;

  _ClassInfo(this.cls, this.nonPrimitiveFields);
}
