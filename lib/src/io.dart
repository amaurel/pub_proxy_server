library pub_proxy_server.io;

import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final Logger log = new Logger('pub_proxy_server.io');

File moveFile(File file, String dir){
  return file.renameSync(path.join(dir, path.basename(file.path)));
}

void ensureDirectoryExist(dir){
  if (dir is String) dir = new Directory(dir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
}

Future<bool> checkSum(File file, String checsum){
  if (checsum == null){
    log.warning("_checkSum checsum is null $file");
    return new Future.value(true);
  }
  
  MD5 md5 = new MD5();
  return file.openRead().forEach((bytes)=>md5.add(bytes)).then((_){
    var cs = CryptoUtils.bytesToBase64(md5.close());
    if (cs != checsum) log.warning("_checkSum failed checsum $checsum but found $cs $file ");
    return cs == checsum;
  });
}

Future run(app,args,{String workingDirectory, runInShell: true, List<int> exitCodes}){
  if (exitCodes == null) exitCodes = [0];
  return Process.run(app, args, runInShell: runInShell, workingDirectory: workingDirectory).then((result) {
    //stdout.write(result.stdout);
    //stderr.write(result.stderr);
    if (exitCodes.contains(result.exitCode)){
      print("$app $args exit code ${result.exitCode}");
    }
    else {
      throw ("$app $args failed with exit code ${result.exitCode}");
    }
  });
}