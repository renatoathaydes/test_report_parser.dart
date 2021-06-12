import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' as log;

const docUrl =
    'https://raw.githubusercontent.com/dart-lang/test/master/pkgs/test/doc/json_reporter.md';

final etagFile = File('.dartle_tool/etag.txt');

final log.Logger logger = log.Logger('generate.dart');

Future<void> generateModel({required bool force}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(docUrl));
    await _setHeaders(request, force);
    await _processMarkdownResponse(await request.close());
  } finally {
    client.close();
  }
}

Future<void> _setHeaders(HttpClientRequest request, bool force) async {
  if (force) {
    logger.info('Forcing re-generation of model');
  } else {
    final etag = await _loadEtag();
    if (etag != null) {
      request.headers.add('If-None-Match', etag);
    }
  }
  request.headers.add('Accept', 'text/plain');
}

Future<void> _processMarkdownResponse(HttpClientResponse response) async {
  if (response.statusCode == 200) {
    logger.info('Got new markdown successfully, generating new model');
    final context = ParserContext();
    await for (final line in response.lines()) {
      context.receiveLine(line.trimRight());
    }
    final fileHandle =
        await File('lib/src/model.g.dart').open(mode: FileMode.writeOnly);
    try {
      await context.write(fileHandle.writeString);
    } finally {
      await fileHandle.close();
    }
    final etag = response.headers.value('Etag');
    if (etag != null) {
      await _storeEtag(etag);
    }
  } else if (response.statusCode == 304) {
    logger.info('Markdown has not been modified, skipping generation');
  } else {
    throw Exception('Unexpected response: $response');
  }
}

Future<String?> _loadEtag() async {
  if (await etagFile.exists()) {
    final etag = await etagFile.readAsString();
    logger.fine('Using etag $etag');
    return etag;
  }
  return null;
}

Future<void> _storeEtag(String etag) async {
  if (!await etagFile.parent.exists()) {
    await etagFile.parent.create(recursive: true);
  }
  if (etag.startsWith('W/')) {
    etag = etag.substring(2);
  }
  await etagFile.writeAsString(etag, flush: true);
}

class ParserContext {
  var _isInCodeBrackets = false;
  var _isWaitingForCode = false;
  final _definition = <String>[];
  final _classes = <_Class>[];

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
      _classes.add(_parseClass(_definition, _classes));
      _definition.clear();
    } else {
      _definition.add(line);
    }
  }

  Future<void> write(FutureOr<void> Function(String) writer) async {
    await writer("import 'dart:convert' show json;\n\n");
    for (final cls in _classes) {
      await writer(cls.contents.join('\n'));
      await writer('\n\n');
    }
    await _writeJsonParser(_classes, writer);
  }
}

_Class _parseClass(List<String> definition, List<_Class> classes) {
  final cls = _Class();
  final iter = definition.iterator;
  _parseClassDefinition(iter, cls);
  _parseFields(iter, cls, classes);
  while (iter.moveNext()) {
    if (iter.current.isNotEmpty) {
      throw Exception(
          'Non-empty lines after end of class definition: "${iter.current}"');
    }
  }
  _addParentFields(cls, classes);
  _addConstructor(cls);
  _addEquals(cls);
  _addHashCode(cls);
  _addToString(cls);
  cls.contents.add('}');
  return cls;
}

void _parseClassDefinition(Iterator<String> iter, _Class cls) {
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

void _parseFields(Iterator<String> iter, _Class cls, List<_Class> classes) {
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

_Field _parseField(String current, _Class cls, List<_Class> classes) {
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
    return _Field(parts[1], parts[0]);
  }
  if (parts.length == 4 && parts[2] == '=') {
    cls.contents.add('  final $line');
    return _Field(parts[1], parts[0], parts[3]);
  }
  throw Exception('Expected field definition, got line: "$current"');
}

void _addParentFields(_Class cls, List<_Class> classes) {
  final parentName = cls.extendsClass;
  if (parentName == null) return;
  final parentClass = classes.firstWhere((c) => c.name == parentName);
  final existingFields = cls.fields.map((f) => f.name).toSet();
  final nonFinalFields = parentClass.fields
      .where((f) => f.value == null && !existingFields.contains(f.name))
      .map((f) => f.copyToChildClass());
  for (final field in nonFinalFields) {
    cls.fields.add(field);
    cls.contents.add('\n  @override');
    cls.contents.add('  final ${field.type} ${field.name};');
  }
}

void _addConstructor(_Class cls) {
  if (cls.isAbstract) return;
  final constructorFields = cls.fields
      .where((f) => f.value == null)
      .map((f) => '${f.type.endsWith('?') ? '' : 'required '}this.${f.name}')
      .join(', ');
  cls.contents.add('\n  ${cls.name}({$constructorFields});');
}

void _addEquals(_Class cls) {
  if (cls.isAbstract) return;
  final fieldParts =
      cls.fields.map((f) => '${f.name} == other.${f.name}').join(' && ');
  cls.contents.add('\n  @override\n  bool operator ==(Object other) =>\n'
      '    identical(this, other) ||\n'
      '    other is ${cls.name} && runtimeType == other.runtimeType'
      '${fieldParts.isEmpty ? '' : ' &&\n    $fieldParts'};');
}

void _addHashCode(_Class cls) {
  if (cls.isAbstract) return;
  final fieldParts = cls.fields.map((f) => '${f.name}.hashCode').join(' ^ ');
  cls.contents.add('\n  @override\n  int get hashCode =>\n'
      '    ${fieldParts.isEmpty ? '37' : fieldParts};');
}

void _addToString(_Class cls) {
  if (cls.isAbstract) return;
  final fieldParts = cls.fields.map((f) => '${f.name}: \$${f.name}').join(', ');
  cls.contents.add('\n  @override\n  String toString() =>\n'
      '    "${cls.name}{$fieldParts}";');
}

Future<void> _writeJsonParser(
    List<_Class> classes, FutureOr<void> Function(String) writer) async {
  await writer(r'''
Event parseJsonToEvent(String text) {
  final map = json.decode(text);
  switch(map['type']) {
''');
  for (var cls in classes.where((cls) => !cls.isAbstract)) {
    final typeField = cls.fields.firstWhere((f) => f.name == 'type',
        orElse: () => const _Field.empty());
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

class _Class {
  bool isAbstract = false;
  String name = '';
  String? extendsClass;
  final List<_Field> fields = [];
  final List<String> contents = [];
}

class _Field {
  final bool fromParentClass;
  final String name;
  final String type;
  final String? value;

  const _Field(this.name, this.type,
      [this.value, this.fromParentClass = false]);

  const _Field.empty()
      : fromParentClass = false,
        name = '',
        type = '',
        value = null;

  _Field copyToChildClass() => _Field(name, type, value, true);
}

extension Lines on HttpClientResponse {
  Stream<String> lines() {
    return transform(utf8.decoder).transform(const LineSplitter());
  }
}
