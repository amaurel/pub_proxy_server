part of pub_proxy_server;

class PubCache<K,V> {
  final Logger log = new Logger('PubCache');
  Map<K,V> cache;
  Timer timer;
  
  PubCache(Duration invalideEvery){
    cache={};
    timer = new Timer.periodic(invalideEvery, invalidate);
  }
  
  void invalidate(Timer t){
    log.fine("invalidate");
    cache={};
  }
  
  V operator [](Object key)=>cache[key];
  void operator []=(K key, V value){cache[key]=value;}
  bool containsKey(Object key)=>cache.containsKey(key);
}