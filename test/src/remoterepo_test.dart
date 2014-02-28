part of  pub_proxy_server_test;

remoterepo_test(){
  
  test('test 1 : containsPackage' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.containsPackage("yaml").then((flag){
      expect(flag, equals(true));
    }).then((_){
      return repo.containsPackage("000000121").then((flag){
        expect(flag, equals(false));
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
  
  test('test 4 : getPackageStream' , (){
    PubRepo repo = new PubFederatedRepo.localAndDartLangProxy();
    return repo.getPackageStream("uuid", "0.2.2").then((Stream stream){
      expect(stream != null, equals(true));
      return stream.drain();
    });
  });
}