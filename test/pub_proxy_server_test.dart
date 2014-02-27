library pub_proxy_server_test;
import 'dart:io';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:pub_proxy_server/pub_proxy_server.dart';
import 'package:logging/logging.dart';

part 'src/remoterepo_test.dart';

void main(){
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}:${rec.loggerName}: ${rec.time}: ${rec.message}');
    if (rec.error != null) print(rec.error);
    if (rec.stackTrace != null) print(rec.stackTrace);
  });
  remoterepo_test();
   
}