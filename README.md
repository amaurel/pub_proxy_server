pub_proxy_server
=====

Private pub and proxy server.

Installation
------------

Add this package to your pubspec.yaml file:

    dependencies:
      pub_proxy_server: any

Then, run `pub install` to download and link in the package.
  
Set PUB_HOSTED_URL environent variable to something like http://127.0.0.1:8042

```dart
import 'package:pub_proxy_server/pub_proxy_server.dart' as pub_proxy_server;

void main() {
  pub_proxy_server.start();
  //pub_proxy_server.start(port:8888,packageCacheDirectory:"some directory ...");
}
```