import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          final directory = Directory('../website/captures/ios-simulator/core');
          directory.createSync(recursive: true);
          final image = File('${directory.path}/$screenshotName.png');
          image.writeAsBytesSync(screenshotBytes);

          final result = Process.runSync('python3', <String>[
            'test_driver/ios_fullscreen_postprocess.py',
            image.path,
          ]);
          if (result.exitCode != 0) {
            stderr.writeln(result.stderr);
            return false;
          }
          return true;
        },
  );
}
