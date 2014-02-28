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
    return stream.forEach((bytes)=>sink.add(bytes))
      .then((_)=>sink.close())
      .then((_)=>pps_io.checkSum(tmpfile, checksum))
      .then((check)=> check == true ? true : throw new PubRepoException("checksum failed for file : $tmpfile"))
      .then((_)=>pps_io.run("tar" , ["-xzvf" , "package.tar.gz"], workingDirectory:tmpdirectory.path))
      .then((_){
        var pubspec = new File(path.join(tmpdirectory.path,'pubspec.yaml'));  
        var doc = yaml.loadYaml(pubspec.readAsStringSync());
        var package = doc["name"]; var version = doc["version"];
        File file = settings.packageFile(package,version);
        if (file.existsSync()) throw new PubRepoException("cannot save package $package, file $file is in the way.");
        pps_io.ensureDirectoryExist(packageDirectory(package));
        var dir = packageDirectory(package).createTempSync("tmp_$version");
        tmpfile = tmpfile.renameSync(path.join(tmpfile.parent.path, path.basename(file.path)));
        pps_io.moveFile(pubspec, dir.path);
        pps_io.moveFile(tmpfile, dir.path);
        dir.renameSync(settings.packageVersionDirectory(package,version).path);
        return file;})
      .then((file)=>tmpdirectory.delete(recursive: true).then((_)=>file));
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
    pps_io.ensureDirectoryExist(repoDir);
    pps_io.ensureDirectoryExist(tmpDir);
    log.fine('ensureDirectory repoDir $repoDir');
    log.fine('ensureDirectory tmpDir $tmpDir');
  }
  
  Directory packageDirectory(package)=>new Directory(path.join(repoDir,package));
  Directory packageVersionDirectory(package,version)=>new Directory(path.join(packageDirectory(package).path,version));
  File packageYamlFile(package,version)=>new File(path.join(packageVersionDirectory(package,version).path, "pubspec.yaml"));
  File packageFile(package,version)=>new File(path.join(packageVersionDirectory(package,version).path, "${package}.tar.gz"));
}