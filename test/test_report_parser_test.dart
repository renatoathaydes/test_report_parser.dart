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
    test('group 1 test 2', () {}, skip: true);
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
    emittedEvent<StartEvent>(events, (e) {
      expect(e.type, equals('start'));
      expect(e.protocolVersion, equals('0.1.1'));
      expect(e.time, allOf(greaterThanOrEqualTo(0), lessThan(100)));
    });
    emittedEvent<SuiteEvent>(events, (e) {
      expect(e.type, equals('suite'));
      expect(e.suite.path, equals(tempTestFile.path));
      expect(e.time, allOf(greaterThanOrEqualTo(0), lessThan(100)));
    });
    emittedEvent<AllSuitesEvent>(events, (e) {
      expect(e.type, equals('allSuites'));
      expect(e.count, equals(1));
      expect(e.time, allOf(greaterThanOrEqualTo(0), lessThan(1000)));
    });
    emittedEvent<DoneEvent>(events, (e) {
      expect(e.type, equals('done'));
      expect(e.success, isTrue);
      expect(e.time, allOf(greaterThanOrEqualTo(0), lessThan(10000)));
    });
    emittedEvents<GroupEvent>(events, (e) {
      expect(e.map((a) => a.type).toList(),
          equals(Iterable.generate(3, (_) => 'group').toList()));
      expect(e.map((a) => a.group.name),
          equals(['', 'First Group', 'Second Group']));
      expect(e.map((a) => a.group.testCount), equals([4, 2, 1]));
      expect(e.map((a) => a.group.parentID),
          equals([isNull, isNotNull, isNotNull]));
      expect(e.map((a) => '${a.group.line}:${a.group.column}'),
          equals([equals('null:null'), equals('5:3'), equals('9:3')]));
    });
    emittedEvents<TestStartEvent>(events, (e) {
      expect(e.map((a) => a.type).toList(),
          equals(Iterable.generate(5, (_) => 'testStart').toList()));
      expect(e.map((a) => a.test.id).toList(), equals([1, 3, 5, 6, 8]));
      expect(
          e.map((a) => a.test.name).toList(),
          equals([
            'loading ${tempTestFile.path}',
            'basic test 1',
            'First Group group 1 test 1',
            'First Group group 1 test 2',
            'Second Group group 2 test 1'
          ]));
      expect(e.map((a) => a.test.metadata.skip).toList(),
          equals([false, false, false, true, false]));
    });
  });

  test('can parse JSON events', () {
    final event =
        parseJsonToEvent('{"success":true,"type":"done","time":36361}');
    expect(event, equals(DoneEvent(success: true, time: 36361)));
  });
}

C Function(A) combine<A, B, C>(B Function(A) first, C Function(B) second) {
  return (input) {
    print(input);
    return second(first(input));
  };
}

void emittedEvent<T extends Event>(
  List<Event> events,
  void Function(T) assertions,
) {
  final event = events.whereType<T>();
  if (event.isEmpty) {
    throw Exception('Did not emit event $T');
  }
  if (event.length > 1) {
    throw Exception('Emitted more than one event $T: $event');
  }
  assertions(event.first);
}

void emittedEvents<T extends Event>(
  List<Event> events,
  void Function(List<T>) assertions,
) {
  final event = events.whereType<T>().toList();
  if (event.isEmpty) {
    throw Exception('Did not emit event $T');
  }
  assertions(event);
}
