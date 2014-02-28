part of pub_proxy_server;

class PermissionStore {
  final Logger log = new Logger('PermissionStore');
  List<UserPermission> _userPermissions = [];
  
  bool isValidUser(username, password){
    log.fine("isValidUser $username $password");
    UserPermission per = _userPermissions.firstWhere((perm)=>perm.username == username, orElse: ()=>null);
    if (per == null) return false;
    return per.password == password;
  }
  
  bool isValideUserName(String email){
    log.fine("isValideUserName $email");
    return _userPermissions.any((each)=>each.username == email);
  }
  
  addPermission(UserPermission perm){
    _userPermissions.add(perm);
  }
  
}

class UserPermission {
  String username;
  String password;
  UserPermission(this.username,this.password);
  
}