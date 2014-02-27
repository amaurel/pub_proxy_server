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

import 'package:pub_proxy_server/src/async.dart' as pps_async;
 
 
part 'src/cache.dart';
part 'src/store.dart';
part 'src/repo.dart';
part 'src/remoterepo.dart';
part 'src/federatedrepo.dart';
part 'src/io.dart';

void start_pub_proxy_server(PubRepo repo, {int port}) {
  
  final Logger log = new Logger('pub_proxy_server');
  final String pub_dartlang_org = "https://pub.dartlang.org" ; 
  final UrlTemplate apiPackagesUrlTemplate = new UrlTemplate('/api/packages/:package');
  final UrlTemplate apiPackagesVersionUrlTemplate = new UrlTemplate('/api/packages/:package/versions/:version');
  final UrlTemplate packagesUrlTemplate = new UrlTemplate('/packages/:package/versions/:version');
  final UrlTemplate apiPackagesVersionNewUrlTemplate = new UrlTemplate('/api/packages/versions/new');
  final UrlTemplate uploadUrlTemplate = new UrlTemplate('/upload');
  final UrlTemplate uploadsuccessUrlTemplate = new UrlTemplate('/successupload');
 
  if (port == null) port = Platform.environment['PORT'] == null ? 8042 : int.parse(Platform.environment['PORT']);
  
  VirtualDirectory staticFiles = new VirtualDirectory('');
  HttpClient client = new HttpClient(); 
   
  Future servepackage(HttpRequest request, String package){
    log.fine("servepackage package $package");
    return repo.getVersions(package).then((Map versions){
      return request.response..write(JSON.encode(versions))..close();
    });
  }
  
  Future servepackageversion(HttpRequest request, String package, String version){
    log.fine("servepackageversion package $package version $version");
    return repo.getPubspec(package, version).then((Map pubspec){
      return request.response..write(JSON.encode(pubspec))..close();
    });
    
  }
  
  Future servedownloadpackage(HttpRequest request, String package, String version){
    if (version.endsWith('.tar.gz')) version = version.substring(0, version.length - '.tar.gz'.length);
    log.fine("servedownloadpackage package $package version $version");
    return repo.getPackageFile(package, version).then((file){
      return staticFiles.serveFile(file,request);
    });
  }
  
  Future servenewpackage(HttpRequest request){
    log.fine("servenewpackage");
    return client.getUrl(Uri.parse("$pub_dartlang_org${request.uri.path}"))
        .then((remoterequest){
          remoterequest.headers.add("authorization", request.headers["authorization"]);
          remoterequest.headers.add("accept", "application/vnd.pub.v2+json");
          remoterequest.headers.add("user-agent", "Dart pub 1.1.3");
          return remoterequest.close();
        })
          .then((HttpClientResponse remoteresponse){
            var host = request.headers["host"].first;
            String answer = '{"url":"http://$host/upload","fields":{}}';
            log.fine("servenewpackage response $answer");
            request.response.write(answer);
            return request.response.close();
          });
  }
  
  String findBoundary(HttpRequest request){
    var contentype = request.headers["content-type"].first;
    var i = contentype.indexOf("boundary=");
    String boundary = contentype.substring(i+1+"boundary=".length, contentype.length-1);
    print("boundary $boundary");
    return boundary;
  }
  
  Future serveupload(HttpRequest request){
    log.fine("serveupload");
    String boundary = findBoundary(request);
    MimeMultipartTransformer mt = new MimeMultipartTransformer(boundary);
    return request.transform(mt).listen((MimeMultipart mm){
      return repo.publishPackage(mm).then((_){
        var host = request.headers["host"].first;
        var location = "http://$host/successupload";
        log.fine("serveupload location $location");
        request.response.headers.add("location", location);
        return request.response.close();
      });
    }).asFuture();
  }
  
  Future servesuccessupload(HttpRequest request){
    log.fine("servesuccessupload");
    request.response..write('{"success": {"message": "Done"}}');
    return request.response.close();
  }
  
  Future serveunknown(HttpRequest request){
    log.warning("serveunknown");
    log.warning("serveunknown ${request.headers}");
    log.warning("serveunknown ${request.uri.authority}");
    request.response.statusCode = 500;
    return request.response.close();
  }
  
  void handleError(HttpRequest request, e, st){
    if (e is PubRepoException){
      log.warning(e.msg, e );
    } else {
      log.warning('Oups !', e ,st);
    }
    try {
      request.response.statusCode = 404;
    } catch (e){
      
    }
    try {
      request.response.close();
    } catch (e){
      
    }
  }
  
  void servepub(HttpRequest request){
    log.fine("servepub ${request.uri.path}");
    log.fine("servepub ${request.headers}");
    try {
      UrlMatch match;
      Future fut;
      if ((match = apiPackagesVersionNewUrlTemplate.match(request.uri.path)) != null){
        fut = servenewpackage(request);
      } else if ((match = apiPackagesVersionUrlTemplate.match(request.uri.path)) != null){
        fut = servepackageversion(request,match.parameters["package"],match.parameters["version"]);
      } else if ((match = apiPackagesUrlTemplate.match(request.uri.path)) != null){
        fut = servepackage(request,match.parameters["package"]);
      } else if ((match = packagesUrlTemplate.match(request.uri.path)) != null){
        fut = servedownloadpackage(request,match.parameters["package"],match.parameters["version"]);
      } else if ((match = uploadUrlTemplate.match(request.uri.path)) != null){
        fut = serveupload(request);
      } else if ((match = uploadsuccessUrlTemplate.match(request.uri.path)) != null){
        fut = servesuccessupload(request);
      } else {
        fut = serveunknown(request);
      }
      fut.catchError((e, st)=>handleError(request, e, st));
    } catch (e,st){
      handleError(request, e, st);
    }
  }
   
  runZoned(() {
    HttpServer.bind('0.0.0.0', port).then((server) {
      log.fine("Server started listening port $port");
      var router = new Router(server)..defaultStream.listen(servepub);
    });
  },
  onError: (e, stackTrace) {
    if (e is PubRepoException){
      log.warning(e.msg, e );
    } else {
      log.warning('Oups !', e ,stackTrace);
    }
  });
}
 





