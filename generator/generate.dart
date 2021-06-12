import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'common.dart';
import 'etag.dart';
import 'json.dart';
import 'parser.dart';

const docUrl =
    'https://raw.githubusercontent.com/dart-lang/test/master/pkgs/test/doc/json_reporter.md';

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
    final etag = await loadEtag();
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
      await generate(context.classes, fileHandle.writeString);
    } finally {
      await fileHandle.close();
    }
    final etag = response.headers.value('Etag');
    if (etag != null) {
      await storeEtag(etag);
    }
  } else if (response.statusCode == 304) {
    logger.info('Markdown has not been modified, skipping generation');
  } else {
    throw Exception('Unexpected response: $response');
  }
}

Future<void> generate(
    List<DartClass> classes, FutureOr<void> Function(String) writer) async {
  for (final cls in classes) {
    _addParentFields(cls, classes);
    _addConstructor(cls);
    _addEquals(cls);
    _addHashCode(cls);
    _addToString(cls);
    cls.contents.add('}');
  }

  await writer("import 'dart:convert' show json;\n\n");
  for (final cls in classes) {
    await writer(cls.contents.join('\n'));
    await writer('\n\n');
  }
  await writeJsonParser(classes, writer);
}

void _addParentFields(DartClass cls, List<DartClass> classes) {
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

void _addConstructor(DartClass cls) {
  if (cls.isAbstract) return;
  final constructorFields = cls.fields
      .where((f) => f.value == null)
      .map((f) => '${f.type.endsWith('?') ? '' : 'required '}this.${f.name}')
      .join(', ');
  cls.contents.add('\n  ${cls.name}({$constructorFields});');
}

void _addEquals(DartClass cls) {
  if (cls.isAbstract) return;
  final fieldParts =
      cls.fields.map((f) => '${f.name} == other.${f.name}').join(' && ');
  cls.contents.add('\n  @override\n  bool operator ==(Object other) =>\n'
      '    identical(this, other) ||\n'
      '    other is ${cls.name} && runtimeType == other.runtimeType'
      '${fieldParts.isEmpty ? '' : ' &&\n    $fieldParts'};');
}

void _addHashCode(DartClass cls) {
  if (cls.isAbstract) return;
  final fieldParts = cls.fields.map((f) => '${f.name}.hashCode').join(' ^ ');
  cls.contents.add('\n  @override\n  int get hashCode =>\n'
      '    ${fieldParts.isEmpty ? '37' : fieldParts};');
}

void _addToString(DartClass cls) {
  if (cls.isAbstract) return;
  final fieldParts = cls.fields.map((f) => '${f.name}: \$${f.name}').join(', ');
  cls.contents.add('\n  @override\n  String toString() =>\n'
      '    "${cls.name}{$fieldParts}";');
}

extension Lines on HttpClientResponse {
  Stream<String> lines() {
    return transform(utf8.decoder).transform(const LineSplitter());
  }
}
