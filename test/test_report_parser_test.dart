import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:test_report_parser/src/model.g.dart';

const exampleTest = r'''
import 'package:test/scaffolding.dart';

void main() {
  test('basic test 1', () {});
  group('First Group', () {
    test('group 1 test 1', () {});
    test('group 1 test 2', () {});
  });
  group('Second Group', () {
    test('group 2 test 1', () {});
  });
}
''';

void main() {
  test('can parse successful test output', () async {
    final tempTestFile = File('${Directory.systemTemp.path}/temp_test.dart');
    addTearDown(() => ignoreExceptions(tempTestFile.deleteSync));
    await tempTestFile.writeAsString(exampleTest, flush: true);

    final events = <Event>[];
    final exitCode = await exec(
        Process.start('dart', [
          'run',
          'test',
          '--reporter',
          'json',
          tempTestFile.absolute.path,
        ]),
        name: 'dart run test',
        onStdoutLine: combine(parseJsonToEvent, events.add));
    expect(exitCode, equals(0));
    expect(events[0],
        isA<StartEvent>().having((e) => e.type, 'type', equals('start')));
    expect(events[1],
        isA<StartEvent>().having((e) => e.type, 'type', equals('start')));
  });

  test('can parse JSON events', () {
    final event =
        parseJsonToEvent('{"success":true,"type":"done","time":36361}');
    expect(event, equals(DoneEvent(success: true, time: 36361)));
  });
}

B Function(String) combine<A, B>(A Function(String) fun, B Function(A) other) {
  return (input) {
    print(input);
    return other(fun(input));
  };
}
