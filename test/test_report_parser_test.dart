import 'package:test/scaffolding.dart';

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
  test('can parse successful test output', () {});
}
