part of pub_proxy_server;

class PubFederatedRepo implements PubRepo {
  final Logger log = new Logger('PubFederatedRepo');
  List<PubRepo> repos = [];
  
  PubFederatedRepo.localAndDartLangProxy(){
    repos = [new PubRepoImpl(new Store(new StoreSettings())), 
             new DartLangRemoteRepo(new Store(new StoreSettings.fromRepoDirPrefix('cache')), new HttpClient())];
  }
  
  PubFederatedRepo(this.repos);
  
  Future<File> getPackageFile(String package, String version){
    return this.findRepoForPackage(package).then((repo){
      return repo.getPackageFile(package, version);
    });
  }
  
  Future<Stream> getPackageStream(String package, String version){
    return this.findRepoForPackage(package).then((repo){
          return repo.getPackageStream(package, version);
        });
  }
  
  Future<Map> getVersions(String package){
    return this.findRepoForPackage(package).then((repo){
      return repo.getVersions(package);
    });
  }
  
  Future<Map> getPubspec(String package, String version){
    return this.findRepoForPackage(package).then((repo){
      return repo.getPubspec(package, version);
    });
  }
  
  Future publishPackage(Stream stream, {String checksum}){
    if (!canPublish) throw "cannot publish";
    return this.repos.firstWhere((repo)=>repo.canPublish).publishPackage(stream, checksum: checksum);
  }
  
  bool get canPublish => this.repos.any((each)=>each.canPublish);
  Future<bool> containsPackage(String package)=>this.findRepoForPackage(package, orElse:()=>null).then((pack)=>pack != null);

  Future<PubRepo> findRepoForPackage(String package, {orElse()}){
    Function fun = orElse != null ? orElse : ()=>throw new PubRepoException("package $package not found");
    return pps_async.firstWhere(this.repos, (PubRepo repo){
      log.fine("findRepoForPackage $package searching in $repo");
      return repo.containsPackage(package);
    }, orElse:fun).then((repo){
      log.fine("findRepoForPackage $package found in $repo");
      return repo;
    });
  }
}