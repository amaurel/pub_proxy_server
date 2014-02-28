import 'package:logging/logging.dart';
import 'package:pub_proxy_server/pub_proxy_server.dart';


void main() {
  initLog();
  PermissionStore store = new PermissionStore();
  store.addPermission(new UserPermission("alexandre", "alexandre"));
  store.addPermission(new UserPermission("alexandre.maurel@gmail.com", "")); //necessary to publish
  store.addPermission(new UserPermission("heroku", "heroku"));
  start_pub_proxy_server(new PubFederatedRepo.localAndDartLangProxy(), permissionStore:store);
}
 
initLog(){
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}:${rec.loggerName}: ${rec.time}: ${rec.message}');
    if (rec.error != null) print(rec.error);
    if (rec.stackTrace != null) print(rec.stackTrace);
  });
}