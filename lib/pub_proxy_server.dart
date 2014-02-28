library pub_proxy_server;

import 'dart:io' ;
import 'dart:async';
import 'dart:convert';
import 'package:http_server/http_server.dart' show VirtualDirectory;
import 'package:route/server.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:route_hierarchical/url_template.dart';
import 'package:route_hierarchical/url_matcher.dart';
import 'package:mime/mime.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:crypto/crypto.dart';

import 'package:pub_proxy_server/src/async.dart' as pps_async;
import 'package:pub_proxy_server/src/io.dart' as pps_io;
 
part 'src/cache.dart';
part 'src/store.dart';
part 'src/repo.dart';
part 'src/remoterepo.dart';
part 'src/federatedrepo.dart';
part 'src/server.dart';
part 'src/permissions.dart';

void start_pub_proxy_server(PubRepo repo, {int port, PermissionStore permissionStore}) {
  if (port == null) port = Platform.environment['PORT'] == null ? 8042 : int.parse(Platform.environment['PORT']);
  var server = new PubServer(repo, port, permissionStore:permissionStore);
  server.start();
}
 





