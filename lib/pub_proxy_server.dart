library proxy_pub_server;

import 'dart:io' ;
import 'dart:async';
import 'package:http_server/http_server.dart' show VirtualDirectory;
import 'package:path/path.dart' show join, dirname;
import 'package:route/server.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:route_hierarchical/url_template.dart';
import 'package:route_hierarchical/url_matcher.dart';
 
String pub_dartlang_org = "https://pub.dartlang.org" ; 
 
UrlTemplate apiPackagesUrlTemplate = new UrlTemplate('/api/packages/:package');
UrlTemplate apiPackagesVersionUrlTemplate = new UrlTemplate('/api/packages/:package/versions/:version');
UrlTemplate packagesUrlTemplate = new UrlTemplate('/packages/:package/versions/:version');
 
final Logger log = new Logger('main');

void start() {
  initLog();
  var packageCacheDirectory = normalize(join(dirname(Platform.script.toFilePath()), '..', 'build' , 'pubcache' ));
  var dir = new Directory(packageCacheDirectory);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  log.fine("packageCacheDirectory : $packageCacheDirectory");
  VirtualDirectory staticFiles = new VirtualDirectory(packageCacheDirectory);
  HttpClient client = new HttpClient();
  Map cache = {};
    
  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 8042 : int.parse(portEnv);
  
  bool isLocalPackage(String package){
    log.fine("isLocalPackage package : $package");
    return false;
  }
  
  Future<Map> servePubProxy(request){
    return client.getUrl(Uri.parse("$pub_dartlang_org${request.uri.path}"))
      .then((remoterequest)=>remoterequest.close())
        .then((remoteresponse){
          return remoteresponse.toList().then((bytes){
            return {"bytes":bytes, "headers":remoteresponse.headers};
          });
        });
  }
  
  Future serveCacheValue(HttpRequest request, cacheValue){
    cacheValue["headers"].forEach((name, values)=>values.forEach((value)=>request.response.headers.add(name, value)));
    List<List<int>> bytes = cacheValue["bytes"];
    bytes.forEach((b)=>request.response.add(b));
    return request.response.close();
  }
  
  void servePubProxyCache(HttpRequest request){
    if (cache.containsKey(request.uri.path)){
      serveCacheValue(request, cache[request.uri.path]);
    } else {
      if ((packagesUrlTemplate.match(request.uri.path)) != null){
        var filename = packageCacheDirectory+request.uri.toFilePath();
        File file = new File(filename);
        if (file.existsSync()) staticFiles.serveFile(file, request);
        else {
          servePubProxy(request).then((Map answer){
            if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
            List<List<int>> bytes = answer["bytes"];
            IOSink sink = file.openWrite();
            bytes.forEach((b)=>sink.add(b));
            return sink.close();
          }).then((_)=>staticFiles.serveFile(file, request));
        }
      } else {
        servePubProxy(request).then((Map answer){
          cache[request.uri.path] = answer;
          return serveCacheValue(request, answer);
        });
      }
    }
  }
  
  servepackage(HttpRequest request){
    
  }
  
  servepackageversion(HttpRequest request){
    
  }
  
  servedownloadpackage(HttpRequest request){
    
  }
  
  void servepub(HttpRequest request){
    log.fine("req ${request.uri.path}");
    UrlMatch match;
    if ((match = apiPackagesVersionUrlTemplate.match(request.uri.path)) != null){
      if (isLocalPackage(match.parameters["package"])){
        servepackage(request);
      }
    } else if ((match = apiPackagesUrlTemplate.match(request.uri.path)) != null){
      if (isLocalPackage(match.parameters["package"])){
        servepackageversion(request);
      }
    } else if ((match = packagesUrlTemplate.match(request.uri.path)) != null){
       if (isLocalPackage(match.parameters["package"])){
         servedownloadpackage(request);
      }
    }
    servePubProxyCache(request);
  }
   
  Future<String> requestpub(HttpRequest request){
    client.getUrl(Uri.parse("$pub_dartlang_org${request.uri.path}"))
      .then((HttpClientRequest remoterequest)=>remoterequest.close())
        .then((HttpClientResponse remoteresponse){
          remoteresponse.headers.forEach((name, values)=>values.forEach((value)=>request.response.headers.add(name, value)));
          remoteresponse.pipe(request.response);
        });
  }
   
  runZoned(() {
    HttpServer.bind('0.0.0.0', port).then((server) {
      log.fine("Server started listening port $port");
      var router = new Router(server)..defaultStream.listen(servepub);
    });
  },
  onError: (e, stackTrace) => log.warning('Oups !', e ,stackTrace));
}

initLog(){
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}:${rec.loggerName}: ${rec.time}: ${rec.message}');
    if (rec.error != null) print(rec.error);
    if (rec.stackTrace != null) print(rec.stackTrace);
  });
}