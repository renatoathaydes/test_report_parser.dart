# test_report_parser

This library contains an auto-generated Dart Model representing the events emitted by the Dart Tests JSON reporter.

It can be used to parse the Dart Test JSON report into typed Dart objects for further processing.

The model is generated by parsing the [json_reporter.md](https://raw.githubusercontent.com/dart-lang/test/master/pkgs/test/doc/json_reporter.md)
page, which documents the Dart Test JSON reporter output.

## Building

This project relies on [Dartle](https://github.com/renatoathaydes/dartle/) to run the build.

If you have `dartle` installed, simply run `dartle` in the root directory to build everything.

Otherwise, run the build using `dart` as following:

```bash
dart pub get
dart dartle.dart
```
