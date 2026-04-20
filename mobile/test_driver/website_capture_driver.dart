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
          return true;
        },
  );
}
