import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../generator/generate.dart';
import '../generator/parser.dart';

const _sampleMarkdown = r'''
# Exmample
### Event

```
abstract class Event {
  // The type of the event.
  //
  // This is always one of the subclass types listed below.
  String type;

  // The time (in milliseconds) that has elapsed since the test runner started.
  int time;
}
```

This is the root class of the protocol. All root-level objects emitted by the
JSON reporter will be subclasses of `Event`.

### StartEvent

```
class StartEvent extends Event {
  String type = "start";

  // The version of the JSON reporter protocol being used.
  //
  // This is a semantic version, but it reflects only the version of the
  // protocol—it's not identical to the version of the test runner itself.
  String protocolVersion;

  // The version of the test runner being used.
  String runnerVersion;

  // The pid of the VM process running the tests.
  int? pid;
}
```
''';

const _sampleMarkdownParsed = r'''
import 'dart:convert' show json;

abstract class Event {
  /// The type of the event.
  ///
  /// This is always one of the subclass types listed below.
  abstract final String type;

  /// The time (in milliseconds) that has elapsed since the test runner started.
  abstract final int time;
}

class StartEvent extends Event {
  @override
  final String type = "start";

  /// The version of the JSON reporter protocol being used.
  ///
  /// This is a semantic version, but it reflects only the version of the
  /// protocol—it's not identical to the version of the test runner itself.
  final String protocolVersion;

  /// The version of the test runner being used.
  final String runnerVersion;

  /// The pid of the VM process running the tests.
  final int? pid;

  @override
  final int time;

  StartEvent({required this.protocolVersion, required this.runnerVersion, this.pid, required this.time});

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is StartEvent && runtimeType == other.runtimeType &&
    type == other.type && protocolVersion == other.protocolVersion && runnerVersion == other.runnerVersion && pid == other.pid && time == other.time;

  @override
  int get hashCode =>
    type.hashCode ^ protocolVersion.hashCode ^ runnerVersion.hashCode ^ pid.hashCode ^ time.hashCode;

  @override
  String toString() =>
    "StartEvent{type: $type, protocolVersion: $protocolVersion, runnerVersion: $runnerVersion, pid: $pid, time: $time}";
}

Event parseJsonToEvent(String text) {
  final map = json.decode(text);
  switch(map['type']) {
    case "start":
      return StartEvent(protocolVersion: map['protocolVersion'], runnerVersion: map['runnerVersion'], pid: map['pid'], time: map['time']);
    default:
      throw Exception('Unknown Event type: $map');
  }
}
''';

void main() {
  test('can generate code for sample markdown', () async {
    final context = ParserContext();
    _sampleMarkdown.split('\n').forEach(context.receiveLine);
    final result = StringBuffer();
    await generate(context.classes, result.write);
    expect(result.toString(), equals(_sampleMarkdownParsed));
  });
}
