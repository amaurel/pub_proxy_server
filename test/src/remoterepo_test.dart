part of  pub_proxy_server_test;

remoterepo_test(){
  
  test('test 1 : containsPackage' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.containsPackage("yaml").then((flag){
      expect(flag, equals(true));
    }).then((_){
      return repo.containsPackage("000000121").then((flag){
        //expect(flag, equals(false));
      });
    });
  });
  
  test('test 2 : getVersions' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.getVersions("yaml").then((Map m){
      expect(m.containsKey("versions"), equals(true));
      expect(m["versions"].isNotEmpty, equals(true));
    });
  });
  
  test('test 3 : getPubspec' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.getPubspec("http_server", "0.9.1").then((Map m){
      expect(m.containsKey("pubspec"), equals(true));
    });
  });
  
  test('test 4 : getPackageFile' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.getPackageFile("uuid", "0.2.2").then((File file){
      expect(file.existsSync(), equals(true));
      expect(file.path.endsWith("0.2.2.tar.gz"), equals(true));
    });
  });
  
  test('test 5 : getPackageFile' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    var futures = [];
    futures.add(repo.getPackageFile("dbcrypt", "0.2.1"));
    futures.add(repo.getPackageFile("drandom", "0.0.3"));
    return Future.wait(futures).then((files){
      expect(files[0].existsSync(), equals(true));
      expect(files[0].path.endsWith("0.2.1.tar.gz"), equals(true));
      expect(files[1].existsSync(), equals(true));
      expect(files[1].path.endsWith("0.0.3.tar.gz"), equals(true));
    });
  });
}