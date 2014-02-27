part of pub_proxy_server;

class Store {
  final Logger log = new Logger('Store');
  StoreSettings settings;
  Store(this.settings){
    this.settings.ensureDirectory();
  }
  
  bool containsPackage(String package)=>(settings.packageDirectory(package).existsSync());
   
  Future<File> getPackageFile(String package, String version){
    var file = settings.packageFile(package, version);
    log.fine("getPackageFile $package $version file $file");
    if (file.existsSync()){
      return new Future.value(file);
    } else {
      return new Future.value(null);
    }
  }
  Directory packageDirectory(package) =>this.settings.packageDirectory(package);
  File packageYamlFile(package,version)=>this.settings.packageYamlFile(package, version);
  
  Future savePackage(Stream stream, {String checksum}){
    log.fine("savePackage");
    var tmpdirectory = new Directory(settings.tmpDir).createTempSync("tmp");
    var tmpfile = new File(path.join(tmpdirectory.path,'package.tar.gz'));
    var sink = tmpfile.openWrite();
    //return stream.pipe(s).then((_){ not working !!!
    return stream.forEach((bytes)=>sink.add(bytes)).then((_)=>sink.close()).then((_){
      return _checkSum(tmpfile, checksum).then((check){
        if (!check) throw new PubRepoException("checksum failed for file : $tmpfile");
        return run("tar" , ["-xzvf" , "package.tar.gz"], workingDirectory:tmpdirectory.path).then((_){
          var pubspec = new File(path.join(tmpdirectory.path,'pubspec.yaml'));  
          var doc = yaml.loadYaml(pubspec.readAsStringSync());
          var package = doc["name"]; var version = doc["version"];
          File file = settings.packageFile(package,version);
          if (file.existsSync()) throw new PubRepoException("cannot save package $package, file $file is in the way.");
          var dir = packageDirectory(package);
          ensureDirectoryExist(dir.path);
          File pubspecfile = settings.packageYamlFile(package,version);
          File tmppubspeclfile = new File(path.join(pubspecfile.parent.path,'tmp.yaml'));
          return pubspec.copy(tmppubspeclfile.path).then((_){
            tmppubspeclfile.renameSync(pubspecfile.path);
            File dummyfile = new File(path.join(file.parent.path,'package.tar.gz'));
            return tmpfile.copy(dummyfile.path).then((_){
              dummyfile.renameSync(file.path);
              return tmpdirectory.delete(recursive: true).then((_){
                return file;
              });
            });
          });
        }); 
      });
    });
  }
}
 

class StoreSettings {
  final Logger log = new Logger('StoreSettings');
  String repoDir;
  String tmpDir;
  String defaultRepoDir = 'repo';
  
  StoreSettings.fromRepoDirPrefix(this.defaultRepoDir);
  StoreSettings.fromDir(this.repoDir,this.tmpDir);
  StoreSettings();
  
  String get _homeDir {
    if (Platform.operatingSystem == 'windows') return path.join(Platform.environment['APPDATA'], 'pub_proxy_server');
    else return path.join(Platform.environment['HOME'], '.pub_proxy_server');
  } 
  
  ensureDirectory(){
    repoDir = repoDir == null ? path.join(this._homeDir, this.defaultRepoDir): repoDir;
    tmpDir = tmpDir == null ? path.join(this._homeDir,'tmp') : tmpDir;
    ensureDirectoryExist(repoDir);
    ensureDirectoryExist(tmpDir);
    log.fine('ensureDirectory repoDir $repoDir');
    log.fine('ensureDirectory tmpDir $tmpDir');
  }
  
  Directory packageDirectory(package)=>new Directory(path.join(repoDir,package));
  File packageYamlFile(package,version)=>new File(path.join(packageDirectory(package).path, "$version.yaml"));
  File packageFile(package,version)=>new File(path.join(packageDirectory(package).path, "${version}.tar.gz"));
}