import 'common.dart';

class ParserContext {
  var _isInCodeBrackets = false;
  var _isWaitingForCode = false;
  final _definition = <String>[];
  final classes = <DartClass>[];

  void receiveLine(String line) {
    if (_isInCodeBrackets) {
      _receiveCode(line);
    } else if (_isWaitingForCode) {
      if (line == '```') {
        _isInCodeBrackets = true;
      } else if (line.isNotEmpty) {
        _isWaitingForCode = false;
      }
    } else if (line.startsWith('### ')) {
      _isWaitingForCode = true;
    }
  }

  void _receiveCode(String line) {
    if (line == '```') {
      _isInCodeBrackets = false;
      _isWaitingForCode = false;
      classes.add(_parseClass(_definition, classes));
      _definition.clear();
    } else {
      _definition.add(line);
    }
  }
}

DartClass _parseClass(List<String> definition, List<DartClass> classes) {
  final cls = DartClass();
  final iter = definition.iterator;
  _parseClassDefinition(iter, cls);
  _parseFields(iter, cls, classes);
  while (iter.moveNext()) {
    if (iter.current.isNotEmpty) {
      throw Exception(
          'Non-empty lines after end of class definition: "${iter.current}"');
    }
  }
  return cls;
}

void _parseClassDefinition(Iterator<String> iter, DartClass cls) {
  while (iter.moveNext()) {
    if (iter.current.isEmpty) continue;
    if (!iter.current.endsWith('{')) {
      throw Exception('Expected class definition, got line: "${iter.current}"');
    }
    final parts = iter.current
        .substring(0, iter.current.length - 1)
        .trim()
        .split(RegExp('\\s+'));
    if (parts.length == 3 && parts[0] == 'abstract' && parts[1] == 'class') {
      cls
        ..isAbstract = true
        ..name = parts[2];
    } else if (parts.length == 4 &&
        parts[0] == 'class' &&
        parts[2] == 'extends') {
      cls
        ..name = parts[1]
        ..extendsClass = parts[3];
    } else if (parts.length == 2 && parts[0] == 'class') {
      cls.name = parts[1];
      // TODO remove this once ticket is fixed:
      // https://github.com/dart-lang/test/issues/1536
      if (cls.name == 'AllSuitesEvent') {
        cls.extendsClass = 'Event';
      }
    } else {
      throw Exception('Expected class definition, got line: "${iter.current}"');
    }
    cls.contents.add('${cls.isAbstract ? 'abstract ' : ''}'
        'class ${cls.name} '
        '${cls.extendsClass == null ? '' : 'extends ${cls.extendsClass} '}{');
    return;
  }
  throw Exception('Ran out of lines before finding the class definition');
}

void _parseFields(
    Iterator<String> iter, DartClass cls, List<DartClass> classes) {
  while (iter.moveNext()) {
    final line = iter.current.trim();
    if (line.isEmpty) {
      cls.contents.add('');
      continue;
    }
    if (line.startsWith('// ')) {
      cls.contents.add('  /// ${line.substring(3)}');
      continue;
    }
    if (line.startsWith('/// ')) {
      cls.contents.add(iter.current);
      continue;
    }
    if (line == '//') {
      cls.contents.add('  ///');
      continue;
    }
    if (line == '///') {
      cls.contents.add(iter.current);
      continue;
    }
    if (line == '}') {
      return;
    }
    cls.fields.add(_parseField(iter.current, cls, classes));
  }
  throw Exception('Ran out of lines while parsing fields of class ${cls.name}');
}

DartField _parseField(String current, DartClass cls, List<DartClass> classes) {
  if (!current.endsWith(';')) {
    throw Exception('Expected field definition, got line: "$current"');
  }
  final parentFields = cls.extendsClass == null
      ? <String>{}
      : classes
          .firstWhere((c) => c.name == cls.extendsClass)
          .fields
          .map((f) => f.name)
          .toSet();
  final line = current.trim();
  final parts = line.substring(0, line.length - 1).split(RegExp('\\s+'));
  if (parentFields.contains(parts[1])) {
    cls.contents.add('  @override');
  }
  if (parts.length == 2) {
    cls.contents.add('  ${cls.isAbstract ? 'abstract ' : ''}final $line');
    return DartField(parts[1], parts[0]);
  }
  if (parts.length == 4 && parts[2] == '=') {
    final value = _strAsSingleQuote(parts[3]);
    cls.contents.add('  final ${parts[0]} ${parts[1]} = $value;');
    return DartField(parts[1], parts[0], value);
  }
  throw Exception('Expected field definition, got line: "$current"');
}

String _strAsSingleQuote(String part) {
  if (part.startsWith('"') && part.endsWith('"')) {
    return "'${part.substring(1, part.length - 1)}'";
  }
  return part;
}
