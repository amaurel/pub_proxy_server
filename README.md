pub_proxy_server
=====

Private pub and proxy server.

Publish private package to your local server.
Act as proxy for pub.dartlang.org.
Private and public packages all accessible through pub command line.

pub publish --server http://127.0.0.1:8042
pub get


Installation
------------

Add this package to your pubspec.yaml file:

    dependencies:
      pub_proxy_server: any

Then, run `pub install` to download and link in the package.
  
Set PUB_HOSTED_URL environent variable to http://127.0.0.1:8042

```dart
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
```

Roadmap
------------

md5 checksum

Add a transactional store, SQLite, Mongo .. ?

Https support

Web admin pages

Autentication

