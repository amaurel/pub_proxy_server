import 'package:logging/logging.dart';
import 'package:pub_proxy_server/pub_proxy_server.dart';


void main() {
  initLog();
  start_pub_proxy_server(new PubFederatedRepo.localAndDartLangProxy());
}
 
initLog(){
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}:${rec.loggerName}: ${rec.time}: ${rec.message}');
    if (rec.error != null) print(rec.error);
    if (rec.stackTrace != null) print(rec.stackTrace);
  });
   
}