import 'package:logging/logging.dart' as log;

final log.Logger logger = log.Logger('generate.dart');

class DartClass {
  bool isAbstract = false;
  String name = '';
  String? extendsClass;
  final List<DartField> fields = [];
  final List<String> contents = [];
}

class DartField {
  final bool fromParentClass;
  final String name;
  final String type;
  final String? value;

  /// Whether the attribute was added in a later protocol version, so runners
  /// of older versions do not send it.
  final bool isAddedLater;

  const DartField(this.name, this.type,
      [this.value, this.fromParentClass = false, this.isAddedLater = false]);

  const DartField.empty()
      : fromParentClass = false,
        name = '',
        type = '',
        value = null,
        isAddedLater = false;

  bool get isOptional => type.endsWith('?');

  bool get isGeneric => type.contains('<');

  String get genericType {
    var startIndex = type.indexOf('<');
    if (startIndex <= 0) {
      throw Exception('Type is not generic: $type');
    }
    return type.substring(startIndex + 1, type.length - 1);
  }

  /// The value used for an attribute that is absent from the JSON.
  String get absentValue {
    if (type == 'bool') return 'false';
    throw Exception(
        'No default value for attribute "$name" of type $type added in a later protocol version');
  }

  DartField copyToChildClass() =>
      DartField(name, type, value, true, isAddedLater);
}
