part of pub_proxy_server;

abstract class PubRepo {
  Future<File> getPackageFile(String package, String version);
  Future<Map> getVersions(String package);
  Future<Map> getPubspec(String package, String version);
  Future publishPackage(Stream stream, {String checksum});
  bool get canPublish;
  Future<bool> containsPackage(String package);
}
 
class PubRepoImpl implements PubRepo {
  final Logger log = new Logger('PubRepoImpl');
  Store store;
  
  PubRepoImpl(this.store);
  
  bool get canPublish => true;
  
  Future<bool> containsPackage(String package){
    return getVersions(package).then((m){
      return m["versions"].isNotEmpty;
    });
  }
  
  Future<File> getPackageFile(String package, String version)=>store.getPackageFile(package, version);
  
  Future<Map> getVersions(String package){
    log.fine("getVersions package $package");
    return new Future.sync((){
      var versions = [];
      var dir = store.packageDirectory(package);
      if (!dir.existsSync()) return {"versions":versions};
      store.packageDirectory(package).listSync(recursive: false).forEach((fse){
        if (fse is File && fse.path.endsWith(".yaml")) versions.add({"version":yaml.loadYaml(fse.readAsStringSync())["version"]});
      });
      return {"versions":versions};
    });
  }
  
  Future<Map> getPubspec(String package, String version){
    log.fine("getPubspec package $package version $version");
    return new Future.sync(()=>{"pubspec":yaml.loadYaml(store.packageYamlFile(package,version).readAsStringSync())});
  }
  
  Future publishPackage(Stream stream, {String checksum}){
    log.fine("publishPackage");
    return store.savePackage(stream, checksum:checksum);
  }
}

class PubRepoException {
  String msg;
  PubRepoException(this.msg);
  
  String toString(){
    return "PubRepoException($msg)";
  }
}