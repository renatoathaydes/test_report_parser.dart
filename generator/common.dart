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

  const DartField(this.name, this.type,
      [this.value, this.fromParentClass = false]);

  const DartField.empty()
      : fromParentClass = false,
        name = '',
        type = '',
        value = null;

  DartField copyToChildClass() => DartField(name, type, value, true);
}
