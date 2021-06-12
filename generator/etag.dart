import 'dart:io';
import 'common.dart';

final etagFile = File('.dartle_tool/etag.txt');

Future<String?> loadEtag() async {
  if (await etagFile.exists()) {
    final etag = await etagFile.readAsString();
    logger.fine('Using etag $etag');
    return etag;
  }
  return null;
}

Future<void> storeEtag(String etag) async {
  if (!await etagFile.parent.exists()) {
    await etagFile.parent.create(recursive: true);
  }
  if (etag.startsWith('W/')) {
    etag = etag.substring(2);
  }
  await etagFile.writeAsString(etag, flush: true);
}
