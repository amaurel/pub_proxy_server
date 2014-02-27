library pub_proxy_server.async;

import 'dart:async';

Future<bool> _any(Iterator itr, Future<bool> f(element) ){
    if (itr.moveNext()){
      return f(itr.current).then((flag){
        if (flag){
          return true;
        } else {
          return _any(itr, f);
        }
      });
    } else {
      return new Future.value(false);
    }
  }
  
Future<bool> any(Iterable input, Future<bool> f(element)){
  return _any(input.iterator, f);
}

Future firstWhere(Iterable input, Future<bool> f(element), { Function orElse }){
  if (orElse == null){
    return _firstWhere(input.iterator, f ).then((object){
      if (object == null) throw "not found";
      else return object;
    });
  } else {
    return  _firstWhere(input.iterator, f).then((object){
      if (object == null) return orElse();
      else return object;
    });
  }
}

Future _firstWhere(Iterator itr, Future<bool> f(element)){
  if (itr.moveNext()){
    return f(itr.current).then((flag){
      if (flag){
        return itr.current;
      } else {
        return _firstWhere(itr, f);
      }
    });
  } else {
    return new Future.value(null);
  }
}