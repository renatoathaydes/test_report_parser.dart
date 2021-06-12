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
  final int pid;

  @override
  final int time;

  StartEvent(
      {required this.protocolVersion,
      required this.runnerVersion,
      required this.pid,
      required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StartEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          protocolVersion == other.protocolVersion &&
          runnerVersion == other.runnerVersion &&
          pid == other.pid &&
          time == other.time;

  @override
  int get hashCode =>
      type.hashCode ^
      protocolVersion.hashCode ^
      runnerVersion.hashCode ^
      pid.hashCode ^
      time.hashCode;

  @override
  String toString() =>
      "StartEvent{type: $type, protocolVersion: $protocolVersion, runnerVersion: $runnerVersion, pid: $pid, time: $time}";
}

class AllSuitesEvent extends Event {
  @override
  final String type = "allSuites";

  /// The total number of suites that will be loaded.
  final int count;

  @override
  final int time;

  AllSuitesEvent({required this.count, required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllSuitesEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          count == other.count &&
          time == other.time;

  @override
  int get hashCode => type.hashCode ^ count.hashCode ^ time.hashCode;

  @override
  String toString() =>
      "AllSuitesEvent{type: $type, count: $count, time: $time}";
}

class SuiteEvent extends Event {
  @override
  final String type = "suite";

  /// Metadata about the suite.
  final Suite suite;

  @override
  final int time;

  SuiteEvent({required this.suite, required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          suite == other.suite &&
          time == other.time;

  @override
  int get hashCode => type.hashCode ^ suite.hashCode ^ time.hashCode;

  @override
  String toString() => "SuiteEvent{type: $type, suite: $suite, time: $time}";
}

class DebugEvent extends Event {
  @override
  final String type = "debug";

  /// The suite for which debug information is reported.
  final int suiteID;

  /// The HTTP URL for the Dart Observatory, or `null` if the Observatory isn't
  /// available for this suite.
  final String observatory;

  /// The HTTP URL for the remote debugger for this suite's host page, or `null`
  /// if no remote debugger is available for this suite.
  final String remoteDebugger;

  @override
  final int time;

  DebugEvent(
      {required this.suiteID,
      required this.observatory,
      required this.remoteDebugger,
      required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebugEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          suiteID == other.suiteID &&
          observatory == other.observatory &&
          remoteDebugger == other.remoteDebugger &&
          time == other.time;

  @override
  int get hashCode =>
      type.hashCode ^
      suiteID.hashCode ^
      observatory.hashCode ^
      remoteDebugger.hashCode ^
      time.hashCode;

  @override
  String toString() =>
      "DebugEvent{type: $type, suiteID: $suiteID, observatory: $observatory, remoteDebugger: $remoteDebugger, time: $time}";
}

class GroupEvent extends Event {
  @override
  final String type = "group";

  /// Metadata about the group.
  final Group group;

  @override
  final int time;

  GroupEvent({required this.group, required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          group == other.group &&
          time == other.time;

  @override
  int get hashCode => type.hashCode ^ group.hashCode ^ time.hashCode;

  @override
  String toString() => "GroupEvent{type: $type, group: $group, time: $time}";
}

class TestStartEvent extends Event {
  @override
  final String type = "testStart";

  /// Metadata about the test that started.
  final Test test;

  @override
  final int time;

  TestStartEvent({required this.test, required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestStartEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          test == other.test &&
          time == other.time;

  @override
  int get hashCode => type.hashCode ^ test.hashCode ^ time.hashCode;

  @override
  String toString() => "TestStartEvent{type: $type, test: $test, time: $time}";
}

class MessageEvent extends Event {
  @override
  final String type = "print";

  /// The ID of the test that printed a message.
  final int testID;

  /// The type of message being printed.
  final String messageType;

  /// The message that was printed.
  final String message;

  @override
  final int time;

  MessageEvent(
      {required this.testID,
      required this.messageType,
      required this.message,
      required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          testID == other.testID &&
          messageType == other.messageType &&
          message == other.message &&
          time == other.time;

  @override
  int get hashCode =>
      type.hashCode ^
      testID.hashCode ^
      messageType.hashCode ^
      message.hashCode ^
      time.hashCode;

  @override
  String toString() =>
      "MessageEvent{type: $type, testID: $testID, messageType: $messageType, message: $message, time: $time}";
}

class ErrorEvent extends Event {
  @override
  final String type = "error";

  /// The ID of the test that experienced the error.
  final int testID;

  /// The result of calling toString() on the error object.
  final String error;

  /// The error's stack trace, in the stack_trace package format.
  final String stackTrace;

  /// Whether the error was a TestFailure.
  final bool isFailure;

  @override
  final int time;

  ErrorEvent(
      {required this.testID,
      required this.error,
      required this.stackTrace,
      required this.isFailure,
      required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          testID == other.testID &&
          error == other.error &&
          stackTrace == other.stackTrace &&
          isFailure == other.isFailure &&
          time == other.time;

  @override
  int get hashCode =>
      type.hashCode ^
      testID.hashCode ^
      error.hashCode ^
      stackTrace.hashCode ^
      isFailure.hashCode ^
      time.hashCode;

  @override
  String toString() =>
      "ErrorEvent{type: $type, testID: $testID, error: $error, stackTrace: $stackTrace, isFailure: $isFailure, time: $time}";
}

class TestDoneEvent extends Event {
  @override
  final String type = "testDone";

  /// The ID of the test that completed.
  final int testID;

  /// The result of the test.
  final String result;

  /// Whether the test's result should be hidden.
  final bool hidden;

  /// Whether the test (or some part of it) was skipped.
  final bool skipped;

  @override
  final int time;

  TestDoneEvent(
      {required this.testID,
      required this.result,
      required this.hidden,
      required this.skipped,
      required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestDoneEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          testID == other.testID &&
          result == other.result &&
          hidden == other.hidden &&
          skipped == other.skipped &&
          time == other.time;

  @override
  int get hashCode =>
      type.hashCode ^
      testID.hashCode ^
      result.hashCode ^
      hidden.hashCode ^
      skipped.hashCode ^
      time.hashCode;

  @override
  String toString() =>
      "TestDoneEvent{type: $type, testID: $testID, result: $result, hidden: $hidden, skipped: $skipped, time: $time}";
}

class DoneEvent extends Event {
  @override
  final String type = "done";

  /// Whether all tests succeeded (or were skipped).
  final bool success;

  @override
  final int time;

  DoneEvent({required this.success, required this.time});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoneEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          success == other.success &&
          time == other.time;

  @override
  int get hashCode => type.hashCode ^ success.hashCode ^ time.hashCode;

  @override
  String toString() => "DoneEvent{type: $type, success: $success, time: $time}";
}

class Test {
  /// An opaque ID for the test.
  final int id;

  /// The name of the test, including prefixes from any containing groups.
  final String name;

  /// The ID of the suite containing this test.
  final int suiteID;

  /// The IDs of groups containing this test, in order from outermost to
  /// innermost.
  final List<int> groupIDs;

  /// The (1-based) line on which the test was defined, or `null`.
  final int line;

  /// The (1-based) column on which the test was defined, or `null`.
  final int column;

  /// The URL for the file in which the test was defined, or `null`.
  final String url;

  /// The (1-based) line in the original test suite from which the test
  /// originated.
  ///
  /// Will only be present if `root_url` is different from `url`.
  final int root_line;

  /// The (1-based) line on in the original test suite from which the test
  /// originated.
  ///
  /// Will only be present if `root_url` is different from `url`.
  final int root_column;

  /// The URL for the original test suite in which the test was defined.
  ///
  /// Will only be present if different from `url`.
  final String root_url;

  /// This field is deprecated and should not be used.
  final Metadata metadata;

  Test(
      {required this.id,
      required this.name,
      required this.suiteID,
      required this.groupIDs,
      required this.line,
      required this.column,
      required this.url,
      required this.root_line,
      required this.root_column,
      required this.root_url,
      required this.metadata});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Test &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          suiteID == other.suiteID &&
          groupIDs == other.groupIDs &&
          line == other.line &&
          column == other.column &&
          url == other.url &&
          root_line == other.root_line &&
          root_column == other.root_column &&
          root_url == other.root_url &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      suiteID.hashCode ^
      groupIDs.hashCode ^
      line.hashCode ^
      column.hashCode ^
      url.hashCode ^
      root_line.hashCode ^
      root_column.hashCode ^
      root_url.hashCode ^
      metadata.hashCode;

  @override
  String toString() =>
      "Test{id: $id, name: $name, suiteID: $suiteID, groupIDs: $groupIDs, line: $line, column: $column, url: $url, root_line: $root_line, root_column: $root_column, root_url: $root_url, metadata: $metadata}";
}

class Suite {
  /// An opaque ID for the group.
  final int id;

  /// The platform on which the suite is running.
  final String? platform;

  /// The path to the suite's file.
  final String path;

  Suite({required this.id, this.platform, required this.path});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suite &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          platform == other.platform &&
          path == other.path;

  @override
  int get hashCode => id.hashCode ^ platform.hashCode ^ path.hashCode;

  @override
  String toString() => "Suite{id: $id, platform: $platform, path: $path}";
}

class Group {
  /// An opaque ID for the group.
  final int id;

  /// The name of the group, including prefixes from any containing groups.
  final String? name;

  /// The ID of the suite containing this group.
  final int suiteID;

  /// The ID of the group's parent group, unless it's the root group.
  final int? parentID;

  /// The number of tests (recursively) within this group.
  final int testCount;

  /// The (1-based) line on which the group was defined, or `null`.
  final int line;

  /// The (1-based) column on which the group was defined, or `null`.
  final int column;

  /// The URL for the file in which the group was defined, or `null`.
  final String url;

  /// This field is deprecated and should not be used.
  final Metadata metadata;

  Group(
      {required this.id,
      this.name,
      required this.suiteID,
      this.parentID,
      required this.testCount,
      required this.line,
      required this.column,
      required this.url,
      required this.metadata});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          suiteID == other.suiteID &&
          parentID == other.parentID &&
          testCount == other.testCount &&
          line == other.line &&
          column == other.column &&
          url == other.url &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      suiteID.hashCode ^
      parentID.hashCode ^
      testCount.hashCode ^
      line.hashCode ^
      column.hashCode ^
      url.hashCode ^
      metadata.hashCode;

  @override
  String toString() =>
      "Group{id: $id, name: $name, suiteID: $suiteID, parentID: $parentID, testCount: $testCount, line: $line, column: $column, url: $url, metadata: $metadata}";
}

class Metadata {
  final bool skip;
  final String? skipReason;

  Metadata({required this.skip, this.skipReason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Metadata &&
          runtimeType == other.runtimeType &&
          skip == other.skip &&
          skipReason == other.skipReason;

  @override
  int get hashCode => skip.hashCode ^ skipReason.hashCode;

  @override
  String toString() => "Metadata{skip: $skip, skipReason: $skipReason}";
}

Event parseJsonToEvent(String text) {
  final map = json.decode(text);
  switch (map['type']) {
    case "start":
      return StartEvent(
          protocolVersion: map['protocolVersion'],
          runnerVersion: map['runnerVersion'],
          pid: map['pid'],
          time: map['time']);
    case "allSuites":
      return AllSuitesEvent(count: map['count'], time: map['time']);
    case "suite":
      return SuiteEvent(suite: map['suite'], time: map['time']);
    case "debug":
      return DebugEvent(
          suiteID: map['suiteID'],
          observatory: map['observatory'],
          remoteDebugger: map['remoteDebugger'],
          time: map['time']);
    case "group":
      return GroupEvent(group: map['group'], time: map['time']);
    case "testStart":
      return TestStartEvent(test: map['test'], time: map['time']);
    case "print":
      return MessageEvent(
          testID: map['testID'],
          messageType: map['messageType'],
          message: map['message'],
          time: map['time']);
    case "error":
      return ErrorEvent(
          testID: map['testID'],
          error: map['error'],
          stackTrace: map['stackTrace'],
          isFailure: map['isFailure'],
          time: map['time']);
    case "testDone":
      return TestDoneEvent(
          testID: map['testID'],
          result: map['result'],
          hidden: map['hidden'],
          skipped: map['skipped'],
          time: map['time']);
    case "done":
      return DoneEvent(success: map['success'], time: map['time']);
    default:
      throw Exception('Unknown Event type: $map');
  }
}
