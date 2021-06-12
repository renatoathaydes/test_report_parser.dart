import 'dart:async';

import 'common.dart';

Future<void> writeJsonParser(
    List<DartClass> classes, FutureOr<void> Function(String) writer) async {
  await writer(r'''
Event parseJsonToEvent(String text) {
  final map = json.decode(text);
  switch(map['type']) {
''');
  for (var cls in classes.where((cls) => !cls.isAbstract)) {
    final typeField = cls.fields.firstWhere((f) => f.name == 'type',
        orElse: () => const DartField.empty());
    final fieldType = typeField.value;
    if (fieldType != null) {
      final fields = cls.fields
          .where((f) => f.value == null)
          .map((f) => "${f.name}: map['${f.name}']")
          .join(', ');
      await writer('    case $fieldType:\n      return ${cls.name}(');
      await writer(fields);
      await writer(');\n');
    }
  }
  await writer(r'''
    default:
      throw Exception('Unknown Event type: $map');
  }
}
''');
}
