import 'package:test_report_parser/test_report_parser.dart';

const logExample = r'''
{"protocolVersion":"0.1.1","runnerVersion":"1.16.8","pid":45879,"type":"start","time":0}
{"suite":{"id":0,"platform":"vm","path":"test/io_test.dart"},"type":"suite","time":0}
{"test":{"id":1,"name":"loading test/io_test.dart","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":null,"column":null,"url":null},"type":"testStart","time":2}
{"suite":{"id":2,"platform":"vm","path":"test/cache_test.dart"},"type":"suite","time":16}
{"success":true,"type":"done","time":36361}
''';

void main() {
  for (final line in logExample.split('\n').where((l) => l.isNotEmpty)) {
    final event = parseJsonToEvent(line);
    print(event);

    // check specific events
    if (event is TestStartEvent) {
      print('=== Test "${event.test.name}" has started. ===');
    }
    if (event is DoneEvent) {
      if (event.success) {
        print('!!!!!! Tests were successful !!!!!!');
      } else {
        print('XXXXXX There were failures. XXXXXX');
      }
    }
  }
}
