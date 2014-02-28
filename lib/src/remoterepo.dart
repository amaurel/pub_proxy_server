part of pub_proxy_server;

abstract class RemoteRepo implements PubRepo {
  Uri get server;
} 

class DartLangRemoteRepo extends CacheRemoteRepoImpl {
  DartLangRemoteRepo(Store store, HttpClient client):super(store, client){
    server = new Uri.https("pub.dartlang.org", "");
  }
}

class CacheRemoteRepoImpl extends RemoteRepoImpl {
  PubCache cache;
  CacheRemoteRepoImpl(Store store,HttpClient client):super(store,client){
    cache = new PubCache(new Duration(hours:12));
  }
 
  Future<Map> getVersions(String package){
    if (cache.containsKey(package)){
      log.fine("getVersions package $package : found cache entry");
      return new Future.value(cache[package]);
    }
    return super.getVersions(package).then((Map m){
      cache[package] = m;
      return m;
    });
  }
  
  Future<Map> getPubspec(String package, String version){
    var key = "$package-$version";
    if (cache.containsKey(key)){
      log.fine("getPubspec package $package version $version : found cache entry");
      return new Future.value(cache[key]);
    }
    return super.getPubspec(package,version).then((Map m){
      cache[key] = m;
      return m;
    });
  }
  
  Future<bool> containsPackage(String package){
    var key = "$package@contains";
    if (cache.containsKey(key)) {
      log.fine("containsPackage package $package : found cache entry");
      return new Future.value(cache[key]);
    }
    return super.containsPackage(package).then((m){
      cache[key] = m;
      return m;
    });
  }

}
  
class RemoteRepoImpl implements RemoteRepo {
  final Logger log = new Logger('RemoteRepoImpl');
  HttpClient client;
  Uri server;
  Store store;
  
  RemoteRepoImpl(this.store,this.client);
   
  bool get canPublish => false;
  
  Future<File> getPackageFile(String package, String version){
    log.fine("getPackageFile package $package version $version");
    return store.getPackageFile(package, version).then((file){
      if (file != null){
        log.fine("getPackageFile package $package version $version file found : $file");
        return file;
      } else {
        log.fine("getPackageFile package $package version $version file not found");
        return this._downloadPackage(package, version);
      }
    });
  }
  
  Future<Stream> getPackageStream(String package, String version){
      return this.getPackageFile(package, version).then((file){
        return file.openRead();
      });
    }
  
  Future<bool> containsPackage(String package){
    log.fine("containsPackage package $package");
    var uri = server.resolve('/api/packages/$package');
    //HEAD is not working !!! server respond 404
    return client.openUrl("GET", uri).then((request)=>request.close()).then((response){
      response.drain(); //how to interupt/close?
      return response.statusCode == 200;
    });
  }
  
  Future<File> _downloadPackage(String package, String version){
    log.fine("downloadPackage package $package version $version");
    var uri = server.resolve('/packages/$package/versions/${version}.tar.gz');
    return client.getUrl(uri).then((request)=>request.close()).then((response){
      //response.statusCode != 200
      log.fine("downloadPackage $package version $version status ${response.statusCode} response.headers : ${response.headers.toString()}");
      var checksum = extractMD5CheckSum(response);
      return store.savePackage(response, checksum: checksum);
    });
  }
  
  String extractMD5CheckSum(HttpClientResponse response){
    String googhash;
    if (response.headers["x-goog-hash"] != null){
      googhash = response.headers["x-goog-hash"].firstWhere((each)=>each.startsWith("md5"), orElse: ()=> null);
    }
    if (googhash == null) return null;
    log.fine("extractMD5CheckSum found x-goog-hash: $googhash");
    var i = googhash.indexOf("md5="); 
    googhash = googhash.substring(i+"md5=".length);
    log.fine("extractMD5CheckSum md5=$googhash");
    return googhash;
  }
  
  Future<Map> getVersions(String package){
    log.fine("getVersions package $package");
    var uri = server.resolve('/api/packages/$package');
    return client.getUrl(uri).then((request)=>request.close()).then((response){
      return response.transform(new  Utf8Decoder()).transform(new JsonDecoder(null)).single;
    });
  }
  
  Future<Map> getPubspec(String package, String version){
    log.fine("getPubspec package $package version $version");
    var uri = server.resolve('/api/packages/$package/versions/$version');
    return client.getUrl(uri).then((request)=>request.close()).then((response){
      return response.transform(new Utf8Decoder()).transform(new JsonDecoder(null)).single;
    });
  }
  
  Future publishPackage(Stream stream, {String checksum}){
    throw "not yet implemented";
  }
}