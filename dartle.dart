import 'package:dartle/dartle_dart.dart';
import 'package:path/path.dart' show join;

import 'generator/generate.dart';

final dartleDart = DartleDart();

final libDirDartFiles =
    dir(join(dartleDart.rootDir, 'lib'), fileExtensions: const {'.dart'});

void main(List<String> args) {
  dartleDart.formatCode.dependsOn({'generateDartSources'});

  final generateTask = Task(generateDartSources,
      argsValidator: const ArgsCount.range(min: 0, max: 1),
      phase: TaskPhase.custom(TaskPhase.setup.index + 1, 'code_generation'),
      description: 'Generates the model of the Dart Test JSON Reporter from'
          ' the Markdown Docs on GitHub');

  run(args, tasks: {
    generateTask,
    ...dartleDart.tasks,
  }, defaultTasks: {
    dartleDart.build
  });
}

Future<void> generateDartSources(List<String> args) async {
  var force = false;
  if (args.length == 1) {
    if (args[0] == 'force') {
      force = true;
    } else {
      throw Exception('Unrecognized option: ${args[0]}');
    }
  }
  await generateModel(force: force);
}
