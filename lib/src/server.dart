part of pub_proxy_server;

class PubServer {
   
  PubRepo repo;
  int port;
  PermissionStore permissionStore;
  bool isSecure;
  String address;
  
  final Logger log = new Logger('PubServer');
  final String pub_dartlang_org = "https://pub.dartlang.org" ; 
  final UrlTemplate apiPackagesUrlTemplate = new UrlTemplate('/api/packages/:package');
  final UrlTemplate apiPackagesVersionUrlTemplate = new UrlTemplate('/api/packages/:package/versions/:version');
  final UrlTemplate packagesUrlTemplate = new UrlTemplate('/packages/:package/versions/:version');
  final UrlTemplate apiPackagesVersionNewUrlTemplate = new UrlTemplate('/api/packages/versions/new');
  final UrlTemplate uploadUrlTemplate = new UrlTemplate('/upload');
  final UrlTemplate uploadsuccessUrlTemplate = new UrlTemplate('/successupload');
  VirtualDirectory staticFiles = new VirtualDirectory('');
  HttpClient client = new HttpClient(); 
  
  PubServer(this.repo, this.port, {bool isSecure: false, String address:'0.0.0.0', PermissionStore permissionStore}){
    this.permissionStore = permissionStore;
    this.isSecure = isSecure;
    this.address = address;
  }
  
  Future<HttpServer> bind(){
    if (isSecure){
      return HttpServer.bindSecure(address, port);      
    } else {
      return HttpServer.bind(address, port);
    }
  }
  
  start(){
    runZoned(() {
      bind().then((server) {
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
  
  Future<bool> checkRequestOauthPermission(String token){
    log.fine("checkRequestOauthPermission token xxx");
    return this.client.getUrl(new Uri.https("www.googleapis.com", "/oauth2/v1/userinfo", {"access_token":token})).then((request){
      return request.close().then((HttpClientResponse response){
        if (response.statusCode != 200) return false;
        return response.transform(new Utf8Decoder()).transform(new JsonDecoder(null)).single.then((Map m){
          if (m.containsKey("email")){
            return this.permissionStore.isValideUserName(m["email"]);
          } else {
            return false;
          }
        });
      });
    });
  }
  
  Future<bool> checkRequestPermission(HttpRequest request){
    log.fine("checkRequestPermission");
    return new Future.sync((){
      if (permissionStore == null) return true;
          if (request.headers["authorization"] == null || request.headers["authorization"].isEmpty){
            return false;
          }
          var auth = request.headers["authorization"].first;
          log.fine("checkRequestPermission auth $auth");
          var authType = auth.split(" ");
          if (authType.length != 2) return false;
          auth = authType.last.trim();
          authType = authType.first.trim();
          if (authType == "Basic"){
            log.fine("checkRequestPermission $authType");
            auth = new String.fromCharCodes(CryptoUtils.base64StringToBytes(auth));
            List list = auth.split(":");
            if (list.length != 2) return false;
            var username = list.first;
            var password = list.last;
            return this.permissionStore.isValidUser(username, password);
          } else if (authType == "Bearer") {
            log.fine("checkRequestPermission $authType");
            return checkRequestOauthPermission(auth);
          } else {
            log.warning("checkRequestPermission unknown authentication type $authType");
            return false;
          }
    });
  }
  
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
    return repo.getPackageStream(package, version).then((stream){
      return stream.forEach((bytes)=>request.response.add(bytes)).then((_){
        return request.response.close();
      });
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
  
  Future permissionDenied(HttpRequest request){
    request.response.statusCode = 550;
    return request.response.close();
  }
  
  Future servepub(HttpRequest request){
    log.fine("servepub ${request.uri.path}");
    log.fine("servepub ${request.headers}");
    log.fine("servepub ${request.connectionInfo.remoteAddress}");
    return checkRequestPermission(request).then((flag){
      if (flag) return basicservepub(request); 
      else return permissionDenied(request);
    });
  }
  
  String getParam(String param, UrlMatch match){
    var pa = Uri.decodeComponent(match.parameters[param]);
    log.fine("getParam $pa");
    return pa;
  }
  
  Future basicservepub(HttpRequest request){
    

    UrlMatch match;
    Future fut;
    if ((match = apiPackagesVersionNewUrlTemplate.match(request.uri.path)) != null){
      fut = servenewpackage(request);
    } else if ((match = apiPackagesVersionUrlTemplate.match(request.uri.path)) != null){
      fut = servepackageversion(request,getParam("package",match),getParam("version",match));
    } else if ((match = apiPackagesUrlTemplate.match(request.uri.path)) != null){
      fut = servepackage(request,getParam("package",match));
    } else if ((match = packagesUrlTemplate.match(request.uri.path)) != null){
      fut = servedownloadpackage(request,getParam("package",match),getParam("version",match));
    } else if ((match = uploadUrlTemplate.match(request.uri.path)) != null){
      fut = serveupload(request);
    } else if ((match = uploadsuccessUrlTemplate.match(request.uri.path)) != null){
      fut = servesuccessupload(request);
    } else {
      fut = serveunknown(request);
    }
    return fut;
  }
}